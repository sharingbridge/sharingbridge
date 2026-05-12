# Manual Testing Guide — Completed Modules

This guide walks through how to verify the donor-setup modules that
have shipped across `sharebridge-integration-service` and
`sharebridge-mobile-app`. It pairs **automated test suites** with
**manual API smoke tests** and an **end-to-end** flow on the mobile app.

All commands assume **PowerShell on Windows**. Translate to bash as
needed.

## Modules in scope

| # | Module | Where it lives |
|---|--------|----------------|
| 1 | Donor setup `suggest-vendors` (mock top-5) | `sharebridge-integration-service/src/server.js`, `src/suggestVendors.js` |
| 2 | Preferences save/fetch HTTP API | `sharebridge-integration-service/src/server.js`, `src/preferencesStore.js` |
| 3 | Preferences repository boundary toward user-service | `sharebridge-integration-service/src/preferencesRepository.js` |
| 4 | Signed-token auth context (JWT Bearer) | `sharebridge-integration-service/src/authContext.js`, `src/tokenService.js` |
| 5 | Mobile donor setup UI + repository | `sharebridge-mobile-app/lib/features/donor_setup/**` |
| 6 | Mobile HTTP client (timeout, retry, typed errors, auth headers) | `sharebridge-mobile-app/lib/features/donor_setup/data/http_donor_setup_api_client.dart` |
| 7 | Mobile auth context | `sharebridge-mobile-app/lib/features/donor_setup/data/auth_context.dart` |
| 8 | Mobile cache fallback (`shared_preferences`) | `sharebridge-mobile-app/lib/features/donor_setup/presentation/pages/donor_setup_page.dart` |

## Prerequisites

- Node.js 20+ on `PATH`.
- Flutter 3.16+ on `PATH` (and a target device — Windows desktop, web,
  or an Android emulator at minimum).
- Both repos cloned alongside this one:
  - `D:\kannan\sharebridge_repos\sharebridge-integration-service`
  - `D:\kannan\sharebridge_repos\sharebridge-mobile-app`
- User service cloned and runnable for token minting:
  - `D:\kannan\sharebridge_repos\sharebridge-user-service`
- Port `8080` free locally.
- Port `8081` free locally.

### Auth signing secret (`AUTH_TOKEN_SECRET`)

This guide describes the **donor-setup MVP** path: symmetric HS256 tokens and a shared `AUTH_TOKEN_SECRET` between user-service and integration-service. Production is expected to use **managed secrets**, **rotation**, and later **stronger patterns** (e.g. asymmetric signing)—see `development/AGENT_HANDOFF.md` follow-ups.

Tokens are signed and verified with that **symmetric** secret (`AUTH_TOKEN_SECRET`).

- **You do not have to set it for basic local smoke tests.** If the variable is unset, both `sharebridge-user-service` and `sharebridge-integration-service` use the same **built-in dev default** from each repo’s `src/tokenService.js` (`sharebridge-dev-secret-change-me`). Tokens minted on user-service `:8081` will verify on integration-service `:8080` as long as you did not change the secret on one side only.

- **Set it explicitly** when you want to match staging/prod habits or avoid relying on the default string. The value must be **identical** on both servers before each `npm start`:

  ```powershell
  # In the user-service terminal, before `npm start`:
  $env:AUTH_TOKEN_SECRET = "your-strong-local-secret"

  # In the integration-service terminal, before `npm start`:
  $env:AUTH_TOKEN_SECRET = "your-strong-local-secret"
  ```

- If you override **`AUTH_TOKEN_ISSUER`** or **`AUTH_TOKEN_AUDIENCE`** in either service, override them **to the same values** on both; otherwise verification will fail.

## 1. Automated test suites

### 1a. Integration service (Node.js, currently 32 tests)

```powershell
cd D:\kannan\sharebridge_repos\sharebridge-integration-service
npm install     # first time only
npm test
```

Coverage at a glance:

| Test file | What it asserts |
|-----------|-----------------|
| `test/suggestVendors.test.js` | request validators and mock response shape |
| `test/preferencesRepository.test.js` | local + user-service repository behavior, auth-header forwarding, typed upstream error mapping |
| `test/preferencesRoundtrip.test.js` | full HTTP save→fetch roundtrip, dedupe by `(restaurant_name, order_url)`, per-user isolation, validation rejection |
| `test/authContext.test.js` | signed bearer parsing/verification + `user_id` reconciliation |
| `test/authContextRoundtrip.test.js` | signed-token flow, mismatch and missing-token guards (`403`/`401`) |
| `test/userServicePreferencesRoundtrip.test.js` | integration-service → user-service backend path roundtrip + upstream 403 surfacing |
| `test/backfill-presets.test.js` | normalizing `PreferencesStore` rows for user-service backfill |

Each roundtrip test boots a real `http.Server` on port 0 against a
temp-dir `PreferencesStore`, so the HTTP wiring under test is the same
code that runs in `npm start`.

Expected output footer:

```
# tests 32
# pass 32
# fail 0
```

### 1b. Mobile app (Flutter, currently 19 tests)

```powershell
cd D:\kannan\sharebridge_repos\sharebridge-mobile-app
flutter pub get   # first time only
flutter test
```

Coverage at a glance:

| Test file | What it asserts |
|-----------|-----------------|
| `test/features/donor_setup/application/suggest_vendors_usecase_test.dart` | top-5 trim and missing-permission guard |
| `test/features/donor_setup/application/confirm_presets_usecase_test.dart` | save delegation and empty-list guard |
| `test/features/donor_setup/data/suggest_vendors_response_dto_test.dart` | response DTO mapping and malformed payload handling |
| `test/features/donor_setup/data/http_donor_setup_api_client_test.dart` | retry-then-success, persistent 5xx, 4xx mapping, malformed JSON, no-retry on save 5xx, auth headers on the wire |
| `test/features/donor_setup/presentation/donor_setup_page_test.dart` | search renders suggestions; confirm saves, reloads list from (fake) server, success status; full menu line + restaurant title; cache clear |
| `test/features/donor_setup/presentation/donor_presets_page_test.dart` | saved-presets screen lists server presets; copy/open order URL affordances |

Expected last line: `All tests passed!`.

### 1c. User service (Node.js, currently 35 tests)

```powershell
cd D:\kannan\sharebridge_repos\sharebridge-user-service
npm install       # first time only
npm test
```

Coverage at a glance:

| Test file | What it asserts |
|-----------|-----------------|
| `test/userServiceRoundtrip.test.js` | mint token + donor-presets PUT/GET roundtrip (dedupe), 401/403 auth, `/health`, 404, invalid JSON bodies, presets array/type validation, URL-encoded path `user_id` |
| `test/tokenService.test.js` | JWT mint/verify, secret/expiry/claims/tamper cases, env-driven defaults |
| `test/authContext.test.js` | bearer extraction and authenticated `user_id` resolution |
| `test/userStore.test.js` | file-backed init/read, `getOrCreateUser`, preset list/replace dedupe and persistence |

Expected output footer:

```
# tests 35
# pass 35
# fail 0
```

## 2. Manual API smoke tests

Start user-service in one PowerShell window:

```powershell
cd D:\kannan\sharebridge_repos\sharebridge-user-service
npm install   # first time only
npm start
# User service listening on 8081
```

Start integration-service in a second PowerShell window:

```powershell
cd D:\kannan\sharebridge_repos\sharebridge-integration-service
npm start
# Integration service listening on 8080
```

In a third window, drive the API.

First, mint a signed token from user-service (required for all preferences endpoints):

```powershell
Invoke-RestMethod -Method Post -Uri http://localhost:8081/v1/auth/token `
  -ContentType application/json `
  -Body (@{ user_id = "alice" } | ConvertTo-Json)
```

Save the returned `token`:

