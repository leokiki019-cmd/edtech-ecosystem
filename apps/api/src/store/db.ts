// @ts-nocheck
import initSqlJs from 'sql.js';
import type { Database as SqlJsDatabase, Statement as SqlStatement } from 'sql.js';
import { existsSync, mkdirSync, readFileSync, writeFileSync } from 'node:fs';
import { join } from 'node:path';
import { randomUUID } from 'node:crypto';

// sql.js is pure JavaScript + WebAssembly - works on Vercel serverless
// without native compilation (unlike better-sqlite3).
let dbInstance: SqlJsDatabase | null = null;

async function initDatabase(): Promise<SqlJsDatabase> {
  const SQL = await initSqlJs();

  // Get database path
  const defaultDataDir = process.env.VERCEL
    ? '/tmp/edtech-data'
    : join(process.cwd(), 'data');
  const dataDir = process.env.DATA_DIR ?? defaultDataDir;
  if (!existsSync(dataDir)) {
    mkdirSync(dataDir, { recursive: true });
  }
  const dbPath = join(dataDir, 'edtech.sqlite');

  // Try to load existing database from file
  let buffer: Uint8Array | null = null;
  try {
    if (existsSync(dbPath)) {
      buffer = readFileSync(dbPath);
    }
  } catch {
    // File doesn't exist yet, start fresh
  }

  const db = new (SQL as any).Database(buffer ? { file: buffer } : {});

  // Enable foreign keys
  db.run('PRAGMA foreign_keys = ON');

  return db;
}

// Initialize database at module load time
const dbPromise = initDatabase();
dbPromise.then((db) => {
  dbInstance = db;
});

function getDb(): any {
  if (!dbInstance) {
    throw new Error('Database not initialized');
  }
  return dbInstance;
}

function saveDbToFile(db: SqlJsDatabase): void {
  const defaultDataDir = process.env.VERCEL
    ? '/tmp/edtech-data'
    : join(process.cwd(), 'data');
  const dataDir = process.env.DATA_DIR ?? defaultDataDir;
  const dbPath = join(dataDir, 'edtech.sqlite');
  try {
    const data = db.export();
    writeFileSync(dbPath, Buffer.from(data as Uint8Array));
  } catch {
    // Best-effort persistence
  }
}

const SCHEMA_VERSION = 1;

function parseJson<T>(value: string | null, fallback: T): T {
  if (value === null || value === undefined) return fallback;
  try {
    return JSON.parse(value);
  } catch {
    return fallback;
  }
}

function normDate(value: string | null): string | null {
  if (!value) return value;
  if (value.includes("T")) return value;
  return `${value.replace(" ", "T")}Z`;
}

// ============================================
// Types
// ============================================

export type Role = "student" | "teacher" | "admin";

export interface User {
  id: string;
  displayName: string;
  email: string;
  phone: string;
  role: Role;
  courseIds: string[];
  passwordHash?: string;
  isPhoneVerified?: boolean;
  createdAt: string;
}

export interface College {
  id: string;
  name: string;
  shortName: string;
  createdAt: string;
}

export type DepartmentCategory = "3 Years" | "2 Years" | "6 Months" | "2 Years Paramedical";

export interface Department {
  id: string;
  collegeId: string;
  name: string;
  code: string;
  category: DepartmentCategory;
  durationMonths: number;
  createdAt: string;
}

export type AssignmentStatus = "draft" | "open" | "closed";
export type SubmissionStatus = "pending" | "submitted" | "graded" | "late" | "missing";

export interface Attachment {
  id: string;
  fileName: string;
  mimeType: string;
  sizeBytes: number;
  url: string;
}

export interface Assignment {
  id: string;
  courseId: string;
  title: string;
  brief: string;
  dueAt: string;
  status: AssignmentStatus;
  createdAt: string;
}

export interface Submission {
  id: string;
  assignmentId: string;
  studentId: string;
  status: SubmissionStatus;
  submittedAt: string | null;
  attachments: Attachment[];
  grade: number | null;
  effortScore: number | null;
}

export type CalendarEventKind = "assignment" | "quiz" | "class" | "institution";

export interface CalendarEvent {
  id: string;
  courseId: string | null;
  title: string;
  kind: CalendarEventKind;
  startsAt: string;
  endsAt: string | null;
}

export type ChatChannelKind = "announcement" | "discussion";

export interface ChatChannel {
  id: string;
  courseId: string;
  name: string;
  kind: ChatChannelKind;
  memberIds: string[];
}

export interface ChatMessage {
  id: string;
  channelId: string;
  authorId: string;
  body: string;
  sentAt: string;
}

