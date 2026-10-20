import { randomUUID } from 'node:crypto';
import { db } from '../db.js';
import type {
  Assignment,
  CalendarEvent,
  ChatChannel,
  ChatMessage,
  Course,
  EffortScore,
  IntegrityFlag,
  Role,
  Submission,
  SignedTelemetryBatch,
  User,
} from '@edtech/shared';

function parseJson<T>(value: string | null, fallback: T): T {
  if (value === null || value === undefined) return fallback;
  try {
    return JSON.parse(value);
  } catch {
    return fallback;
  }
}

function toUser(row: any): User {
  return {
    id: row.id,
    displayName: row.display_name,
    email: row.email,
    role: row.role as Role,
    courseIds: parseJson(row.course_ids, []),
    createdAt: row.created_at,
  };
}

function toCourse(row: any): Course {
  return {
    id: row.id,
    title: row.title,
    code: row.code,
    teacherId: row.teacher_id,
    studentIds: parseJson(row.student_ids, []),
    term: row.term,
    createdAt: row.created_at,
  };
}

function toAssignment(row: any): Assignment {
  return {
    id: row.id,
    courseId: row.course_id,
    title: row.title,
    brief: row.brief,
    dueAt: row.due_at,
    status: row.status,
    createdAt: row.created_at,
  };
}

function toSubmission(row: any): Submission {
  return {
    id: row.id,
    assignmentId: row.assignment_id,
    studentId: row.student_id,
    status: row.status,
    submittedAt: row.submitted_at,
    attachments: parseJson(row.attachments, []),
    grade: row.grade,
    effortScore: row.effort_score,
  };
}

function toCalendarEvent(row: any): CalendarEvent {
  return {
    id: row.id,
    courseId: row.course_id,
    title: row.title,
    kind: row.kind,
    startsAt: row.starts_at,
    endsAt: row.ends_at,
  };
}

function toChannel(row: any): ChatChannel {
  return {
    id: row.id,
    courseId: row.course_id,
    name: row.name,
    kind: row.kind,
    memberIds: parseJson(row.member_ids, []),
  };
}

function toMessage(row: any): ChatMessage {
  return {
    id: row.id,
    channelId: row.channel_id,
    authorId: row.author_id,
    body: row.body,
    sentAt: row.sent_at,
  };
}

/* ---------- users ---------- */

export function getUsers(): User[] {
  return (db.prepare('SELECT * FROM users').all() as unknown as any[]).map(toUser);
}

export function getUser(userId: string): User | undefined {
  return toUser(db.prepare('SELECT * FROM users WHERE id = ?').get(userId) as any);
}

/* ---------- courses ---------- */

export function getCourses(): Course[] {
  return (db.prepare('SELECT * FROM courses').all() as unknown as any[]).map(toCourse);
}

export function getCourse(courseId: string): Course | undefined {
  return toCourse(db.prepare('SELECT * FROM courses WHERE id = ?').get(courseId) as any);
}

export function getAssignmentsByCourse(courseId: string): Assignment[] {
  return (db
    .prepare('SELECT * FROM assignments WHERE course_id = ? ORDER BY due_at')
    .all(courseId) as unknown as any[]).map(toAssignment);
}

/* ---------- assignments ---------- */

export function getAssignment(assignmentId: string): Assignment | undefined {
  return toAssignment(
    db.prepare('SELECT * FROM assignments WHERE id = ?').get(assignmentId) as any,
  );
}

/* ---------- submissions ---------- */

export function getSubmissionsByAssignment(assignmentId: string): Submission[] {
  return (db
    .prepare('SELECT * FROM submissions WHERE assignment_id = ?')
    .all(assignmentId) as unknown as any[]).map(toSubmission);
}

export function getSubmission(submissionId: string): Submission | undefined {
  return toSubmission(
    db.prepare('SELECT * FROM submissions WHERE id = ?').get(submissionId) as any,
  );
}

export function createSubmission(input: {
  assignmentId: string;
  studentId: string;
  status: Submission['status'];
  submittedAt: string | null;
  attachments: { fileName: string; mimeType: string; sizeBytes: number; url: string }[];
}): Submission {
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
}

/* ---------- calendar ---------- */

export function getCalendarEvents(courseIds: Set<string>): CalendarEvent[] {
  if (courseIds.size === 0) {
    return (db
      .prepare('SELECT * FROM calendar_events WHERE course_id IS NULL')
      .all() as unknown as any[]).map(toCalendarEvent);
  }
  const conditions = [...courseIds].map(() => 'course_id = ?').join(' OR ');
  return (db
    .prepare(`SELECT * FROM calendar_events WHERE course_id IS NULL OR ${conditions}`)
    .all(...[...courseIds]) as unknown as any[]).map(toCalendarEvent);
}

/* ---------- chat channels ---------- */

export function getChannelsByCourse(courseId: string): ChatChannel[] {
  return (db
    .prepare('SELECT * FROM chat_channels WHERE course_id = ?')
    .all(courseId) as unknown as any[]).map(toChannel);
}

export function getChannel(channelId: string): ChatChannel | undefined {
  return toChannel(
    db.prepare('SELECT * FROM chat_channels WHERE id = ?').get(channelId) as any,
  );
}

export function getMessages(channelId: string): ChatMessage[] {
  return (db
    .prepare('SELECT * FROM chat_messages WHERE channel_id = ? ORDER BY sent_at')
    .all(channelId) as unknown as any[]).map(toMessage);
}

export function createMessage(input: {
  channelId: string;
  authorId: string;
  body: string;
}): ChatMessage {
  const id = randomUUID();
  const now = new Date().toISOString();
  db.prepare(
    'INSERT INTO chat_messages (id, channel_id, author_id, body, sent_at) VALUES (?, ?, ?, ?, ?)'
  ).run(id, input.channelId, input.authorId, input.body, now);
  return { id, channelId: input.channelId, authorId: input.authorId, body: input.body, sentAt: now };
}

/* ---------- telemetry ---------- */

export function getTelemetryBatches(): SignedTelemetryBatch[] {
  return db.prepare('SELECT * FROM telemetry_batches').all() as unknown as SignedTelemetryBatch[];
}

export function createTelemetryBatch(batch: SignedTelemetryBatch): void {
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
}

/* ---------- effort & integrity ---------- */

export function getEffortScore(studentId: string, assignmentId: string): EffortScore | undefined {
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
}

export function getIntegrityFlags(studentId: string, assignmentId: string): IntegrityFlag[] {
  const rows = db
    .prepare('SELECT flag FROM integrity_flags WHERE student_id = ? AND assignment_id = ?')
    .all(studentId, assignmentId) as { flag: string }[];
  return rows.map((r) => r.flag as IntegrityFlag);
}

export function setIntegrityFlags(studentId: string, assignmentId: string, flags: IntegrityFlag[]): void {
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
}
