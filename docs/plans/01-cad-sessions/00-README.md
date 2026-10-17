# 01 — CAD-triggered sessions

Master plan: [`../../PLAN.md`](../../PLAN.md) · Builds on: phase 1 scaffold (`agent/lib`, drift schema v1, `MockApiClient`)

## Goal
- The PC is never locked. The worker uses it freely; time is counted only against a chosen project.
- Opening a CAD app (AutoCAD, Revit, SketchUp) with no active session raises a small must-answer window: sign in, pick project and task. Answering starts the timer.
- A Timer Bar shows project, task, today's active time and remaining hours. The manager dashboard sees who is on which project (backend; out of this plan).
- Lunch break: 60 min a day, taken in up to 2 pieces, any time. Work day ends at 17:00; later work is tracked as overtime, separately.
- Project folder sync, change watcher, uploads, and an automatic end-of-day backup of changed files.
- End Work report, Summary, and recovery from crashes or shutdowns. Offline-safe throughout; no tracked time is ever lost.

## Decisions (already made; do not revisit)
| # | Decision |
| --- | --- |
| C1 | **No lock.** The fullscreen lock, `LockService` fullscreen mode and the login-time lock from phase 1 are removed from the startup path. The agent starts hidden to the tray area (skip taskbar, no window) and only shows a window for: the project prompt, Timer Bar, break/overtime prompts, upload dialog, End Work, Summary. Keyboard hook, watchdog and installer are out of scope (later plan). |
| C2 | **Launch trigger.** A `LaunchDetector` polls the process list every 3 s. If a process named `acad.exe`, `Revit.exe` or `SketchUp.exe` (case-insensitive) appears and no session is open and it is not on break, show the Project Prompt. Excel and K-SMART browser tabs are tracked as apps but never trigger the prompt. If the worker dismisses the prompt, ask again after 5 min while the CAD process is still running. |
| C3 | **Project prompt.** One window: if not signed in, Employee ID + PIN first (existing `AuthController`); then project cards and task choice (existing `ProjectSelectController`), then Start. Start → open session → sync folder → open it in Explorer → show Timer Bar. Block-mode projects at 100% cannot be started (existing `StartBlock`). |
| C4 | **Tracking.** Every 5 s sample idle seconds (`GetLastInputInfo` vs `GetTickCount`) and the foreground app (`GetForegroundWindow` → process image name + window title). Idle ≥ `idle_threshold_secs` (default 300) → status idle, no active time, idle seconds counted separately; input resumes tracking. Classify: `acad.exe`=AutoCAD, `Revit.exe`=Revit, `SketchUp.exe`=SketchUp, `EXCEL.EXE`=Excel, a browser whose title contains "K-SMART" (case-insensitive)=K-SMART, else `Other:<exe>`. A 5 s sample whose gap since the previous sample exceeds 15 s (sleep/hibernate) counts as idle for the gap, never active. |
| C5 | **Heartbeats.** Every 60 s write a row to `heartbeats` (client UUID, from, to, active_secs, idle_secs, apps_json) before any network call. The SyncWorker sends unsynced rows in batches of 50 and marks `synced_at` only after the server ack. UI shows server `my_used_seconds` + unsynced local active seconds. Server dedupes by client UUID. |
| C6 | **Hour limits.** Existing `HourUsage`/`canTrack`. At 80% show a toast once per session. At 100%: `overrun_mode=allow` keeps tracking and the bar shows red "Overrun"; `block` ends the session and shows "Ask your manager for more hours". Only normal-hours active time counts toward the allocation. |
| C7 | **Lunch break.** Allowance `break_allowance_secs` (config, default 3600). Up to `break_max_pieces` (default 2) pieces per day, started any time by the worker with a Break button on the Timer Bar. Starting a break closes the heartbeat slice, stops tracking and shows a Break window with a live "time left" counter. Ending a break (Resume) restarts tracking. Break time is never counted as work. When the allowance is used up the Break window shows "Break used up" and tracking auto-resumes on Resume only; if the worker does not resume within 5 min after allowance runs out, no work time is counted until they do. A break left open is closed at midnight local time. |
| C8 | **Work day end.** `workday_end` (config, default `17:00` local). At that time the active session is stopped (last heartbeat flushed) and a prompt asks "Continue as overtime?". Yes → new session with `kind=overtime` on the same project and task. No → End Work flow. Time after `workday_end` can only be tracked in an overtime session. If a session starts after `workday_end`, it is overtime from the start with a notice. |
| C9 | **Overtime accounting.** Overtime sessions send heartbeats like normal ones but are stored with `kind=overtime`, shown in Summary as "Overtime", and are excluded from `HourUsage` (they never reduce the project allocation and never trigger the 80%/100% rules). The local unsynced-seconds figure for a project counts only `kind=normal`. |
| C10 | **Contract frozen (amended).** No new request fields. The session `kind` (normal/overtime) is stored locally only; `sessions/start` is sent unchanged. Breaks, overtime start and work-day end go out as extra `type` values on the existing `POST /agent/events` (`break_start`, `break_end`, `overtime_start`, `workday_end`, data `{piece,secs,project_id}`). The backend can later add a `kind` field without any agent change beyond one line in `SyncWorker`. |
| C11 | **Sync worker.** One `SyncWorker` drains, in order: pending session starts → heartbeats → session stops → outbox rows (events, task complete, daily report, upload confirms). Exponential backoff 5 s → 5 min cap with jitter, resets on success. Runs every 30 s and on connectivity change. Non-retryable errors (4xx except 408/429) mark the row `failed` with `last_error` and are logged, never retried silently forever. |
| C12 | **Files.** Projects root `D:\Projects` with fallback `%USERPROFILE%\Projects`; folder `{code}_{sanitized name}` with subfolders 01_Survey, 02_Drawings, 03_Structural, 04_KSMART, 05_Exports, 06_Client-Docs (or `folder_template` from the project). Sync downloads files whose local version is older or missing to a temp file then renames atomically; local versions live in `file_versions`. `mock://` URLs are served by generating dummy content (`MockApiClient.dummyContent`). Files checked out by another worker download read-only and show "In use by X". |
| C13 | **Change watcher.** `Directory.watch(recursive)` on the project folder records created/modified files per day, ignoring `*.bak`, `*.sv$`, `*.dwl`, `*.dwl2`, `~$*`, `*.tmp`. A file counts as changed when its size or mtime differs from the synced baseline. The list survives restarts (rebuilt by scanning against `file_versions` on session start). |
| C14 | **Uploads and daily backup.** Upload = request URL (`files/upload-url`) → PUT (single, or multipart for > 50 MB with per-part retry) → `files/confirm` → new version. Rows live in `uploads` and are retried. End Work pre-ticks every changed file of the day (worker can untick) and queues them as the backup; individual files over 200 MB are skipped with a visible warning. Upload dialog can also be opened any time from the Timer Bar, with a note and "Mark task complete". |
| C15 | **End Work.** Form: what I did today (required), each task with status (In progress/Completed/Blocked) + note, notes for manager, changed files (pre-ticked). Submit → stop session → queue uploads → queue `daily-report` → Summary. Summary shows today's active, idle, break and overtime time, hours per app, per-project totals and remaining hours (from `my-hours/today`, falling back to local data offline). "Done" closes the Timer Bar and returns to hidden-in-tray. |
| C16 | **Recovery.** On start, if a session is `open` without clean stop: close it at its last heartbeat time, mark `unclean`, queue a stop with `unclean=true` and an `unclean_session` event, and require the Pending Report before the next session can start. A day with sessions but no submitted report (also after a shutdown) also requires the Pending Report. |
| C17 | **Config keys added.** `break_allowance_secs` (3600), `break_max_pieces` (2), `workday_end` ("17:00"), `launch_poll_secs` (3), `prompt_retry_mins` (5), `max_upload_file_bytes` (209715200). All in `config.json`; defaults in `AppConfig.defaults`. |
| C18 | **Testability.** Win32 access sits behind `IdleMonitor`, `ActiveAppMonitor`, `ProcessLister` interfaces with fakes; time comes from `clockProvider`. Unit tests required: idle/active accounting, heartbeat batching/dedupe, hour limits incl. overtime exclusion, break allowance maths, workday-end rollover, unclean recovery, file ignore rules. |

