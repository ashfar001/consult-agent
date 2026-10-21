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

Before a worker signs in, create their employee ID and PIN in the SQUAREM console, assign the worker to a project and task, then approve the new PC on **Devices** after its first connection. On the worker PC, sign in and select the task to start tracking. Offline time is saved locally and syncs when the connection returns.

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
