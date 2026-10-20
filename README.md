# EdTech Ecosystem

**Private repository:** https://github.com/leokiki019-cmd/edtech-ecosystem

A unified EdTech ecosystem for classroom management, student collaboration, and
process-based academic integrity monitoring. This monorepo is the implementation
foundation for the project described in [`Project_Proposal.pdf`](./Project_Proposal.pdf).
A converted Word copy is available at [`Project_Proposal.docx`](./Project_Proposal.docx).

## Current status

| Area | Status |
| --- | --- |
| API (`apps/api`) | Working Fastify + TypeScript scaffold with seeded in-memory data |
| Browser extension (`apps/extension`) | Working Manifest V3 scaffold: typing/paste telemetry, effort score, AI tab-switch tracking |
| Flutter app (`apps/app`) | Static UI scaffold: dashboard, courses, calendar, chat, integrity |
| Rust core (`crates/telemetry-core`) | Event model, effort scoring, integrity flags, and unit tests; not yet compiled in this environment |
| Data and auth | In-memory data only; no database, authentication, or authorization yet |

The API has been typechecked, built, and smoke-tested. The extension has been
syntax-checked. Flutter and Rust are not installed on the current machine, so
those two components have not been run yet.

## Components

### 1. API (`apps/api`)

Fastify 5 + TypeScript REST API. It provides seeded classroom data and the
process-based integrity pipeline:

- Course, assignment, submission, roster, calendar, and chat endpoints.
- Signed telemetry batch ingestion.
- Effort score calculation and integrity flag generation.
- In-memory store seeded with one course, five users, four assignments, three
  submissions, five calendar events, two chat channels, and two messages.

Source layout:

```
apps/api/src
├── app.ts                  Fastify instance, CORS, error handling
├── config.ts               Environment configuration
├── index.ts                Server bootstrap
├── routes/
│   ├── classroom.ts        Calendar, channels, messages
│   ├── courses.ts          Courses, assignments, submissions
│   └── telemetry.ts        Telemetry ingestion and integrity reports
├── services/effort.ts      Effort metrics, score, and flags
└── store/memory.ts         Seed data and in-memory state
```

### 2. Browser extension (`apps/extension`)

Manifest V3 extension ("Integrity Lens") that captures process signals while a
student writes:

- Keystroke cadence (inter-key timing only; never key content).
- Paste count and pasted character volume.
- Cursor movement distance.
- Tab switches to supported generative AI platforms.

The popup shows the live effort score, keystrokes, pastes, pasted characters, AI
tab switches, and active time. Password and hidden inputs, as well as elements
marked with `data-sensitive`, are ignored. Sessions are stored per tab in
`chrome.storage.session`.

Supported AI hosts: `chatgpt.com`, `chat.openai.com`, `claude.ai`,
`gemini.google.com`, `copilot.microsoft.com`, `perplexity.ai`.

### 3. Flutter app (`apps/app`)

Cross-platform client scaffold with a five-tab shell:

- Dashboard with deadline cards and summary metrics.
- Courses with course cards.
- Calendar with upcoming events.
- Chat with channel list.
- Integrity with an effort score card and privacy notice.

The screens currently use static sample data. The next step is wiring them to
the API.

### 4. Shared types (`packages/shared`)

TypeScript domain contracts shared by the API and future clients: users, roles,
courses, assignments, submissions, calendar events, chat, telemetry, effort
scores, integrity reports, and API envelopes.

### 5. Rust telemetry core (`crates/telemetry-core`)

Native engine foundation intended for FFI (`flutter_rust_bridge`) and WebAssembly
builds. It includes:

- `EventKind` and `TelemetryEvent` models with camelCase JSON interop.
- `EffortMetrics::from_events`, `score`, and `integrity_flags`.
- Three unit tests covering organic typing, mass paste, and AI tab switching.

The crate is configured as `cdylib`, `staticlib`, and `rlib` so it can serve
desktop/mobile FFI and WASM targets.

## Repository layout