## Status
- [x] 01 — Schema v2 and pure domain logic
- [x] 02 — Win32 monitors and CAD launch detector
- [x] 03 — SessionManager, break/overtime engine, SyncWorker, mock API additions
- [x] 04 — Project prompt, Timer Bar and break/overtime windows (no lock)
- [x] 05 — Folder sync, change watcher, uploader, upload dialog
- [x] 06 — End Work, Summary, Pending Report, recovery
- [ ] 07 — Acceptance (automated checks pass; manual Windows checks pending, see README)

> Slices 01–06 were built directly in one session rather than through `/run-plan`, so there are no slice files. Automated coverage is under `agent/test/`.

## Dependencies and parallel tracks
| Slice | Prerequisites | Parallel with | Model | Files touched |
| --- | --- | --- | --- | --- |
| 01 | none | 02, 05 (disjoint) | Sonnet | `agent/lib/data/db/**`, `agent/lib/domain/**`, `agent/lib/config/**`, `agent/test/domain/**`, `agent/test/data/db_test.dart` |
| 02 | none | 01, 05 | Sonnet | `agent/lib/services/win32/**`, `agent/lib/services/launch_detector.dart`, `agent/test/services/**` |
| 03 | 01, 02 | 05 | Opus | `agent/lib/services/session_manager.dart`, `agent/lib/services/sync_worker.dart`, `agent/lib/data/api/**`, `agent/test/services/session_*`, `agent/test/data/mock_*` |
| 04 | 03 | 05 | Sonnet | `agent/lib/features/prompt/**`, `agent/lib/features/timer_bar/**`, `agent/lib/features/break/**`, `agent/lib/app/router.dart`, `agent/lib/app/bootstrap.dart`, `agent/lib/services/lock_service.dart`, `agent/test/features/prompt_*` |
| 05 | 01 | 02, 03, 04 | Sonnet | `agent/lib/services/folder_manager.dart`, `file_watcher.dart`, `uploader.dart`, `agent/lib/features/upload/**`, `agent/pubspec.yaml` (file_picker only), `agent/test/services/file_*` |
| 06 | 03, 04, 05 | none | Sonnet | `agent/lib/features/end_day/**`, `summary/**`, `pending_report/**`, `agent/lib/services/recovery_service.dart`, `agent/test/services/recovery_*` |
| 07 | all | none | Opus + Haiku | `docs/**`, `README.md`, `.github/workflows/**` |