export type TelemetryEventType = "keystroke" | "cursor" | "paste" | "focus" | "blur" | "ai_tab_switch";

export interface TelemetryEvent {
  id: string;
  sessionId: string;
  assignmentId: string;
  studentId: string;
  type: TelemetryEventType;
  occurredAt: string;
  payload: Record<string, number | string | boolean>;
}

export interface SignedTelemetryBatch {
  batchId: string;
  studentId: string;
  assignmentId: string;
  events: TelemetryEvent[];
  clientSignature: string;
  clientPublicKey: string;
  createdAt: string;
}

export interface EffortScore {
  sessionId: string;
  assignmentId: string;
  studentId: string;
  score: number;
  keystrokes: number;
  pastes: number;
  pasteVolume: number;
  aiTabSwitches: number;
  activeSeconds: number;
  computedAt: string;
}

export type IntegrityFlag = "none" | "large_paste" | "ai_tab_switch" | "low_typing_ratio" | "telemetry_gap";

export interface IntegrityReport {
  submissionId: string | null;
  assignmentId: string;
  studentId: string;
  effortScore: EffortScore;
  flags: IntegrityFlag[];
  replayAvailable: boolean;
  generatedAt: string;
}

export interface ApiError {
  error: { code: string; message: string };
}

export interface ApiResponse<T> {
  data: T;
}

export interface AttendanceRecord {
  id: string;
  courseId: string;
  studentId: string;
  date: string;
  status: 'present' | 'absent' | 'late' | 'excused';
  markedBy: string;
  notes: string;
  createdAt: string;
}

export interface TeacherNote {
  id: string;
  courseId: string;
  bookName: string;
  courseCode: string;
  title: string;
  content: string;
  authorId: string;
  createdAt: string;
  updatedAt: string;
}

export interface StudentDepartment {
  id: string;
  studentId: string;
  departmentId: string;
  enrolledAt: string;
  enrolledBy: string;
}

export interface SmsCode {
  id: string;
  phone: string;
  code: string;
  expiresAt: string;
  createdAt?: string;
}

// ============================================
// INITIALIZATION
// ============================================

export async function initDb(): Promise<void> {
  await dbPromise;
  const db = getDb();
  runMigrations(db);
  seedIfEmpty(db);
}

function migrateDepartmentsTable(db: SqlJsDatabase): void {
  const columns = db.prepare("PRAGMA table_info(departments)").all() as unknown as { name: string }[];
  if (columns.length === 0) return;
  const names = new Set(columns.map((c) => c.name));
  if (!names.has("category") || !names.has("duration_months")) {
    db.run("DROP TABLE departments");
  }
}

function ensureSchemaVersionTable(db: SqlJsDatabase): void {
  db.prepare(
    `CREATE TABLE IF NOT EXISTS schema_version (
      version INTEGER PRIMARY KEY,
      applied_at TEXT NOT NULL DEFAULT (datetime('now'))
    )`
  ).run();
}

function getSchemaVersion(db: SqlJsDatabase): number {
  const row = db.prepare('SELECT version FROM schema_version ORDER BY version DESC LIMIT 1').get() as { version: number } | undefined;
  return row?.version ?? 0;
}

function setSchemaVersion(db: SqlJsDatabase, version: number): void {
  db.prepare(
    `INSERT INTO schema_version (version, applied_at) VALUES (?, datetime('now'))`
  ).run(version);
}

function migrateToV1(db: SqlJsDatabase): void {
  // No-op: schema.sql already creates all tables with IF NOT EXISTS.
}

function runMigrations(db: SqlJsDatabase): void {
  ensureSchemaVersionTable(db);
  const current = getSchemaVersion(db);
  if (current < 1) {
    migrateToV1(db);
    setSchemaVersion(db, 1);
  }
}

function readSql(name: string): string {
  const candidates = [
    join(process.cwd(), 'db', name),
    join(process.cwd(), 'apps', 'api', 'db', name),
    join(process.cwd(), 'apps/api/db', name),
  ];
  for (const candidate of candidates) {
    if (existsSync(candidate)) {
      return readFileSync(candidate, 'utf-8');
    }
  }
  throw new Error(`Cannot find db/${name}. Looked in: ${candidates.join(", ")}`);
}

function seedIfEmpty(db: SqlJsDatabase): void {
  migrateDepartmentsTable(db);

  const schema = readSql('schema.sql');
  db.exec(schema);

  const count = db.prepare("SELECT COUNT(*) AS c FROM users").get() as { c: number };
  const deptCount = db.prepare("SELECT COUNT(*) AS c FROM departments").get() as { c: number };

  if (count.c === 0 || deptCount.c === 0) {
    db.exec(readSql('seed.sql'));
  }

  runMigrations(db);
  saveDbToFile(db);
}

