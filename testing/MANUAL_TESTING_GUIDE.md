# Manual Testing Guide — Completed Modules

This guide walks through how to verify the donor-setup modules and the
**Offer food help (initiator–seeker handoff)** slice that have shipped across
`sharingbridge-integration-service`, `sharingbridge-ai-orchestration`,
`sharingbridge-mobile-app`, and `sharingbridge-web-app`. It pairs **automated test suites** with
**manual API smoke tests** and **end-to-end** flows on the **mobile app** and **web dashboard**.

All commands assume **PowerShell on Windows**. Translate to bash as
needed.

**Path note:** GitHub repository slugs use the `sharingbridge-*` prefix. Examples assume sibling service clones live under one parent folder, e.g. `D:\kannan\sharingbridge\sharingbridge-mobile-app` (coordination docs often live in `D:\kannan\sharingbridge\sharingbridge`). Adjust drive and parent path for your machine; slug table in `development/AGENT_SESSION.md` § GitHub.

## Modules in scope

| # | Module | Where it lives |
|---|--------|----------------|
| 1 | Vendor preset setup `suggest-vendors` (mock or orchestration) | `sharingbridge-integration-service`, `sharingbridge-ai-orchestration` |
| 1b | Initiator–beneficiary `instruction-pack` | `sharingbridge-integration-service` → `sharingbridge-ai-orchestration` |
| 2 | Preferences save/fetch HTTP API | `sharingbridge-integration-service/src/server.js`, `src/preferencesStore.js` |
| 3 | Preferences repository boundary toward user-service | `sharingbridge-integration-service/src/preferencesRepository.js` |
| 4 | Signed-token auth context (JWT Bearer) | `sharingbridge-integration-service/src/authContext.js`, `src/tokenService.js` |
| 5 | Mobile vendor preset setup UI + repository | `sharingbridge-mobile-app/lib/features/donor_setup/**` |
| 6 | Mobile HTTP client (timeout, retry, typed errors, auth headers) | `sharingbridge-mobile-app/lib/features/donor_setup/data/http_donor_setup_api_client.dart` |
| 7 | Mobile auth context | `sharingbridge-mobile-app/lib/features/donor_setup/data/auth_context.dart` |
| 8 | Mobile cache fallback (`shared_preferences`) | `sharingbridge-mobile-app/lib/features/donor_setup/presentation/pages/donor_setup_page.dart` |
| 9 | Mobile home hub + **Offer food help** (3 steps: guidance → optional reference photo + **Get AI delivery instructions** (API with local fallback) → copy + vendor deep links) | `sharingbridge-mobile-app/lib/presentation/app_home_page.dart`, `lib/features/donor_seeker_interaction/**` |
| 10 | Web **Order initiation history** (coordinator dashboard) | `sharingbridge-web-app` — see **§4** |
| 11 | Reference photo upload (Cloudinary) | `sharingbridge-photo-service` — see **§1e**, **§2b**, **§3f**; [photo-service-local.md](../configuration/photo-service-local.md) |
| 12 | **Record seeker demand** + eco kitchen routes (pledge / I pay) | `sharingbridge-mobile-app/lib/features/seeker_demand/**` → `GET /v1/standard-offers`, `POST /v1/seeker-demands` |
| 13 | Web **Actions** tab (pledges, kitchen commits) | `sharingbridge-web-app` → `GET /v1/demand/board`; requires SQL **M1–M4** |
| 14 | Web **Connection** panel (order code handoff) | `ConnectionLookupPanel` → `GET /v1/connections/:orderCode`; **M4** + kitchen commit |
| 14b | Web **Updates** banner (connection-ready) | `DashboardNotificationsBanner` — demand board on sign-in / **Refresh**; **§4d-b** |
| 15 | **Notification-service** (FCM push) | `sharingbridge-notification-service`; **M5** + Firebase — [notification-service-local.md](../configuration/notification-service-local.md) |
| 16 | Web **data boundaries** banner + coordinator **scope** (time / area) | `sharingbridge-web-app` — Initiations, Actions, Map share scope |
| 17 | Mobile **handover map picker** + server reverse geocode | `HandoverLocationPicker`, `GET /v1/geocode/reverse` — [Handover_Location_Map_Picker.md](../design/Handover_Location_Map_Picker.md); setup [mobile-client.md § Handover](../configuration/mobile-client.md#handover-location--map-picker-address-pickup-note) |
| 18 | Web **Initiations** / **Actions** mobile layout | `sharingbridge-web-app` — single-column Initiations on narrow viewports; scrollable Actions supply split — **§4c-d** |

**Setup order:** [database-setup-sequence.md](../configuration/database-setup-sequence.md) (**1 → 2 → M1–M5** → notification deploy). Skipped steps: same doc § **If a step was skipped**.

## Prerequisites

- Node.js 20+ on `PATH`.
- Flutter 3.16+ on `PATH` (and a target device — Windows desktop, web,
  or an Android emulator at minimum).
- Service repos cloned alongside this one:
  - `D:\kannan\sharingbridge\sharingbridge-ai-orchestration`
  - `D:\kannan\sharingbridge\sharingbridge-integration-service`
  - `D:\kannan\sharingbridge\sharingbridge-mobile-app`
  - `D:\kannan\sharingbridge\sharingbridge-web-app` (for **§4** only)
- User service cloned and runnable (Google sign-in + optional dev token mint):
  - `D:\kannan\sharingbridge\sharingbridge-user-service`
- Photo service (reference images on **Help a seeker**):
  - `D:\kannan\sharingbridge\sharingbridge-photo-service`
  - **Python 3.10+** (3.13 works) — project venv inside that repo only; see **§1e**
  - Port **8092** free locally
- Notification service (eco kitchen FCM — **M5** + Firebase):
  - `D:\kannan\sharingbridge\sharingbridge-notification-service`
  - Port **8093** (photo-service uses 8092)
  - [notification-service-local.md](../configuration/notification-service-local.md)
- For **§4** (web): Google Web client + [coordinator-seed.sql](../configuration/coordinator-seed.sql) — [configuration/e2e-deployment-sequence.md](../configuration/e2e-deployment-sequence.md) **Phase 0–1**.
- For **§3-auth** (mobile Google): Android OAuth client + SHA-1 on user-service — [configuration/google-auth-setup.md](../configuration/google-auth-setup.md) §2.2.
- Port `8080` free locally (integration-service).
- Port `8081` free locally (user-service).
- Port `8091` — **only if** you run optional Python AI ([configuration/ai-orchestration-local.md](../configuration/ai-orchestration-local.md)); not required for web/mobile/Postgres smoke tests.

### Local PostgreSQL (required for Node backends)

Both **`sharingbridge-user-service`** and **`sharingbridge-integration-service`** require **`DATABASE_URL`** at startup (no JSON file store). Full setup: [configuration/database.md](../configuration/database.md) **Option A**.

| Step | Action |
|------|--------|
| 1 | Postgres running; database **`sharingbridge`** created |
| 2 | Run [schema-spatial-bootstrap.sql](../configuration/schema-spatial-bootstrap.sql) then [schema.sql](../configuration/schema.sql) as `postgres` |
| 3 | Run [local-postgres-grants.sql](../configuration/local-postgres-grants.sql) as `postgres` (fixes `permission denied for table users`) |
| 4 | Copy `env.example` → `.env` in **both** Node repos; set the same `DATABASE_URL` (match your port, e.g. `5433`) |
| 5 | Coordinator: `coordinator` row in `user_roles` ([coordinator-seed.sql](../configuration/coordinator-seed.sql)) after the user exists in `users` |
| 6 | Marketplace + eco kitchen + push: **M1 → M5** in [database-setup-sequence.md](../configuration/database-setup-sequence.md); notification deploy per [notification-service-local.md](../configuration/notification-service-local.md); `NOMINATIM_USER_AGENT` on integration-service |

**Verify DB before starting apps (psql or pgAdmin on `sharingbridge`):**

```sql
\dt
-- expect: users, user_roles, donor_presets, order_intents, photo_artifacts
```

**After sign-in / tests:** inspect data in pgAdmin under **Databases → sharingbridge → Schemas → public → Tables**.

### Auth signing secret (`AUTH_TOKEN_SECRET`)

This guide describes the **donor-setup MVP** path: symmetric HS256 tokens and a shared `AUTH_TOKEN_SECRET` between user-service and integration-service. Production is expected to use **managed secrets**, **rotation**, and later **stronger patterns** (e.g. asymmetric signing)—see `development/AGENT_SESSION.md` follow-ups.

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

### 1a. Integration service (Node.js)

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
| `test/orchestrationRoutes.test.js` | feature-flag wiring to mock orchestration HTTP (`suggest-vendors`, `instruction-pack`) |
| `test/seekerDemandsRoute.test.js`, `test/marketplaceRoute.test.js` | seeker demand + marketplace HTTP (in-memory stores injected in tests only) |
| `test/localityKey.test.js`, `test/fixtures/standardOffersCatalog.js` | postal `locality_key` resolution; catalog mirror of M3 seed SQL |

Route tests inject temp `PreferencesStore` or `test/support/inMemoryMarketplaceStore.js` — production `npm start` uses Postgres only (`DATABASE_URL` + `USER_SERVICE_BASE_URL`).

Expected: `# fail 0` in the `npm test` footer (count grows with the suite).

### 1d. AI orchestration service (Python, currently 6 tests)

Use a **project venv inside `sharingbridge-ai-orchestration` only** (not under the parent `sharingbridge` folder). Requires **Python 3.10+** (`python3.13` on PATH — not Anaconda’s default `python`). Full setup: [ai-orchestration-local.md](../configuration/ai-orchestration-local.md).

```powershell
cd D:\kannan\sharingbridge\sharingbridge-ai-orchestration
python3.13 -m venv .venv
.\.venv\Scripts\Activate.ps1   # if empty or errors, delete .venv and recreate
pip install -r requirements.txt
python -m pytest -q
```

| Test file | What it asserts |
|-----------|-----------------|
| `tests/test_orchestration.py` | `/health`, query-ranked `suggest-vendors`, `instruction-pack` includes verbal notes and presets |

Expected last line: `6 passed`. If `uvicorn` fails with `ForwardRef._evaluate() … recursive_guard`, delete `.venv`, recreate with `python3.13`, and `pip install -r requirements.txt` again (old Pydantic v1 + Python 3.13).

Run the API (venv activated):

```powershell
$env:PORT = "8091"
uvicorn app.main:app --host 0.0.0.0 --port 8091
```

If pip prints red errors but you still see `Uvicorn running on http://0.0.0.0:8091`, the server is up — confirm with `Invoke-RestMethod http://127.0.0.1:8091/health`.

### 1e. Photo service (Python, currently 5 tests)

Use a **project venv inside `sharingbridge-photo-service` only** (not Anaconda global, not the parent `sharingbridge` folder). Full setup: [configuration/photo-service-local.md](../configuration/photo-service-local.md).

```powershell
cd D:\kannan\sharingbridge\sharingbridge-photo-service
python3.13 -m venv .venv
.\.venv\Scripts\Activate.ps1
pip install -r requirements-dev.txt
copy env.example .env
# Edit .env: same DATABASE_URL and AUTH_TOKEN_SECRET as user-service; set CLOUDINARY_* (required)
python -m pytest -q
```

Expected last line: `5 passed`. Then run the API (venv still activated):

```powershell
uvicorn app.main:app --host 0.0.0.0 --port 8092
```

Confirm: `Invoke-RestMethod http://127.0.0.1:8092/health`

### 1b. Mobile app (Flutter)

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
| `test/features/donor_setup/data/auth_context_test.dart` | omit / include `user_id` by Bearer presence; preference URI helpers |
| `test/features/donor_setup/data/http_donor_setup_api_client_test.dart` | retry-then-success, persistent 5xx, 4xx mapping, malformed JSON, no-retry on save 5xx, **`DELETE` clear presets**, **`POST` delete-item**, auth headers, **Bearer omits `user_id` in body/query** |
| `test/features/donor_seeker_interaction/data/http_order_intent_client_test.dart` | order-intent POST/GET auth payload |
| `test/features/donor_seeker_interaction/data/http_instruction_pack_client_test.dart` | instruction-pack POST auth payload |
| `test/features/donor_setup/presentation/donor_setup_page_test.dart` | search; **Copy link** / **Open vendor page** / **Suggest again**; confirm saves **without** collapsing list to saved-only; success status + snackbar; presets navigation; slow-load race; cache clear |
| `test/features/donor_setup/presentation/donor_presets_page_test.dart` | saved-presets list; copy/open; per-row **Remove**; **Clear all** |
| `test/features/donor_seeker_interaction/donor_seeker_interaction_page_test.dart` | home hub opens **Help a seeker**; **Continue** → **Get AI delivery instructions** (injected stub) → **register order intent** button → copy enables **Open …** |
| `test/features/donor_seeker_interaction/donation_history_page_test.dart` | home hub → **Order initiation history**; list + detail with injected intents; empty state |
| `test/features/donor_seeker_interaction/delivery_instruction_stub_test.dart` | stub text: dignity, consent, presets; optional photo/verbal lines |
| `test/widget_test.dart` | app boots with **SharingBridge** home hub (Vendor presets + Help a seeker + Order initiation history) |

Expected last line: `All tests passed!`.

### 1c. User service (Node.js, currently 40 tests)

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
| `test/userStore.test.js` | file-backed init/read, `getOrCreateUser`, preset list/replace dedupe, **`deletePayeePreset`**, persistence |

Expected output footer:

```
# tests 37
# pass 37
# fail 0
```

### 1f. Notification service (Node.js)

Requires **M5** and Firebase. Part of the eco kitchen stack after integration-service.

```powershell
cd D:\kannan\sharingbridge\sharingbridge-notification-service
copy env.example .env
# DATABASE_URL (same as integration); WEBHOOK_SECRET; FIREBASE_SERVICE_ACCOUNT_PATH or JSON
npm install
npm test
npm start
# listens on http://localhost:8093
```

Confirm: `Invoke-RestMethod http://localhost:8093/health`

Wire integration-service `.env`:

```env
CONNECTION_NOTIFY_WEBHOOK_URL=http://localhost:8093/internal/connection-ready
CONNECTION_NOTIFY_WEBHOOK_SECRET=<same as notification WEBHOOK_SECRET>
```

Detail: [notification-service-local.md](../configuration/notification-service-local.md).

### 1g. Web app (Vitest)

```powershell
cd D:\kannan\sharingbridge\sharingbridge-web-app
npm install     # first time only
npm test
```

| Test file | What it asserts |
|-----------|-----------------|
| `src/authSession.test.ts` | session save/load/expiry |
| `src/config.test.ts` | `VITE_*` config from env |
| `src/format.test.ts` | list/detail formatting helpers |
| `src/feedScope.test.ts` | dashboard boundaries banner copy; coordinator vs initiator `feed` parsing |

Expected: **34 passed** (Vitest). End-to-end browser checks are in **§4**.

## 2. Manual API smoke tests

### Multi-service stack (AI + reference photos)

| Terminal | Service | Port | When needed |
|----------|---------|------|-------------|
| 1 | `sharingbridge-ai-orchestration` (`uvicorn … --port 8091`) | 8091 | Live LLM instruction-pack / suggest-vendors |
| 2 | `sharingbridge-user-service` (`npm start`) | 8081 | Always |
| 3 | `sharingbridge-integration-service` with AI env (see §2a.1) | 8080 | Always |
| 4 | `sharingbridge-photo-service` (`uvicorn … --port 8092`) | 8092 | **Help a seeker** with a reference photo (**§3f**) |

Start user-service in one PowerShell window (`.env` must include **`DATABASE_URL`**):

```powershell
cd D:\kannan\sharingbridge\sharingbridge-user-service
npm install   # first time only
npm start
# User service listening on 8081 (PostgreSQL)
```

If startup exits with `DATABASE_URL is required`, add it to `.env` per [database.md](../configuration/database.md).

Start ai-orchestration in a second PowerShell window (for deterministic AI). Create the venv in **`sharingbridge-ai-orchestration`**, not the repo parent:

```powershell
cd D:\kannan\sharingbridge\sharingbridge-ai-orchestration
python3.13 -m venv .venv
.\.venv\Scripts\Activate.ps1
pip install -r requirements.txt   # first time only
$env:PORT = "8091"
uvicorn app.main:app --host 0.0.0.0 --port 8091
```

Use **Python 3.10+** (`python3.13`); see [ai-orchestration-local.md](../configuration/ai-orchestration-local.md). Start integration-service in a third PowerShell window (same **`DATABASE_URL`** in `.env` as user-service; **`GIS_SCHEMA=extensions`** required):

```powershell
cd D:\kannan\sharingbridge\sharingbridge-integration-service
$env:AI_ORCHESTRATION_BASE_URL = "http://localhost:8091"
$env:AI_SUGGEST_VENDORS_ENABLED = "true"
$env:AI_INSTRUCTION_PACK_ENABLED = "true"
npm start
# Integration service listening on 8080 (PostgreSQL)
```

If startup fails with `GIS_SCHEMA is required` or `order_intents.location column is required`, run SQL **1a + 1** per [database-setup-sequence.md](../configuration/database-setup-sequence.md).

#### 2a.1 Integration AI env (copy from `env.example`)

| Variable | Example |
|----------|---------|
| `AI_ORCHESTRATION_BASE_URL` | `http://localhost:8091` |
| `AI_SUGGEST_VENDORS_ENABLED` | `true` |
| `AI_INSTRUCTION_PACK_ENABLED` | `true` |

Without these flags, `suggest-vendors` uses the fixed mock list and `instruction-pack` uses integration’s server-side fallback template.

#### 2b. Photo service (reference photo upload)

Start in **another PowerShell window** when testing **§3f** with a reference photo. Use **Python 3.10+** (`python3.13` on PATH — not Anaconda’s default `python`). Unit tests: **§1e**; more detail: [photo-service-local.md](../configuration/photo-service-local.md).

**First time on this machine** (venv, deps, `.env`):

```powershell
cd D:\kannan\sharingbridge\sharingbridge-photo-service
python3.13 -m venv .venv
.\.venv\Scripts\Activate.ps1
pip install -r requirements-dev.txt
copy env.example .env
# Edit .env now (required): same DATABASE_URL and AUTH_TOKEN_SECRET as user-service; set CLOUDINARY_* (required)
# Optional: python -m pytest -q
```

One-time setup ends above — **finish editing `.env` before `uvicorn` in the next block** (the service reads `.env` only at startup).

**Every run** (`.env` already exists; with user-service and integration-service already up):

```powershell
cd D:\kannan\sharingbridge\sharingbridge-photo-service
.\.venv\Scripts\Activate.ps1
uvicorn app.main:app --host 0.0.0.0 --port 8092
# Photo service listening on 8092
```

Confirm:

```powershell
Invoke-RestMethod http://127.0.0.1:8092/health
```

Mobile must pass `--dart-define=PHOTO_SERVICE_BASE_URL=…` (**§3-host**). Upload is `POST /v1/photos/upload` (Bearer initiator JWT). Without photo-service running, instruction-pack still works but photo upload fails when a reference image is attached.

In another window, drive the API.

Mint a signed token (same `AUTH_TOKEN_SECRET` as user-service `.env`):

```powershell
cd D:\kannan\sharingbridge\sharingbridge-user-service
$token = node scripts/mint-dev-jwt.mjs alice initiator
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

Expect a `suggestions` array (≤ 5 entries) plus `generated_at`. With orchestration enabled, `source` is `orchestration` (or `deterministic` from the orchestration service) and **Swiggy/Zomato-heavy queries reorder** the list; with flags off, `source` is `mock` and results are fixed.

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
$bobToken = node scripts/mint-dev-jwt.mjs bob initiator
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

### 2h. Instruction pack (integration → orchestration)

No bearer required for MVP (optional `user_id` in body). Orchestration flags should be on (§2a.1).

```powershell
$packBody = @{
  user_id = "alice"
  verbal_handover_notes = "Blue gate, ask for Raj"
  has_reference_photo = $true
  presets = @(
    @{
      restaurant_name = "A2B"
      menu_items = @("Mini Meals")
      app_name = "Zomato"
      order_url = "https://www.zomato.com/chennai/a2b/order"
    }
  )
} | ConvertTo-Json -Depth 5

Invoke-RestMethod -Method Post -Uri http://localhost:8080/v1/donor-seeker/instruction-pack `
  -ContentType application/json -Body $packBody
```

Expect HTTP 200, non-empty `delivery_instructions`, `pack_id`, and `source` of `orchestration` (or `deterministic` from upstream). Your handover notes and preset names should appear in the text.

Direct orchestration health (optional):

```powershell
Invoke-RestMethod http://localhost:8091/health
```

## 3. End-to-end with the mobile app

Flutter only. For the **web coordinator dashboard**, use **§4** (same backends, browser + Vite).

Keep **user-service** on `8081` and **integration-service** on `8080` running before `flutter run`. Add **ai-orchestration** (`8091`) for live LLM paths and **photo-service** (`8092`) when testing reference photo upload (**§3f**).

### 3-host. API URLs by device (read this first)

Backends always run on **your PC** (`user-service` **8081**, `integration-service` **8080**, optional `photo-service` **8092**). The Flutter app runs on a **phone or emulator**, so the `--dart-define` URLs must be whatever **that device** uses to reach the PC — not what works in PowerShell on the PC.

#### Pick one row — use it for every `--dart-define`

| Where you run the app | `USER_SERVICE_BASE_URL` | `API_BASE_URL` | `PHOTO_SERVICE_BASE_URL` |
|----------------------|-------------------------|----------------|--------------------------|
| **Android emulator** (Google Sign-In) | `http://10.0.2.2:8081` | `http://10.0.2.2:8080` | `http://10.0.2.2:8092` |
| **Windows desktop** (`flutter run -d windows`) | `http://localhost:8081` | `http://localhost:8080` | `http://localhost:8092` |
| **Physical Android phone** (USB or Wi‑Fi) | `http://<PC-LAN-IP>:8081` | `http://<PC-LAN-IP>:8080` | `http://<PC-LAN-IP>:8092` |
| **Hosted / friends testing** | `https://…user-service…onrender.com` | `https://…integration…onrender.com` | `https://…photo…` (when deployed) |

Do **not** mix rows (e.g. `localhost` on an emulator, or `10.0.2.2` on a physical phone).

#### What `localhost` means

| Device running the app | `localhost` points to |
|------------------------|------------------------|
| Android emulator | The emulator — **not** your PC → use **`10.0.2.2`** |
| Physical phone | The phone — **not** your PC → use **`<PC-LAN-IP>`** |
| Windows desktop (`-d windows`) | Your PC → **`localhost`** is correct |

#### Physical phone: same network as the PC

The PC’s LAN address (e.g. `192.168.1.3` from `ipconfig` → **Wi‑Fi** → **IPv4 Address**) only works when the phone can route to that subnet.

| Phone connection | Works with `http://192.168.x.x:8080`? |
|------------------|--------------------------------------|
| Same Wi‑Fi / router as the PC | **Yes** |
| Mobile data only | **No** |
| Different broadband / guest Wi‑Fi / another home network | **No** |

**Sanity check on the phone** (Chrome): open `http://<PC-LAN-IP>:8080/health` — you should see JSON with `"ok": true`. If the browser cannot load it, the app will not either (fix Wi‑Fi or firewall before changing Flutter code).

#### Find `<PC-LAN-IP>` (Windows)

```powershell
ipconfig
```

Use the **IPv4 Address** under **Wireless LAN adapter Wi‑Fi** (example: `192.168.1.3`). Ethernet counts only if that adapter is connected.

Example `flutter run` on a physical device:

```powershell
flutter run -d <device_id> `
  --dart-define=GOOGLE_CLIENT_ID=<Android OAuth client ID> `
  --dart-define=USER_SERVICE_BASE_URL=http://192.168.1.3:8081 `
  --dart-define=API_BASE_URL=http://192.168.1.3:8080 `
  --dart-define=PHOTO_SERVICE_BASE_URL=http://192.168.1.3:8092
```

Replace `192.168.1.3` with your IPv4. After changing `--dart-define`, stop the app and run **`flutter run` again** (hot reload does not update compile-time URLs).

#### USB workaround (phone and PC on different networks)

With the phone on USB debugging, forward ports to the PC:

```powershell
$adb = "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe"
& $adb reverse tcp:8080 tcp:8080
& $adb reverse tcp:8081 tcp:8081
& $adb reverse tcp:8092 tcp:8092
```

Then use **`http://127.0.0.1:8080`** (and `:8081`, `:8092`) in all three `--dart-define`s — on the phone, `127.0.0.1` is tunneled to the PC.

#### HTTP (local) vs HTTPS (hosted)

| Build | Plain `http://` to LAN IP |
|-------|---------------------------|
| `flutter run` (debug) | Allowed (cleartext only in debug/profile manifests) |
| Release APK for testers / Play Store | Use **`https://`** Render URLs only — release builds block cleartext |

See also [configuration/mobile-client.md](../configuration/mobile-client.md) § Local networking.

### 3-run. Start an Android emulator

```powershell
cd D:\kannan\sharingbridge\sharingbridge-mobile-app
flutter pub get
flutter emulators                    # list AVDs
flutter emulators --launch <emulator_id>   # e.g. Pixel_7_API_34
flutter devices                      # note device id, e.g. emulator-5554
```

Wait until the emulator home screen is up, then use `-d <device_id>` in the commands below.

### 3-auth. Google Sign-In on Android emulator (initiator, recommended)

Requires [configuration/google-auth-setup.md](../configuration/google-auth-setup.md): **Android** OAuth client (package name + debug SHA-1), `GOOGLE_CLIENT_ID_ANDROID` in user-service `.env`, Gmail added as OAuth **test user**.

```powershell
cd D:\kannan\sharingbridge\sharingbridge-mobile-app
flutter run -d emulator-5554 `
  --dart-define=GOOGLE_CLIENT_ID=<Android OAuth client ID> `
  --dart-define=USER_SERVICE_BASE_URL=http://10.0.2.2:8081 `
  --dart-define=API_BASE_URL=http://10.0.2.2:8080 `
  --dart-define=PHOTO_SERVICE_BASE_URL=http://10.0.2.2:8092
```

Replace `emulator-5554` with your `flutter devices` id.

1. App opens → **Continue with Google** (initiator JWT). Users with both **`initiator`** and **`coordinator`** in `user_roles` can use mobile as initiator and web as coordinator (same Gmail).
2. Walk through **§3c** / **§3f** / **§3g**.

**Windows desktop:** `google_sign_in` is not supported on `-d windows`; use the emulator for Google auth, or **§3-dev** with a dev token.

### 3-dev. Dev token path (fallback, no Google)

Mint on the **PC** with user-service `scripts/mint-dev-jwt.mjs` (same `AUTH_TOKEN_SECRET` as `.env`). The app still uses **`10.0.2.2`** to reach backends from the emulator.

```powershell
cd D:\kannan\sharingbridge\sharingbridge-user-service
$mobileToken = node scripts/mint-dev-jwt.mjs alice initiator

cd D:\kannan\sharingbridge\sharingbridge-mobile-app
flutter run -d emulator-5554 `
  --dart-define=USER_SERVICE_BASE_URL=http://10.0.2.2:8081 `
  --dart-define=API_BASE_URL=http://10.0.2.2:8080 `
  --dart-define=PHOTO_SERVICE_BASE_URL=http://10.0.2.2:8092 `
  --dart-define=USER_ID=alice `
  --dart-define=AUTH_TOKEN=$mobileToken
```

**Windows desktop (dev token only):**

```powershell
flutter run -d windows `
  --dart-define=API_BASE_URL=http://localhost:8080 `
  --dart-define=USER_ID=alice `
  --dart-define=AUTH_TOKEN=$mobileToken
```

With `AUTH_TOKEN` set, the app sends only `Authorization: Bearer <token>` (JWT subject is the user id).

### 3c. Walkthrough on the app

Use after **§3-auth** (Google) or **§3-dev** (token as `alice`). On the **emulator**, confirm **§3-host** URLs before debugging empty lists or connection errors.

1. App opens to the **SharingBridge** home hub with **Vendor presets**, **Help a seeker**, and **Order initiation history**. Tap **Vendor presets**. If you ran API smoke **§2c** as `alice` with the same user id as the app, you may see "Loaded saved presets from server."; a new Google initiator starts empty until you save presets.
2. Type something like `zomato a2b mini meals` → tap **Suggest Vendors** (or **Suggest again**). With **orchestration enabled** (§2a.1), rankings change with query keywords; with flags off, the list is the **same fixed mock** every time. Each row shows the **full** menu line, **Copy link**, and **Open vendor page** when the URL is `http`/`https`. Auth-protected endpoints carry `Authorization: Bearer <signed token>`.
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

### 3d. Why Suggest Vendors and Saved presets can both look “static”

- **Suggest Vendors** uses `POST /v1/donor-setup/suggest-vendors`. With **`AI_SUGGEST_VENDORS_ENABLED`** and orchestration running, results are **query-ranked**; without those env vars, the integration service returns a **fixed mock** (three venues). That is expected until a live LLM provider is enabled.
- **Saved presets** reflects **`GET …/preferences`**. After **Confirm and Save** on Vendor preset setup, the **suggestion** list is still the mock search result until you run **Suggest Vendors** again; use **Saved presets** to see persisted rows only.
- **Clear cache / Sign out** on Vendor preset setup only clears the **phone’s offline cache** (`shared_preferences`). It does **not** delete presets on the server, so **Saved presets** will still show server rows after a refresh.

### 3e. Clear server-side saved presets (empty the listing)

Pick one approach:

0. **In the app (Saved presets screen):** tap **Clear all** → confirm. No shell commands; integration delegates to user-service `PUT { presets: [] }`.

1. **Postgres** (requires user-service + integration running with `USER_SERVICE_BASE_URL`): presets live in **`donor_presets`**. Clear via API (same bearer token as the app), or in pgAdmin/psql:

   ```sql
   UPDATE donor_presets SET presets_json = '[]'::jsonb, updated_at = now()
   WHERE user_id = 'YOUR_USER_ID';
   ```

   Or **replace with an empty list** via API:

   ```powershell
   $token = node scripts/mint-dev-jwt.mjs alice initiator
   $uid = "alice"
   Invoke-RestMethod -Method Put -Uri "http://localhost:8081/v1/users/$uid/donor-presets" `
     -Headers @{ Authorization = "Bearer $token" } -ContentType "application/json" `
     -Body '{"presets":[]}'
   ```

3. **Fresh user id**: run the app with a new `--dart-define=USER_ID=...` and mint a matching token. That user has no presets until you save again.

**Replace semantics:** Production saves go through user-service — `PUT` donor-presets **replaces** the full preset list for that user. Use **Clear all** or the API/SQL above to shrink the list; integration does not merge against a local file store at runtime.

### 3f. Help a seeker (initiator–seeker handoff)

Uses the same authed **`GET …/preferences`** load as Vendor preset setup (saved presets). There is **no** separate field-flow draft in `shared_preferences` for this screen. The flow is **three steps** (see the step label at the top of the screen).

1. From the home hub, tap **Help a seeker**.
2. **Step 1 — Guidance:** read dignity and **photo consent** text, then tap **Continue**.
3. **Step 2 — Handover location:** confirm **pickup note** (≥3 characters) and coordinates. With `GOOGLE_MAPS_API_KEY` in `android/local.properties`, you see the **cab-style map** (pan + fixed pin); otherwise editable lat/lng fields. **Address** and **Postal area** load from `GET /v1/geocode/reverse` (integration-service must be on latest code). Optionally add **reference photo** and **Handover notes**, then tap **Get AI delivery instructions** (photo uploads to photo-service when attached — **§2b**).
4. **Step 3 — Copy instructions and place order:** review the text, tap **Copy instructions to clipboard and register order intent**. Same registration behaviour as before (**Order intent registered** / **updated**).

**Photo-service troubleshooting:** SnackBar “Could not upload photo…” → start **§2b**, check `PHOTO_SERVICE_BASE_URL` (**§3-host**), and `.env` (`CLOUDINARY_*` required). Physical device: use your PC’s Wi‑Fi IP, not `localhost` or `10.0.2.2`.

If presets fail to load (offline/server), you can still generate instructions; **Open …** stays disabled until registration succeeds. If order-intent registration fails, the SnackBar still confirms clipboard copy and you can open vendor apps manually.

### 3f-b. Hosted backend + Android emulator (Render)

Use [configuration/mobile-client.md](../configuration/mobile-client.md). Public `https://` URLs work from emulators (no `10.0.2.2`). **Sign in with Google** on device — there is no HTTP JWT mint on hosted user-service.

```powershell
cd D:\kannan\sharingbridge\sharingbridge-mobile-app
flutter run -d emulator-5554 `
  --dart-define=GOOGLE_CLIENT_ID=<Android OAuth client ID> `
  --dart-define=API_BASE_URL=https://sharingbridge-integration-service.onrender.com `
  --dart-define=USER_SERVICE_BASE_URL=https://sharingbridge-user-service.onrender.com
```

Walk through **§3f**; step 4 must show **Order intent registered** (or **updated** on repeat).

### 3h. Handover map picker (mobile)

**Docs:** [mobile-client.md § Handover](../configuration/mobile-client.md#handover-location--map-picker-address-pickup-note) · reading steps **10–13** in [README.md § Documentation guide](../README.md#documentation-guide).

**Prerequisites:** integration-service deployed with `GET /v1/geocode/reverse` (hosted or local **§2**); initiator JWT (Google or dev token).

**Map UI (optional):**

1. Google Cloud → **Maps SDK for Android** → API key restricted to `app.sharingbridge` + debug SHA-1 ([google-auth-setup.md](../configuration/google-auth-setup.md)).
2. `sharingbridge-mobile-app/android/local.properties`: `GOOGLE_MAPS_API_KEY=AIza…` (see `local.properties.example`). Gradle sets `HANDOVER_MAP_ENABLED=true` — **no** `--dart-define` for the API key.
3. Rebuild: `flutter run -d <device>` with your usual `API_BASE_URL` / `USER_SERVICE_BASE_URL` defines.

**Verify (Help a seeker or Start initiation → eco kitchen):**

1. On handover step, **with key:** map + centre pin + read-only **Address** + editable **Pickup note** + read-only **Postal area**.
2. Pan map or **Refresh GPS** — address/postal lines update after debounced geocode.
3. **Without key** (empty `local.properties` line): coordinate form fallback (`HandoverLocationConfirmCard`) — flow still completes.
4. Hosted Render: use `https://…integration…` as `API_BASE_URL`; redeploy integration if address line stays empty (`502` → check `NOMINATIM_USER_AGENT` on Render).

**Eco kitchen:** after manual lat/lng edit on form fallback, menu clears until **Reload menu for updated coordinates**; **Refresh GPS** auto-reloads menu ([Handover_Location_Map_Picker.md](../design/Handover_Location_Map_Picker.md)).

### 3g. Order initiation history (mobile dashboard)

1. From the home hub, tap **Order initiation history** (listed after **Help a seeker**).
2. The app calls `GET /v1/donor-seeker/order-intents` with your Bearer token (newest first). Rows are grouped **by day**.
3. After at least one successful **Help a seeker** copy (§3f), you should see a row with the same reference id. Pull to refresh after registering another intent.
4. Tap a row → detail shows pack id, status, notes, preset snapshot, and whether a reference photo was attached.
5. Tap **Home** in the app bar → returns to the hub (Vendor presets / Help a seeker / Order initiation history). **Back** only pops one screen.

Empty state is normal before any intent is registered. Requires the same `AUTH_TOKEN` / `API_BASE_URL` as other flows. Coordinator view of the same data: **§4**.

## 4. End-to-end with the web dashboard

Repository: `sharingbridge-web-app`. Configuration: [configuration/web-client.md](../configuration/web-client.md). Deploy order (Google → local → Render): [configuration/e2e-deployment-sequence.md](../configuration/e2e-deployment-sequence.md).

Keep **user-service** (`8081`), **integration-service** (`8080`), and (for AI paths) **ai-orchestration** (`8091`) running as in **§2**. For coordinator **reference photo** thumbnails, the initiator must have uploaded via **photo-service** (`8092`, **§2b**) during **§3f**. The web app does not call photo-service directly — it shows URLs stored on the order intent.

### 4a. Prerequisites (Google, CORS, `.env`)

Complete [configuration/e2e-deployment-sequence.md](../configuration/e2e-deployment-sequence.md) **Phase 0–1** (Google Console Web client, test users, coordinator SQL seed).

1. **user-service** — copy `env.example` → `.env`:
   - `GOOGLE_CLIENT_ID_WEB` = same Web Client ID as web app
   - `WEB_CORS_ORIGINS=http://localhost:5173`
   - `user_roles` includes `coordinator` for your dashboard Gmail ([coordinator-seed.sql](../configuration/coordinator-seed.sql))
2. **integration-service** — `WEB_CORS_ORIGINS=http://localhost:5173`, same `AUTH_TOKEN_SECRET` as user-service. Restart after edits.
3. **sharingbridge-web-app** — `.env`:
   - `VITE_GOOGLE_CLIENT_ID` = Web Client ID
   - `VITE_API_BASE_URL=http://localhost:8080`
   - `VITE_USER_SERVICE_BASE_URL=http://localhost:8081`
4. Optional: register at least one order intent via mobile **§3f** (**§3-auth** Google initiator or **§3-dev**) so the coordinator dashboard is not empty on first **Refresh**.

No **client secret** in any `.env` for this flow.

### 4b. Run locally and sign in (coordinator)

```powershell
cd D:\kannan\sharingbridge\sharingbridge-web-app
copy env.example .env
# Edit .env: VITE_GOOGLE_CLIENT_ID, API URLs (or copy env.localtest / env.render)
npm install
npm run dev
```

1. Open http://localhost:5173.
2. **First visit:** **Sign in with Google**.
3. **Sign in with Google** using a Gmail that has the `coordinator` role in `user_roles`. If Chrome shows the wrong account, choose **Use another account** in Google’s popup.
4. Dashboard loads (coordinator role). Header shows coordinator email when the API returns it.
5. **Sign out** clears sessionStorage and GIS auto-select for this app.
6. **Returning visit:** sign-in page shows **Last signed in as** *email* and **Use a different Google account** (another Gmail with `coordinator` in `user_roles`). After revoke, reload and sign in with the other account.

### 4c. Order initiation history (coordinator view)

1. After at least one successful mobile **Help a seeker** copy (**§3f**) on the **same** integration host (`localhost:8080` or hosted URL), click **Refresh** on the web dashboard.
2. List shows **all** initiators’ intents. Use **By initiator** or **By day** above the list (**By city** is reserved for a future API field).
3. Each row includes the initiator **`user_id`**; detail pane shows **Initiator** explicitly.
4. Detail should match mobile **Order initiation history** (**§3g**) for that initiator — same reference id, pack id, status, notes, preset snapshot.
5. If the initiator attached a reference photo, detail shows a **thumbnail** and **Open full image (Cloudinary)** link (`reference_photo_view_url`).
6. **Home** in the header clears the selected row and scrolls to the top.

### 4c-a. Order operations (payment done + mark delivered)

**Initiator (limited dashboard or mobile §3g):**

1. Open an initiation you registered.
2. Tap **Mark payment done** — confirm the dialog.
3. List row shows **Payment: paid externally** chip; success banner on web.

**Coordinator:**

1. Select an initiation in the list — note **Payment** and **Delivery** chips on each row.
2. In the detail pane, tap **Mark delivered** — confirm the dialog.
3. **Delivery** chip becomes **delivered**; **Delivered at** in the metrics grid shows a timestamp (API sets `delivered_at`).

### 4c-b. Data boundaries banner (coordinator + initiator)

1. Sign in as **coordinator** or **initiator** (limited dashboard).
2. Below the hero (and coordinator scope toolbar when applicable), confirm **Data boundaries** on **Initiations**, **Actions**, or **Map**.
3. Expect four lines: **Time**, **Area**, **Sort**, **Limit** — they should match what the API is actually applying (not decorative).
4. **Initiator:** default is usually the last **2 hours** and **your initiations only** until you tap **By area** and allow location; then **Area** should mention distance from your position.
5. **Coordinator:** default **Time** = **All time**, **Area** = **All areas**, **Limit** = up to the server max rows (typically 100).

### 4c-c. Coordinator scope toolbar (time + area)

Requires **coordinator** role and integration-service with demand-board query support (same deploy generation as web **June 2026** boundaries work).

1. Set **Time window** to **Last 24 hours** and **Area** to **All areas** → **Apply scope**.
2. **Data boundaries** banner updates; List row count should drop if you have older test intents.
3. Switch to **Actions** — banner still shows the same time/area; demand lines and pledges respect the scope (no endless **Loading…** flicker after load completes).
4. Set **Area** to **Postal area key** `IN:TN:600115` (or a key from your seed data) → **Apply scope** — Initiations and Actions should only show rows for that postal grid.
5. Set **Area** to **Near my location** → **Apply scope** — allow browser location when prompted; **Area** in the banner should mention distance from your location.
6. **Reset** clears the form; click **Apply scope** again to return to all time / all areas.
7. Header **Refresh** on List/Map should keep the last applied scope (not revert to defaults).

### 4c-d. Initiations and Actions on narrow viewports

Resize the browser to phone width (or DevTools device mode) while signed in as **coordinator**.

1. **Initiations** — single column only (no duplicate empty detail pane on the right).
2. **Actions** — scroll the supply split vertically; demand lines and pledge/kitchen ledger remain reachable.

### 4d. Actions tab (coordinator)

Requires SQL **M1–M4** and at least one seeker demand (mobile **Start initiation** → eco kitchen route, or API).

1. Open the **Actions** tab (not Initiations).
2. Confirm pledges and demand lines load once (brief **Loading…**, then content).
3. **Pledge** on a demand line (email-share consent checkbox required).
4. As coordinator, **Kitchen commit** on a line (legacy API: `POST /v1/vendor-bids`) — enter kitchen name and portions.
5. **Refresh** reloads the board; with **§4c-c** scope applied, counts match the boundaries banner.

### 4d-b. Updates banner (web)

Requires **M4** and at least one **kitchen commit** in the current demand-board scope (**§4d** step 4). Not realtime — loads on **sign-in** and header **Refresh** only.

1. After a kitchen commit, sign in (or click **Refresh** on the dashboard header).
2. Below the hero, confirm **Updates (n)** lists the order code (`SB-…`) with a role badge (Coordinator / Your order / Your pledge / Your kitchen commit).
3. Click **Open Connection** — dashboard switches to **Actions** and loads that order in the Connection panel (**§4f**).

### 4f. Connection panel (order code)

Requires **M4** and a kitchen commit on a matching demand line (**§4d** step 4).

1. On **Actions**, scroll to **Connection** (or `ConnectionLookupPanel`).
2. Enter the order code shown on mobile after recording a seeker demand (`SB-…`).
3. As **initiator** (initiator who recorded the demand) or **coordinator**, confirm kitchen display name and login emails appear in-app.
4. Unrelated users receive **403** from `GET /v1/connections/:orderCode`.

In-app source of truth per [Eco_Kitchen_Initiation_Flow.md](../design/Eco_Kitchen_Initiation_Flow.md). Connection lookup UI is on **web** today.

### 4g. FCM push after kitchen commit

Requires **M5**, notification-service (**§1f**), integration `CONNECTION_NOTIFY_WEBHOOK_*`, mobile APK with `google-services.json`.

1. Sign in on mobile — confirm a `device_tokens` row.
2. Coordinator **Kitchen commit** (**§4d** step 4) on the matching demand line.
3. Initiator/pledger device receives push; payload includes `order_code`.
4. Confirm emails in **§4f** Connection panel match the same order.

Setup gaps: [database-setup-sequence.md](../configuration/database-setup-sequence.md) § **If a step was skipped** · [notification-service-local.md](../configuration/notification-service-local.md).

### 4e. Empty list / mismatch

- Coordinators see intents for **every** initiator on **that** integration API host (unless a scope filter from **§4c-c** is applied). An empty list usually means no initiator has registered an intent on **this** host yet (localhost vs Render are separate stores).
- `VITE_API_BASE_URL` must match mobile `API_BASE_URL` (both localhost or both Render URLs).
- `403 wrong_client_role` on web: account has no `donor`/`initiator` or `coordinator` in `user_roles` (`no_app_role`). Initiator-only accounts should sign in successfully and see the **limited** dashboard.
- `403 wrong_client_role` on mobile: account missing `initiator` in `user_roles` (rare after sign-in; every user gets `initiator` ensured).
- **Connection refused** on emulator sign-in or API: you used `localhost` in dart-defines — switch both URLs to `http://10.0.2.2:8081` and `http://10.0.2.2:8080` (**§3-host**).
- **“Network unavailable”** on a **physical phone** with correct `192.168.x.x` dart-defines: phone and PC are on **different networks** (mobile data, other broadband, guest Wi‑Fi) — join the **same Wi‑Fi as the PC**, verify `http://<PC-LAN-IP>:8080/health` in the phone browser, or use **USB + `adb reverse`** (**§3-host**).
- `401 invalid_google_token`: `VITE_GOOGLE_CLIENT_ID` must match `GOOGLE_CLIENT_ID_WEB`; add `http://localhost:5173` under Google **Authorized JavaScript origins**.
- CORS errors (local): `WEB_CORS_ORIGINS=http://localhost:5173` on **both** Node services in **local** `.env`.
- CORS errors (hosted dashboard): set `WEB_CORS_ORIGINS=https://<static-site>.onrender.com` on **both** services in the **Render** dashboard — [backend-render.md](../configuration/backend-render.md).

See [configuration/google-auth-setup.md](../configuration/google-auth-setup.md) troubleshooting.

## 5. Cleanup / fresh slate

To wipe persisted initiator presets, use **§3e** (app **Clear all**, user-service `PUT { presets: [] }`, or SQL on `donor_presets`). Presets live in **Postgres**, not integration-service `data/`.

To reset marketplace / seeker demand rows (dev only): [reset-marketplace-data.sql](../configuration/reset-marketplace-data.sql) then re-run **M3** seed. SQL pick-up guide: [database-setup-sequence.md](../configuration/database-setup-sequence.md) § Where you are.

To reset the mobile client's local fallback cache, use the
platform-specific shared preferences clear (e.g. uninstall and
reinstall the app on Android, or delete the Flutter app data folder on
Windows).

### 5b. Historical: local field draft key (no longer used)

Earlier MVP builds stored a field draft under `sharingbridge_field_interaction_draft_v1`. The current **Help a seeker** screen does **not** use that key. To reset mobile state, use app data clear / uninstall only if you need a full wipe; donor-setup offline cache is separate (see **Clear cache / Sign out** on Vendor preset setup and **§3**).

## 6. Hosted backend smoke (Render)

Use this after deploying per **[configuration/backend-render.md](../configuration/backend-render.md)**.

1. Confirm `/health` on user-service, integration-service, photo-service, and notification-service return `ok: true` (allow 30–60s on cold start).
2. Mint a token locally: `node scripts/mint-dev-jwt.mjs demo-user initiator` in user-service (with hosted `AUTH_TOKEN_SECRET` in env if backfilling Render data).
3. Call **hosted** integration `POST …/v1/donor-setup/suggest-vendors` and `POST …/v1/donor-seeker/instruction-pack` with `Authorization: Bearer <token>`.
4. `POST …/v1/donor-seeker/order-intents` with the same Bearer token (see [configuration/backend-render.md](../configuration/backend-render.md) smoke script). First call returns HTTP **201** and `created: true`. Repeat the **same** `pack_id` — expect HTTP **200**, `created: false`, and the **same** `order_intent_id`.
5. Run the mobile app (see [configuration/mobile-client.md](../configuration/mobile-client.md)). Walk **§3f**, eco kitchen routes, **§4f** Connection, and **§4g** FCM after kitchen commit.
6. Deploy `sharingbridge-web-app` static site per [configuration/e2e-deployment-sequence.md](../configuration/e2e-deployment-sequence.md) Phases 3–5; **Sign in with Google** on the live URL and **Refresh** — **§4**.

If suggest-vendors or instruction-pack fail, verify `AI_ORCHESTRATION_BASE_URL`, `AI_*_ENABLED=true`, and matching `AI_ORCHESTRATION_INTERNAL_API_KEY` on integration and ai-orchestration.

---

## 7. What "good" looks like (acceptance summary)

- `python -m pytest -q` in `sharingbridge-ai-orchestration` reports `6 passed`.
- `npm test` in `sharingbridge-integration-service` reports `# pass 152 / # fail 0` (approximate — run locally to confirm).
- `npm test` in `sharingbridge-user-service` reports `# pass 49 / # fail 0` (approximate).
- `npm test` in `sharingbridge-web-app` (Vitest) reports **34 passed** (approximate).
- `flutter test` in `sharingbridge-mobile-app` ends with `All tests passed!` (**66 tests** approximate).
- `Invoke-RestMethod http://localhost:8080/health` returns `ok=True`.
- Step 2c returns HTTP 200 with `saved_count=1`; step 2d echoes the
  same preset back.
- Step 2e leaves `total_count=1` after the second save (dedupe holds).
- Step 2f returns HTTP 403 with `code=user_id_mismatch`, and HTTP 401
  with `code=missing_auth_context`.
- Step 2g shows alice and bob with disjoint preset lists.
- **§3-auth** or **§3-dev** on an **Android emulator** uses `10.0.2.2` for both user-service and integration URLs (**§3-host**).
- Step **§3c** shows the mobile UI loading server presets on cold start,
  saving new picks (full mock list remains after save; **Saved presets** shows server truth),
  and falling back to the local cache when the backend is offline.
- Step **2i** returns a non-empty `delivery_instructions` string when orchestration is enabled.
- Step **3f** walks **Help a seeker** (guidance → handover location + optional photo/instruction-pack → copy + register).
- Step **3h** verifies handover map picker or form fallback + server reverse geocode (**§3-host** integration on latest deploy).
- Step **4c** shows the coordinator web dashboard listing initiator order intents (including initiator `user_id` and reference photo thumbnail when uploaded) after mobile **§3f** on the same integration host.
- Step **4c-b** shows the **Data boundaries** banner on Initiations / Actions / Map with sensible Time / Area / Limit copy.
- Step **4c-c** lets coordinators **Apply scope** (time + area) and see Initiations, Map, and Actions stay aligned.
- Step **4c-d** confirms **Initiations** / **Actions** layout on narrow viewports (single column; scrollable Actions ledger).
- Step **4d** / **4d-b** / **4f** / **4g**: Actions pledge + kitchen commit; **Updates** banner on sign-in/refresh; Connection emails on web; FCM push on mobile (**M4** + **M5** + notification deploy).
