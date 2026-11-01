// @ts-nocheck
// In-memory database store for Vercel serverless compatibility
// Data is seeded on each cold start and persists within a function instance

const SCHEMA_VERSION = 1;

// In-memory stores
let db = {
  users: [],
  courses: [],
  colleges: [],
  departments: [],
  assignments: [],
  submissions: [],
  calendar_events: [],
  chat_channels: [],
  chat_messages: [],
  telemetry_batches: [],
  telemetry_events: [],
  effort_scores: [],
  integrity_flags: [],
  sms_verification_codes: [],
  attendance_records: [],
  teacher_notes: [],
  student_departments: [],
  schema_version: [],
};

let initialized = false;

function parseJson(value, fallback) {
  if (value === null || value === undefined) return fallback;
  try {
    return JSON.parse(value);
  } catch {
    return fallback;
  }
}

function normDate(value) {
  if (!value) return value;
  if (value.includes("T")) return value;
  return `${value.replace(" ", "T")}Z`;
}

function randomUUID() {
  return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, (c) => {
    const r = (Math.random() * 16) | 0;
    const v = c === 'x' ? r : (r & 0x3) | 0x8;
    return v.toString(16);
  });
}

function nowISO() {
  return new Date().toISOString();
}

async function initDatabase() {
  if (initialized) return db;
  initialized = true;

  // Read schema and seed data
  const fs = await import('node:fs');
  const path = await import('node:path');

  function readSql(name) {
    const candidates = [
      path.join(process.cwd(), 'db', name),
      path.join(process.cwd(), 'apps', 'api', 'db', name),
      path.join(process.cwd(), 'apps/api/db', name),
    ];
    for (const candidate of candidates) {
      if (fs.existsSync(candidate)) {
        return fs.readFileSync(candidate, 'utf-8');
      }
    }
    throw new Error(`Cannot find db/${name}`);
  }

  // Parse and execute schema (simplified - just create empty tables)
  // The schema.sql contains CREATE TABLE IF NOT EXISTS statements
  // We just need to seed the data

  // Seed data
  const seedSql = readSql('seed.sql');

  // Simple SQL parser for INSERT statements
  const insertRegex = /INSERT OR IGNORE INTO (\w+) \(([^)]+)\) VALUES \((.*?)\);/gs;
  let match;
  while ((match = insertRegex.exec(seedSql)) !== null) {
    const table = match[1];
    const columns = match[2].split(',').map(c => c.trim());
    const valuesStr = match[3];
    // Parse values (simple parsing for string and number literals)
    const values = [];
    let current = '';
    let inString = false;
    for (let i = 0; i < valuesStr.length; i++) {
      const ch = valuesStr[i];
      if (ch === "'" && !inString) {
        inString = true;
        current += ch;
      } else if (ch === "'" && inString) {
        inString = false;
        current += ch;
      } else if (ch === ',' && !inString) {
        values.push(current.trim());
        current = '';
      } else {
        current += ch;
      }
    }
    if (current.trim()) values.push(current.trim());

    const row = {};
    columns.forEach((col, i) => {
      let val = values[i] || '';
      if (val.startsWith("'") && val.endsWith("'")) {
        val = val.slice(1, -1).replace(/''/g, "'");
      } else if (val === 'NULL' || val === 'null') {
        val = null;
      } else if (!isNaN(val) && val !== '') {
        val = Number(val);
      }
      row[col] = val;
    });

    if (db[table]) {
      db[table].push(row);
    }
  }

  // Seed schema_version
  db.schema_version.push({ version: 1, applied_at: nowISO() });

  return db;
}

function getDb() {
  if (!initialized) {
    throw new Error('Database not initialized');
  }
  return db;
}

// ============================================
// Types (re-exported for consumers)
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
  await initDatabase();
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
  return db.users.map(toUser);
}

export function getUser(userId: string): User | undefined {
  const row = db.users.find((u: any) => u.id === userId);
  if (!row) return undefined;
  return toUser(row);
}

export function getUserByPhone(phone: string): User | undefined {
  const row = db.users.find((u: any) => u.phone === phone);
  if (!row) return undefined;
  return toUser(row);
}

export function getUserAuthByPhone(phone: string): { id: string; passwordHash: string | null } | undefined {
  const row = db.users.find((u: any) => u.phone === phone);
  if (!row) return undefined;
  return { id: row.id, passwordHash: row.password_hash };
}

