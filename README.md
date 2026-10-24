# EdTech Ecosystem

**Private repository:** https://github.com/leokiki019-cmd/edtech-ecosystem

A unified EdTech ecosystem for classroom management, student collaboration, and
process-based academic integrity monitoring. This monorepo is the implementation
foundation for the project described in [`Project_Proposal.pdf`](./Project_Proposal.pdf).
A converted Word copy is available at [`Project_Proposal.docx`](./Project_Proposal.docx).

## Current status

| Area | Status |
| --- | --- |
| API (`apps/api`) | Working Fastify + TypeScript service on SQLite with auth (scrypt passwords, HMAC-signed tokens, SMS verification codes) |
| Browser extension (`apps/extension`) | Manifest v0.2.0: consent-gated telemetry, signed batch upload to the API, options page with account login, retry queue |
| Flutter app (`apps/app`) | Wired to the API: login / signup / SMS verification, auth-gated routing, live courses, calendar, chat, integrity screens |
| Rust core (`crates/telemetry-core`) | Event model, effort scoring, integrity flags, and unit tests; not yet compiled in this environment |

The API has been typechecked, built, and smoke-tested end to end (auth flow
included). The extension scripts are syntax-checked and the manifest is valid.
The Flutter app passes `flutter analyze` with no errors, builds for web in
release mode, and passes an 8-case integration test suite against the live API.
Rust is not installed on this machine, so that component has not been run.

### Demo accounts

All seeded accounts share the password `password123`:

| Phone | Role | Name |
| --- | --- | --- |
| `+15550001001` | teacher | Dr. Maya Chen |
| `+15550001002` | student | Alex Rivera |
| `+15550001003` | student | Priya Nair |
| `+15550001004` | student | Jordan Lee |
| `+15550001005` | admin | Sam Okafor |

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

Version 0.2.0 adds the sync pipeline and consent flow:

- **Consent gate**: nothing is recorded or uploaded until the student enables
  monitoring on the options page. The options page opens automatically on
  install and explains exactly what is and is not recorded.
- **Account link**: the options page signs in against the API
  (`/api/v1/auth/login`) so batches carry the real student identity.
- **Signed batch upload**: queued events are flushed every 15 seconds as
  HMAC-SHA256-signed batches to `POST /api/v1/telemetry/batches`, with offline
  queueing, exponential-backoff retries, and a 401 → "sign in again" state.
- **Popup sync status**: the popup now shows consent state and queued batches.

The popup shows the live effort score, keystrokes, pastes, pasted characters, AI
tab switches, and active time. Password and hidden inputs, as well as elements
marked with `data-sensitive`, are ignored. Sessions are stored per tab in
`chrome.storage.session`.

Supported AI hosts: `chatgpt.com`, `chat.openai.com`, `claude.ai`,
`gemini.google.com`, `copilot.microsoft.com`, `perplexity.ai`.

### 3. Flutter app (`apps/app`)

Cross-platform client with a five-tab shell and full auth flow:

- **Auth gate**: the router redirects signed-out users to login; sign up, sign
  in, and SMS verification ("forgot password") all round-trip the API. Tokens
  are held in memory for the session.
- Dashboard with greeting, deadline cards, and live summary metrics.
- Courses loaded from the API with teacher names and open-assignment counts.
- Calendar with upcoming events for the signed-in user's role.
- Chat with course channels; messages post as the signed-in user.
- Integrity with the real effort score for the first open assignment, and an
  honest empty state until the extension records telemetry.

The API base URL defaults to `http://localhost:4000` and can be overridden at
build time with `--dart-define=API_BASE_URL=https://your-api.example.com`.

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
| `NODE_ENV` | `development` | Log level selection; also controls whether SMS codes are echoed in responses |
| `HOST` | `0.0.0.0` | Bind address |
| `PORT` | `4000` | HTTP port |
| `CORS_ORIGIN` | `*` | Allowed CORS origin |
| `AUTH_SECRET` | dev-only fallback | HMAC key for bearer tokens; **set this in production** |

The database is a single SQLite file at `apps/api/data/edtech.sqlite`, created
and seeded automatically on first run (delete the file to re-seed).

### Load the extension

1. Open `chrome://extensions`.
2. Enable **Developer mode**.
3. Choose **Load unpacked** and select `apps/extension`.

The settings page opens on first install: sign in with a seeded account
(e.g. `+15550001002` / `password123`), then enable monitoring consent. Open any
page, type into a document, and click the extension icon to see the live
session score and sync status. Use `?assignmentId=a-001` in the page URL or a
`<meta name="edtech-assignment-id" content="a-001">` tag to attach a session to
an assignment (sessions without an assignment stay local and are never
uploaded).

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

To run the release web build locally:

```powershell
flutter build web --release
# serve apps/app/build/web with any static server, e.g. on port 8080
```

The app signs in against the API at `http://localhost:4000` by default.

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
| POST | `/api/v1/auth/register` | Create an account (student or teacher); returns user + token |
| POST | `/api/v1/auth/login` | Sign in with phone/email + password; returns user + token |
| POST | `/api/v1/auth/send-sms` | Send an SMS verification code (echoed in dev only) |
| POST | `/api/v1/auth/verify-sms` | Verify the code; marks the phone verified and returns a token |
| GET | `/api/v1/auth/me` | Resolve the bearer token to the current user |
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
| API smoke test | All endpoints verified, including the full auth flow: seeded login (`password123`), wrong-password 401, register, signed-token `/me`, forged-token 401, SMS send/verify/reuse-rejection, telemetry ingest (score 45, `large_paste`), integrity report, ISO-8601 dates |
| Extension syntax | `node --check` passed for background, content, popup, and options scripts |
| Manifest | Valid Manifest V3 JSON with `options_ui` |
| `flutter analyze` | No errors and no warnings from new code |
| `flutter build web --release` | Passed; production bundle in `apps/app/build/web` |
| Flutter integration tests | 8/8 passed against the live API (login, wrong password, courses, assignments, calendar, chat, integrity, register + SMS flow) — see `apps/app/test/api_integration_test.dart` |
| Flutter UI smoke | Web build serves and renders; auth gate redirects to the login screen |
| Rust | Not run; Rust toolchain not installed |

See [`docs/IMPLEMENTATION_NOTES.md`](./docs/IMPLEMENTATION_NOTES.md) for the
chronological record of setup and verification.

## Known limitations and next steps

1. Verify telemetry signatures server-side (the batches are HMAC-signed by the
   extension, but the API does not verify them yet) and move to asymmetric keys.
2. Enforce bearer-token authorization on the classroom/telemetry routes (tokens
   are issued and verified for `/auth/me`, but other routes are still open).
3. Build the Rust core for FFI and WASM, then integrate it with Flutter via
   `flutter_rust_bridge`.
4. Persist per-assignment telemetry streams to support time-lapse writing replay.
5. Implement Google Sheets/Excel sync, automated missing-assignment nudges, and
   the teacher AI assistant.
6. Add push notifications for deadlines and overdue assignments.
7. Add CI for typecheck, build, extension checks, Flutter analyze/test, and Rust
   tests.
8. Scope extension host permissions before distribution (optional_host_permissions
   with per-site grants instead of `<all_urls>`).

## Repository access

The repository is private and owned by `leokiki019-cmd`; the owner already has
full access. No access keys or tokens are stored in this repository. To grant a
teammate access, add them under **Settings → Collaborators and teams** on
GitHub. Collaborator invites require the teammate's GitHub username.