// ============================================
// USERS
// ============================================

function toUser(row: any): User {
  return {
    id: row.id,
    displayName: row.display_name,
    email: row.email,
    phone: row.phone,
    role: row.role as Role,
    courseIds: parseJson(row.course_ids, []),
    isPhoneVerified: Boolean(row.is_phone_verified),
    createdAt: normDate(row.created_at) ?? row.created_at,
  };
}

export function getUsers(): User[] {
  const db = getDb();
  return (db.prepare('SELECT * FROM users').all() as unknown as any[]).map(toUser);
}

export function getUser(userId: string): User | undefined {
  const db = getDb();
  const row = db.prepare('SELECT * FROM users WHERE id = ?').get(userId) as any;
  if (!row) return undefined;
  return toUser(row);
}

export function getUserByPhone(phone: string): User | undefined {
  const db = getDb();
  const row = db.prepare('SELECT * FROM users WHERE phone = ?').get(phone) as any;
  if (!row) return undefined;
  return toUser(row);
}

export function getUserAuthByPhone(phone: string): { id: string; passwordHash: string | null } | undefined {
  const db = getDb();
  const row = db.prepare('SELECT id, password_hash FROM users WHERE phone = ?').get(phone) as any;
  if (!row) return undefined;
  return { id: row.id, passwordHash: row.password_hash };
}

export function getUserAuthByEmail(email: string): { id: string; passwordHash: string | null } | undefined {
  const db = getDb();
  const row = db.prepare('SELECT id, password_hash FROM users WHERE email = ?').get(email) as any;
  if (!row) return undefined;
  return { id: row.id, passwordHash: row.password_hash };
}

export function createUser(input: {
  id: string;
  displayName: string;
  email: string;
  phone: string;
  role: Role;
  courseIds: string[];
  passwordHash: string;
  isPhoneVerified: number;
  createdAt?: string;
}): User {
  const db = getDb();
  const createdAt = input.createdAt || new Date().toISOString();
  db.prepare(
    `INSERT INTO users (id, display_name, email, phone, role, course_ids, password_hash, is_phone_verified, created_at)
     VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)`
  ).run(
    input.id,
    input.displayName,
    input.email,
    input.phone,
    input.role,
    JSON.stringify(input.courseIds),
    input.passwordHash,
    input.isPhoneVerified,
    createdAt,
  );
  saveDbToFile(db);
  return getUser(input.id)!;
}

export function updateUser(userId: string, updates: Partial<{
  displayName: string;
  email: string;
  phone: string;
  passwordHash: string;
  isPhoneVerified: number;
}>): void {
  const db = getDb();
  const sets: string[] = [];
  const params: any[] = [];
  if (updates.displayName !== undefined) {
    sets.push('display_name = ?');
    params.push(updates.displayName);
  }
  if (updates.email !== undefined) {
    sets.push('email = ?');
    params.push(updates.email);
  }
  if (updates.phone !== undefined) {
    sets.push('phone = ?');
    params.push(updates.phone);
  }
  if (updates.passwordHash !== undefined) {
    sets.push('password_hash = ?');
    params.push(updates.passwordHash);
  }
  if (updates.isPhoneVerified !== undefined) {
    sets.push('is_phone_verified = ?');
    params.push(updates.isPhoneVerified);
  }
  params.push(userId);
  db.prepare(`UPDATE users SET ${sets.join(', ')} WHERE id = ?`).run(...params);
  saveDbToFile(db);
}

// ============================================
// COURSES
// ============================================

function toCourse(row: any): Course {
  return {
    id: row.id,
    title: row.title,
    code: row.code,
    teacherId: row.teacher_id,
    studentIds: parseJson(row.student_ids, []),
    term: row.term,
    createdAt: normDate(row.created_at) ?? row.created_at,
  };
}

export function getCourses(): Course[] {
  const db = getDb();
  return (db.prepare('SELECT * FROM courses').all() as unknown as any[]).map(toCourse);
}

export function getCourse(courseId: string): Course | undefined {
  const db = getDb();
  const row = db.prepare('SELECT * FROM courses WHERE id = ?').get(courseId) as any;
  if (!row) return undefined;
  return toCourse(row);
}

export function getAssignmentsByCourse(courseId: string): Assignment[] {
  const db = getDb();
  return (db
    .prepare('SELECT * FROM assignments WHERE course_id = ? ORDER BY due_at')
    .all(courseId) as unknown as any[]).map((row: any) => ({
      id: row.id,
      courseId: row.course_id,
      title: row.title,
      brief: row.brief,
      dueAt: normDate(row.due_at) ?? row.due_at,
      status: row.status,
      createdAt: normDate(row.created_at) ?? row.created_at,
    }));
}