```powershell
$token = (Invoke-RestMethod -Method Post -Uri http://localhost:8081/v1/auth/token `
  -ContentType application/json `
  -Body (@{ user_id = "alice" } | ConvertTo-Json)).token
$headers = @{ Authorization = "Bearer $token" }
```

### 2a. Health check (no auth)

```powershell
Invoke-RestMethod http://localhost:8080/health
```

Expect `ok=True`, `service=integration-service`.

### 2b. Suggest vendors (no auth on this endpoint)

```powershell
$body = @{
  query_text = "zomato a2b mini meals"
  location_precision = "manual_area"
  manual_area = "Chennai"
  client_platform = "powershell-test"
} | ConvertTo-Json

Invoke-RestMethod -Method Post -Uri http://localhost:8080/v1/donor-setup/suggest-vendors `
  -ContentType application/json -Body $body
```

Expect a `suggestions` array (≤ 5 entries) plus `generated_at`.

### 2c. Save presets via signed Bearer token (auth required)

```powershell
$body = @{
  presets = @(
    @{
      restaurant_name = "A2B"
      order_url = "https://www.zomato.com/chennai/a2b/order"
      menu_items = @("Mini Meals")
      app_name = "Zomato"
    }
  )
} | ConvertTo-Json -Depth 5

Invoke-RestMethod -Method Post -Uri http://localhost:8080/v1/donor-setup/preferences `
  -Headers $headers -ContentType application/json -Body $body
```

Expect `user_id=alice`, `saved_count=1`, `total_count=1`, plus a
generated `preset_ids[0]` and `saved_at`.

### 2d. Fetch presets back

```powershell
Invoke-RestMethod -Headers $headers http://localhost:8080/v1/donor-setup/preferences
```

Expect `user_id=alice` and the preset you just saved.

### 2e. Verify dedupe — re-save same `(restaurant_name, order_url)`

```powershell
$body2 = @{
  presets = @(
    @{
      restaurant_name = "A2B"
      order_url = "https://www.zomato.com/chennai/a2b/order"
      menu_items = @("Mini Meals", "Curd Rice")
      app_name = "Zomato"
    }
  )
} | ConvertTo-Json -Depth 5

Invoke-RestMethod -Method Post -Uri http://localhost:8080/v1/donor-setup/preferences `
  -Headers $headers -ContentType application/json -Body $body2

Invoke-RestMethod -Headers $headers http://localhost:8080/v1/donor-setup/preferences
```

Expect `total_count=1` on the save response, and the GET should show
`menu_items` updated to the new list — latest wins, no duplicate row.

### 2f. Verify auth-context guards

**Mismatch** (header says `alice`, body says `bob`):

```powershell
$body3 = @{
  user_id = "bob"
  presets = @(
    @{ restaurant_name = "X"; order_url = "https://x"; menu_items = @("Y"); app_name = "Z" }
  )
} | ConvertTo-Json -Depth 5

