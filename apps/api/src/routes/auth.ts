import crypto from "node:crypto";
import type { FastifyInstance, FastifyReply } from "fastify";
import type { ApiError, User } from "@edtech/shared";
import {
  createUser,
  getUser,
  getUserAuthByPhone,
  getUserAuthByEmail,
  getUserByPhone,
  getUsers,
  createSmsCode,
  verifySmsCode,
  markPhoneVerified,
} from "../store/db";
import { config } from "../config";

const TOKEN_TTL_SECONDS = 7 * 24 * 60 * 60; // 7 days

const fail = (
  reply: FastifyReply,
  statusCode: number,
  code: string,
  message: string,
) => reply.code(statusCode).send({ error: { code, message } } satisfies ApiError);

/* ---------- password hashing (scrypt with per-user salt) ---------- */

export function hashPassword(password: string): string {
  const salt = crypto.randomBytes(16).toString("hex");
  const derived = crypto.scryptSync(password, salt, 64).toString("hex");
  return `scrypt$${salt}$${derived}`;
}

export function verifyPassword(password: string, stored: string): boolean {
  const [scheme, salt, hash] = stored.split("$");
  if (scheme !== "scrypt" || !salt || !hash) {
    return false;
  }
  const derived = crypto.scryptSync(password, salt, 64);
  const expected = Buffer.from(hash, "hex");
  return (
    derived.length === expected.length && crypto.timingSafeEqual(derived, expected)
  );
}

/* ---------- signed bearer tokens (HMAC-SHA256) ---------- */

export function generateToken(userId: string): string {
  const issuedAt = Math.floor(Date.now() / 1000);
  const payload = {
    sub: userId,
    iat: issuedAt,
    exp: issuedAt + TOKEN_TTL_SECONDS,
  };
  const body = Buffer.from(JSON.stringify(payload)).toString("base64url");
  const signature = crypto
    .createHmac("sha256", config.authSecret)
    .update(body)
    .digest("base64url");
  return `${body}.${signature}`;
}

export function verifyToken(token: string): string | null {
  const separator = token.lastIndexOf(".");
  if (separator <= 0) {
    return null;
  }
  const body = token.slice(0, separator);
  const signature = token.slice(separator + 1);
  const expected = crypto
    .createHmac("sha256", config.authSecret)
    .update(body)
    .digest("base64url");

  const provided = Buffer.from(signature);
  const wanted = Buffer.from(expected);
  if (provided.length !== wanted.length || !crypto.timingSafeEqual(provided, wanted)) {
    return null;
  }

  try {
    const payload = JSON.parse(Buffer.from(body, "base64url").toString("utf-8"));
    if (typeof payload.sub !== "string" || typeof payload.exp !== "number") {
      return null;
    }
    if (payload.exp < Math.floor(Date.now() / 1000)) {
      return null;
    }
    return payload.sub;
  } catch {
    return null;
  }
}

function generateSmsCode(): string {
  return crypto.randomInt(100000, 999999).toString();
}

