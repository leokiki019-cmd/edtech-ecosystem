const parsedPort = Number.parseInt(process.env.PORT ?? "4000", 10);

export const config = {
  env: process.env.NODE_ENV ?? "development",
  // Dev fallback keeps local setup frictionless; set AUTH_SECRET in production.
  authSecret: process.env.AUTH_SECRET ?? "edtech-dev-secret-change-me",
  host: process.env.HOST ?? "0.0.0.0",
  port: Number.isFinite(parsedPort) ? parsedPort : 4000,
  corsOrigin: process.env.CORS_ORIGIN ?? "*",
};
