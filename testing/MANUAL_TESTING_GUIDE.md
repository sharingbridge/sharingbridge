# Manual Testing Guide — Completed Modules

This guide walks through how to verify the donor-setup modules and the
**donor–seeker field MVP-0 slice** that have shipped across
`sharingbridge-integration-service` and `sharingbridge-mobile-app`. It
pairs **automated test suites** with **manual API smoke tests** and
**end-to-end** flows on the mobile app.

All commands assume **PowerShell on Windows**. Translate to bash as
needed.

**Path note:** GitHub repository slugs use the `sharingbridge-*` prefix. Examples assume sibling service clones live under one parent folder, e.g. `D:\kannan\sharingbridge\sharingbridge-mobile-app` (coordination docs often live in `D:\kannan\sharingbridge\sharingbridge`). Adjust drive and parent path for your machine. If you still keep an older parent folder name such as `sharingbridge_repos`, substitute it in every `cd` (see `development/GITHUB_ORG_AND_REPO_RENAMES.md`).

## Modules in scope

| # | Module | Where it lives |
|---|--------|----------------|
| 1 | Donor setup `suggest-vendors` (mock top-5) | `sharingbridge-integration-service/src/server.js`, `src/suggestVendors.js` |
| 2 | Preferences save/fetch HTTP API | `sharingbridge-integration-service/src/server.js`, `src/preferencesStore.js` |
| 3 | Preferences repository boundary toward user-service | `sharingbridge-integration-service/src/preferencesRepository.js` |
| 4 | Signed-token auth context (JWT Bearer) | `sharingbridge-integration-service/src/authContext.js`, `src/tokenService.js` |
| 5 | Mobile donor setup UI + repository | `sharingbridge-mobile-app/lib/features/donor_setup/**` |
| 6 | Mobile HTTP client (timeout, retry, typed errors, auth headers) | `sharingbridge-mobile-app/lib/features/donor_setup/data/http_donor_setup_api_client.dart` |
| 7 | Mobile auth context | `sharingbridge-mobile-app/lib/features/donor_setup/data/auth_context.dart` |
| 8 | Mobile cache fallback (`shared_preferences`) | `sharingbridge-mobile-app/lib/features/donor_setup/presentation/pages/donor_setup_page.dart` |
| 9 | Mobile home hub + donor–seeker field flow (consent, safety, beneficiary notes; local draft) | `sharingbridge-mobile-app/lib/presentation/app_home_page.dart`, `lib/features/donor_seeker_interaction/**` |

## Prerequisites

- Node.js 20+ on `PATH`.
- Flutter 3.16+ on `PATH` (and a target device — Windows desktop, web,
  or an Android emulator at minimum).
- Both repos cloned alongside this one:
  - `D:\kannan\sharingbridge\sharingbridge-integration-service`
  - `D:\kannan\sharingbridge\sharingbridge-mobile-app`
- User service cloned and runnable for token minting:
  - `D:\kannan\sharingbridge\sharingbridge-user-service`
- Port `8080` free locally.
- Port `8081` free locally.

### Auth signing secret (`AUTH_TOKEN_SECRET`)

This guide describes the **donor-setup MVP** path: symmetric HS256 tokens and a shared `AUTH_TOKEN_SECRET` between user-service and integration-service. Production is expected to use **managed secrets**, **rotation**, and later **stronger patterns** (e.g. asymmetric signing)—see `development/AGENT_HANDOFF.md` follow-ups.

Tokens are signed and verified with that **symmetric** secret (`AUTH_TOKEN_SECRET`).

- **You do not have to set it for basic local smoke tests.** If the variable is unset, both `sharingbridge-user-service` and `sharingbridge-integration-service` use the same **built-in dev default** from each repo’s `src/tokenService.js` (open that file in each clone—the string must match on both sides). Tokens minted on user-service `:8081` will verify on integration-service `:8080` as long as you did not change the secret on one side only.

