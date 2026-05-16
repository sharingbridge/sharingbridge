# Mobile client configuration

Repository: `sharingbridge-mobile-app` (Flutter).

## API endpoints

| Use | URL |
|-----|-----|
| **All donor APIs** (setup, suggest-vendors, instruction-pack, presets, order-intents) | **integration-service** only |
| **Mint JWT** | **user-service** (`POST /v1/auth/token`) — run before `flutter run` (not in app UI yet) |

Mobile must **not** call ai-orchestration directly.

## `dart-define` (hosted Render)

Run in **this order** in the same PowerShell window:

```powershell
cd D:\kannan\sharingbridge\sharingbridge-mobile-app

$token = (Invoke-RestMethod -Method POST -Uri "https://sharingbridge-user-service.onrender.com/v1/auth/token" `
  -ContentType "application/json" -Body '{"user_id":"demo-user"}').token

flutter run `
  --dart-define=API_BASE_URL=https://sharingbridge-integration-service.onrender.com `
  --dart-define=USER_ID=demo-user `
  --dart-define=AUTH_TOKEN=$token
```

| Define | Value |
|--------|--------|
| `API_BASE_URL` | integration-service `https://…onrender.com` (no trailing `/`) |
| `USER_ID` | donor id used when minting the token |
| `AUTH_TOKEN` | JWT string from user-service — **not** the literal text `<token …>` |

Use public `https://` on devices and emulators. Re-mint the JWT after ~1 hour.

**Common mistakes**

- Running `flutter run` before `cd` to the mobile repo → `No pubspec.yaml file found`.
- Pasting placeholder `<token from user-service …>` → PowerShell syntax error (`<` is redirection).
- Running `flutter` before `$token = …` → empty `AUTH_TOKEN`.

## `dart-define` (local three-service stack)

```powershell
cd D:\kannan\sharingbridge\sharingbridge-mobile-app
$token = (Invoke-RestMethod -Method POST -Uri "http://localhost:8081/v1/auth/token" `
  -ContentType "application/json" -Body '{"user_id":"demo-user"}').token
flutter run `
  --dart-define=API_BASE_URL=http://localhost:8080 `
  --dart-define=USER_ID=demo-user `
  --dart-define=AUTH_TOKEN=$token
```

Android emulator: `http://10.0.2.2:8080` for integration.

## Main flows

| Screen | Backend |
|--------|---------|
| Donor setup | integration — suggest-vendors, save/load presets |
| Offer food help | instruction-pack + `POST …/order-intents` on copy — see [field-handoff.md](./field-handoff.md) |

Offline: presets may cache in `shared_preferences` when integration is unreachable.

See [MANUAL_TESTING_GUIDE.md](../testing/MANUAL_TESTING_GUIDE.md) for full test steps.
