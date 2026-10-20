import Database from "better-sqlite3";
import { existsSync, mkdirSync, readFileSync } from "node:fs";
import { join } from "node:path";

const dataDir = join(process.cwd(), "data");
if (!existsSync(dataDir)) {
  mkdirSync(dataDir, { recursive: true });
}

export const db = new Database(join(dataDir, "edtech.sqlite"));
db.pragma("foreign_keys = ON");

export function initDb() {
  const schema = readFileSync(join(process.cwd(), "db", "schema.sql"), "utf-8");
  db.exec(schema);

  const count = db.prepare("SELECT COUNT(*) AS c FROM users").get() as { c: number };
  if (count.c === 0) {
    const seed = readFileSync(join(process.cwd(), "db", "seed.sql"), "utf-8");
    db.exec(seed);
  }
}
