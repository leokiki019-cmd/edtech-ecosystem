export type Role = "student" | "teacher" | "admin";

export const AI_PLATFORM_HOSTS = [
  "chatgpt.com",
  "chat.openai.com",
  "claude.ai",
  "gemini.google.com",
  "copilot.microsoft.com",
  "perplexity.ai",
] as const;

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
  error: {
    code: string;
    message: string;
  };
}

export interface ApiResponse<T> {
  data: T;
}
