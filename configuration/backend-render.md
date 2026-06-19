# Backend — Render deployment

Host **Web Services** for Track A. Credentials: [authentication.md](./authentication.md). Mobile wiring: [mobile-client.md](./mobile-client.md).

## Experience API edge

**Mobile and web call only `sharingbridge-integration-service`** (`API_BASE_URL` / `VITE_API_BASE_URL`). That service is the **Experience API** (shared BFF): it validates JWT, applies CORS, proxies presets to user-service, bridges AI to ai-orchestration, and owns order-intent data in Postgres. Internal services are not browser- or app-facing.

Layering detail: [Technical Architecture § As-built](../design/SharingBridge_Technical_Architecture.md#as-built-architecture-june-2026).

| Layer | Repo | Runtime | Called by |
|-------|------|---------|-----------|
| **Experience** | `sharingbridge-integration-service` | Node 20 | mobile, web |
| **System** | `sharingbridge-user-service` | Node 20 | integration only |
| **Process** | `sharingbridge-ai-orchestration` | Docker | integration (`/internal/...`) |
| **Process** | `sharingbridge-photo-service` | Docker | mobile (`PHOTO_SERVICE_BASE_URL`) |
| **Process** | `sharingbridge-notification-service` | Node 20 | integration only (`CONNECTION_NOTIFY_WEBHOOK_URL`) |
| **Client** | `sharingbridge-web-app` | **Static Site** | coordinator browser |

**Not on Render for MVP:** `sharingbridge-location-safety` (archived), api-gateway, order-service.

Each repo has a root **`render.yaml`** blueprint. Connect via **New + → Blueprint** (first time) or **Sync** on an existing blueprint so **Auto-Deploy on commit** to `main` stays enabled.

**Do not use:** Static Site, Private Service, Worker, Cron, Key Value (for MVP app data).

**Database:** use **[Supabase](https://supabase.com)** (hosted Postgres) for tables and data. Render hosts **APIs only** — set **`DATABASE_URL`** on **user-service, integration-service, photo-service, and notification-service** to your Supabase connection URI. Full steps: [database.md](./database.md) (create tables in Supabase **SQL Editor**, then wire Render). SQL order: [database-setup-sequence.md](./database-setup-sequence.md) (include M4 eco-kitchen + M5 `device_tokens` for connection push).

Node services that use Postgres **require** `DATABASE_URL` at startup (no in-memory marketplace fallback). Without it, deploy fails or marketplace / device-token routes return 503. See [database.md](./database.md).

---

## Create each service

1. [dashboard.render.com](https://dashboard.render.com) → **New +** → **Web Service**
2. **Git Provider** → GitHub → **one** repository · **Branch:** `main` · **Root directory:** blank
3. Optional **Project:** `sharingbridge`

---

## Build and deploy settings

| Field | User-service | AI orchestration | Integration | Photo service | Notification service |
|-------|--------------|------------------|-------------|---------------|----------------------|
| Build Command | `npm install` | *(empty)* | `npm install` | *(empty — Docker)* | `npm install` |
| Start Command | `npm start` | **blank** | `npm start` | **blank** | `npm start` |
| Pre-Deploy Command | blank | blank | blank | blank | blank |
| Health Check Path | `/health` | `/health` | `/health` | `/health` | `/health` |
| Auto-Deploy | **On commit** to `main` | same | same | same | same |

**Static site (`sharingbridge-web-app`):** Build `npm install && npm run build` · Publish **`dist`** · Auto-Deploy **On commit** · see [web-client.md](./web-client.md).

### Auto-deploy not firing?

1. **Dashboard** → service → **Settings** → **Build & Deploy** → check **Auto-Deploy** mode:
   - **On Commit** — deploys after every push to the linked branch (simplest).
   - **After CI Checks Pass** — deploys only when GitHub reports a **successful** check on the commit. If the repo has **no** `.github/workflows/ci.yml` (or checks fail), Render **never** auto-deploys. Either add a `CI` workflow (see `sharingbridge-web-app` / `sharingbridge-photo-service`) or switch to **On Commit**.
2. **Branch** = `main` (matches `render.yaml`).
3. **GitHub** repo linked to the correct service (one repo per service).
4. Pushed to `main` on GitHub (local-only commits do not deploy).
5. **GitHub → repo → Actions:** confirm the latest `CI` workflow is green before expecting a Render deploy (when using After CI Checks Pass).
6. **Static site:** changing `VITE_*` requires a **new deploy** (values are compile-time).

**AI (Docker):** `Dockerfile` + `start.sh`. Non-empty **Start Command** in the UI → **Exited status 1**. Healthy logs: `Starting uvicorn on 0.0.0.0:…`, `GET /health … 200`. `GET /` → 404 is expected.

---

## Environment variables

**Full per-service tables:** [environment-variables.md](./environment-variables.md) (local + Render columns, mobile `--dart-define`, optional dev/MVP flags).

Secret generation: [authentication.md](./authentication.md). Postgres: [database.md](./database.md).

**Render reminders:**

- Do **not** set `PORT` on Node services (Render injects it).
- `DATABASE_URL` + `AUTH_TOKEN_SECRET` must match on user-service, integration-service, and photo-service.
- `WEB_CORS_ORIGINS` must be the **same string** on user-service and integration-service.
- Web static site: set `VITE_*` at **build** time; redeploy after changing them.
- Web and mobile use **Google Sign-In** only on production (no dev token mint over HTTP).
- photo-service: **Docker** — keep Render **Start Command** blank (`Dockerfile` + `start.sh`).
- **`LOG_LEVEL`:** set `warn` (default) on all five backend APIs; use `info` temporarily for startup config dumps — see [environment-variables.md](./environment-variables.md#log_level-all-backend-apis).

After deploy, complete [e2e-deployment-sequence.md](./e2e-deployment-sequence.md) Phase 4 (Google origins + `WEB_CORS_ORIGINS`).

### `WEB_CORS_ORIGINS` — local laptop vs Render (both backends)

CORS is enforced on **user-service** and **integration-service** (not on the static web repo). The value must list the **browser origin** where the dashboard runs (scheme + host + port), not the API URL.

| Where you edit | When | Set `WEB_CORS_ORIGINS` to |
|----------------|------|---------------------------|
| **Local** `.env` in user-service **and** integration-service | `npm run dev` at http://localhost:5173 | `http://localhost:5173` |
| **Render** dashboard for **both** Node services | After static site is deployed | `https://<your-static-site>.onrender.com` |
| **Render** (optional) | You still use local Vite but APIs stay on Render | `http://localhost:5173,https://<your-static-site>.onrender.com` |

Rules:

1. **Same string** on user-service and integration-service (always).
2. **Local `.env` does not apply on Render** — set env in the Render dashboard (or `render.yaml`) for hosted services.
3. **Do not** put the Render static URL only in local `.env` unless you are testing local Vite against hosted APIs; for normal local dev, `http://localhost:5173` is enough on your laptop.
4. **Do** add the Render static URL on **Render** user-service and integration-service when users open the **hosted** dashboard (Phase 4 in [e2e-deployment-sequence.md](./e2e-deployment-sequence.md)).
5. Also add the static URL in **Google Console** → Web client → **Authorized JavaScript origins** (separate from CORS).

Comma-separated, no trailing slashes, no paths. Redeploy both Node services after changing CORS on Render.

---

## Notification service (optional — connection-ready FCM push)

**Repo:** `sharingbridge-notification-service` · **Not browser-facing** — integration-service calls it when an eco kitchen commits.

| When you need it | Skip it when… |
|------------------|----------------|
| Mobile push after kitchen commit | Connection panel on web Actions is enough for your pilot |
| FCM tokens registered via `PUT /v1/device-tokens` | You have not run `device_tokens` migration or rebuilt the APK with Firebase |

**Local guide (Firebase, ports, smoke):** [notification-service-local.md](./notification-service-local.md)

### Create on Render

1. **New +** → **Web Service** → repo `sharingbridge-notification-service`, branch `main`.
2. **Runtime:** Node 20 · **Build:** `npm install` · **Start:** `npm start` · **Health:** `/health`
3. Or **Blueprint** → apply root `render.yaml` → set secrets when prompted.

**Local port:** `8093` (photo-service uses `8092`). On Render, `PORT` is injected — do not set it.

### Environment (Render dashboard)

| Variable | Value |
|----------|--------|
| `DATABASE_URL` | **Same** Supabase URI as integration-service (`device_tokens` table — [schema-device-tokens-migration.sql](./schema-device-tokens-migration.sql)) |
| `WEBHOOK_SECRET` | Generate a long random string — **copy the same value** to integration-service as `CONNECTION_NOTIFY_WEBHOOK_SECRET` |
| `FIREBASE_SERVICE_ACCOUNT_JSON` | Full Firebase Admin service-account JSON (one secret env var). Alternative local-only: `FIREBASE_SERVICE_ACCOUNT_PATH` |
| `LOG_LEVEL` | `warn` |

Do **not** set `AUTH_TOKEN_SECRET` on notification-service — webhook auth uses `WEBHOOK_SECRET` / `X-Webhook-Secret`, not JWT.

### Wire integration-service (after notification URL exists)

On **integration-service** Render env:

```env
CONNECTION_NOTIFY_WEBHOOK_URL=https://<your-notification-service>.onrender.com/internal/connection-ready
CONNECTION_NOTIFY_WEBHOOK_SECRET=<same string as notification WEBHOOK_SECRET>
```

Redeploy **integration-service** after saving. Without these vars, connection handoff still works in-app; only push/email webhook is skipped.

### Mobile + Firebase (required for push to devices)

1. Firebase project → Android app `app.sharingbridge` + `google-services.json` in mobile repo.
2. SHA fingerprints in Firebase Console for your APK signing key.
3. Rebuild release/debug APK after pulling mobile FCM changes.

Detail: [notification-service-local.md](./notification-service-local.md) · [mobile-client.md](./mobile-client.md) § FCM push.

---

## Local `.env` (not used on Render)

Both Node services (and notification-service) load a repo-root `.env` on `npm start` via `dotenv`.

```powershell
cd sharingbridge-user-service
copy env.example .env
# edit AUTH_TOKEN_SECRET, WEB_CORS_ORIGINS, …

cd ..\sharingbridge-integration-service
copy env.example .env
# match AUTH_TOKEN_SECRET; set USER_SERVICE_BASE_URL=http://localhost:8081
# set WEB_CORS_ORIGINS=http://localhost:5173 when using sharingbridge-web-app locally
# optional push: CONNECTION_NOTIFY_WEBHOOK_URL=http://localhost:8093/internal/connection-ready

cd ..\sharingbridge-notification-service
copy env.example .env
# same DATABASE_URL; WEBHOOK_SECRET matches integration CONNECTION_NOTIFY_WEBHOOK_SECRET
# FIREBASE_SERVICE_ACCOUNT_PATH=.\firebase-adminsdk.json
```

Web app: `sharingbridge-web-app/.env` from `env.example` (`VITE_*` URLs). Rebuild or restart `npm run dev` after changing `VITE_*`.

Optional FCM stack: [notification-service-local.md](./notification-service-local.md).

---

## Deploy order

1. **PostgreSQL** (when using DB) → schema + migrations — [database-setup-sequence.md](./database-setup-sequence.md) (M1–M5 for full eco kitchen + push)
2. user-service → URL + `AUTH_TOKEN_SECRET` + `DATABASE_URL`
3. ai-orchestration → URL + API key + `SHARINGBRIDGE_WEBSITE_URL=pending`
4. integration-service → both URLs + both secrets + `DATABASE_URL`
5. photo-service → same `DATABASE_URL` + `AUTH_TOKEN_SECRET` + **Cloudinary** (`CLOUDINARY_*` or `CLOUDINARY_URL`)
6. **notification-service** (optional) → same `DATABASE_URL` + `WEBHOOK_SECRET` + `FIREBASE_SERVICE_ACCOUNT_JSON` → note public URL
7. integration-service → set `CONNECTION_NOTIFY_WEBHOOK_URL` + `CONNECTION_NOTIFY_WEBHOOK_SECRET` → redeploy
8. web-app static site → `VITE_*` → then Phase 4 CORS + Google origins

Blueprints: each repo’s `render.yaml`. Integration still needs pasted URLs and `AUTH_TOKEN_SECRET` after steps 1–3 exist. Notification webhook URL is step 6–7.

---

## Smoke test

```powershell
$USER_URL = "https://sharingbridge-user-service.onrender.com"
$INT_URL  = "https://sharingbridge-integration-service.onrender.com"
$AI_URL   = "https://sharingbridge-ai-orchestration.onrender.com"
$PHO_URL  = "https://sharingbridge-photo-service.onrender.com"
$NOT_URL  = "https://sharingbridge-notification-service.onrender.com"

Invoke-RestMethod "$USER_URL/health"
Invoke-RestMethod "$AI_URL/health"
Invoke-RestMethod "$INT_URL/health"
Invoke-RestMethod "$PHO_URL/health"
Invoke-RestMethod "$NOT_URL/health"

# Authenticated smoke: mint JWT locally with the same AUTH_TOKEN_SECRET as Render user-service
cd path\to\sharingbridge-user-service
$env:AUTH_TOKEN_SECRET = "<same secret as Render user-service>"
$token = node scripts/mint-dev-jwt.mjs demo-user initiator
$h = @{ Authorization = "Bearer $token" }

Invoke-RestMethod -Method POST -Uri "$INT_URL/v1/donor-setup/suggest-vendors" `
  -Headers $h -ContentType "application/json" `
  -Body '{"query_text":"biryani","location_precision":"manual","manual_area":"Chennai"}'

Invoke-RestMethod -Method POST -Uri "$INT_URL/v1/donor-seeker/instruction-pack" `
  -Headers $h -ContentType "application/json" `
  -Body '{"verbal_handover_notes":"Near main gate","has_reference_photo":false,"presets":[]}'

$oi = Invoke-RestMethod -Method POST -Uri "$INT_URL/v1/donor-seeker/order-intents" `
  -Headers $h -ContentType "application/json" `
  -Body '{"pack_id":"smoke-pack-1","status":"instructions_copied","has_reference_photo":false,"presets_snapshot":[]}'
# First POST: HTTP 201, created: true

$oi2 = Invoke-RestMethod -Method POST -Uri "$INT_URL/v1/donor-seeker/order-intents" `
  -Headers $h -ContentType "application/json" `
  -Body '{"pack_id":"smoke-pack-1","status":"instructions_copied","has_reference_photo":true,"verbal_handover_notes":"repeat tap"}'
# Repeat same pack_id: HTTP 200, created: false, same order_intent_id as $oi.order_intent_id

Invoke-RestMethod -Uri "$INT_URL/v1/donor-seeker/order-intents" -Headers $h
# Lists order_intents for the token subject (newest first)
```

---

## Mobile app (after smoke)

See [mobile-client.md](./mobile-client.md) — mint JWT, then `flutter run` from `sharingbridge-mobile-app`.

---

## Troubleshooting

| Symptom | Fix |
|---------|-----|
| Stuck on configure | One repo per service; Node: `npm install` + `npm start` |
| Docker **Exited status 1** | Clear **Start Command** |
| `401 missing_auth_context` | Bearer JWT from user-service |
| `403` / invalid JWT | Match `AUTH_TOKEN_SECRET` |
| `401 Invalid internal API key` | Match `AI_ORCHESTRATION_INTERNAL_API_KEY` |
| AI not used | `AI_ORCHESTRATION_BASE_URL`, `AI_*_ENABLED=true` |
| Presets / intents lost on redeploy | Use **Supabase** + `DATABASE_URL` on both Node services — [database.md](./database.md) |
| `DATABASE_URL` / connection errors | Use **internal** URL; run schema SQL; redeploy both services |
| Browser **Failed to fetch** on web | `WEB_CORS_ORIGINS` on **both** backends includes the web origin; web `.env` `VITE_*` must point at the same API hosts you use for mobile |
| Local env ignored | Copy `env.example` → `.env` in each Node repo; restart `npm start` |
| Push never arrives | `device_tokens` migration; mobile `google-services.json`; Firebase SHA; `CONNECTION_NOTIFY_WEBHOOK_*` on integration; notification `FIREBASE_SERVICE_ACCOUNT_JSON` — [notification-service-local.md](./notification-service-local.md) |
| Webhook `401` / `403` on connection-ready | `WEBHOOK_SECRET` on notification-service must equal integration `CONNECTION_NOTIFY_WEBHOOK_SECRET`; header `X-Webhook-Secret` |
