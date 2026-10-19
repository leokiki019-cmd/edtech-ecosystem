import { buildApp } from "./app";
import { config } from "./config";

const app = await buildApp();

try {
  await app.listen({ host: config.host, port: config.port });
} catch (error) {
  app.log.error(error);
  process.exit(1);
}