export function addStudentToCourse(courseId: string, studentId: string): void {
  const db = getDb();
  const course = db.prepare('SELECT student_ids FROM courses WHERE id = ?').get(courseId) as { student_ids: string } | undefined;
  if (!course) return;
  const ids = parseJson(course.student_ids, []);
  if (!ids.includes(studentId)) {
    ids.push(studentId);
    db.prepare('UPDATE courses SET student_ids = ? WHERE id = ?').run(JSON.stringify(ids), courseId);
    saveDbToFile(db);
  }
}

export function removeStudentFromCourse(courseId: string, studentId: string): void {
  const db = getDb();
  const course = db.prepare('SELECT student_ids FROM courses WHERE id = ?').get(courseId) as { student_ids: string } | undefined;
  if (!course) return;
  const ids = parseJson(course.student_ids, []).filter((id: string) => id !== studentId);
  db.prepare('UPDATE courses SET student_ids = ? WHERE id = ?').run(JSON.stringify(ids), courseId);
  saveDbToFile(db);
}

// ============================================
// COLLEGE
// ============================================

function toCollege(row: any): College {
  return {
    id: row.id,
    name: row.name,
    shortName: row.short_name,
    createdAt: normDate(row.created_at) ?? row.created_at,
  };
}

export function getColleges(): College[] {
  const db = getDb();
  return (db.prepare('SELECT * FROM colleges ORDER BY name').all() as unknown as any[]).map(toCollege);
}

export function getCollege(collegeId: string): College | undefined {
  const db = getDb();
  const row = db.prepare('SELECT * FROM colleges WHERE id = ?').get(collegeId) as any;
  if (!row) return undefined;
  return toCollege(row);
}

export function getDepartments(collegeId: string): Department[] {
  const db = getDb();
  return (db
    .prepare('SELECT * FROM departments WHERE college_id = ? ORDER BY name')
    .all(collegeId) as unknown as any[]).map((row: any) => ({
      id: row.id,
      collegeId: row.college_id,
      name: row.name,
      code: row.code,
      category: row.category,
      durationMonths: row.duration_months,
      createdAt: normDate(row.created_at) ?? row.created_at,
    }));
}

// ============================================
// ASSIGNMENTS
// ============================================

function toAssignment(row: any): Assignment {
  return {
    id: row.id,
    courseId: row.course_id,
    title: row.title,
    brief: row.brief,
    dueAt: normDate(row.due_at) ?? row.due_at,
    status: row.status,
    createdAt: normDate(row.created_at) ?? row.created_at,
  };
}

export function getAssignment(assignmentId: string): Assignment | undefined {
  const db = getDb();
  const row = db.prepare('SELECT * FROM assignments WHERE id = ?').get(assignmentId) as any;
  if (!row) return undefined;
  return toAssignment(row);
}

// ============================================
// SUBMISSIONS
// ============================================

function toSubmission(row: any): Submission {
  return {
    id: row.id,
    assignmentId: row.assignment_id,
    studentId: row.student_id,
    status: row.status,
    submittedAt: normDate(row.submitted_at),
    attachments: parseJson(row.attachments, []),
    grade: row.grade,
    effortScore: row.effort_score,
  };
}

export function getSubmissionsByAssignment(assignmentId: string): Submission[] {
  const db = getDb();
  return (db
    .prepare('SELECT * FROM submissions WHERE assignment_id = ?')
    .all(assignmentId) as unknown as any[]).map(toSubmission);
}

export function getSubmission(submissionId: string): Submission | undefined {
  const db = getDb();
  const row = db.prepare('SELECT * FROM submissions WHERE id = ?').get(submissionId) as any;
  if (!row) return undefined;
  return toSubmission(row);
}

export function createSubmission(input: {
  assignmentId: string;
  studentId: string;
  status: Submission['status'];
  submittedAt: string | null;
  attachments: { fileName: string; mimeType: string; sizeBytes: number; url: string }[];
}): Submission {
  const db = getDb();
  const id = randomUUID();
  const now = new Date().toISOString();
  const attachmentsWithIds = input.attachments.map((a) => ({
    ...a,
    id: randomUUID(),
  }));
  db.prepare(
    `INSERT INTO submissions (id, assignment_id, student_id, status, submitted_at, attachments, grade, effort_score, created_at)
     VALUES (?, ?, ?, ?, ?, ?, NULL, NULL, ?)`
  ).run(
    id,
    input.assignmentId,
    input.studentId,
    input.status,
    input.submittedAt,
    JSON.stringify(attachmentsWithIds),
    now
  );
  saveDbToFile(db);
  return {
    id,
    assignmentId: input.assignmentId,
    studentId: input.studentId,
    status: input.status,
    submittedAt: input.submittedAt,
    attachments: attachmentsWithIds,
    grade: null,
    effortScore: null,
  };
}

