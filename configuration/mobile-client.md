# Mobile client configuration

Repository: `sharingbridge-mobile-app` (Flutter).

## API endpoints

| Use | URL |
|-----|-----|
| **All donor APIs** (setup, suggest-vendors, instruction-pack, presets) | **integration-service** only |
| **Mint JWT** | **user-service** (`POST /v1/auth/token`) — not wired in app UI today; use curl/PowerShell or script before `flutter run` |

Mobile must **not** call ai-orchestration directly.

## `dart-define` (hosted Render)

```powershell
$USER_URL = "https://sharingbridge-user-service.onrender.com"
$INT_URL  = "https://sharingbridge-integration-service.onrender.com"

$token = (Invoke-RestMethod -Method POST -Uri "$USER_URL/v1/auth/token" `
  -ContentType "application/json" -Body '{"user_id":"demo-user"}').token

cd D:\kannan\sharingbridge\sharingbridge-mobile-app
flutter run `
  --dart-define=API_BASE_URL=$INT_URL `
  --dart-define=USER_ID=demo-user `
  --dart-define=AUTH_TOKEN=$token
```

| Define | Value |
|--------|--------|
| `API_BASE_URL` | integration-service `https://…onrender.com` (no trailing `/`) |
| `USER_ID` | donor id passed when minting token |
| `AUTH_TOKEN` | JWT from user-service |

Re-mint token when expired (~1 hour). Use public `https://` on physical devices and emulators (not `localhost` / `10.0.2.2` for hosted backend).

## `dart-define` (local three-service stack)

| Define | Typical value |
|--------|----------------|
| `API_BASE_URL` | `http://localhost:8080` (integration) |
| `USER_ID` | `demo-user` |
| `AUTH_TOKEN` | from `POST http://localhost:8081/v1/auth/token` |

Android emulator to host machine integration: `http://10.0.2.2:8080`.

## Main flows

| Screen | Backend |
|--------|---------|
| Donor setup | integration — suggest-vendors, save/load presets |
| Offer food help | integration — instruction-pack; see [field-handoff.md](./field-handoff.md) |

Offline: presets may cache in `shared_preferences` when integration is unreachable.

See [MANUAL_TESTING_GUIDE.md](../testing/MANUAL_TESTING_GUIDE.md) for full test steps.