export function getUserAuthByEmail(email: string): { id: string; passwordHash: string | null } | undefined {
  const row = db.users.find((u: any) => u.email === email);
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
  const createdAt = input.createdAt || nowISO();
  const row = {
    id: input.id,
    display_name: input.displayName,
    email: input.email,
    phone: input.phone,
    role: input.role,
    course_ids: JSON.stringify(input.courseIds),
    password_hash: input.passwordHash,
    is_phone_verified: input.isPhoneVerified,
    created_at: createdAt,
  };
  db.users.push(row);
  return getUser(input.id)!;
}

export function updateUser(userId: string, updates: Partial<{
  displayName: string;
  email: string;
  phone: string;
  passwordHash: string;
  isPhoneVerified: number;
}>): void {
  const idx = db.users.findIndex((u: any) => u.id === userId);
  if (idx === -1) return;
  const row = db.users[idx];
  if (updates.displayName !== undefined) row.display_name = updates.displayName;
  if (updates.email !== undefined) row.email = updates.email;
  if (updates.phone !== undefined) row.phone = updates.phone;
  if (updates.passwordHash !== undefined) row.password_hash = updates.passwordHash;
  if (updates.isPhoneVerified !== undefined) row.is_phone_verified = updates.isPhoneVerified;
}

// ============================================
// COURSES
// ============================================

