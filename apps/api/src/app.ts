import cors from "@fastify/cors";
import Fastify from "fastify";
import type { FastifyError } from "fastify";
import type { ApiError } from "@edtech/shared";
import { config } from "./config";
import { classroomRoutes } from "./routes/classroom";
import { courseRoutes } from "./routes/courses";
import { telemetryRoutes } from "./routes/telemetry";

export async function buildApp() {
  const app = Fastify({
    logger: {
      level: config.env === "production" ? "info" : "debug",
    },
  });

  await app.register(cors, { origin: config.corsOrigin });

  app.get("/health", async () => ({
    status: "ok",
    service: "edtech-api",
    version: "0.1.0",
    timestamp: new Date().toISOString(),
  }));

  await app.register(courseRoutes, { prefix: "/api/v1" });
  await app.register(telemetryRoutes, { prefix: "/api/v1" });
  await app.register(classroomRoutes, { prefix: "/api/v1" });

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
