import type { IncomingMessage, ServerResponse } from "node:http";
import { buildApp } from "../apps/api/src/create-app";

// Built once per cold start and reused across invocations. The store is
// in-memory, so there is no file or network dependency to resolve here.
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