function toCourse(row: any): any {
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

export function getCourses(): any[] {
  return db.courses.map(toCourse);
}

export function getCourse(courseId: string): any | undefined {
  const row = db.courses.find((c: any) => c.id === courseId);
  if (!row) return undefined;
  return toCourse(row);
}

export function getAssignmentsByCourse(courseId: string): any[] {
  return db.assignments
    .filter((a: any) => a.course_id === courseId)
    .sort((a: any, b: any) => a.due_at.localeCompare(b.due_at))
    .map((row: any) => ({
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
  const course = db.courses.find((c: any) => c.id === courseId);
  if (!course) return;
  const ids = parseJson(course.student_ids, []);
  if (!ids.includes(studentId)) {
    ids.push(studentId);
    course.student_ids = JSON.stringify(ids);
  }
}

export function removeStudentFromCourse(courseId: string, studentId: string): void {
  const course = db.courses.find((c: any) => c.id === courseId);
  if (!course) return;
  const ids = parseJson(course.student_ids, []).filter((id: string) => id !== studentId);
  course.student_ids = JSON.stringify(ids);
}

// ============================================
// COLLEGE
// ============================================

export function getColleges(): any[] {
  return db.colleges;
}

export function getCollege(collegeId: string): any | undefined {
  return db.colleges.find((c: any) => c.id === collegeId);
}

export function getDepartments(collegeId: string): any[] {
  return db.departments.filter((d: any) => d.college_id === collegeId);
}

// ============================================
// ASSIGNMENTS
// ============================================

export function getAssignment(assignmentId: string): any | undefined {
  return db.assignments.find((a: any) => a.id === assignmentId);
}

// ============================================
// SUBMISSIONS
// ============================================

export function getSubmissionsByAssignment(assignmentId: string): any[] {
  return db.submissions.filter((s: any) => s.assignment_id === assignmentId);
}

export function getSubmission(submissionId: string): any | undefined {
  return db.submissions.find((s: any) => s.id === submissionId);
}

export function createSubmission(input: {
  assignmentId: string;
  studentId: string;
  status: any;
  submittedAt: string | null;
  attachments: any[];
}): any {
  const id = randomUUID();
  const now = nowISO();
  const attachmentsWithIds = input.attachments.map((a: any) => ({
    ...a,
    id: randomUUID(),
  }));
  const row = {
    id,
    assignment_id: input.assignmentId,
    student_id: input.studentId,
    status: input.status,
    submitted_at: input.submittedAt,
    attachments: JSON.stringify(attachmentsWithIds),
    grade: null,
    effort_score: null,
    created_at: now,
  };
  db.submissions.push(row);
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

export function updateSubmission(submissionId: string, updates: any): void {
  const row = db.submissions.find((s: any) => s.id === submissionId);
  if (!row) return;
  if (updates.status !== undefined) row.status = updates.status;
  if (updates.submittedAt !== undefined) row.submitted_at = updates.submittedAt;
  if (updates.attachments !== undefined) row.attachments = JSON.stringify(updates.attachments);
  if (updates.grade !== undefined) row.grade = updates.grade;
  if (updates.effortScore !== undefined) row.effort_score = updates.effortScore;
}

// ============================================
// CALENDAR
// ============================================

export function getCalendarEvents(courseIds: Set<string>): any[] {
  if (courseIds.size === 0) {
    return db.calendar_events.filter((e: any) => e.course_id === null);
  }
  return db.calendar_events.filter((e: any) => e.course_id === null || courseIds.has(e.course_id));
}

// ============================================
// CHAT CHANNELS
// ============================================

export function getChannelsByCourse(courseId: string): any[] {
  return db.chat_channels.filter((c: any) => c.course_id === courseId);
}

export function getChannel(channelId: string): any | undefined {
  return db.chat_channels.find((c: any) => c.id === channelId);
}

export function getMessages(channelId: string): any[] {
  return db.chat_messages
    .filter((m: any) => m.channel_id === channelId)
    .sort((a: any, b: any) => a.sent_at.localeCompare(b.sent_at));
}

export function createMessage(input: { channelId: string; authorId: string; body: string }): any {
  const id = randomUUID();
  const now = nowISO();
  const row = {
    id,
    channel_id: input.channelId,
    author_id: input.authorId,
    body: input.body,
    sent_at: now,
  };
  db.chat_messages.push(row);
  return { id, channelId: input.channelId, authorId: input.authorId, body: input.body, sentAt: now };
}

// ============================================
// TELEMETRY
// ============================================

export function getTelemetryBatches(): any[] {
  return db.telemetry_batches;
}

export function createTelemetryBatch(batch: any): void {
  db.telemetry_batches.push({
    batch_id: batch.batchId,
    student_id: batch.studentId,
    assignment_id: batch.assignmentId,
    client_signature: batch.clientSignature,
    client_public_key: batch.clientPublicKey,
    created_at: batch.createdAt,
  });
  for (const event of batch.events) {
    db.telemetry_events.push({
      id: event.id,
      batch_id: batch.batchId,
      session_id: event.sessionId,
      type: event.type,
      occurred_at: event.occurredAt,
      payload: JSON.stringify(event.payload),
    });
  }
}

// ============================================
// EFFORT & INTEGRITY
// ============================================

export function getEffortScore(studentId: string, assignmentId: string): any | undefined {
  return db.effort_scores.find((e: any) => e.student_id === studentId && e.assignment_id === assignmentId);
}

export function setEffortScore(score: any): void {
  const existing = db.effort_scores.find((e: any) => e.session_id === score.sessionId);
  if (existing) {
    Object.assign(existing, score);
  } else {
    db.effort_scores.push(score);
  }
}

export function getIntegrityFlags(studentId: string, assignmentId: string): any[] {
  return db.integrity_flags.filter((f: any) => f.student_id === studentId && f.assignment_id === assignmentId);
}

export function setIntegrityFlags(studentId: string, assignmentId: string, flags: any[]): void {
  db.integrity_flags = db.integrity_flags.filter((f: any) => !(f.student_id === studentId && f.assignment_id === assignmentId));
  const sessionRow = db.effort_scores.find((e: any) => e.student_id === studentId && e.assignment_id === assignmentId);
  const sessionId = sessionRow?.session_id || randomUUID();
  for (const flag of flags) {
    db.integrity_flags.push({ session_id: sessionId, assignment_id: assignmentId, student_id: studentId, flag });
  }
}

// ============================================
// SMS VERIFICATION
// ============================================

export function createSmsCode(input: any): any {
  const row = {
    id: input.id,
    phone: input.phone,
    code: input.code,
    expires_at: input.expiresAt,
    created_at: input.createdAt || nowISO(),
  };
  db.sms_verification_codes.push(row);
  return input;
}

export function verifySmsCode(phone: string, code: string): boolean {
  const idx = db.sms_verification_codes.findIndex((c: any) => c.phone === phone && c.code === code);
  if (idx === -1) return false;
  const row = db.sms_verification_codes[idx];
  db.sms_verification_codes.splice(idx, 1);
  const expiresAt = normDate(row.expires_at);
  if (!expiresAt || new Date(expiresAt).getTime() <= Date.now()) {
    return false;
  }
  return true;
}

export function markPhoneVerified(phone: string): void {
  const row = db.users.find((u: any) => u.phone === phone);
  if (row) row.is_phone_verified = 1;
}

// ============================================
// ATTENDANCE
// ============================================

export function getAttendanceRecords(courseId?: string, date?: string): any[] {
  let records = db.attendance_records;
  if (courseId) records = records.filter((r: any) => r.course_id === courseId);
  if (date) records = records.filter((r: any) => r.date === date);
  return records.sort((a: any, b: any) => b.date.localeCompare(a.date));
}

export function getAttendanceRecord(id: string): any | undefined {
  return db.attendance_records.find((r: any) => r.id === id);
}

export function upsertAttendanceRecord(input: {
  id?: string;
  courseId: string;
  studentId: string;
  date: string;
  status: string;
  markedBy: string;
  notes?: string;
}): any {
  const existing = db.attendance_records.find((r: any) =>
    r.course_id === input.courseId && r.student_id === input.studentId && r.date === input.date
  );
  const now = nowISO();
  if (existing) {
    existing.status = input.status;
    existing.marked_by = input.markedBy;
    existing.notes = input.notes ?? '';
    return { ...existing, id: existing.id };
  }
  const id = input.id || randomUUID();
  const row = {
    id,
    course_id: input.courseId,
    student_id: input.studentId,
    date: input.date,
    status: input.status,
    marked_by: input.markedBy,
    notes: input.notes ?? '',
    created_at: now,
  };
  db.attendance_records.push(row);
  return { id, courseId: input.courseId, studentId: input.studentId, date: input.date, status: input.status, markedBy: input.markedBy, notes: input.notes ?? '', createdAt: now };
}

// ============================================
// TEACHER NOTES
// ============================================

export function getTeacherNotes(courseId?: string, courseCode?: string): any[] {
  let notes = db.teacher_notes;
  if (courseId) notes = notes.filter((n: any) => n.course_id === courseId);
  if (courseCode) notes = notes.filter((n: any) => n.course_code === courseCode);
  return notes.sort((a: any, b: any) => b.created_at.localeCompare(a.created_at));
}

export function getTeacherNote(id: string): any | undefined {
  return db.teacher_notes.find((n: any) => n.id === id);
}

export function upsertTeacherNote(input: {
  id?: string;
  courseId: string;
  bookName: string;
  courseCode: string;
  title: string;
  content: string;
  authorId: string;
}): any {
  const now = nowISO();
  const existing = db.teacher_notes.find((n: any) => n.id === input.id);
  if (existing) {
    existing.book_name = input.bookName;
    existing.course_code = input.courseCode;
    existing.title = input.title;
    existing.content = input.content;
    existing.updated_at = now;
    return { ...existing, id: input.id };
  }
  const id = input.id || randomUUID();
  const row = {
    id,
    course_id: input.courseId,
    book_name: input.bookName,
    course_code: input.courseCode,
    title: input.title,
    content: input.content,
    author_id: input.authorId,
    created_at: now,
    updated_at: now,
  };
  db.teacher_notes.push(row);
  return { id, courseId: input.courseId, bookName: input.bookName, courseCode: input.courseCode, title: input.title, content: input.content, authorId: input.authorId, createdAt: now, updatedAt: now };
}

export function deleteTeacherNote(id: string): void {
  db.teacher_notes = db.teacher_notes.filter((n: any) => n.id !== id);
}

// ============================================
// STUDENT DEPARTMENTS
// ============================================

export function getStudentDepartments(studentId?: string, departmentId?: string): any[] {
  let depts = db.student_departments;
  if (studentId) depts = depts.filter((d: any) => d.student_id === studentId);
  if (departmentId) depts = depts.filter((d: any) => d.department_id === departmentId);
  return depts.sort((a: any, b: any) => b.enrolled_at.localeCompare(a.enrolled_at));
}

export function enrollStudentInDepartment(input: { studentId: string; departmentId: string; enrolledBy: string }): any {
  const id = randomUUID();
  const now = nowISO();
  const row = {
    id,
    student_id: input.studentId,
    department_id: input.departmentId,
    enrolled_at: now,
    enrolled_by: input.enrolledBy,
  };
  db.student_departments.push(row);
  return { id, studentId: input.studentId, departmentId: input.departmentId, enrolledAt: now, enrolledBy: input.enrolledBy };
}

export function unenrollStudentFromDepartment(studentId: string, departmentId: string): void {
  db.student_departments = db.student_departments.filter(
    (d: any) => !(d.student_id === studentId && d.department_id === departmentId)
  );
}

export function getStudentsByDepartment(departmentId: string): any[] {
  const deptStudentIds = db.student_departments
    .filter((d: any) => d.department_id === departmentId)
    .map((d: any) => d.student_id);
  return db.users.filter((u: any) => deptStudentIds.includes(u.id) && u.role === 'student');
}

export function getDepartmentsByStudent(studentId: string): any[] {
  const deptIds = db.student_departments
    .filter((d: any) => d.student_id === studentId)
    .map((d: any) => d.department_id);
  return db.departments.filter((d: any) => deptIds.includes(d.id));
}

// ============================================
// STUDENTS BY COURSE
// ============================================

export function getStudentsByCourse(courseId: string): any[] {
  const course = db.courses.find((c: any) => c.id === courseId);
  if (!course) return [];
  const studentIds = parseJson(course.student_ids, []);
  return db.users.filter((u: any) => studentIds.includes(u.id) && u.role === 'student');
}