- **Set it explicitly** when you want to match staging/prod habits or avoid relying on the default string. The value must be **identical** on both servers before each `npm start`:

  ```powershell
  # In the user-service terminal, before `npm start`:
  $env:AUTH_TOKEN_SECRET = "your-strong-local-secret"

  # In the integration-service terminal, before `npm start`:
  $env:AUTH_TOKEN_SECRET = "your-strong-local-secret"
  ```

- If you override **`AUTH_TOKEN_ISSUER`** or **`AUTH_TOKEN_AUDIENCE`** in either service, override them **to the same values** on both; otherwise verification will fail.

## 1. Automated test suites

### 1a. Integration service (Node.js, currently 40 tests)

```powershell
cd D:\kannan\sharingbridge\sharingbridge-integration-service
npm install     # first time only
npm test
```

Coverage at a glance:

| Test file | What it asserts |
|-----------|-----------------|
| `test/suggestVendors.test.js` | request validators and mock response shape |
| `test/preferencesRepository.test.js` | local + user-service repository behavior, `clearForUser`, auth-header forwarding, typed upstream error mapping |
| `test/preferencesRoundtrip.test.js` | full HTTP save→fetch roundtrip, **`DELETE` clears authed user**, **`POST …/delete-item`** removes one row, dedupe by `(restaurant_name, order_url)`, per-user isolation, validation rejection |
| `test/authContext.test.js` | signed bearer parsing/verification + `user_id` reconciliation |
| `test/authContextRoundtrip.test.js` | signed-token flow, mismatch and missing-token guards (`403`/`401`), **`DELETE` without token → `401`** |
| `test/userServicePreferencesRoundtrip.test.js` | integration-service → user-service backend path roundtrip, **`POST …/delete-item`** through stub user-service, upstream 403 surfacing |
| `test/backfill-presets.test.js` | normalizing `PreferencesStore` rows for user-service backfill |

Each roundtrip test boots a real `http.Server` on port 0 against a
temp-dir `PreferencesStore`, so the HTTP wiring under test is the same
code that runs in `npm start`.

Expected output footer:

```
# tests 40
# pass 40
# fail 0
```

### 1b. Mobile app (Flutter, currently 30 tests)

```powershell
cd D:\kannan\sharingbridge\sharingbridge-mobile-app
flutter pub get   # first time only
flutter test
```

Coverage at a glance:

| Test file | What it asserts |
|-----------|-----------------|
| `test/features/donor_setup/application/suggest_vendors_usecase_test.dart` | top-5 trim and missing-permission guard |
| `test/features/donor_setup/application/confirm_presets_usecase_test.dart` | save delegation and empty-list guard |
| `test/features/donor_setup/application/clear_presets_usecase_test.dart` | clear delegation to repository |
| `test/features/donor_setup/data/suggest_vendors_response_dto_test.dart` | response DTO mapping and malformed payload handling |
| `test/features/donor_setup/data/http_donor_setup_api_client_test.dart` | retry-then-success, persistent 5xx, 4xx mapping, malformed JSON, no-retry on save 5xx, **`DELETE` clear presets**, **`POST` delete-item**, auth headers on the wire |
| `test/features/donor_setup/presentation/donor_setup_page_test.dart` | search; **Copy link** / **Open vendor page** / **Suggest again**; confirm saves **without** collapsing list to saved-only; success status + snackbar; presets navigation; slow-load race; cache clear |
| `test/features/donor_setup/presentation/donor_presets_page_test.dart` | saved-presets list; copy/open; per-row **Remove**; **Clear all** |
| `test/features/donor_seeker_interaction/donor_seeker_interaction_page_test.dart` | home hub opens field flow; consent/safety gates; **Save & close** persists `FieldInteractionDraft` in `shared_preferences` |
| `test/widget_test.dart` | app boots with **SharingBridge** home hub (Donor setup + Offer food help) |

Expected last line: `All tests passed!`.

### 1c. User service (Node.js, currently 37 tests)

```powershell
cd D:\kannan\sharingbridge\sharingbridge-user-service
npm install       # first time only
npm test
```

