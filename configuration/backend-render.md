# Backend — Render deployment

Host three **Web Services** for Track A. Credentials: [authentication.md](./authentication.md). Mobile wiring: [mobile-client.md](./mobile-client.md).

| # | Repo | Runtime | Used by |
|---|------|---------|---------|
| 1 | `sharingbridge-user-service` | Node 20 | JWT mint; integration |
| 2 | `sharingbridge-ai-orchestration` | Docker | integration (`/internal/...`) |
| 3 | `sharingbridge-integration-service` | Node 20 | mobile (`API_BASE_URL`) |

**Not on Render for MVP:** `sharingbridge-location-safety` (archived), api-gateway, order-service, photo-service.

**Do not use:** Static Site, Private Service, Worker, Cron, Key Value (for MVP app data).

**PostgreSQL:** use [Render Postgres](https://render.com/docs/databases) for users, roles, and order intents — see [database.md](./database.md). Both Node services share one `DATABASE_URL`.

---

## PostgreSQL (recommended for production)

1. **New +** → **PostgreSQL** → create `sharingbridge-db` (or similar).
2. Copy **Internal Database URL** from the database **Connections** tab.
3. Set **`DATABASE_URL`** on **user-service** and **integration-service** to that URL (same value on both).
4. Apply schema and one-time JSON import — [database.md](./database.md).

Deploy Postgres **before** or **with** the first DB-enabled deploy of the Node services. Without `DATABASE_URL`, services still use JSON files on disk (not durable on Render).

---

## Create each service

1. [dashboard.render.com](https://dashboard.render.com) → **New +** → **Web Service**
2. **Git Provider** → GitHub → **one** repository · **Branch:** `main` · **Root directory:** blank
3. Optional **Project:** `sharingbridge`

---

## Build and deploy settings

| Field | User-service | AI orchestration | Integration |
|-------|--------------|------------------|-------------|
| Build Command | `npm install` | *(empty)* | `npm install` |
| Start Command | `npm start` | **blank** | `npm start` |
| Pre-Deploy Command | blank | blank | blank |
| Health Check Path | `/health` | `/health` | `/health` |
| Auto-Deploy | After CI checks pass | same | same |

**AI (Docker):** `Dockerfile` + `start.sh`. Non-empty **Start Command** in the UI → **Exited status 1**. Healthy logs: `Starting uvicorn on 0.0.0.0:…`, `GET /health … 200`. `GET /` → 404 is expected.

---

## Environment variables

See [authentication.md](./authentication.md) for secret generation.

### `sharingbridge-user-service`

| Key | Value |
|-----|--------|
| `WEB_CORS_ORIGINS` | On Render: `https://<static-site>.onrender.com` (see § WEB_CORS_ORIGINS). Local `.env`: `http://localhost:5173` |
| `GOOGLE_CLIENT_ID_WEB` | Web OAuth client ID (same as `VITE_GOOGLE_CLIENT_ID`) |
| `GOOGLE_CLIENT_ID_ANDROID` | Android OAuth client ID (when mobile uses Google) |
| `DATABASE_URL` | Render Postgres **internal** URL — [database.md](./database.md) |
| `COORDINATOR_EMAILS` | Legacy file/env allowlist; **omit after DB cutover** — seed `user_roles` instead |
| `ALLOW_DEV_TOKEN_MINT` | `false` on Render |
| `AUTH_TOKEN_SECRET` | generated |
| `AUTH_TOKEN_ISSUER` | `sharingbridge-user-service` |
| `AUTH_TOKEN_AUDIENCE` | `sharingbridge-clients` |
| `AUTH_TOKEN_TTL_SECONDS` | `3600` |

Optional (legacy JSON mode only): persistent disk at `/app/data`. Not needed when using Postgres.

### `sharingbridge-ai-orchestration`

| Key | Value |
|-----|--------|
| `AI_ORCHESTRATION_INTERNAL_API_KEY` | same as integration |
| `AI_LLM_MODE` | `deterministic` |
| `SHARINGBRIDGE_WEBSITE_URL` | `pending` |
| `OPENAI_API_KEY` | omit for MVP |

### `sharingbridge-integration-service`

| Key | Value |
|-----|--------|
| `AUTH_TOKEN_SECRET` | same as user-service |
| `AUTH_TOKEN_ISSUER` | `sharingbridge-user-service` |
| `AUTH_TOKEN_AUDIENCE` | `sharingbridge-clients` |
| `PREFERENCES_BACKEND` | `user_service` |
| `USER_SERVICE_BASE_URL` | `https://<user-host>` (no trailing `/`) |
| `AI_ORCHESTRATION_BASE_URL` | `https://<ai-host>` (no trailing `/`) |
| `AI_ORCHESTRATION_INTERNAL_API_KEY` | same as ai-orchestration |
| `AI_ORCHESTRATION_TIMEOUT_MS` | `15000` |
| `WEB_CORS_ORIGINS` | web app origin(s), e.g. `http://localhost:5173` or your static site URL (comma-separated) |
| `DATABASE_URL` | Same Postgres **internal** URL as user-service — [database.md](./database.md) |
| `AI_SUGGEST_VENDORS_ENABLED` | `true` |
| `AI_INSTRUCTION_PACK_ENABLED` | `true` |

Do not set `PORT` (Render injects it).

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

## Local `.env` (not used on Render)

Both Node services load a repo-root `.env` on `npm start` via `dotenv` (`import "dotenv/config"` in `src/server.js`).

```powershell
cd sharingbridge-user-service
copy .env.example .env
# edit AUTH_TOKEN_SECRET, WEB_CORS_ORIGINS, …

cd ..\sharingbridge-integration-service
copy .env.example .env
# match AUTH_TOKEN_SECRET; set USER_SERVICE_BASE_URL=http://localhost:8081
# set WEB_CORS_ORIGINS=http://localhost:5173 when using sharingbridge-web-app locally
```

Web app: `sharingbridge-web-app/.env` from `.env.example` (`VITE_*` URLs). Rebuild or restart `npm run dev` after changing `VITE_*`.

---

## Deploy order

1. **PostgreSQL** (when using DB) → schema + migration — [database.md](./database.md)
2. user-service → URL + `AUTH_TOKEN_SECRET` + `DATABASE_URL`
3. ai-orchestration → URL + API key + `SHARINGBRIDGE_WEBSITE_URL=pending`
4. integration-service → both URLs + both secrets + `DATABASE_URL`

Blueprints: each repo’s `render.yaml`. Integration still needs pasted URLs and `AUTH_TOKEN_SECRET` after 1–2 exist.

---

## Smoke test

```powershell
$USER_URL = "https://sharingbridge-user-service.onrender.com"
$INT_URL  = "https://sharingbridge-integration-service.onrender.com"
$AI_URL   = "https://sharingbridge-ai-orchestration.onrender.com"

Invoke-RestMethod "$USER_URL/health"
Invoke-RestMethod "$AI_URL/health"
Invoke-RestMethod "$INT_URL/health"

$token = (Invoke-RestMethod -Method POST -Uri "$USER_URL/v1/auth/token" `
  -ContentType "application/json" -Body '{"user_id":"demo-user"}').token
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
| Presets / intents lost on redeploy | Set `DATABASE_URL` on both Node services; use Render Postgres — [database.md](./database.md) |
| `DATABASE_URL` / connection errors | Use **internal** URL; run schema SQL; redeploy both services |
| Browser **Failed to fetch** on web | `WEB_CORS_ORIGINS` on **both** backends includes the web origin; web `.env` `VITE_*` must point at the same API hosts you use for mobile |
| Local env ignored | Copy `.env.example` → `.env` in each Node repo; restart `npm start` |
