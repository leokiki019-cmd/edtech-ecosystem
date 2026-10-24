-- SQLite schema for the EdTech Ecosystem API
-- Single-file database, no server required

PRAGMA foreign_keys = ON;

CREATE TABLE IF NOT EXISTS users (
  id TEXT PRIMARY KEY,
  display_name TEXT NOT NULL,
  email TEXT NOT NULL UNIQUE,
  phone TEXT NOT NULL UNIQUE,
  role TEXT NOT NULL CHECK (role IN ('student', 'teacher', 'admin')),
  course_ids TEXT NOT NULL DEFAULT '[]',
  password_hash TEXT,
  is_phone_verified INTEGER NOT NULL DEFAULT 0,
  created_at TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS courses (
  id TEXT PRIMARY KEY,
  title TEXT NOT NULL,
  code TEXT NOT NULL,
  teacher_id TEXT NOT NULL,
  student_ids TEXT NOT NULL DEFAULT '[]',
  term TEXT NOT NULL,
  created_at TEXT NOT NULL,
  FOREIGN KEY (teacher_id) REFERENCES users(id)
);

CREATE TABLE IF NOT EXISTS assignments (
  id TEXT PRIMARY KEY,
  course_id TEXT NOT NULL,
  title TEXT NOT NULL,
  brief TEXT NOT NULL,
  due_at TEXT NOT NULL,
  status TEXT NOT NULL DEFAULT 'open' CHECK (status IN ('draft', 'open', 'closed')),
  created_at TEXT NOT NULL,
  FOREIGN KEY (course_id) REFERENCES courses(id)
);

CREATE TABLE IF NOT EXISTS submissions (
  id TEXT PRIMARY KEY,
  assignment_id TEXT NOT NULL,
  student_id TEXT NOT NULL,
  status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'submitted', 'graded', 'late', 'missing')),
  submitted_at TEXT,
  attachments TEXT NOT NULL DEFAULT '[]',
  grade REAL,
  effort_score INTEGER,
  created_at TEXT NOT NULL DEFAULT (datetime('now')),
  FOREIGN KEY (assignment_id) REFERENCES assignments(id),
  FOREIGN KEY (student_id) REFERENCES users(id)
);

CREATE TABLE IF NOT EXISTS calendar_events (
  id TEXT PRIMARY KEY,
  course_id TEXT,
  title TEXT NOT NULL,
  kind TEXT NOT NULL,
  starts_at TEXT NOT NULL,
  ends_at TEXT,
  FOREIGN KEY (course_id) REFERENCES courses(id)
);

CREATE TABLE IF NOT EXISTS chat_channels (
  id TEXT PRIMARY KEY,
  course_id TEXT NOT NULL,
  name TEXT NOT NULL,
  kind TEXT NOT NULL DEFAULT 'discussion' CHECK (kind IN ('announcement', 'discussion')),
  member_ids TEXT NOT NULL DEFAULT '[]',
  FOREIGN KEY (course_id) REFERENCES courses(id)
);

CREATE TABLE IF NOT EXISTS chat_messages (
  id TEXT PRIMARY KEY,
  channel_id TEXT NOT NULL,
  author_id TEXT NOT NULL,
  body TEXT NOT NULL,
  sent_at TEXT NOT NULL,
  FOREIGN KEY (channel_id) REFERENCES chat_channels(id),
  FOREIGN KEY (author_id) REFERENCES users(id)
);

CREATE TABLE IF NOT EXISTS telemetry_batches (
  batch_id TEXT PRIMARY KEY,
  student_id TEXT NOT NULL,
  assignment_id TEXT NOT NULL,
  client_signature TEXT NOT NULL,
  client_public_key TEXT NOT NULL,
  created_at TEXT NOT NULL,
  FOREIGN KEY (student_id) REFERENCES users(id),
  FOREIGN KEY (assignment_id) REFERENCES assignments(id)
);

CREATE TABLE IF NOT EXISTS telemetry_events (
  id TEXT PRIMARY KEY,
  batch_id TEXT NOT NULL,
  session_id TEXT NOT NULL,
  type TEXT NOT NULL,
  occurred_at TEXT NOT NULL,
  payload TEXT NOT NULL DEFAULT '{}',
  FOREIGN KEY (batch_id) REFERENCES telemetry_batches(batch_id)
);

CREATE TABLE IF NOT EXISTS effort_scores (
  session_id TEXT PRIMARY KEY,
  assignment_id TEXT NOT NULL,
  student_id TEXT NOT NULL,
  score INTEGER NOT NULL DEFAULT 0,
  keystrokes INTEGER NOT NULL DEFAULT 0,
  pastes INTEGER NOT NULL DEFAULT 0,
  paste_volume INTEGER NOT NULL DEFAULT 0,
  ai_tab_switches INTEGER NOT NULL DEFAULT 0,
  active_seconds INTEGER NOT NULL DEFAULT 0,
  computed_at TEXT NOT NULL,
  FOREIGN KEY (assignment_id) REFERENCES assignments(id),
  FOREIGN KEY (student_id) REFERENCES users(id)
);

CREATE TABLE IF NOT EXISTS integrity_flags (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  session_id TEXT NOT NULL,
  assignment_id TEXT NOT NULL,
  student_id TEXT NOT NULL,
  flag TEXT NOT NULL,
  created_at TEXT NOT NULL DEFAULT (datetime('now'))
);

-- No FK on phone: verification codes are transient and must not crash when
-- the account lookup fails; routes validate the account explicitly.
CREATE TABLE IF NOT EXISTS sms_verification_codes (
  id TEXT PRIMARY KEY,
  phone TEXT NOT NULL,
  code TEXT NOT NULL,
  expires_at TEXT NOT NULL,
  created_at TEXT NOT NULL DEFAULT (datetime('now'))
);

CREATE INDEX IF NOT EXISTS idx_sms_codes_phone ON sms_verification_codes(phone);
CREATE INDEX IF NOT EXISTS idx_assignments_course ON assignments(course_id);
CREATE INDEX IF NOT EXISTS idx_submissions_assignment ON submissions(assignment_id);
CREATE INDEX IF NOT EXISTS idx_submissions_student ON submissions(student_id);
CREATE INDEX IF NOT EXISTS idx_telemetry_batch ON telemetry_events(batch_id);
CREATE INDEX IF NOT EXISTS idx_effort_student_assignment ON effort_scores(student_id, assignment_id);
CREATE INDEX IF NOT EXISTS idx_messages_channel ON chat_messages(channel_id);
CREATE INDEX IF NOT EXISTS idx_calendar_course ON calendar_events(course_id);