try {
  Invoke-RestMethod -Method Post -Uri http://localhost:8080/v1/donor-setup/preferences `
    -Headers $headers -ContentType application/json -Body $body3
} catch {
  $_.Exception.Response.StatusCode  # Forbidden (403)
  $_.ErrorDetails.Message            # {"code":"user_id_mismatch", ...}
}
```

**Missing auth context entirely**:

```powershell
try {
  Invoke-RestMethod http://localhost:8080/v1/donor-setup/preferences
} catch {
  $_.Exception.Response.StatusCode  # Unauthorized (401)
  $_.ErrorDetails.Message            # {"code":"missing_auth_context", ...}
}
```

### 2g. Verify per-user isolation

```powershell
$bobToken = (Invoke-RestMethod -Method Post -Uri http://localhost:8081/v1/auth/token `
  -ContentType application/json `
  -Body (@{ user_id = "bob" } | ConvertTo-Json)).token
$bobHeaders = @{ Authorization = "Bearer $bobToken" }
$bobBody = @{
  presets = @(
    @{
      restaurant_name = "Saravana Bhavan"
      order_url = "https://www.swiggy.com/sb"
      menu_items = @("Idli")
      app_name = "Swiggy"
    }
  )
} | ConvertTo-Json -Depth 5

Invoke-RestMethod -Method Post -Uri http://localhost:8080/v1/donor-setup/preferences `
  -Headers $bobHeaders -ContentType application/json -Body $bobBody

(Invoke-RestMethod -Headers $headers    http://localhost:8080/v1/donor-setup/preferences).presets.Count  # alice's count
(Invoke-RestMethod -Headers $bobHeaders http://localhost:8080/v1/donor-setup/preferences).presets.Count  # bob's count
```

Expect each user to only see their own presets.

### 2h. (Optional) Verify user-service backend switch

```powershell
$env:PREFERENCES_BACKEND = "user_service"
$env:USER_SERVICE_BASE_URL = "http://localhost:8081"
npm start
```

Then unset and restart (to return to local backend):

```powershell
Remove-Item Env:PREFERENCES_BACKEND
Remove-Item Env:USER_SERVICE_BASE_URL
npm start
```

## 3. End-to-end with the mobile app

Keep integration-service on `localhost:8080` and user-service on `localhost:8081`, then mint a token and run Flutter:

```powershell
$mobileToken = (Invoke-RestMethod -Method Post -Uri http://localhost:8081/v1/auth/token `
  -ContentType application/json `
  -Body (@{ user_id = "alice" } | ConvertTo-Json)).token
```

### 3a. Windows desktop

```powershell
cd D:\kannan\sharebridge_repos\sharebridge-mobile-app
flutter run -d windows --dart-define=API_BASE_URL=http://localhost:8080 --dart-define=USER_ID=alice --dart-define=AUTH_TOKEN=$mobileToken
```

### 3b. Android emulator

```powershell
cd D:\kannan\sharebridge_repos\sharebridge-mobile-app
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8080 --dart-define=USER_ID=alice --dart-define=AUTH_TOKEN=$mobileToken
```

The mobile client now sends only `Authorization: Bearer <AUTH_TOKEN>`.

### 3c. Walkthrough on the app

1. App opens to **Donor Setup**. Because step 2c saved presets for
   `alice`, the page shows status "Loaded saved presets from server."
2. Type something like `zomato a2b mini meals` → tap **Suggest Vendors**.
   The mock backend returns the **same fixed** suggestions every time (it does **not** personalize by `query_text`); each row shows the **full** comma-separated **menu items** under the restaurant name. Auth-protected endpoints carry `Authorization: Bearer <signed token>`.
3. Check one or more suggestions → tap **Confirm and Save Presets**.
   Status flips to "Presets saved successfully." The list on **Donor Setup** immediately reloads from the server so it shows **only** the presets you saved (not the full mock search result with old checkboxes). Re-running the GET from step 2d matches the same set (with dedupe applied server-side).
4. **Cache fallback path**: stop the backend (Ctrl+C in step 2's
   window), kill and relaunch the app — the page falls back to
   "Using cached presets (offline fallback)." once the remote load
   fails.
5. **Retry / typed errors**: stop the backend mid-request — the typed
   exception path renders messages like "Server is temporarily
   unavailable (HTTP 500)." or "Network unavailable. Check your
   connection and retry." instead of stack traces.
6. **Saved presets / order links**: tap the app-bar icon with tooltip **Saved presets** → **Saved presets** loads from the server (`GET /v1/donor-setup/preferences`). Each row shows the **order URL** (selectable text), **Copy link**, and **Open link** (opens the vendor URL in the system browser). Pull-to-refresh reloads the list.

### 3d. Why Suggest Vendors and Saved presets can both look “static”

- **Suggest Vendors** always hits the **same mock** (`POST /v1/donor-setup/suggest-vendors`): three fixed venues. That is expected until real search/AI replaces the mock.
- **Saved presets** (screen + Donor Setup list after save) reflects **whatever the integration-service returns from `GET …/preferences`** — i.e. **persisted** data, not the mock suggestion list.
- **Clear cache / Sign out** on Donor Setup only clears the **phone’s offline cache** (`shared_preferences`). It does **not** delete presets on the server, so **Saved presets** will still show server rows after a refresh.

### 3e. Clear server-side saved presets (empty the listing)

Pick one approach:

1. **Wipe the local integration file store** (typical dev: `PREFERENCES_BACKEND=local`): stop `npm start` on integration-service, delete the data file or folder, restart.

   ```powershell
   cd D:\kannan\sharebridge_repos\sharebridge-integration-service
   Remove-Item -Recurse -Force data -ErrorAction SilentlyContinue
   npm start
   ```

   To clear **only one user**, edit `data\preferences.json` and remove that user’s array under `byUser` (or set it to `[]`), then restart the server.

2. **User-service backend** (`PREFERENCES_BACKEND=user_service`): presets live in user-service. Either delete that user’s presets in `sharebridge-user-service\data\user-service-store.json` under `donorPresets` (while the service is stopped), or **replace with an empty list** via API (same bearer token as the app):

   ```powershell
   $token = "<paste token from POST /v1/auth/token>"
   $uid = "alice"
   Invoke-RestMethod -Method Put -Uri "http://localhost:8081/v1/users/$uid/donor-presets" `
     -Headers @{ Authorization = "Bearer $token" } -ContentType "application/json" `
     -Body '{"presets":[]}'
   ```

3. **Fresh user id**: run the app with a new `--dart-define=USER_ID=...` and mint a matching token. That user has no presets until you save again.

**Local merge caveat:** With the default **file-backed** integration store (`local`), each save **merges** presets by `(restaurant_name, order_url)`; older venues for that user are **not** removed if you omit them in a later save. To shrink the list you must clear storage (above) or use **user-service** mode, where `PUT` donor-presets **replaces** the full set.

## 4. Cleanup / fresh slate

To wipe persisted donor presets and start over (same as §3e option 1):

```powershell
cd D:\kannan\sharebridge_repos\sharebridge-integration-service
Remove-Item -Recurse -Force data -ErrorAction SilentlyContinue
npm start
```

To reset the mobile client's local fallback cache, use the
platform-specific shared preferences clear (e.g. uninstall and
reinstall the app on Android, or delete the Flutter app data folder on
Windows).

### 4b. (Optional) Copy file-backed presets into user-service

Use this **before or right after** you point integration-service at user-service presets (`PREFERENCES_BACKEND=user_service`). Requires user-service running and the **same `AUTH_TOKEN_SECRET`** as used for `/v1/auth/token`:

```powershell
cd D:\kannan\sharebridge_repos\sharebridge-integration-service
$env:USER_SERVICE_BASE_URL = "http://localhost:8081"
# Dry run: $env:BACKFILL_DRY_RUN = "1"
npm run backfill:user-service-presets
```

See `development/USER_SERVICE_PREFERENCES_MIGRATION.md` for the full cutover checklist.

## 5. What "good" looks like (acceptance summary)

- `npm test` in `sharebridge-integration-service` reports `# pass 32 / # fail 0`.
- `npm test` in `sharebridge-user-service` reports `# pass 35 / # fail 0`.
- `flutter test` in `sharebridge-mobile-app` ends with `All tests passed!` (**19 tests**, 0 failures — summary line shows `+19`).
- `Invoke-RestMethod http://localhost:8080/health` returns `ok=True`.
- Step 2c returns HTTP 200 with `saved_count=1`; step 2d echoes the
  same preset back.
- Step 2e leaves `total_count=1` after the second save (dedupe holds).
- Step 2f returns HTTP 403 with `code=user_id_mismatch`, and HTTP 401
  with `code=missing_auth_context`.
- Step 2g shows alice and bob with disjoint preset lists.
- Step 3c shows the mobile UI loading server presets on cold start,
  saving new picks, **Donor Setup list matching the server immediately after save**,
  and falling back to the local cache when the backend is offline.
