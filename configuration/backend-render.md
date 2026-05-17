# Backend — Render deployment

Host three **Web Services** for Track A. Credentials: [authentication.md](./authentication.md). Mobile wiring: [mobile-client.md](./mobile-client.md).

| # | Repo | Runtime | Used by |
|---|------|---------|---------|
| 1 | `sharingbridge-user-service` | Node 20 | JWT mint; integration |
| 2 | `sharingbridge-ai-orchestration` | Docker | integration (`/internal/...`) |
| 3 | `sharingbridge-integration-service` | Node 20 | mobile (`API_BASE_URL`) |

**Not on Render for MVP:** `sharingbridge-location-safety` (archived), api-gateway, order-service, photo-service.

**Do not use:** Static Site, Private Service, Worker, Cron, Postgres, Key Value.

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
| `AUTH_TOKEN_SECRET` | generated |
| `AUTH_TOKEN_ISSUER` | `sharingbridge-user-service` |
| `AUTH_TOKEN_AUDIENCE` | `sharingbridge-clients` |
| `AUTH_TOKEN_TTL_SECONDS` | `3600` |

Optional: persistent disk at `/app/data`.

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
| `AI_SUGGEST_VENDORS_ENABLED` | `true` |
| `AI_INSTRUCTION_PACK_ENABLED` | `true` |

Do not set `PORT` (Render injects it).

---

## Deploy order

1. user-service → URL + `AUTH_TOKEN_SECRET`
2. ai-orchestration → URL + API key + `SHARINGBRIDGE_WEBSITE_URL=pending`
3. integration-service → both URLs + both secrets

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
| Presets lost on redeploy | user-service disk or DB later |
