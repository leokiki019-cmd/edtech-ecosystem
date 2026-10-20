# Implementation Notes

Record of the work completed for the EdTech ecosystem project.

- Date: 2026-10-19
- Repository: https://github.com/leokiki019-cmd/edtech-ecosystem
- Initial commit: `41e1ea3` — "Initial monorepo scaffold"

## 1. Proposal extraction and conversion

The project brief arrived as `Project_Proposal.pdf` (3 pages, 74,850 bytes).
The PDF could not be read directly by the model, and no PDF tooling was
installed on the machine.

Steps:

1. Installed Python 3.12.10 via `winget` in user scope.
2. Installed `pdf2docx` 0.5.13 with its dependencies (PyMuPDF, python-docx,
   opencv-python-headless, and others).
3. Converted `Project_Proposal.pdf` to `Project_Proposal.docx` (41,253 bytes).
   Text and embedded images were preserved.
4. Extracted the document text with `python-docx` to recover the requirements.

The proposal describes four pillars:

- A cross-platform Flutter classroom command center (student portal, calendar,
  communication hub).
- A native Rust/C++ telemetry engine delivered through FFI and WebAssembly.
- A Manifest V3 process-based integrity extension (effort score, AI platform
  tab tracking, writing replay).
- A teacher AI bot with Google Sheets/Excel sync, missing-assignment nudges, and
  classroom organization.

## 2. Environment inventory

Available before setup:

- Node.js 24.18.0
- npm 11.16.0
- Git for Windows
- `winget` 1.29.380

Installed during work:

- Python 3.12.10 (user scope) and `pdf2docx` for the document conversion.
- GitHub CLI 2.102.0 (user scope) for repository operations.

Not available:

- Flutter SDK and Dart.
- Rust and Cargo.

The Flutter and Rust components are therefore scaffolds only and have not been
executed or compiled on this machine.

## 3. Monorepo scaffold

Root configuration:

- `package.json` with npm workspaces for `apps/api` and `packages/shared`.
- `Cargo.toml` workspace covering `crates/*`, resolver 2, size-optimized release
  profile.
- `.editorconfig`, `.gitignore`, `.gitattributes` with LF normalization.
- Git repository initialized on branch `main`.

### Shared package (`packages/shared`)

TypeScript domain contracts for roles, users, courses, assignments, submissions,
attachments, calendar events, chat channels/messages, telemetry events, signed
batches, effort scores, integrity flags/reports, and API response envelopes. It
also exports the list of monitored AI platform hosts.

### API (`apps/api`)

- Fastify 5 with `@fastify/cors`.
- Structured logging (debug in development, info in production).
- Centralized not-found and error handlers returning a consistent `ApiError`
  shape.
- Route modules for courses/assignments/submissions, telemetry/integrity, and
  classroom calendar/chat.
- In-memory store with seed data covering one course, five users, four
  assignments, three submissions, five calendar events, two channels, and two
  messages.
- Effort scoring service shared by ingestion and reporting.
- TypeScript strict mode, `tsx` for development, `tsup` for ESM production
  bundles.

Endpoints implemented:

```
GET  /health
GET  /api/v1/courses
GET  /api/v1/courses/:courseId
GET  /api/v1/courses/:courseId/assignments
GET  /api/v1/courses/:courseId/channels
GET  /api/v1/assignments/:assignmentId
GET  /api/v1/assignments/:assignmentId/roster
POST /api/v1/assignments/:assignmentId/submissions
POST /api/v1/telemetry/batches
GET  /api/v1/integrity/:assignmentId/:studentId
GET  /api/v1/calendar?userId=
GET  /api/v1/channels/:channelId/messages
POST /api/v1/channels/:channelId/messages
```

### Browser extension (`apps/extension`)

- Manifest V3 with a module service worker and a content script on HTTP/HTTPS
  pages.
- Content script captures inter-keystroke timing, paste character counts,
  cursor distance, and assignment context. It skips password and hidden inputs
  and elements marked `data-sensitive`.