Coverage at a glance:

| Test file | What it asserts |
|-----------|-----------------|
| `test/userServiceRoundtrip.test.js` | mint token + donor-presets PUT/GET roundtrip (dedupe), **`POST …/donor-presets/delete-item`**, 401/403 auth, `/health`, 404, invalid JSON bodies, presets array/type validation, URL-encoded path `user_id` |
| `test/tokenService.test.js` | JWT mint/verify, secret/expiry/claims/tamper cases, env-driven defaults |
| `test/authContext.test.js` | bearer extraction and authenticated `user_id` resolution |
| `test/userStore.test.js` | file-backed init/read, `getOrCreateUser`, preset list/replace dedupe, **`deleteDonorPreset`**, persistence |

Expected output footer:

```
# tests 37
# pass 37
# fail 0
```

## 2. Manual API smoke tests

Start user-service in one PowerShell window:

```powershell
cd D:\kannan\sharingbridge\sharingbridge-user-service
npm install   # first time only
npm start
# User service listening on 8081
```

Start integration-service in a second PowerShell window:

```powershell
cd D:\kannan\sharingbridge\sharingbridge-integration-service
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
cd D:\kannan\sharingbridge\sharingbridge-mobile-app
flutter run -d windows --dart-define=API_BASE_URL=http://localhost:8080 --dart-define=USER_ID=alice --dart-define=AUTH_TOKEN=$mobileToken
```

### 3b. Android emulator

```powershell
cd D:\kannan\sharingbridge\sharingbridge-mobile-app
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8080 --dart-define=USER_ID=alice --dart-define=AUTH_TOKEN=$mobileToken
```

The mobile client now sends only `Authorization: Bearer <AUTH_TOKEN>`.

### 3c. Walkthrough on the app

1. App opens to the **SharingBridge** home hub with **Donor setup** and **Offer food help**. Tap **Donor setup** to open **Donor Setup** (same flow as before hub shipped). Because step 2c saved presets for
   `alice`, the page shows status "Loaded saved presets from server."
2. Type something like `zomato a2b mini meals` → tap **Suggest Vendors** (or **Suggest again** to re-fetch with the same query). The mock backend returns the **same fixed** suggestions every time (it does **not** personalize by `query_text`); each row shows the **full** menu line, **Copy link**, and **Open vendor page** when the URL is `http`/`https`. Auth-protected endpoints carry `Authorization: Bearer <signed token>`.
3. Check one or more suggestions → tap **Confirm and Save Presets**.
   A **SnackBar** and green status show "Presets saved successfully." The **full suggestion list stays on screen** (only checkboxes clear) so you can save another subset or open **Saved presets** without losing unselected rows. Server state still updates (dedupe on save as before).
4. **Cache fallback path**: stop the backend (Ctrl+C in step 2's
   window), kill and relaunch the app — the page falls back to
   "Using cached presets (offline fallback)." once the remote load
   fails.
5. **Retry / typed errors**: stop the backend mid-request — the typed
   exception path renders messages like "Server is temporarily
   unavailable (HTTP 500)." or "Network unavailable. Check your
   connection and retry." instead of stack traces.
6. **Saved presets / order links**: tap the app-bar icon with tooltip **Saved presets** → **Saved presets** loads from the server (`GET /v1/donor-setup/preferences`). Each row shows the **order URL** (selectable text), **Copy link**, and **Open link**. Per-row **Remove** calls integration `POST /v1/donor-setup/preferences/delete-item` (user-service: `POST /v1/users/{id}/donor-presets/delete-item` when that backend is on). **Clear all** uses `DELETE …/preferences`. Pull-to-refresh reloads the list.

### 3f. Donor–seeker field flow (MVP-0, device-only)

No backend call yet; draft is stored under `sharingbridge_field_interaction_draft_v1` in `shared_preferences`.

