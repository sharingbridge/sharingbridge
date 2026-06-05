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
| **Client** | `sharingbridge-web-app` | **Static Site** | coordinator browser |

**Not on Render for MVP:** `sharingbridge-location-safety` (archived), api-gateway, order-service.

Each repo has a root **`render.yaml`** blueprint. Connect via **New + → Blueprint** (first time) or **Sync** on an existing blueprint so **Auto-Deploy on commit** to `main` stays enabled.

**Do not use:** Static Site, Private Service, Worker, Cron, Key Value (for MVP app data).

**Database:** use **[Supabase](https://supabase.com)** (hosted Postgres) for tables and data. Render hosts **APIs only** — set **`DATABASE_URL`** on both Node services to your Supabase connection URI. Full steps: [database.md](./database.md) (create tables in Supabase **SQL Editor**, then wire Render).

Without `DATABASE_URL` (and DB-enabled code), services still use JSON on disk (not durable on Render).

---

## Create each service

1. [dashboard.render.com](https://dashboard.render.com) → **New +** → **Web Service**
2. **Git Provider** → GitHub → **one** repository · **Branch:** `main` · **Root directory:** blank
3. Optional **Project:** `sharingbridge`

---

## Build and deploy settings

| Field | User-service | AI orchestration | Integration | Photo service |
|-------|--------------|------------------|-------------|---------------|
| Build Command | `npm install` | *(empty)* | `npm install` | *(empty — Docker)* |
| Start Command | `npm start` | **blank** | `npm start` | **blank** |
| Pre-Deploy Command | blank | blank | blank | blank |
| Health Check Path | `/health` | `/health` | `/health` | `/health` |
| Auto-Deploy | **On commit** to `main` | same | same | same |

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
- **`LOG_LEVEL`:** set `warn` (default) on all four backend APIs; use `info` temporarily for startup config dumps — see [environment-variables.md](./environment-variables.md#log_level-all-backend-apis).

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

## Local `.env` (not used on Render)

Both Node services load a repo-root `.env` on `npm start` via `dotenv` (`import "dotenv/config"` in `src/server.js`).

```powershell
cd sharingbridge-user-service
copy env.example .env
# edit AUTH_TOKEN_SECRET, WEB_CORS_ORIGINS, …

cd ..\sharingbridge-integration-service
copy env.example .env
# match AUTH_TOKEN_SECRET; set USER_SERVICE_BASE_URL=http://localhost:8081
# set WEB_CORS_ORIGINS=http://localhost:5173 when using sharingbridge-web-app locally
```

Web app: `sharingbridge-web-app/.env` from `env.example` (`VITE_*` URLs). Rebuild or restart `npm run dev` after changing `VITE_*`.

---

## Deploy order

1. **PostgreSQL** (when using DB) → schema + migration — [database.md](./database.md)
2. user-service → URL + `AUTH_TOKEN_SECRET` + `DATABASE_URL`
3. ai-orchestration → URL + API key + `SHARINGBRIDGE_WEBSITE_URL=pending`
4. integration-service → both URLs + both secrets + `DATABASE_URL`
5. photo-service → same `DATABASE_URL` + `AUTH_TOKEN_SECRET` + **Cloudinary** (`CLOUDINARY_*` or `CLOUDINARY_URL`)
6. web-app static site → `VITE_*` → then Phase 4 CORS + Google origins

Blueprints: each repo’s `render.yaml`. Integration still needs pasted URLs and `AUTH_TOKEN_SECRET` after 1–2 exist.

---

## Smoke test

```powershell
$USER_URL = "https://sharingbridge-user-service.onrender.com"
$INT_URL  = "https://sharingbridge-integration-service.onrender.com"
$AI_URL   = "https://sharingbridge-ai-orchestration.onrender.com"
$PHO_URL  = "https://sharingbridge-photo-service.onrender.com"

Invoke-RestMethod "$USER_URL/health"
Invoke-RestMethod "$AI_URL/health"
Invoke-RestMethod "$INT_URL/health"
Invoke-RestMethod "$PHO_URL/health"

# Authenticated smoke: mint JWT locally with the same AUTH_TOKEN_SECRET as Render user-service
cd path\to\sharingbridge-user-service
$env:AUTH_TOKEN_SECRET = "<same secret as Render user-service>"
$token = node scripts/mint-dev-jwt.mjs demo-user donor
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
