import type { FastifyInstance, FastifyReply } from "fastify";
import type { ApiError } from "../store/db";
import { verifyToken } from "../routes/auth";

const fail = (
  reply: FastifyReply,
  statusCode: number,
  code: string,
  message: string,
) => reply.code(statusCode).send({ error: { code, message } } satisfies ApiError);

/** Extract the Bearer token from the Authorization header. */
function extractToken(authHeader: string | undefined): string | null {
  if (!authHeader || !authHeader.startsWith("Bearer ")) {
    return null;
  }
  return authHeader.substring(7);
}

/** Fastify preHandler: enforce a valid bearer token on every protected route.
 *  Sets `request.userId` so downstream handlers can scope data to the caller.
 *  Public routes (/health, /api/v1/auth/*) must register this hook themselves
 *  or skip it entirely. */
export async function authenticate(request: any, reply: FastifyReply) {
  const token = extractToken(request.headers.authorization);
  if (!token) {
    return fail(reply, 401, "UNAUTHORIZED", "Missing or invalid token");
  }

  const userId = verifyToken(token);
  if (!userId) {
    return fail(reply, 401, "UNAUTHORIZED", "Invalid or expired token");
  }

  request.userId = userId;
}

/** Role guard: only allow the given roles. Must run after `authenticate`. */
export function requireRoles(...allowed: string[]) {
  return async (request: any, reply: FastifyReply) => {
    const userId = request.userId;
    const { getUser } = await import("../store/db");
    const user = await getUser(userId);
    if (!user || !allowed.includes(user.role)) {
      return fail(reply, 403, "FORBIDDEN", "Insufficient role for this route");
    }
  };
}