```
.
├── apps/
│   ├── api/                  Fastify + TypeScript API
│   ├── app/                  Flutter client scaffold
│   └── extension/            Manifest V3 browser extension
├── crates/
│   └── telemetry-core/       Rust telemetry and scoring engine
├── packages/
│   └── shared/               Shared TypeScript domain types
├── docs/
│   └── IMPLEMENTATION_NOTES.md
├── Project_Proposal.pdf      Original project proposal
├── Project_Proposal.docx     Converted Word copy
├── Cargo.toml                Rust workspace
├── package.json              npm workspace root
└── .gitattributes            LF normalization and binary rules
```

## Quick start

### Prerequisites

- Node.js 20+ and npm 10+ (verified with Node 24.18.0 and npm 11.16.0).
- Flutter SDK 3.4+ for the app.
- Rust stable for the core.
- Chrome or Edge for the extension.

### Install and run the API

```powershell
npm install
npm run dev:api
```

The API listens on `http://localhost:4000`. Verify it:

```powershell
Invoke-RestMethod http://localhost:4000/health
```

Production build:

```powershell
npm run build:api
npm run start --workspace @edtech/api
```

Environment variables are documented in `apps/api/.env.example`:

| Variable | Default | Purpose |
| --- | --- | --- |
| `NODE_ENV` | `development` | Log level selection |
| `HOST` | `0.0.0.0` | Bind address |
| `PORT` | `4000` | HTTP port |
| `CORS_ORIGIN` | `*` | Allowed CORS origin |

### Load the extension

1. Open `chrome://extensions`.
2. Enable **Developer mode**.
3. Choose **Load unpacked** and select `F:\Project\apps\extension`.

Open any page, type into a document, and click the extension icon to see the
live session score. Use `?assignmentId=a-001` in the page URL or a
`<meta name="edtech-assignment-id" content="a-001">` tag to attach a session to
an assignment.

### Run the Flutter app

```powershell
cd apps/app
flutter create . --project-name edtech_app
flutter pub get
flutter run
```

`flutter create .` generates the platform folders (`android`, `ios`, `web`,
`windows`, etc.) that are not checked in yet. It should preserve the existing
`lib/main.dart`, `pubspec.yaml`, and `analysis_options.yaml`.

### Test the Rust core

```powershell
cargo test
```

Run this from the repository root so Cargo uses the workspace.

## API reference

Base path: `/api/v1` (except `/health`).

| Method | Path | Purpose |
| --- | --- | --- |
| GET | `/health` | Service health check |
| GET | `/courses` | List courses with teacher name, student count, and open assignment count |
| GET | `/courses/:courseId` | Course detail with teacher, roster, and assignments |
| GET | `/courses/:courseId/assignments` | Assignments for a course, sorted by due date |
| GET | `/assignments/:assignmentId` | Assignment detail with course |
| GET | `/assignments/:assignmentId/roster` | Submission status, grade, and effort score per student |
| POST | `/assignments/:assignmentId/submissions` | Create or update a student submission |
| POST | `/telemetry/batches` | Ingest a signed telemetry batch and compute an effort score |
| GET | `/integrity/:assignmentId/:studentId` | Latest integrity report and flags |
| GET | `/calendar?userId=` | Calendar events for a user's role and courses |
| GET | `/courses/:courseId/channels` | Chat channels for a course |
| GET | `/channels/:channelId/messages` | Messages in a channel |
| POST | `/channels/:channelId/messages` | Post a message (students cannot post in announcement channels) |

### Submit a submission

```http
POST /api/v1/assignments/a-002/submissions
Content-Type: application/json

{
  "studentId": "u-student-2",
  "attachments": []
}
```

Submission status becomes `submitted`, or `late` when the due date has passed.
Submitting when the assignment is still `draft` returns `409`.

### Ingest telemetry

```http
POST /api/v1/telemetry/batches
Content-Type: application/json

{
  "batchId": "batch-demo-1",
  "studentId": "u-student-1",
  "assignmentId": "a-001",
  "clientSignature": "demo-signature",
  "clientPublicKey": "demo-public-key",
  "createdAt": "2026-10-19T10:00:00Z",
  "events": [
    {
      "id": "ev-1",
      "sessionId": "sess-demo",
      "assignmentId": "a-001",
      "studentId": "u-student-1",
      "type": "keystroke",
      "occurredAt": "2026-10-19T10:00:00Z",
      "payload": { "deltaMs": 120 }
    },
    {
      "id": "ev-2",
      "sessionId": "sess-demo",
      "assignmentId": "a-001",
      "studentId": "u-student-1",
      "type": "paste",
      "occurredAt": "2026-10-19T10:00:02Z",
      "payload": { "characterCount": 50 }
    }
  ]
}
```