export function updateSubmission(
  submissionId: string,
  updates: Partial<Pick<Submission, 'status' | 'submittedAt' | 'attachments' | 'grade' | 'effortScore'>>
): void {
  const db = getDb();
  const sets: string[] = [];
  const params: any[] = [];
  if (updates.status !== undefined) {
    sets.push('status = ?');
    params.push(updates.status);
  }
  if (updates.submittedAt !== undefined) {
    sets.push('submitted_at = ?');
    params.push(updates.submittedAt);
  }
  if (updates.attachments !== undefined) {
    sets.push('attachments = ?');
    params.push(JSON.stringify(updates.attachments));
  }
  if (updates.grade !== undefined) {
    sets.push('grade = ?');
    params.push(updates.grade);
  }
  if (updates.effortScore !== undefined) {
    sets.push('effort_score = ?');
    params.push(updates.effortScore);
  }
  params.push(submissionId);
  db.prepare(`UPDATE submissions SET ${sets.join(', ')} WHERE id = ?`).run(...params);
  saveDbToFile(db);
}

// ============================================
// CALENDAR
// ============================================

export function getCalendarEvents(courseIds: Set<string>): CalendarEvent[] {
  const db = getDb();
  if (courseIds.size === 0) {
    return (db
      .prepare('SELECT * FROM calendar_events WHERE course_id IS NULL')
      .all() as unknown as any[]).map((row: any) => ({
        id: row.id,
        courseId: row.course_id,
        title: row.title,
        kind: row.kind,
        startsAt: normDate(row.starts_at) ?? row.starts_at,
        endsAt: normDate(row.ends_at),
      }));
  }
  const conditions = [...courseIds].map(() => 'course_id = ?').join(' OR ');
  return (db
    .prepare(`SELECT * FROM calendar_events WHERE course_id IS NULL OR ${conditions}`)
    .all(...[...courseIds]) as unknown as any[]).map((row: any) => ({
      id: row.id,
      courseId: row.course_id,
      title: row.title,
      kind: row.kind,
      startsAt: normDate(row.starts_at) ?? row.starts_at,
      endsAt: normDate(row.ends_at),
    }));
}

// ============================================
// CHAT CHANNELS
// ============================================

export function getChannelsByCourse(courseId: string): ChatChannel[] {
  const db = getDb();
  return (db
    .prepare('SELECT * FROM chat_channels WHERE course_id = ?')
    .all(courseId) as unknown as any[]).map((row: any) => ({
      id: row.id,
      courseId: row.course_id,
      name: row.name,
      kind: row.kind,
      memberIds: parseJson(row.member_ids, []),
    }));
}

export function getChannel(channelId: string): ChatChannel | undefined {
  const db = getDb();
  const row = db.prepare('SELECT * FROM chat_channels WHERE id = ?').get(channelId) as any;
  if (!row) return undefined;
  return {
    id: row.id,
    courseId: row.course_id,
    name: row.name,
    kind: row.kind,
    memberIds: parseJson(row.member_ids, []),
  };
}

export function getMessages(channelId: string): ChatMessage[] {
  const db = getDb();
  return (db
    .prepare('SELECT * FROM chat_messages WHERE channel_id = ? ORDER BY sent_at')
    .all(channelId) as unknown as any[]).map((row: any) => ({
      id: row.id,
      channelId: row.channel_id,
      authorId: row.author_id,
      body: row.body,
      sentAt: normDate(row.sent_at) ?? row.sent_at,
    }));
}

export function createMessage(input: {
  channelId: string;
  authorId: string;
  body: string;
}): ChatMessage {
  const db = getDb();
  const id = randomUUID();
  const now = new Date().toISOString();
  db.prepare(
    'INSERT INTO chat_messages (id, channel_id, author_id, body, sent_at) VALUES (?, ?, ?, ?, ?)'
  ).run(id, input.channelId, input.authorId, input.body, now);
  saveDbToFile(db);
  return { id, channelId: input.channelId, authorId: input.authorId, body: input.body, sentAt: now };
}

// ============================================
// TELEMETRY
// ============================================

export function getTelemetryBatches(): SignedTelemetryBatch[] {
  const db = getDb();
  return db.prepare('SELECT * FROM telemetry_batches').all() as unknown as SignedTelemetryBatch[];
}