1. From the home hub, tap **Offer food help**.
2. Step through **Start here** → **Consent** (both checkboxes required) → **Quick safety** (self-assessment checkbox) → **Beneficiary details** (optional text). **Continue** shows inline error text if a gate is not satisfied.
3. Tap **Save & close** on the last step — the screen closes and the draft is persisted on this device only. Re-open **Offer food help** to see **Last saved:** timestamp on the beneficiary step when a draft exists.

Instruction pack, secure photo upload, and vendor redirect are **not** in this build; see `development/AGENT_HANDOFF.md` next tasks.

### 3d. Why Suggest Vendors and Saved presets can both look “static”

- **Suggest Vendors** always hits the **same mock** (`POST /v1/donor-setup/suggest-vendors`): three fixed venues. That is expected until real search/AI replaces the mock.
- **Saved presets** reflects **`GET …/preferences`**. After **Confirm and Save** on Donor Setup, the **suggestion** list is still the mock search result until you run **Suggest Vendors** again; use **Saved presets** to see persisted rows only.
- **Clear cache / Sign out** on Donor Setup only clears the **phone’s offline cache** (`shared_preferences`). It does **not** delete presets on the server, so **Saved presets** will still show server rows after a refresh.

### 3e. Clear server-side saved presets (empty the listing)

Pick one approach:

0. **In the app (Saved presets screen):** tap **Clear all** → confirm. No shell commands; uses integration-service `DELETE` (or user-service `PUT` with `[]` when that backend is enabled).

1. **Wipe the local integration file store** (typical dev: `PREFERENCES_BACKEND=local`): stop `npm start` on integration-service, delete the data file or folder, restart.

   ```powershell
   cd D:\kannan\sharingbridge\sharingbridge-integration-service
   Remove-Item -Recurse -Force data -ErrorAction SilentlyContinue
   npm start
   ```

   To clear **only one user**, edit `data\preferences.json` and remove that user’s array under `byUser` (or set it to `[]`), then restart the server.

2. **User-service backend** (`PREFERENCES_BACKEND=user_service`): presets live in user-service. Either delete that user’s presets in `sharingbridge-user-service\data\user-service-store.json` under `donorPresets` (while the service is stopped), or **replace with an empty list** via API (same bearer token as the app):

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
cd D:\kannan\sharingbridge\sharingbridge-integration-service
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
cd D:\kannan\sharingbridge\sharingbridge-integration-service
$env:USER_SERVICE_BASE_URL = "http://localhost:8081"
# Dry run: $env:BACKFILL_DRY_RUN = "1"
npm run backfill:user-service-presets
```

See `development/USER_SERVICE_PREFERENCES_MIGRATION.md` for the full cutover checklist.

### 4c. Clear local donor–seeker field draft (MVP-0)

The **Offer food help** flow stores one draft under the `shared_preferences` key `sharingbridge_field_interaction_draft_v1`. To reset: uninstall the app, clear app data, or use a dev-only prefs reset tool. There is no integration-service API for this draft yet.

## 5. What "good" looks like (acceptance summary)

- `npm test` in `sharingbridge-integration-service` reports `# pass 40 / # fail 0`.
- `npm test` in `sharingbridge-user-service` reports `# pass 37 / # fail 0`.
- `flutter test` in `sharingbridge-mobile-app` ends with `All tests passed!` (**30 tests**).
- `Invoke-RestMethod http://localhost:8080/health` returns `ok=True`.
- Step 2c returns HTTP 200 with `saved_count=1`; step 2d echoes the
  same preset back.
- Step 2e leaves `total_count=1` after the second save (dedupe holds).
- Step 2f returns HTTP 403 with `code=user_id_mismatch`, and HTTP 401
  with `code=missing_auth_context`.
- Step 2g shows alice and bob with disjoint preset lists.
- Step 3c shows the mobile UI loading server presets on cold start,
  saving new picks (full mock list remains after save; **Saved presets** shows server truth),
  and falling back to the local cache when the backend is offline.
- Step **3f** completes the field flow gates and persists a local draft; clearing that draft requires app data clear / key removal (no server API for this slice yet).
