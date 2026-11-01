import cors from "@fastify/cors";
import Fastify from "fastify";
import type { FastifyError } from "fastify";
import { authenticate } from "./middleware/auth";
import { config } from "./config";
import { initDb } from "./db";

interface ApiError {
  error: { code: string; message: string };
}
import { authRoutes } from "./routes/auth";
import { classroomRoutes } from "./routes/classroom";
import { courseRoutes } from "./routes/courses";
import { telemetryRoutes } from "./routes/telemetry";
import studentsRoutes from "./routes/students";
import departmentsRoutes from "./routes/departments";
import attendanceRoutes from "./routes/attendance";
import notesRoutes from "./routes/notes";
import excelRoutes from "./routes/excel";

const PUBLIC_PREFIXES = ["/health", "/api/v1/auth"];

export async function buildApp() {
  await initDb();

  const app = Fastify({
    logger: {
      level: config.env === "production" ? "info" : "debug",
    },
  });

  await app.register(cors, { origin: config.corsOrigin });

  // Enforce bearer-token authentication on every route except public ones.
  app.addHook("preHandler", async (request, reply) => {
    // Fastify v5 renamed routerPath -> routeOptions.url.
    const url = request.routeOptions?.url ?? request.url;
    if (PUBLIC_PREFIXES.some((prefix) => url.startsWith(prefix))) {
      return;
    }
    await authenticate(request, reply);
  });

  app.get("/health", async () => ({
    status: "ok",
    service: "edtech-api",
    version: "0.1.0",
    timestamp: new Date().toISOString(),
  }));

  await app.register(courseRoutes, { prefix: "/api/v1" });
  await app.register(telemetryRoutes, { prefix: "/api/v1" });
  await app.register(classroomRoutes, { prefix: "/api/v1" });
  await app.register(authRoutes, { prefix: "/api/v1/auth" });
  await app.register(studentsRoutes, { prefix: "/api/v1" });
  await app.register(departmentsRoutes, { prefix: "/api/v1" });
  await app.register(attendanceRoutes, { prefix: "/api/v1" });
  await app.register(notesRoutes, { prefix: "/api/v1" });
  await app.register(excelRoutes, { prefix: "/api/v1" });

  app.setNotFoundHandler((request, reply) => {
    const error: ApiError = {
      error: {
        code: "ROUTE_NOT_FOUND",
        message: `Route ${request.method} ${request.url} not found`,
      },
    };
    return reply.code(404).send(error);
  });

  app.setErrorHandler((error: FastifyError, request, reply) => {
    const statusCode = error.statusCode ?? 500;
    if (statusCode >= 500) {
      request.log.error(error);
    }

    const payload: ApiError = {
      error: {
        code: statusCode >= 500 ? "INTERNAL_ERROR" : "BAD_REQUEST",
        message:
          statusCode >= 500 ? "An unexpected error occurred" : error.message,
      },
    };
    return reply.code(statusCode).send(payload);
  });

  return app;
}