The response includes the accepted event count and computed effort score. This
sample returns a score of `45` and the `large_paste` flag.

The signature and public-key fields are required but are **not yet
cryptographically verified**. That is a planned hardening step.

## Effort scoring

The TypeScript API and Rust core implement the same scoring model:

| Signal | Effect on score |
| --- | --- |
| Paste volume ratio | Up to `-45` points |
| AI tab switches | `-10` per switch, capped at `-30` |
| Pasted content in a session under 60 active seconds | `-10` |
| Score range | `0` to `100` |

Integrity flags:

| Flag | Condition |
| --- | --- |
| `large_paste` | Paste volume at least 35% of total input, or at least 500 pasted characters |
| `ai_tab_switch` | One or more AI platform tab switches |
| `low_typing_ratio` | Fewer than 100 keystrokes with more than 200 pasted characters |
| `telemetry_gap` | No keystroke or paste events |
| `none` | No other flag applies |

Active time is derived from inter-keystroke delays, with each delay capped at
five seconds to avoid counting long idle periods.

## Seed data

| Entity | Values |
| --- | --- |
| Users | Dr. Maya Chen (teacher), Alex Rivera, Priya Nair, Jordan Lee (students), Sam Okafor (admin) |
| Course | `c-001` CS 301 Human-Computer Interaction, Fall 2026 |
| Assignments | `a-001` Usability Study Report, `a-002` Prototype Critique, `a-003` Final Reflection, `a-004` Heuristic Evaluation |
| Submissions | `s-001` (submitted, effort 84), `s-002` (pending), `s-003` (late, effort 58, grade 72) |
| Channels | `ch-001` Announcements, `ch-002` Studio Discussion |

## Verification performed

| Check | Result |
| --- | --- |
| `npm run typecheck` | Passed for `@edtech/api` and `@edtech/shared` |
| `npm run build:api` | Passed; ESM bundle generated in `apps/api/dist` |
| API smoke test | `/health` ok; 1 course; 5 calendar events; 2 telemetry events accepted; score 45; flag `large_paste`; report linked to submission `s-001`; roster 3 students; 2 channels |
| Extension syntax | `node --check` passed for background, content, and popup scripts |
| Manifest | Valid Manifest V3 JSON |
| Secret scan | No credentials or private keys found in the staged files |
| Git commit | 38 files committed as `41e1ea3` |
| Flutter | Not run; Flutter SDK not installed |
| Rust | Not run; Rust toolchain not installed |

See [`docs/IMPLEMENTATION_NOTES.md`](./docs/IMPLEMENTATION_NOTES.md) for the
chronological record of setup and verification.

## Known limitations and next steps

1. Replace the in-memory store with a database (PostgreSQL or SQLite) and add
   migrations.
2. Add authentication, role-based authorization, and per-user data scoping.
3. Implement server-side verification of telemetry signatures and encrypted
   client logs.
4. Wire the Flutter app to the API and add state management.
5. Build the Rust core for FFI and WASM, then integrate it with Flutter via
   `flutter_rust_bridge`.
6. Persist telemetry event streams to support time-lapse writing replay.
7. Implement Google Sheets/Excel sync, automated missing-assignment nudges, and
   the teacher AI assistant.
8. Add push notifications for deadlines and overdue assignments.
9. Add automated tests for API routes and extension scoring parity.
10. Add CI for typecheck, build, extension checks, and Rust tests; add Docker and
    deployment configuration.
11. Scope extension host permissions before distribution and add an explicit
    student consent flow.

## Repository access

The repository is private and owned by `leokiki019-cmd`; the owner already has
full access. No access keys or tokens are stored in this repository. To grant a
teammate access, add them under **Settings → Collaborators and teams** on
GitHub. Collaborator invites require the teammate's GitHub username.
