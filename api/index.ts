import type { IncomingMessage, ServerResponse } from "node:http";
import { buildApp } from "../apps/api/src/app";

// Built once per cold start; SQLite opens and seeds inside buildApp().
const appPromise = buildApp();

// Fastify's documented Vercel adapter: reuse the ready app and hand it the
// raw Node request/response pair instead of listening on a port.
export default async function handler(
  req: IncomingMessage,
  res: ServerResponse,
) {
  const app = await appPromise;
  await app.ready();
  app.server.emit("request", req, res);
}