- Background service worker aggregates per-tab sessions in
  `chrome.storage.session`, computes the effort score, and records activation of
  known AI platform tabs against the most recently active writing session.
- Popup displays score, stats, active time, and a reset control.
- Icons (16, 48, 128 px) generated locally.

### Flutter app (`apps/app`)

- `pubspec.yaml`, `analysis_options.yaml`, and `lib/main.dart`.
- Five-tab shell: Dashboard, Courses, Calendar, Chat, Integrity.
- Static sample data for the UI; no API integration yet.
- Platform folders are not generated yet; `flutter create .` will add them.

### Rust core (`crates/telemetry-core`)

- `EventKind`, `TelemetryEvent`, `EffortMetrics`, and `IntegrityFlag`.
- `EffortMetrics::from_events`, `score`, and `integrity_flags`.
- Crate types `cdylib`, `staticlib`, and `rlib` for FFI and WASM.
- Three unit tests: organic typing, mass paste, and AI tab switch.
- Pinned stable toolchain with `rustfmt` and `clippy`.

## 4. Verification

Commands and results:

| Command | Result |
| --- | --- |
| `npm install` | 108 packages installed |
| `npm run typecheck` | Passed after fixing Fastify error-handler typing |
| `npm run build:api` | Passed; 20.97 KB ESM bundle |
| API smoke test | All endpoints responded as expected (details below) |
| `node --check` on extension scripts | Passed for background, content, and popup |
| Manifest JSON parse | Valid Manifest V3 document |
| Secret scan of staged files | No matches for common token/key patterns |

Smoke test details against the built server:

- `/health` returned `status: ok`.
- `/api/v1/courses` returned 1 course.
- `/api/v1/calendar?userId=u-student-1` returned 5 events.
- Telemetry batch with 2 events was accepted.
- Computed effort score was 45 with the `large_paste` flag.
- Integrity report resolved to submission `s-001`.
- Assignment roster returned 3 students.
- Course channels returned 2 entries.

Not verified:

- `flutter pub get`, `flutter analyze`, `flutter run`.
- `cargo test` and Rust compilation.
- End-to-end extension-to-API ingestion (the extension currently stores
  sessions locally and does not transmit to the API yet).

## 5. GitHub setup

The machine had a stored GitHub credential for `leokiki019-cmd`, but GitHub CLI
rejected it because the token lacks the `read:org` scope. The token does include
the `repo` scope, so the GitHub REST API was used instead of `gh auth login`.

Actions:

1. Created the private repository `leokiki019-cmd/edtech-ecosystem` through the
   GitHub REST API.
2. Added the `origin` remote over HTTPS.
3. Committed 38 files with a repository-local identity
   (`leokiki019-cmd` / GitHub noreply email) using `git -c`, without changing
   global git configuration.
4. Pushed `main` and set the upstream branch.
5. Verified through the GitHub API that the repository is private with `main` as
   the default branch.

No access keys, personal access tokens, or collaborator credentials were
generated or shared. Owner access is provided by the GitHub account itself.

## 6. Documentation added after the initial commit

- `README.md`: project overview, components, setup, API reference, scoring
  rules, verification summary, limitations, and access notes.
- `docs/IMPLEMENTATION_NOTES.md`: this chronological record.

These files were added after commit `41e1ea3` and may be committed separately.

## 7. Recommended next steps

1. Add authentication and role-based access control before exposing the API
   beyond local development.
2. Replace the in-memory store with a persistent database and migrations.
3. Verify telemetry signatures (Ed25519 or similar) server-side; the current API
   requires the fields but does not verify them.
4. Buffer telemetry and persist writing sessions to enable time-lapse replay.
5. Connect the extension to the API with consent controls and scoped host
   permissions.
6. Generate Flutter platform folders and integrate the API client.
7. Compile and integrate the Rust core through `flutter_rust_bridge` and a WASM
   target.
8. Implement Google Sheets/Excel sync, teacher nudges, and the AI assistant.
9. Add automated API route tests, extension scoring tests, and CI.