**Rules for every slice:** work only in the Files touched globs; regenerate drift code with `cd agent && dart run build_runner build` when tables change; `flutter analyze` and `flutter test` must pass; never add packages beyond the approved list (uuid, path, intl, file_picker, mocktail); append `## Result` to your slice file when done.

## Acceptance checklist
- [ ] Opening AutoCAD with no session shows the project prompt; signing in and choosing a project starts the timer and opens the project folder.
- [ ] The PC is never locked; no fullscreen window appears at startup.
- [ ] Idle time over the threshold is not counted as active; heartbeats are written to SQLite before any network call.
- [ ] With the network off, work for an hour, reconnect: all time reaches the mock server exactly once.
- [ ] Per-project used/allocated hours update live; 80% toast once; block-mode stops at 100%; allow-mode shows Overrun.
- [ ] Break can be started and ended twice; total never exceeds 60 min counted; break time is not work time.
- [ ] At 17:00 the session stops and "Continue as overtime?" appears; overtime hours show separately and do not reduce the allocation.
- [ ] End Work pre-ticks changed files, uploads them as new versions, submits the report and shows the Summary.
- [ ] Killing the agent mid-session then restarting closes the session at the last heartbeat and requires the Pending Report.
- [ ] Windows build from GitHub Actions runs and passes `flutter analyze` and `flutter test`.