export function createTelemetryBatch(batch: SignedTelemetryBatch): void {
  const db = getDb();
  const stmt = db.prepare(
    `INSERT INTO telemetry_batches (batch_id, student_id, assignment_id, client_signature, client_public_key, created_at)
     VALUES (?, ?, ?, ?, ?, ?)`
  );
  stmt.run(
    batch.batchId,
    batch.studentId,
    batch.assignmentId,
    batch.clientSignature,
    batch.clientPublicKey,
    batch.createdAt
  );
  const eventStmt = db.prepare(
    `INSERT INTO telemetry_events (id, batch_id, session_id, type, occurred_at, payload)
     VALUES (?, ?, ?, ?, ?, ?)`
  );
  for (const event of batch.events) {
    eventStmt.run(
      event.id,
      batch.batchId,
      event.sessionId,
      event.type,
      event.occurredAt,
      JSON.stringify(event.payload)
    );
  }
  saveDbToFile(db);
}

// ============================================
// EFFORT & INTEGRITY
// ============================================

export function getEffortScore(studentId: string, assignmentId: string): EffortScore | undefined {
  const db = getDb();
  const row = db
    .prepare('SELECT * FROM effort_scores WHERE student_id = ? AND assignment_id = ?')
    .get(studentId, assignmentId) as any;
  if (!row) return undefined;
  return {
    sessionId: row.session_id,
    assignmentId: row.assignment_id,
    studentId: row.student_id,
    score: row.score,
    keystrokes: row.keystrokes,
    pastes: row.pastes,
    pasteVolume: row.paste_volume,
    aiTabSwitches: row.ai_tab_switches,
    activeSeconds: row.active_seconds,
    computedAt: row.computed_at,
  };
}

export function setEffortScore(score: EffortScore): void {
  const db = getDb();
  db.prepare(
    `INSERT OR REPLACE INTO effort_scores (session_id, assignment_id, student_id, score, keystrokes, pastes, paste_volume, ai_tab_switches, active_seconds, computed_at)
     VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`
  ).run(
    score.sessionId,
    score.assignmentId,
    score.studentId,
    score.score,
    score.keystrokes,
    score.pastes,
    score.pasteVolume,
    score.aiTabSwitches,
    score.activeSeconds,
    score.computedAt
  );
  saveDbToFile(db);
}

export function getIntegrityFlags(studentId: string, assignmentId: string): IntegrityFlag[] {
  const db = getDb();
  const rows = db
    .prepare('SELECT flag FROM integrity_flags WHERE student_id = ? AND assignment_id = ?')
    .all(studentId, assignmentId) as { flag: string }[];
  return rows.map((r) => r.flag as IntegrityFlag);
}

export function setIntegrityFlags(studentId: string, assignmentId: string, flags: IntegrityFlag[]): void {
  const db = getDb();
  db.prepare('DELETE FROM integrity_flags WHERE student_id = ? AND assignment_id = ?').run(studentId, assignmentId);
  const stmt = db.prepare(
    'INSERT INTO integrity_flags (session_id, assignment_id, student_id, flag) VALUES (?, ?, ?, ?)'
  );
  const sessionRow = db
    .prepare('SELECT session_id FROM effort_scores WHERE student_id = ? AND assignment_id = ?')
    .get(studentId, assignmentId) as { session_id: string } | undefined;
  const sessionId = sessionRow?.session_id ?? randomUUID();
  for (const flag of flags) {
    stmt.run(sessionId, assignmentId, studentId, flag);
  }
  saveDbToFile(db);
}

// ============================================
// SMS VERIFICATION
// ============================================

export function createSmsCode(input: {
  id: string;
  phone: string;
  code: string;
  expiresAt: string;
  createdAt?: string;
}): SmsCode {
  const db = getDb();
  db.prepare(
    `INSERT INTO sms_verification_codes (id, phone, code, expires_at, created_at)
     VALUES (?, ?, ?, ?, ?)`
  ).run(input.id, input.phone, input.code, input.expiresAt, input.createdAt || new Date().toISOString());
  saveDbToFile(db);
  return input;
}

export function verifySmsCode(phone: string, code: string): boolean {
  const db = getDb();
  const row = db
    .prepare('SELECT * FROM sms_verification_codes WHERE phone = ? AND code = ?')
    .get(phone, code) as any;

  if (!row) return false;

  db.prepare('DELETE FROM sms_verification_codes WHERE id = ?').run(row.id);
  saveDbToFile(db);

  const expiresAt = normDate(row.expires_at);
  if (!expiresAt || new Date(expiresAt).getTime() <= Date.now()) {
    return false;
  }
  return true;
}

export function markPhoneVerified(phone: string): void {
  const db = getDb();
  db.prepare('UPDATE users SET is_phone_verified = 1 WHERE phone = ?').run(phone);
  saveDbToFile(db);
}

