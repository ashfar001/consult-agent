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

## Configuration

The config file is `%ProgramData%\ConsultAgent\config.json`. A sample is written on first run if the folder is writable. Keys:

`api_base_url`, `mock_api`, `company_name`, `idle_threshold_secs` (300), `poll_interval_secs` (5), `heartbeat_interval_secs` (60), `projects_root` (`D:\Projects`), `fallback_projects_root`, `data_dir`, `log_dir`, `mock_failure_rate`, `mock_latency_ms`.

The environment variable `MOCK_API=true` or `--dart-define=MOCK_API=true` forces mock mode.

Data is stored in `%ProgramData%\ConsultAgent\data\agent.sqlite` and logs in `%ProgramData%\ConsultAgent\logs`. Both fall back to `%LOCALAPPDATA%\ConsultAgent` when ProgramData isn't writable.

Deployment steps (standard user accounts, Group Policy, scheduled tasks) are added in phase 6.
