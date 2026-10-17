# ConsultAgent: Workstation Agent

Windows desktop agent for office PCs. It locks the PC until a worker signs in and picks an assigned project. It then tracks active time and apps per project and task, syncs project files, and collects the end-of-day report. Everything works offline, queued in SQLite.

| Folder       | What                                              |
|--------------|---------------------------------------------------|
| `agent/`     | Flutter Windows app (`ConsultAgent.exe`)          |
| `watchdog/`  | Dart console watchdog (phase 5)                   |
| `installer/` | Inno Setup script (phase 6)                       |

## Development

```sh
cd agent
flutter pub get
dart run build_runner build          # drift code generation
flutter analyze && flutter test      # runs on any OS
flutter run -d windows --dart-define=MOCK_API=true   # Windows only
```

Mock mode login: **EMP001 / 1234**. The mock simulates latency and roughly 15% network failures. You can tune these in `config.json` with `mock_latency_ms` and `mock_failure_rate`.

## How it works (plan 01)

The PC is never locked. The agent runs hidden and shows a window only when needed:

1. A CAD app starts (`acad.exe`, `Revit.exe`, `SketchUp.exe`) with no session running → a **project prompt** asks for sign-in, project and task. Choosing Start begins the timer, syncs the project folder and opens it. Excel and K-SMART in a browser are tracked but never trigger the prompt. *Not now* hides it; it returns after 5 minutes while CAD is still open.
2. A small always-on-top **timer bar** shows project, task, today's active time and hours left. Buttons: lunch break, upload, end work.
3. **Lunch break:** 60 minutes a day, in up to 2 pieces, any time. The timer pauses and break time is never counted as work.
4. At **17:00** the session stops and asks whether to continue as **overtime**. Overtime is recorded separately and never uses up project hours.
5. **End work** collects the day's report (what you did, task statuses, notes) and uploads every changed file as a new version (the daily backup). A summary follows.
6. If the agent was killed or the PC shut down mid-session, the session is closed at its last heartbeat and the report must be filed before the next session.

All time is written to SQLite first and synced when the network allows.

## Administrator exit

For urgent situations a super-admin can close the agent: press **Ctrl+Shift+F12** anywhere in Windows (the agent can be hidden), enter the admin password, and the agent saves any running session, tells the server (`admin_exit` event; wrong tries send `admin_exit_failed`) and quits. After 3 wrong tries it locks for 30 seconds. Closing the window or Alt+F4 does nothing.

The password is never stored. Generate the two config values on any machine with Dart:

```bash
cd agent && dart run tool/hash_admin_password.dart
```

Paste the printed `admin_exit_salt` and `admin_exit_hash` lines into `%ProgramData%\ConsultAgent\config.json`. With no hash set, real builds cannot be exited from the UI.

## Demo build

The build from CI runs in mock mode (`MOCK_API=true`): sign in with **EMP001 / 1234**. In demo builds the prompt also appears when **Notepad** or **Paint** starts, and once at launch, so it can be tried on a PC without CAD. Exit with **Ctrl+Shift+F12** and the demo admin password **admin1234** (accepted only in mock builds with no hash configured).

## Contract note

The API contract is unchanged. Breaks, overtime and the work-day end are sent as extra `type` values on `POST /agent/events`; the overtime flag itself is kept locally.

## Configuration

The config file is `%ProgramData%\ConsultAgent\config.json`. A sample is written on first run if the folder is writable. Keys:

`api_base_url`, `mock_api`, `company_name`, `idle_threshold_secs` (300), `poll_interval_secs` (5), `heartbeat_interval_secs` (60), `projects_root` (`D:\Projects`), `fallback_projects_root`, `data_dir`, `log_dir`, `mock_failure_rate`, `mock_latency_ms`, `break_allowance_secs` (3600), `break_max_pieces` (2), `workday_end` (`17:00`), `launch_poll_secs` (3), `prompt_retry_mins` (5), `max_upload_file_bytes` (200 MB).

The environment variable `MOCK_API=true` or `--dart-define=MOCK_API=true` forces mock mode.

Data is stored in `%ProgramData%\ConsultAgent\data\agent.sqlite` and logs in `%ProgramData%\ConsultAgent\logs`. Both fall back to `%LOCALAPPDATA%\ConsultAgent` when ProgramData isn't writable.

Deployment steps (standard user accounts, Group Policy, scheduled tasks) are added in phase 6.