// ============================================
// ATTENDANCE RECORDS
// ============================================

function toAttendanceRecord(row: any): AttendanceRecord {
  return {
    id: row.id,
    courseId: row.course_id,
    studentId: row.student_id,
    date: row.date,
    status: row.status,
    markedBy: row.marked_by,
    notes: row.notes ?? '',
    createdAt: normDate(row.created_at) ?? row.created_at,
  };
}

export function getAttendanceRecords(courseId?: string, date?: string): AttendanceRecord[] {
  const db = getDb();
  let sql = 'SELECT * FROM attendance_records';
  const params: any[] = [];
  const conditions: string[] = [];
  if (courseId) {
    conditions.push('course_id = ?');
    params.push(courseId);
  }
  if (date) {
    conditions.push('date = ?');
    params.push(date);
  }
  if (conditions.length > 0) sql += ' WHERE ' + conditions.join(' AND ');
  sql += ' ORDER BY date DESC, student_id';
  return (db.prepare(sql).all(...params) as unknown as any[]).map(toAttendanceRecord);
}

export function getAttendanceRecord(id: string): AttendanceRecord | undefined {
  const db = getDb();
  const row = db.prepare('SELECT * FROM attendance_records WHERE id = ?').get(id) as any;
  if (!row) return undefined;
  return toAttendanceRecord(row);
}

export function upsertAttendanceRecord(input: {
  id?: string;
  courseId: string;
  studentId: string;
  date: string;
  status: AttendanceRecord['status'];
  markedBy: string;
  notes?: string;
}): AttendanceRecord {
  const db = getDb();
  const id = input.id || randomUUID();
  const now = new Date().toISOString();
  const exists = db.prepare('SELECT id FROM attendance_records WHERE course_id = ? AND student_id = ? AND date = ?')
    .get(input.courseId, input.studentId, input.date) as any;
  if (exists) {
    db.prepare(
      `UPDATE attendance_records SET status = ?, marked_by = ?, notes = ? WHERE id = ?`
    ).run(input.status, input.markedBy, input.notes ?? '', exists.id);
    saveDbToFile(db);
    return { ...toAttendanceRecord(db.prepare('SELECT * FROM attendance_records WHERE id = ?').get(exists.id)!), id: exists.id };
  }
  db.prepare(
    `INSERT INTO attendance_records (id, course_id, student_id, date, status, marked_by, notes, created_at)
     VALUES (?, ?, ?, ?, ?, ?, ?, ?)`
  ).run(id, input.courseId, input.studentId, input.date, input.status, input.markedBy, input.notes ?? '', now);
  saveDbToFile(db);
  return {
    id,
    courseId: input.courseId,
    studentId: input.studentId,
    date: input.date,
    status: input.status,
    markedBy: input.markedBy,
    notes: input.notes ?? '',
    createdAt: now,
  };
}

// ============================================
// TEACHER NOTES
// ============================================

function toTeacherNote(row: any): TeacherNote {
  return {
    id: row.id,
    courseId: row.course_id,
    bookName: row.book_name,
    courseCode: row.course_code,
    title: row.title,
    content: row.content ?? '',
    authorId: row.author_id,
    createdAt: normDate(row.created_at) ?? row.created_at,
    updatedAt: normDate(row.updated_at) ?? row.updated_at,
  };
}

export function getTeacherNotes(courseId?: string, courseCode?: string): TeacherNote[] {
  const db = getDb();
  let sql = 'SELECT * FROM teacher_notes';
  const params: any[] = [];
  const conditions: string[] = [];
  if (courseId) {
    conditions.push('course_id = ?');
    params.push(courseId);
  }
  if (courseCode) {
    conditions.push('course_code = ?');
    params.push(courseCode);
  }
  if (conditions.length > 0) sql += ' WHERE ' + conditions.join(' AND ');
  sql += ' ORDER BY created_at DESC';
  return (db.prepare(sql).all(...params) as unknown as any[]).map(toTeacherNote);
}

export function getTeacherNote(id: string): TeacherNote | undefined {
  const db = getDb();
  const row = db.prepare('SELECT * FROM teacher_notes WHERE id = ?').get(id) as any;
  if (!row) return undefined;
  return toTeacherNote(row);
}

