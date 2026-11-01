import Database from "better-sqlite3";
import { existsSync, mkdirSync, readFileSync } from "node:fs";
import { join } from "node:path";

const dataDir = join(process.cwd(), "data");
if (!existsSync(dataDir)) {
  mkdirSync(dataDir, { recursive: true });
}

export const db = new Database(join(dataDir, "edtech.sqlite"));
db.pragma("foreign_keys = ON");

const SCHEMA_VERSION = 1;

// The departments table changed shape (duration_years -> category +
// duration_months for the flyer's 6-month panels). CREATE TABLE IF NOT EXISTS
// cannot alter an existing table, so drop the legacy shape and let the schema
// recreate it; it holds only reference rows, re-seeded from seed.sql below.
function migrateDepartmentsTable() {
  const columns = db
    .prepare("PRAGMA table_info(departments)")
    .all() as unknown as { name: string }[];
  if (columns.length === 0) return; // table does not exist yet
  const names = new Set(columns.map((c) => c.name));
  if (!names.has("category") || !names.has("duration_months")) {
    db.exec("DROP TABLE departments");
  }
}

/* ---------- schema versioning ---------- */

function ensureSchemaVersionTable() {
  db.prepare(
    `CREATE TABLE IF NOT EXISTS schema_version (
      version INTEGER PRIMARY KEY,
      applied_at TEXT NOT NULL DEFAULT (datetime('now'))
    )`,
  ).run();
}

function getSchemaVersion(): number {
  const row = db
    .prepare('SELECT version FROM schema_version ORDER BY version DESC LIMIT 1')
    .get() as { version: number } | undefined;
  return row?.version ?? 0;
}

function setSchemaVersion(version: number) {
  db.prepare(
    `INSERT INTO schema_version (version, applied_at) VALUES (?, datetime('now'))`,
  ).run(version);
}

/* Migration 0 → 1: baseline (all tables already exist via schema.sql).
 * Future migrations go here as the schema evolves. */
function migrateToV1() {
  // No-op: schema.sql already creates all tables with IF NOT EXISTS.
  // This migration exists to record that the baseline schema is applied.
}

function runMigrations() {
  ensureSchemaVersionTable();
  const current = getSchemaVersion();

  if (current < 1) {
    migrateToV1();
    setSchemaVersion(1);
  }
}

export function initDb() {
  migrateDepartmentsTable();

  const schema = readFileSync(join(process.cwd(), "db", "schema.sql"), "utf-8");
  db.exec(schema);

  const count = db.prepare("SELECT COUNT(*) AS c FROM users").get() as { c: number };
  const deptCount = db
    .prepare("SELECT COUNT(*) AS c FROM departments")
    .get() as { c: number };
  // Seed when the database is fresh, or when only the college reference rows
  // are missing (added later; INSERT OR IGNORE keeps re-seeding idempotent).
  if (count.c === 0 || deptCount.c === 0) {
    const seed = readFileSync(join(process.cwd(), "db", "seed.sql"), "utf-8");
    db.exec(seed);
  }

  runMigrations();
}
