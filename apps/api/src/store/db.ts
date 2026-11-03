import { randomUUID } from "node:crypto";
import {
  assignments as seedAssignments,
  calendarEvents as seedCalendarEvents,
  channels as seedChannels,
  courses as seedCourses,
  messages as seedMessages,
  submissions as seedSubmissions,
  users as seedUsers,
} from "./memory";

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

export interface Course {
  id: string;
  title: string;
  code: string;
  teacherId: string;
  studentIds: string[];
  term: string;
  createdAt: string;
}

export interface College {
  id: string;
  name: string;
  shortName: string;
  createdAt: string;
}

export type DepartmentCategory =
  | "3 Years"
  | "2 Years"
  | "6 Months"
  | "2 Years Paramedical";

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
export type SubmissionStatus =
  | "pending"
  | "submitted"
  | "graded"
  | "late"
  | "missing";

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

export type CalendarEventKind =
  | "assignment"
  | "quiz"
  | "class"
  | "institution";

export interface CalendarEvent {
  id: string;
  courseId: string | null;
  departmentId?: string | null;
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

export type TelemetryEventType =
  | "keystroke"
  | "cursor"
  | "paste"
  | "focus"
  | "blur"
  | "ai_tab_switch";

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

export type IntegrityFlag =
  | "none"
  | "large_paste"
  | "ai_tab_switch"
  | "low_typing_ratio"
  | "telemetry_gap";

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
  status: "present" | "absent" | "late" | "excused";
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
// In-memory state
// ============================================

type Row = Record<string, any>;

interface IntegrityFlagRow {
  studentId: string;
  assignmentId: string;
  flags: IntegrityFlag[];
}

let db = {
  users: [] as Row[],
  courses: [] as Row[],
  colleges: [] as Row[],
  departments: [] as Row[],
  assignments: [] as Row[],
  submissions: [] as Row[],
  calendar_events: [] as Row[],
  chat_channels: [] as Row[],
  chat_messages: [] as Row[],
  telemetry_batches: [] as SignedTelemetryBatch[],
  effort_scores: [] as EffortScore[],
  integrity_flags: [] as IntegrityFlagRow[],
  sms_verification_codes: [] as Row[],
  attendance_records: [] as Row[],
  teacher_notes: [] as Row[],
  student_departments: [] as Row[],
  schema_version: [] as Row[],
};

let initialized = false;

const DEMO_PASSWORD_HASH =
  "scrypt$d61d8f46ce5212d0de626f54910fe3e1$2af1ee96671aaf94237605c177e50fb6bd0fa9ef4c4ca6543e01afc7b716036d450f753153cb14e3d94a2148e3002d4bac56b8df93e82a60cec5c52a6b7ed2a3";

const COLLEGE_ROW = {
  id: "col-cttc",
  name: "Christian Technical Training Center",
  short_name: "CTTC",
  created_at: "2026-01-01T00:00:00Z",
};

const DEPARTMENT_ROWS: Array<{
  id: string;
  name: string;
  code: string;
  category: DepartmentCategory;
  duration_months: number;
}> = [
  { id: "dept-arc", name: "Architecture", code: "ARC", category: "3 Years", duration_months: 36 },
  { id: "dept-civ", name: "Civil Engineering Technology", code: "CIV", category: "3 Years", duration_months: 36 },
  { id: "dept-cit", name: "Computer Info Tech.", code: "CIT", category: "3 Years", duration_months: 36 },
  { id: "dept-eee", name: "Electrical Technology", code: "EEE", category: "3 Years", duration_months: 36 },
  { id: "dept-ece", name: "Electronics Technology", code: "ECE", category: "3 Years", duration_months: 36 },
  { id: "dept-mec", name: "Mechanical", code: "MEC", category: "3 Years", duration_months: 36 },
  { id: "dept-adm", name: "Auto & Diesel Mechanic", code: "ADM", category: "2 Years", duration_months: 24 },
  { id: "dept-dft", name: "Drafting Civil", code: "DFT", category: "2 Years", duration_months: 24 },
  { id: "dept-elc", name: "Electrician", code: "ELC", category: "2 Years", duration_months: 24 },
  { id: "dept-cnc", name: "CNC Programmer", code: "CNC", category: "6 Months", duration_months: 6 },
  { id: "dept-mac", name: "Machinist", code: "MAC", category: "6 Months", duration_months: 6 },
  { id: "dept-aec", name: "Auto Electrician", code: "AEC", category: "6 Months", duration_months: 6 },
  { id: "dept-ott", name: "FSc. Operation Theatre Technology", code: "OTT", category: "2 Years Paramedical", duration_months: 24 },
  { id: "dept-rad", name: "FSc. Radiography & Medical Imaging Technology", code: "RAD", category: "2 Years Paramedical", duration_months: 24 },
  { id: "dept-mlt", name: "FSc. Medical Laboratory Technology", code: "MLT", category: "2 Years Paramedical", duration_months: 24 },
  { id: "dept-dsp", name: "FSc. Dispensing Technology", code: "DSP", category: "2 Years Paramedical", duration_months: 24 },
  { id: "dept-ane", name: "Anesthesia Technician", code: "ANE", category: "2 Years Paramedical", duration_months: 24 },
  { id: "dept-pht", name: "Public Health Technician", code: "PHT", category: "2 Years Paramedical", duration_months: 24 },
];

function nowISO() {
  return new Date().toISOString();
}

function daysAgo(days: number) {
  return new Date(Date.now() - days * 86_400_000).toISOString();
}

function parseJson<T>(value: unknown, fallback: T): T {
  if (value === null || value === undefined) return fallback;
  if (typeof value !== "string") return value as T;
  try {
    return JSON.parse(value) as T;
  } catch {
    return fallback;
  }
}

function normDate(value: unknown): string | null {
  if (!value || typeof value !== "string") return (value as string | null) ?? null;
  if (value.includes("T")) return value;
  return `${value.replace(" ", "T")}Z`;
}

// ============================================
// Initialization
// ============================================

function seedDatabase() {
  db.users = seedUsers.map((user) => ({
    id: user.id,
    display_name: user.displayName,
    email: user.email,
    phone: user.phone,
    role: user.role,
    course_ids: JSON.stringify(user.courseIds),
    password_hash: DEMO_PASSWORD_HASH,
    is_phone_verified: 1,
    created_at: user.createdAt,
  }));

  db.courses = seedCourses.map((course) => ({
    id: course.id,
    title: course.title,
    code: course.code,
    teacher_id: course.teacherId,
    student_ids: JSON.stringify(course.studentIds),
    term: course.term,
    created_at: course.createdAt,
  }));

  db.assignments = seedAssignments.map((assignment) => ({
    id: assignment.id,
    course_id: assignment.courseId,
    title: assignment.title,
    brief: assignment.brief,
    due_at: assignment.dueAt,
    status: assignment.status,
    created_at: assignment.createdAt,
  }));

  db.submissions = seedSubmissions.map((submission) => ({
    id: submission.id,
    assignment_id: submission.assignmentId,
    student_id: submission.studentId,
    status: submission.status,
    submitted_at: submission.submittedAt,
    attachments: JSON.stringify(submission.attachments),
    grade: submission.grade,
    effort_score: submission.effortScore,
    created_at: submission.submittedAt ?? nowISO(),
  }));

  db.calendar_events = seedCalendarEvents.map((event) => ({
    id: event.id,
    course_id: event.courseId,
    department_id: null,
    title: event.title,
    kind: event.kind,
    starts_at: event.startsAt,
    ends_at: event.endsAt,
  }));

  db.chat_channels = seedChannels.map((channel) => ({
    id: channel.id,
    course_id: channel.courseId,
    name: channel.name,
    kind: channel.kind,
    member_ids: JSON.stringify(channel.memberIds),
  }));

  db.chat_messages = seedMessages.map((message) => ({
    id: message.id,
    channel_id: message.channelId,
    author_id: message.authorId,
    body: message.body,
    sent_at: message.sentAt,
  }));

  db.colleges = [COLLEGE_ROW];
  db.departments = DEPARTMENT_ROWS.map((department) => ({
    id: department.id,
    college_id: COLLEGE_ROW.id,
    name: department.name,
    code: department.code,
    category: department.category,
    duration_months: department.duration_months,
    created_at: "2026-01-01T00:00:00Z",
  }));

  const today = new Date().toISOString().slice(0, 10);
  db.attendance_records = [
    {
      id: "att-r-1",
      course_id: "c-001",
      student_id: "u-student-1",
      date: today,
      status: "present",
      marked_by: "u-teacher-1",
      notes: "",
      created_at: daysAgo(1),
    },
    {
      id: "att-r-2",
      course_id: "c-001",
      student_id: "u-student-2",
      date: today,
      status: "present",
      marked_by: "u-teacher-1",
      notes: "",
      created_at: daysAgo(1),
    },
    {
      id: "att-r-3",
      course_id: "c-001",
      student_id: "u-student-3",
      date: today,
      status: "absent",
      marked_by: "u-teacher-1",
      notes: "Sick leave",
      created_at: daysAgo(1),
    },
  ];

  db.teacher_notes = [
    {
      id: "note-1",
      course_id: "c-001",
      book_name: "Interaction Design Beyond Human-Computer Interaction",
      course_code: "CIT-301",
      title: "Week 1 Notes: Usability Principles",
      content:
        "Covered Nielsen's 10 heuristics, visibility of system status, and user control. Key takeaway: consistency and standards reduce cognitive load.",
      author_id: "u-teacher-1",
      created_at: daysAgo(5),
      updated_at: daysAgo(5),
    },
    {
      id: "note-2",
      course_id: "c-001",
      book_name: "Don't Make Me Think",
      course_code: "CIT-301",
      title: "Week 2 Notes: Web Navigation Best Practices",
      content:
        "Discussed intuitive navigation, clear labeling, and the importance of the three-click rule for web development interfaces.",
      author_id: "u-teacher-1",
      created_at: daysAgo(3),
      updated_at: daysAgo(3),
    },
  ];

  db.student_departments = [
    {
      id: "sd-001",
      student_id: "u-student-1",
      department_id: "dept-cit",
      enrolled_at: daysAgo(30),
      enrolled_by: "u-admin-1",
    },
    {
      id: "sd-002",
      student_id: "u-student-2",
      department_id: "dept-eee",
      enrolled_at: daysAgo(25),
      enrolled_by: "u-admin-1",
    },
  ];

  db.schema_version = [{ version: 1, applied_at: nowISO() }];
}

export async function initDb(): Promise<void> {
  if (initialized) return;
  initialized = true;
  seedDatabase();
}

// ============================================
// Mappers
// ============================================

function toUser(row: Row): User {
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

function toCourse(row: Row): Course {
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

function toCollege(row: Row): College {
  return {
    id: row.id,
    name: row.name,
    shortName: row.short_name,
    createdAt: normDate(row.created_at) ?? row.created_at,
  };
}

function toDepartment(row: Row): Department {
  return {
    id: row.id,
    collegeId: row.college_id,
    name: row.name,
    code: row.code,
    category: row.category as DepartmentCategory,
    durationMonths: row.duration_months,
    createdAt: normDate(row.created_at) ?? row.created_at,
  };
}

function toAssignment(row: Row): Assignment {
  return {
    id: row.id,
    courseId: row.course_id,
    title: row.title,
    brief: row.brief,
    dueAt: normDate(row.due_at) ?? row.due_at,
    status: row.status as AssignmentStatus,
    createdAt: normDate(row.created_at) ?? row.created_at,
  };
}

function toSubmission(row: Row): Submission {
  return {
    id: row.id,
    assignmentId: row.assignment_id,
    studentId: row.student_id,
    status: row.status as SubmissionStatus,
    submittedAt: normDate(row.submitted_at),
    attachments: parseJson(row.attachments, []),
    grade: row.grade ?? null,
    effortScore: row.effort_score ?? null,
  };
}

function toCalendarEvent(row: Row): CalendarEvent {
  return {
    id: row.id,
    courseId: row.course_id ?? null,
    departmentId: row.department_id ?? null,
    title: row.title,
    kind: row.kind as CalendarEventKind,
    startsAt: normDate(row.starts_at) ?? row.starts_at,
    endsAt: normDate(row.ends_at),
  };
}

function toChannel(row: Row): ChatChannel {
  return {
    id: row.id,
    courseId: row.course_id,
    name: row.name,
    kind: row.kind as ChatChannelKind,
    memberIds: parseJson(row.member_ids, []),
  };
}

function toMessage(row: Row): ChatMessage {
  return {
    id: row.id,
    channelId: row.channel_id,
    authorId: row.author_id,
    body: row.body,
    sentAt: normDate(row.sent_at) ?? row.sent_at,
  };
}

function toAttendanceRecord(row: Row): AttendanceRecord {
  return {
    id: row.id,
    courseId: row.course_id,
    studentId: row.student_id,
    date: row.date,
    status: row.status,
    markedBy: row.marked_by,
    notes: row.notes ?? "",
    createdAt: normDate(row.created_at) ?? row.created_at,
  };
}

function toTeacherNote(row: Row): TeacherNote {
  return {
    id: row.id,
    courseId: row.course_id,
    bookName: row.book_name,
    courseCode: row.course_code,
    title: row.title,
    content: row.content,
    authorId: row.author_id,
    createdAt: normDate(row.created_at) ?? row.created_at,
    updatedAt: normDate(row.updated_at) ?? row.updated_at,
  };
}

function toStudentDepartment(row: Row): StudentDepartment {
  return {
    id: row.id,
    studentId: row.student_id,
    departmentId: row.department_id,
    enrolledAt: normDate(row.enrolled_at) ?? row.enrolled_at,
    enrolledBy: row.enrolled_by,
  };
}

// ============================================
// Users
// ============================================

export function getUsers(): User[] {
  return db.users.map(toUser);
}

export function getUser(userId: string): User | undefined {
  const row = db.users.find((user) => user.id === userId);
  return row ? toUser(row) : undefined;
}

export function getUserByPhone(phone: string): User | undefined {
  const row = db.users.find((user) => user.phone === phone);
  return row ? toUser(row) : undefined;
}

export function getUserAuthByPhone(
  phone: string,
): { id: string; passwordHash: string | null } | undefined {
  const row = db.users.find((user) => user.phone === phone);
  return row ? { id: row.id, passwordHash: row.password_hash } : undefined;
}

export function getUserAuthByEmail(
  email: string,
): { id: string; passwordHash: string | null } | undefined {
  const row = db.users.find((user) => user.email === email);
  return row ? { id: row.id, passwordHash: row.password_hash } : undefined;
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
  db.users.push({
    id: input.id,
    display_name: input.displayName,
    email: input.email,
    phone: input.phone,
    role: input.role,
    course_ids: JSON.stringify(input.courseIds),
    password_hash: input.passwordHash,
    is_phone_verified: input.isPhoneVerified,
    created_at: createdAt,
  });
  return getUser(input.id)!;
}

export function updateUser(
  userId: string,
  updates: Partial<{
    displayName: string;
    email: string;
    phone: string;
    passwordHash: string;
    isPhoneVerified: number;
  }>,
): void {
  const row = db.users.find((user) => user.id === userId);
  if (!row) return;
  if (updates.displayName !== undefined) row.display_name = updates.displayName;
  if (updates.email !== undefined) row.email = updates.email;
  if (updates.phone !== undefined) row.phone = updates.phone;
  if (updates.passwordHash !== undefined) row.password_hash = updates.passwordHash;
  if (updates.isPhoneVerified !== undefined) {
    row.is_phone_verified = updates.isPhoneVerified;
  }
}

// ============================================
// Courses
// ============================================

export function getCourses(): Course[] {
  return db.courses.map(toCourse);
}

export function getCourse(courseId: string): Course | undefined {
  const row = db.courses.find((course) => course.id === courseId);
  return row ? toCourse(row) : undefined;
}

export function getAssignmentsByCourse(courseId: string): Assignment[] {
  return db.assignments
    .filter((assignment) => assignment.course_id === courseId)
    .sort((a, b) => a.due_at.localeCompare(b.due_at))
    .map(toAssignment);
}

export function addStudentToCourse(courseId: string, studentId: string): void {
  const course = db.courses.find((entry) => entry.id === courseId);
  if (!course) return;
  const ids = parseJson<string[]>(course.student_ids, []);
  if (!ids.includes(studentId)) {
    ids.push(studentId);
    course.student_ids = JSON.stringify(ids);
  }
}

export function removeStudentFromCourse(courseId: string, studentId: string): void {
  const course = db.courses.find((entry) => entry.id === courseId);
  if (!course) return;
  course.student_ids = JSON.stringify(
    parseJson<string[]>(course.student_ids, []).filter((id) => id !== studentId),
  );
}

// ============================================
// College and departments
// ============================================

export function getColleges(): College[] {
  return db.colleges.map(toCollege);
}

export function getCollege(collegeId: string): College | undefined {
  const row = db.colleges.find((college) => college.id === collegeId);
  return row ? toCollege(row) : undefined;
}

export function getDepartments(collegeId: string): Department[] {
  return db.departments
    .filter((department) => department.college_id === collegeId)
    .map(toDepartment);
}

export function getDepartment(departmentId: string): Department | undefined {
  const row = db.departments.find((department) => department.id === departmentId);
  return row ? toDepartment(row) : undefined;
}

export function createDepartment(input: {
  collegeId: string;
  name: string;
  code: string;
  category: DepartmentCategory;
  durationMonths: number;
}): Department {
  const now = nowISO();
  const row = {
    id: randomUUID(),
    college_id: input.collegeId,
    name: input.name,
    code: input.code,
    category: input.category,
    duration_months: input.durationMonths,
    created_at: now,
  };
  db.departments.push(row);
  return toDepartment(row);
}

export function updateDepartment(
  departmentId: string,
  updates: Partial<{
    name: string;
    code: string;
    category: DepartmentCategory;
    durationMonths: number;
  }>,
): Department | undefined {
  const row = db.departments.find((department) => department.id === departmentId);
  if (!row) return undefined;
  if (updates.name !== undefined) row.name = updates.name;
  if (updates.code !== undefined) row.code = updates.code;
  if (updates.category !== undefined) row.category = updates.category;
  if (updates.durationMonths !== undefined) {
    row.duration_months = updates.durationMonths;
  }
  return toDepartment(row);
}

export function deleteDepartment(departmentId: string): boolean {
  const before = db.departments.length;
  db.departments = db.departments.filter(
    (department) => department.id !== departmentId,
  );
  db.student_departments = db.student_departments.filter(
    (entry) => entry.department_id !== departmentId,
  );
  return db.departments.length < before;
}

// ============================================
// Assignments and submissions
// ============================================

export function getAssignment(assignmentId: string): Assignment | undefined {
  const row = db.assignments.find((assignment) => assignment.id === assignmentId);
  return row ? toAssignment(row) : undefined;
}

export function getSubmissionsByAssignment(assignmentId: string): Submission[] {
  return db.submissions
    .filter((submission) => submission.assignment_id === assignmentId)
    .map(toSubmission);
}

export function getSubmission(submissionId: string): Submission | undefined {
  const row = db.submissions.find((submission) => submission.id === submissionId);
  return row ? toSubmission(row) : undefined;
}

export function createSubmission(input: {
  assignmentId: string;
  studentId: string;
  status: SubmissionStatus;
  submittedAt: string | null;
  attachments: Attachment[];
}): Submission {
  const id = randomUUID();
  const now = nowISO();
  const attachmentsWithIds = input.attachments.map((attachment) => ({
    ...attachment,
    id: attachment.id || randomUUID(),
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
  return toSubmission(row);
}

export function updateSubmission(
  submissionId: string,
  updates: Partial<{
    status: SubmissionStatus;
    submittedAt: string | null;
    attachments: Attachment[];
    grade: number | null;
    effortScore: number | null;
  }>,
): void {
  const row = db.submissions.find((submission) => submission.id === submissionId);
  if (!row) return;
  if (updates.status !== undefined) row.status = updates.status;
  if (updates.submittedAt !== undefined) row.submitted_at = updates.submittedAt;
  if (updates.attachments !== undefined) {
    row.attachments = JSON.stringify(updates.attachments);
  }
  if (updates.grade !== undefined) row.grade = updates.grade;
  if (updates.effortScore !== undefined) row.effort_score = updates.effortScore;
}

// ============================================
// Calendar
// ============================================

export function getCalendarEvents(
  courseIds: Set<string>,
  departmentId?: string,
): CalendarEvent[] {
  return db.calendar_events
    .filter((event) => {
      if (departmentId) {
        return (
          event.department_id === departmentId ||
          event.department_id === null ||
          event.department_id === undefined
        );
      }
      if (courseIds.size === 0) return event.course_id === null;
      return event.course_id === null || courseIds.has(event.course_id);
    })
    .map(toCalendarEvent)
    .sort((a, b) => a.startsAt.localeCompare(b.startsAt));
}

export function createCalendarEvent(input: {
  title: string;
  kind: CalendarEventKind;
  startsAt: string;
  endsAt?: string | null;
  departmentId?: string | null;
  courseId?: string | null;
}): CalendarEvent {
  const row = {
    id: randomUUID(),
    course_id: input.courseId ?? null,
    department_id: input.departmentId ?? null,
    title: input.title,
    kind: input.kind,
    starts_at: input.startsAt,
    ends_at: input.endsAt ?? null,
  };
  db.calendar_events.push(row);
  return toCalendarEvent(row);
}

export function updateCalendarEvent(
  eventId: string,
  updates: Partial<{
    title: string;
    kind: CalendarEventKind;
    startsAt: string;
    endsAt: string | null;
    departmentId: string | null;
    courseId: string | null;
  }>,
): CalendarEvent | undefined {
  const row = db.calendar_events.find((event) => event.id === eventId);
  if (!row) return undefined;
  if (updates.title !== undefined) row.title = updates.title;
  if (updates.kind !== undefined) row.kind = updates.kind;
  if (updates.startsAt !== undefined) row.starts_at = updates.startsAt;
  if (updates.endsAt !== undefined) row.ends_at = updates.endsAt;
  if (updates.departmentId !== undefined) row.department_id = updates.departmentId;
  if (updates.courseId !== undefined) row.course_id = updates.courseId;
  return toCalendarEvent(row);
}

export function deleteCalendarEvent(eventId: string): boolean {
  const before = db.calendar_events.length;
  db.calendar_events = db.calendar_events.filter((event) => event.id !== eventId);
  return db.calendar_events.length < before;
}

// ============================================
// Chat
// ============================================

export function getChannelsByCourse(courseId: string): ChatChannel[] {
  return db.chat_channels
    .filter((channel) => channel.course_id === courseId)
    .map(toChannel);
}

export function getChannel(channelId: string): ChatChannel | undefined {
  const row = db.chat_channels.find((channel) => channel.id === channelId);
  return row ? toChannel(row) : undefined;
}

export function getMessages(channelId: string): ChatMessage[] {
  return db.chat_messages
    .filter((message) => message.channel_id === channelId)
    .sort((a, b) => a.sent_at.localeCompare(b.sent_at))
    .map(toMessage);
}

export function createMessage(input: {
  channelId: string;
  authorId: string;
  body: string;
}): ChatMessage {
  const row = {
    id: randomUUID(),
    channel_id: input.channelId,
    author_id: input.authorId,
    body: input.body,
    sent_at: nowISO(),
  };
  db.chat_messages.push(row);
  return toMessage(row);
}

// ============================================
// Telemetry, effort and integrity
// ============================================

export function getTelemetryBatches(): SignedTelemetryBatch[] {
  return db.telemetry_batches;
}

export function createTelemetryBatch(batch: SignedTelemetryBatch): void {
  db.telemetry_batches.push(batch);
}

export function getEffortScore(
  studentId: string,
  assignmentId: string,
): EffortScore | undefined {
  return db.effort_scores.find(
    (score) =>
      score.studentId === studentId && score.assignmentId === assignmentId,
  );
}

export function setEffortScore(score: EffortScore): void {
  const existing = db.effort_scores.find(
    (entry) => entry.sessionId === score.sessionId,
  );
  if (existing) {
    Object.assign(existing, score);
  } else {
    db.effort_scores.push(score);
  }
}

export function getIntegrityFlags(
  studentId: string,
  assignmentId: string,
): IntegrityFlag[] {
  const row = db.integrity_flags.find(
    (entry) =>
      entry.studentId === studentId && entry.assignmentId === assignmentId,
  );
  return row ? [...row.flags] : [];
}

export function setIntegrityFlags(
  studentId: string,
  assignmentId: string,
  flags: IntegrityFlag[],
): void {
  db.integrity_flags = db.integrity_flags.filter(
    (entry) =>
      !(entry.studentId === studentId && entry.assignmentId === assignmentId),
  );
  db.integrity_flags.push({ studentId, assignmentId, flags: [...flags] });
}

// ============================================
// SMS verification
// ============================================

export function createSmsCode(input: {
  id: string;
  phone: string;
  code: string;
  expiresAt: string;
  createdAt?: string;
}): SmsCode {
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
  const index = db.sms_verification_codes.findIndex(
    (entry) => entry.phone === phone && entry.code === code,
  );
  if (index === -1) return false;
  const [row] = db.sms_verification_codes.splice(index, 1);
  const expiresAt = normDate(row.expires_at);
  return Boolean(expiresAt && new Date(expiresAt).getTime() > Date.now());
}

export function markPhoneVerified(phone: string): void {
  const row = db.users.find((user) => user.phone === phone);
  if (row) row.is_phone_verified = 1;
}

// ============================================
// Attendance
// ============================================

export function getAttendanceRecords(
  courseId?: string,
  date?: string,
): AttendanceRecord[] {
  let records = db.attendance_records;
  if (courseId) records = records.filter((row) => row.course_id === courseId);
  if (date) records = records.filter((row) => row.date === date);
  return records
    .slice()
    .sort((a, b) => b.date.localeCompare(a.date))
    .map(toAttendanceRecord);
}

export function getAttendanceRecord(id: string): AttendanceRecord | undefined {
  const row = db.attendance_records.find((record) => record.id === id);
  return row ? toAttendanceRecord(row) : undefined;
}

export function upsertAttendanceRecord(input: {
  id?: string;
  courseId: string;
  studentId: string;
  date: string;
  status: AttendanceRecord["status"];
  markedBy: string;
  notes?: string;
}): AttendanceRecord {
  const existing = db.attendance_records.find(
    (record) =>
      record.course_id === input.courseId &&
      record.student_id === input.studentId &&
      record.date === input.date,
  );

  if (existing) {
    existing.status = input.status;
    existing.marked_by = input.markedBy;
    existing.notes = input.notes ?? "";
    return toAttendanceRecord(existing);
  }

  const row = {
    id: input.id || randomUUID(),
    course_id: input.courseId,
    student_id: input.studentId,
    date: input.date,
    status: input.status,
    marked_by: input.markedBy,
    notes: input.notes ?? "",
    created_at: nowISO(),
  };
  db.attendance_records.push(row);
  return toAttendanceRecord(row);
}

// ============================================
// Teacher notes
// ============================================

export function getTeacherNotes(
  courseId?: string,
  courseCode?: string,
): TeacherNote[] {
  let notes = db.teacher_notes;
  if (courseId) notes = notes.filter((note) => note.course_id === courseId);
  if (courseCode) {
    notes = notes.filter((note) => note.course_code === courseCode);
  }
  return notes
    .slice()
    .sort((a, b) => b.created_at.localeCompare(a.created_at))
    .map(toTeacherNote);
}

export function getTeacherNote(id: string): TeacherNote | undefined {
  const row = db.teacher_notes.find((note) => note.id === id);
  return row ? toTeacherNote(row) : undefined;
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
  const now = nowISO();
  const existing = db.teacher_notes.find((note) => note.id === input.id);
  if (existing) {
    existing.book_name = input.bookName;
    existing.course_code = input.courseCode;
    existing.title = input.title;
    existing.content = input.content;
    existing.updated_at = now;
    return toTeacherNote(existing);
  }

  const row = {
    id: input.id || randomUUID(),
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
  return toTeacherNote(row);
}

export function deleteTeacherNote(id: string): void {
  db.teacher_notes = db.teacher_notes.filter((note) => note.id !== id);
}

// ============================================
// Student departments
// ============================================

export function getStudentDepartments(
  studentId?: string,
  departmentId?: string,
): StudentDepartment[] {
  let entries = db.student_departments;
  if (studentId) {
    entries = entries.filter((entry) => entry.student_id === studentId);
  }
  if (departmentId) {
    entries = entries.filter((entry) => entry.department_id === departmentId);
  }
  return entries
    .slice()
    .sort((a, b) => b.enrolled_at.localeCompare(a.enrolled_at))
    .map(toStudentDepartment);
}

export function enrollStudentInDepartment(input: {
  studentId: string;
  departmentId: string;
  enrolledBy: string;
}): StudentDepartment {
  const existing = db.student_departments.find(
    (entry) =>
      entry.student_id === input.studentId &&
      entry.department_id === input.departmentId,
  );
  if (existing) return toStudentDepartment(existing);

  const row = {
    id: randomUUID(),
    student_id: input.studentId,
    department_id: input.departmentId,
    enrolled_at: nowISO(),
    enrolled_by: input.enrolledBy,
  };
  db.student_departments.push(row);
  return toStudentDepartment(row);
}

export function unenrollStudentFromDepartment(
  studentId: string,
  departmentId: string,
): void {
  db.student_departments = db.student_departments.filter(
    (entry) =>
      !(
        entry.student_id === studentId &&
        entry.department_id === departmentId
      ),
  );
}

export function getStudentsByDepartment(departmentId: string): User[] {
  const studentIds = new Set(
    db.student_departments
      .filter((entry) => entry.department_id === departmentId)
      .map((entry) => entry.student_id),
  );
  return db.users
    .filter((user) => user.role === "student" && studentIds.has(user.id))
    .map(toUser);
}

export function getDepartmentsByStudent(studentId: string): Department[] {
  const departmentIds = new Set(
    db.student_departments
      .filter((entry) => entry.student_id === studentId)
      .map((entry) => entry.department_id),
  );
  return db.departments
    .filter((department) => departmentIds.has(department.id))
    .map(toDepartment);
}

export function getStudentsByCourse(courseId: string): User[] {
  const course = db.courses.find((entry) => entry.id === courseId);
  if (!course) return [];
  const studentIds = new Set(parseJson<string[]>(course.student_ids, []));
  return db.users
    .filter((user) => user.role === "student" && studentIds.has(user.id))
    .map(toUser);
}
