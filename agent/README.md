# SQUAREM ConsultAgent (Windows)

This is the worker desktop agent. It signs in with an employee ID and PIN, lets the worker choose an assigned project and task, records work time locally, and syncs with the SQUAREM backend. File uploads, daily reports, breaks, overtime, and the protected admin exit use the existing production services.

## Connect to the live console

The default backend is `https://www.app.squarem.in` and `mock_api` defaults to `false`. The health endpoint is `https://www.app.squarem.in/api/health`. The app uses the same origin for `/agent/*` requests. No API key belongs in the source or config file: employee sign-in obtains an auth token and stores it in the OS secure store.

On each Windows PC, edit `%ProgramData%\ConsultAgent\config.json` if you need to change the default. A minimal production config is:

```json
{
  "api_base_url": "https://www.app.squarem.in",
  "mock_api": false,
  "company_name": "SQUAREM"
}
```

The app creates a full sample config at first launch. Existing generated configs containing the exact old placeholder `https://api.example.com` are automatically updated. Custom URLs are preserved. Restart the app after changing a config.

## Timer dock and updates

During work, the agent shows a 6 × 104 px strip on the right edge of the current display. Hover it to reveal the 400 × 104 px controls; it closes three seconds after the pointer and keyboard focus both leave. The Move left / Move right button saves the edge for this Windows user. The timer continues while the dock is collapsed. [Open the interactive design preview](design/timer-dock-preview.html) (window behavior and timer values are demo-only).

From v1.0.7 onward, the sign-in screen checks the public GitHub release for a newer Windows ZIP. Use **Update now** before starting work. The app verifies the release SHA-256 digest, stages it beside the current installation, restarts in the same location, and restores the prior version if startup fails. Install v1.0.7 manually once to enable this feature on older builds. A protected or read-only installation needs a manual update by an administrator. Keep the whole release ZIP together in its own folder; do not run just the EXE from the ZIP.

Before a worker signs in, create their employee ID and PIN in the SQUAREM console, assign the worker to a project and task, then approve the new PC on **Devices** after its first connection. On the worker PC, sign in and select the task to start tracking. Offline time is saved locally and syncs when the connection returns.

Opening the agent shows sign-in and project selection. After **Not now**, it stays hidden until a new CAD app starts or **Ctrl+Shift+F11** is pressed. Leaving a CAD app open does not repeatedly reopen the prompt. Starting work shows the timer bar with the clock, Break, Upload and End work. Select **Hide** or move the pointer away for about three seconds to collapse the bar to a colored strip at the top of the display's work area. Hover over the strip to restore the controls. **Ctrl+Shift+F11** also toggles the bar during a session. **Ctrl+Shift+F12** opens the protected admin exit. Only one agent process can run per Windows login.

After five minutes without keyboard or mouse input (`idle_threshold_secs: 300`, checked every five seconds), the agent records time as idle instead of active. Idle alone does not end the session; normal work stops at the configured `workday_end` (default 17:00), when overtime can be offered.

Launch `ConsultAgent.exe` from the worker's Windows account. If the configured project root is unwritable, project sync uses the configured user fallback, which defaults to `%USERPROFILE%\Projects`. If Windows prompts for elevation, check the executable and shortcut compatibility settings for **Run this program as an administrator**. If the app exits without a prompt, check for an already running agent and verify that the worker can read the installed app and config, and write to the configured data and log locations. The default log is `%ProgramData%\ConsultAgent\logs\agent.log` with a fallback under `%LOCALAPPDATA%\ConsultAgent\logs`.

## Build and check

Use Flutter 3.41.4 or a compatible newer SDK. On a Windows machine with Visual Studio Desktop development with C++ installed:

```powershell
flutter pub get
flutter analyze
flutter test
flutter build windows
```

The Mac development environment can run analysis and tests, but a Windows executable must be built and smoke tested on Windows. Inspect the live sign-in, approval, session, upload and report flow on a real worker PC before distributing it.

The theme and clearer UI copy were adapted from the supplied `SQUAREM-ConsultAgent-Flutter.zip` design handoff. That archive itself is a demo and does not provide production authentication, tracking, or uploads; this source retains the real implementations.