export function upsertTeacherNote(input: {
  id?: string;
  courseId: string;
  bookName: string;
  courseCode: string;
  title: string;
  content: string;
  authorId: string;
}): TeacherNote {
  const db = getDb();
  const id = input.id || randomUUID();
  const now = new Date().toISOString();
  const existing = db.prepare('SELECT id FROM teacher_notes WHERE id = ?').get(id) as any;
  if (existing) {
    db.prepare(
      `UPDATE teacher_notes SET book_name = ?, course_code = ?, title = ?, content = ?, updated_at = ? WHERE id = ?`
    ).run(input.bookName, input.courseCode, input.title, input.content, now, id);
    saveDbToFile(db);
    return { ...toTeacherNote(db.prepare('SELECT * FROM teacher_notes WHERE id = ?').get(id)!), id };
  }
  db.prepare(
    `INSERT INTO teacher_notes (id, course_id, book_name, course_code, title, content, author_id, created_at, updated_at)
     VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)`
  ).run(id, input.courseId, input.bookName, input.courseCode, input.title, input.content, input.authorId, now, now);
  saveDbToFile(db);
  return {
    id,
    courseId: input.courseId,
    bookName: input.bookName,
    courseCode: input.courseCode,
    title: input.title,
    content: input.content,
    authorId: input.authorId,
    createdAt: now,
    updatedAt: now,
  };
}

export function deleteTeacherNote(id: string): void {
  const db = getDb();
  db.prepare('DELETE FROM teacher_notes WHERE id = ?').run(id);
  saveDbToFile(db);
}

// ============================================
// STUDENT DEPARTMENT ENROLLMENT
// ============================================

function toStudentDepartment(row: any): StudentDepartment {
  return {
    id: row.id,
    studentId: row.student_id,
    departmentId: row.department_id,
    enrolledAt: normDate(row.enrolled_at) ?? row.enrolled_at,
    enrolledBy: row.enrolled_by,
  };
}

export function getStudentDepartments(studentId?: string, departmentId?: string): StudentDepartment[] {
  const db = getDb();
  let sql = 'SELECT * FROM student_departments';
  const params: any[] = [];
  const conditions: string[] = [];
  if (studentId) {
    conditions.push('student_id = ?');
    params.push(studentId);
  }
  if (departmentId) {
    conditions.push('department_id = ?');
    params.push(departmentId);
  }
  if (conditions.length > 0) sql += ' WHERE ' + conditions.join(' AND ');
  sql += ' ORDER BY enrolled_at DESC';
  return (db.prepare(sql).all(...params) as unknown as any[]).map(toStudentDepartment);
}

export function enrollStudentInDepartment(input: {
  studentId: string;
  departmentId: string;
  enrolledBy: string;
}): StudentDepartment {
  const db = getDb();
  const id = randomUUID();
  const now = new Date().toISOString();
  db.prepare(
    `INSERT OR IGNORE INTO student_departments (id, student_id, department_id, enrolled_at, enrolled_by)
     VALUES (?, ?, ?, ?, ?)`
  ).run(id, input.studentId, input.departmentId, now, input.enrolledBy);
  saveDbToFile(db);
  return {
    id,
    studentId: input.studentId,
    departmentId: input.departmentId,
    enrolledAt: now,
    enrolledBy: input.enrolledBy,
  };
}

export function unenrollStudentFromDepartment(studentId: string, departmentId: string): void {
  const db = getDb();
  db.prepare('DELETE FROM student_departments WHERE student_id = ? AND department_id = ?').run(studentId, departmentId);
  saveDbToFile(db);
}

export function getStudentsByDepartment(departmentId: string): User[] {
  const db = getDb();
  const rows = db.prepare(
    `SELECT u.* FROM users u JOIN student_departments sd ON u.id = sd.student_id WHERE sd.department_id = ?`
  ).all(departmentId) as unknown as any[];
  return rows.map(toUser);
}

export function getDepartmentsByStudent(studentId: string): Department[] {
  const db = getDb();
  const rows = db.prepare(
    `SELECT d.* FROM departments d JOIN student_departments sd ON d.id = sd.department_id WHERE sd.student_id = ?`
  ).all(studentId) as unknown as any[];
  return rows.map((row: any) => ({
    id: row.id,
    collegeId: row.college_id,
    name: row.name,
    code: row.code,
    category: row.category,
    durationMonths: row.duration_months,
    createdAt: normDate(row.created_at) ?? row.created_at,
  }));
}

// ============================================
// STUDENTS (admin management)
// ============================================

export function getStudentsByCourse(courseId: string): User[] {
  const db = getDb();
  const course = db.prepare('SELECT student_ids FROM courses WHERE id = ?').get(courseId) as { student_ids: string } | undefined;
  if (!course) return [];
  const studentIds = parseJson(course.student_ids, []);
  if (studentIds.length === 0) return [];
  const placeholders = studentIds.map(() => '?').join(', ');
  const rows = db.prepare(`SELECT * FROM users WHERE id IN (${placeholders}) AND role = 'student'`).all(...studentIds) as unknown as any[];
  return rows.map(toUser);
}
