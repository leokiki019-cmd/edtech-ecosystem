import type {
  Assignment,
  CalendarEvent,
  ChatChannel,
  ChatMessage,
  Course,
  EffortScore,
  IntegrityFlag,
  SignedTelemetryBatch,
  Submission,
  User,
} from "@edtech/shared";

const now = Date.now();
const dayMs = 86_400_000;
const hourMs = 3_600_000;
const atDays = (days: number) => new Date(now + days * dayMs).toISOString();
const atHours = (hours: number) => new Date(now + hours * hourMs).toISOString();

export const users: User[] = [
  {
    id: "u-teacher-1",
    displayName: "Dr. Maya Chen",
    email: "maya.chen@example.edu",
    phone: "+15550001001",
    role: "teacher",
    courseIds: ["c-001"],
    createdAt: atDays(-120),
  },
  {
    id: "u-student-1",
    displayName: "Alex Rivera",
    email: "alex.rivera@example.edu",
    phone: "+15550001002",
    role: "student",
    courseIds: ["c-001"],
    createdAt: atDays(-90),
  },
  {
    id: "u-student-2",
    displayName: "Priya Nair",
    email: "priya.nair@example.edu",
    phone: "+15550001003",
    role: "student",
    courseIds: ["c-001"],
    createdAt: atDays(-90),
  },
  {
    id: "u-student-3",
    displayName: "Jordan Lee",
    email: "jordan.lee@example.edu",
    phone: "+15550001004",
    role: "student",
    courseIds: ["c-001"],
    createdAt: atDays(-85),
  },
  {
    id: "u-admin-1",
    displayName: "Sam Okafor",
    email: "sam.okafor@example.edu",
    phone: "+15550001005",
    role: "admin",
    courseIds: [],
    createdAt: atDays(-200),
  },
];

export const courses: Course[] = [
  {
    id: "c-001",
    title: "Human-Computer Interaction",
    code: "CS 301",
    teacherId: "u-teacher-1",
    studentIds: ["u-student-1", "u-student-2", "u-student-3"],
    term: "Fall 2026",
    createdAt: atDays(-60),
  },
];

export const assignments: Assignment[] = [
  {
    id: "a-001",
    courseId: "c-001",
    title: "Usability Study Report",
    brief: "Run a moderated usability study with five participants and report findings, severity ratings and design recommendations.",
    dueAt: atDays(7),
    status: "open",
    createdAt: atDays(-14),
  },
  {
    id: "a-002",
    courseId: "c-001",
    title: "Prototype Critique",
    brief: "Critique a peer interactive prototype using Nielsen's heuristics and propose three concrete improvements.",
    dueAt: atDays(3),
    status: "open",
    createdAt: atDays(-10),
  },
  {
    id: "a-003",
    courseId: "c-001",
    title: "Final Reflection",
    brief: "Reflect on the semester's design process, linking each milestone to the course learning outcomes.",
    dueAt: atDays(14),
    status: "open",
    createdAt: atDays(-4),
  },
  {
    id: "a-004",
    courseId: "c-001",
    title: "Heuristic Evaluation",
    brief: "Evaluate the campus portal against the ten usability heuristics and deliver a findings table.",
    dueAt: atDays(-2),
    status: "closed",
    createdAt: atDays(-21),
  },
];

export const submissions: Submission[] = [
  {
    id: "s-001",
    assignmentId: "a-001",
    studentId: "u-student-1",
    status: "submitted",
    submittedAt: atHours(-20),
    attachments: [
      {
        id: "att-001",
        fileName: "usability-study-report.pdf",
        mimeType: "application/pdf",
        sizeBytes: 482_133,
        url: "https://files.example.edu/att-001",
      },
    ],
    grade: null,
    effortScore: 84,
  },
  {
    id: "s-002",
    assignmentId: "a-002",
    studentId: "u-student-2",
    status: "pending",
    submittedAt: null,
    attachments: [],
    grade: null,
    effortScore: null,
  },
  {
    id: "s-003",
    assignmentId: "a-004",
    studentId: "u-student-3",
    status: "late",
    submittedAt: atDays(-1),
    attachments: [
      {
        id: "att-002",
        fileName: "heuristic-evaluation.docx",
        mimeType: "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
        sizeBytes: 91_204,
        url: "https://files.example.edu/att-002",
      },
    ],
    grade: 72,
    effortScore: 58,
  },
];

export const calendarEvents: CalendarEvent[] = [
  {
    id: "e-001",
    courseId: "c-001",
    title: "Usability Study Report due",
    kind: "assignment",
    startsAt: atDays(7),
    endsAt: null,
  },
  {
    id: "e-002",
    courseId: "c-001",
    title: "Prototype Critique due",
    kind: "assignment",
    startsAt: atDays(3),
    endsAt: null,
  },
  {
    id: "e-003",
    courseId: "c-001",
    title: "Heuristics quiz",
    kind: "quiz",
    startsAt: atDays(5),
    endsAt: atHours(122),
  },
  {
    id: "e-004",
    courseId: "c-001",
    title: "Studio session",
    kind: "class",
    startsAt: atDays(1),
    endsAt: atHours(26),
  },
  {
    id: "e-005",
    courseId: null,
    title: "Institution research symposium",
    kind: "institution",
    startsAt: atDays(10),
    endsAt: atHours(246),
  },
];

export const channels: ChatChannel[] = [
  {
    id: "ch-001",
    courseId: "c-001",
    name: "Announcements",
    kind: "announcement",
    memberIds: ["u-teacher-1", "u-student-1", "u-student-2", "u-student-3"],
  },
  {
    id: "ch-002",
    courseId: "c-001",
    name: "Studio Discussion",
    kind: "discussion",
    memberIds: ["u-teacher-1", "u-student-1", "u-student-2", "u-student-3"],
  },
];

export const messages: ChatMessage[] = [
  {
    id: "m-001",
    channelId: "ch-001",
    authorId: "u-teacher-1",
    body: "Reminder: the usability study report is due next week. Bring questions to Thursday's studio.",
    sentAt: atHours(-30),
  },
  {
    id: "m-002",
    channelId: "ch-002",
    authorId: "u-student-1",
    body: "Sharing my participant consent template for anyone who needs one.",
    sentAt: atHours(-6),
  },
];

export const telemetryBatches: SignedTelemetryBatch[] = [];
export const effortScores = new Map<string, EffortScore>();
export const integrityFlags = new Map<string, IntegrityFlag[]>();

export const effortKey = (studentId: string, assignmentId: string) =>
  `${studentId}:${assignmentId}`;