export async function authRoutes(app: FastifyInstance) {
  // Register new user
  app.post<{
    Body: {
      phone?: string;
      email?: string;
      display_name?: string;
      password?: string;
      role?: string;
    };
  }>("/register", async (request, reply) => {
    const { phone, email, display_name, password, role } = request.body ?? {};

    if (!phone && !email) {
      return fail(reply, 400, "INVALID_BODY", "Phone or email is required");
    }

    if (!password || password.length < 6) {
      return fail(
        reply,
        400,
        "INVALID_BODY",
        "Password must be at least 6 characters",
      );
    }

    if (role !== undefined && role !== "student" && role !== "teacher") {
      return fail(
        reply,
        400,
        "INVALID_BODY",
        "Role must be student or teacher",
      );
    }

    if (phone) {
      const existingByPhone = await getUserByPhone(phone);
      if (existingByPhone) {
        return fail(reply, 409, "USER_EXISTS", "User with this phone already exists");
      }
    }

    if (email) {
      const existingByEmail = (await getUsers()).find((u) => u.email === email);
      if (existingByEmail) {
        return fail(reply, 409, "USER_EXISTS", "User with this email already exists");
      }
    }

    const id = crypto.randomUUID();

    const user = await createUser({
      id,
      displayName: display_name || "New User",
      email: email || "",
      phone: phone || "",
      role: role || "student",
      courseIds: [],
      passwordHash: hashPassword(password),
      isPhoneVerified: 0,
    });

    const token = generateToken(user.id);

    return reply.code(201).send({
      data: { user: publicUser(user), token },
    });
  });

  // Login with phone/email + password
  app.post<{
    Body: {
      phone?: string;
      email?: string;
      password?: string;
    };
  }>("/login", async (request, reply) => {
    const { phone, email, password } = request.body ?? {};

    if (!phone && !email) {
      return fail(reply, 400, "INVALID_BODY", "Phone or email is required");
    }

    if (!password) {
      return fail(reply, 400, "INVALID_BODY", "Password is required");
    }

    const credentials = phone
      ? await getUserAuthByPhone(phone)
      : await getUserAuthByEmail(email!);

    if (
      !credentials ||
      !credentials.passwordHash ||
      !verifyPassword(password, credentials.passwordHash)
    ) {
      return fail(reply, 401, "INVALID_CREDENTIALS", "Invalid phone/email or password");
    }

    const user = await getUser(credentials.id);
    if (!user) {
      return fail(reply, 401, "INVALID_CREDENTIALS", "Invalid phone/email or password");
    }

    const token = generateToken(user.id);

    return {
      data: { user: publicUser(user), token },
    };
  });

  // Send SMS verification code
  app.post<{
    Body: { phone?: string };
  }>("/send-sms", async (request, reply) => {
    const { phone } = request.body ?? {};

    if (!phone) {
      return fail(reply, 400, "INVALID_BODY", "Phone is required");
    }

    const user = await getUserByPhone(phone);
    if (!user) {
      return fail(reply, 404, "USER_NOT_FOUND", "No account is registered for this phone");
    }

    const code = generateSmsCode();
    const expiresAt = new Date(Date.now() + 10 * 60 * 1000).toISOString(); // 10 min

    await createSmsCode({
      id: crypto.randomUUID(),
      phone,
      code,
      expiresAt,
    });

    // In production an SMS provider (Twilio/Vonage) would deliver this code.
    // The code is only echoed outside production to support local demos.
    if (config.env !== "production") {
      app.log.info({ phone }, `SMS verification code: ${code}`);
    }

    return {
      data: {
        message: "Verification code sent",
        phone,
        ...(config.env !== "production" ? { code } : {}),
      },
    };
  });

  // Verify SMS code
  app.post<{
    Body: { phone?: string; code?: string };
  }>("/verify-sms", async (request, reply) => {
    const { phone, code } = request.body ?? {};

    if (!phone || !code) {
      return fail(reply, 400, "INVALID_BODY", "Phone and code are required");
    }

    const valid = await verifySmsCode(phone, code);
    if (!valid) {
      return fail(reply, 400, "INVALID_CODE", "Invalid or expired verification code");
    }

    const user = await getUserByPhone(phone);
    if (!user) {
      return fail(reply, 404, "USER_NOT_FOUND", "User not found");
    }

    await markPhoneVerified(phone);

    const token = generateToken(user.id);

    return {
      data: { user: publicUser(user), token },
    };
  });

  // Get current user from token
  app.get<{ Headers: { authorization?: string } }>("/me", async (request, reply) => {
    const authHeader = request.headers.authorization;
    if (!authHeader || !authHeader.startsWith("Bearer ")) {
      return fail(reply, 401, "UNAUTHORIZED", "Missing or invalid token");
    }

    const token = authHeader.substring(7);
    const userId = verifyToken(token);
    if (!userId) {
      return fail(reply, 401, "UNAUTHORIZED", "Invalid or expired token");
    }

    const user = await getUser(userId);
    if (!user) {
      return fail(reply, 404, "USER_NOT_FOUND", "User not found");
    }

    return { data: { user: publicUser(user) } };
  });
}

/** Strip server-only fields before returning a user to a client. */
function publicUser(user: User): Omit<User, "passwordHash"> {
  const { passwordHash: _ignored, ...safe } = user;
  return safe;
}
