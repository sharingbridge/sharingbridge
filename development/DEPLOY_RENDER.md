# Deploy MVP backend to Render (Track A)

Host the three services mobile and integration tests depend on:

| Service | Repo | Render runtime | Health |
|---------|------|----------------|--------|
| User | `sharingbridge-user-service` | Node 20 | `GET /health` |
| AI orchestration | `sharingbridge-ai-orchestration` | Docker | `GET /health` |
| Integration (public API) | `sharingbridge-integration-service` | Node 20 | `GET /health` |

Mobile talks **only** to integration-service. Integration calls user-service and ai-orchestration server-side.

---

## Before you start

- [Render](https://render.com) account (free tier is enough for demos).
- GitHub repos connected to Render (same `sharingbridge` org).
- Generate one shared internal token (PowerShell):

  ```powershell
  [Convert]::ToBase64String((1..32 | ForEach-Object { Get-Random -Maximum 256 }) -as [byte[]])
  ```

  Use the same value for `AI_ORCHESTRATION_INTERNAL_TOKEN` on **ai-orchestration** and **integration-service**.

---

## Deploy order

Deploy in this order so URLs and secrets exist before wiring integration.

### 1. User service

**Dashboard:** New → Web Service → connect `sharingbridge-user-service`.

| Setting | Value |
|---------|--------|
| Runtime | Node |
| Build command | `npm install` |
| Start command | `npm start` |
| Health check path | `/health` |

**Environment:**

| Key | Value |
|-----|--------|
| `AUTH_TOKEN_SECRET` | Generate in Render (or paste a long random string) |
| `AUTH_TOKEN_ISSUER` | `sharingbridge-user-service` |
| `AUTH_TOKEN_AUDIENCE` | `sharingbridge-clients` |
| `AUTH_TOKEN_TTL_SECONDS` | `3600` |

**Save the service URL**, e.g. `https://sharingbridge-user-service.onrender.com`, and copy `AUTH_TOKEN_SECRET` from the Environment tab (you need it for integration).

**Optional:** Render **Persistent Disk** mounted at `/app/data` if you want donor presets to survive redeploys on the file store. Free tier has limits; for multi-instance production, migrate to Postgres later.

**Or use Blueprint:** repo root `render.yaml` → New → Blueprint.

---

### 2. AI orchestration

**Dashboard:** New → Web Service → connect `sharingbridge-ai-orchestration`.

| Setting | Value |
|---------|--------|
| Runtime | **Docker** |
| Dockerfile path | `./Dockerfile` |
| Health check path | `/health` |

**Environment:**

| Key | Value |
|-----|--------|
| `AI_ORCHESTRATION_INTERNAL_TOKEN` | Same token you generated above |
| `AI_LLM_MODE` | `deterministic` (no OpenAI key required) |
| `SHARINGBRIDGE_WEBSITE_URL` | Your site or `https://sharingbridge.org` |

**Save the service URL**, e.g. `https://sharingbridge-ai-orchestration.onrender.com`.

**Or use Blueprint:** repo `render.yaml`.

---

### 3. Integration service (public API)

**Dashboard:** New → Web Service → connect `sharingbridge-integration-service`.

| Setting | Value |
|---------|--------|
| Runtime | Node |
| Build command | `npm install` |
| Start command | `npm start` |
| Health check path | `/health` |

**Environment:**

| Key | Value |
|-----|--------|
| `AUTH_TOKEN_SECRET` | **Same** as user-service |
| `AUTH_TOKEN_ISSUER` | `sharingbridge-user-service` |
| `AUTH_TOKEN_AUDIENCE` | `sharingbridge-clients` |
| `PREFERENCES_BACKEND` | `user_service` |
| `USER_SERVICE_BASE_URL` | User service URL (no trailing slash) |
| `AI_ORCHESTRATION_BASE_URL` | AI orchestration URL (no trailing slash) |
| `AI_ORCHESTRATION_INTERNAL_TOKEN` | Same as on ai-orchestration |
| `AI_ORCHESTRATION_TIMEOUT_MS` | `15000` |
| `AI_SUGGEST_VENDORS_ENABLED` | `true` |
| `AI_INSTRUCTION_PACK_ENABLED` | `true` |

**This URL is what the mobile app uses** as `API_BASE_URL`.

**Note:** `order-intents` and `PREFERENCES_BACKEND=local` data live on integration’s ephemeral disk if you use local mode; with `user_service`, presets live on user-service’s disk.

---

## Smoke test (hosted)

Replace hosts with your Render URLs.

```powershell
$USER_URL = "https://sharingbridge-user-service.onrender.com"
$INT_URL  = "https://sharingbridge-integration-service.onrender.com"
$AI_URL   = "https://sharingbridge-ai-orchestration.onrender.com"

Invoke-RestMethod "$USER_URL/health"
Invoke-RestMethod "$AI_URL/health"
Invoke-RestMethod "$INT_URL/health"

$token = (Invoke-RestMethod -Method POST -Uri "$USER_URL/v1/auth/token" `
  -ContentType "application/json" `
  -Body '{"user_id":"demo-user"}').token

$headers = @{ Authorization = "Bearer $token" }

Invoke-RestMethod -Method POST -Uri "$INT_URL/v1/donor-setup/suggest-vendors" `
  -Headers $headers -ContentType "application/json" `
  -Body '{"query":"biryani","location":"Chennai"}'

Invoke-RestMethod -Method POST -Uri "$INT_URL/v1/donor-seeker/instruction-pack" `
  -Headers $headers -ContentType "application/json" `
  -Body '{"verbal_handover_notes":"Near main gate","has_reference_photo":false,"presets":[]}'
```

Expect HTTP 200 and JSON bodies (not HTML error pages). First request after idle may be slow (free tier cold start).

---

## Point the mobile app at Render

```powershell
cd D:\kannan\sharingbridge\sharingbridge-mobile-app

# Mint token against hosted user-service (or integration if you expose token route only on user)
$token = (Invoke-RestMethod -Method POST -Uri "$USER_URL/v1/auth/token" `
  -ContentType "application/json" `
  -Body '{"user_id":"demo-user"}').token

flutter run `
  --dart-define=API_BASE_URL=$INT_URL `
  --dart-define=USER_ID=demo-user `
  --dart-define=AUTH_TOKEN=$token
```

**Android emulator:** use the public `https://` integration URL (not `10.0.2.2`).

Re-mint the token when it expires (`AUTH_TOKEN_TTL_SECONDS`, default 1 hour).

---

## Railway (alternative)

Same env vars and order. Per service:

- **user / integration:** Nixpacks or Node, start `npm start`, health `/health`.
- **ai-orchestration:** Deploy from Dockerfile, set `PORT` from platform.

---

## Troubleshooting

| Symptom | Fix |
|---------|-----|
| `401 missing_auth_context` | Send `Authorization: Bearer <token>` from user-service |
| `403` / invalid token | `AUTH_TOKEN_SECRET` mismatch between user and integration |
| Suggest-vendors still mock-like | Check `AI_ORCHESTRATION_BASE_URL`, `AI_SUGGEST_VENDORS_ENABLED=true`, internal token on both AI + integration |
| Orchestration timeout | Cold start: retry; increase `AI_ORCHESTRATION_TIMEOUT_MS` |
| Presets empty after redeploy | Expected on free tier without persistent disk; add disk or migrate DB |

---

## Next (Track B)

After hosted smoke passes, bootstrap **`sharingbridge-photo-service`** and wire reference photo upload into Offer food help. See `IMPLEMENTATION_APPROACH.md` — field slice phase A.

---

## Related docs

- [MANUAL_TESTING_GUIDE.md](../testing/MANUAL_TESTING_GUIDE.md) — local and hosted checks
- [AI_PLATFORM_INTEGRATION.md](./AI_PLATFORM_INTEGRATION.md)
- [AGENT_HANDOFF.md](./AGENT_HANDOFF.md)
