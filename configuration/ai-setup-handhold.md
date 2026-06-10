# AI setup handhold — Groq, Gemini, and Nominatim

Step-by-step wiring for **live** AI in SharingBridge. Use this when you want real LLM output instead of template/mock data.

**Repos involved**

| Service | Port (local) | Role |
|---------|--------------|------|
| `sharingbridge-ai-orchestration` | 8091 | Groq + Gemini + Nominatim |
| `sharingbridge-integration-service` | 8080 | Proxies mobile/web to orchestration |
| `sharingbridge-photo-service` | 8092 | Signed photo URLs for Gemini vision |
| `sharingbridge-mobile-app` | — | Sends queries, GPS, photo URLs |

Mobile and web **never** call Groq/Gemini/Nominatim directly.

---

## 1. What `AI_LLM_MODE` means

| Mode | Meaning | Mobile banner |
|------|---------|---------------|
| `deterministic` (default) | **Not real AI.** Fixed Chennai-style catalog and template instruction text in Python. Safe for CI and offline dev. | Amber notice: sample/template mode |
| `live` | **Real AI** when API keys are set: Groq for text, Gemini for photo vision, Nominatim for GPS → place name | No notice (sources `groq`, `groq+gemini`, `gemini`) |

**`deterministic` is mock/template data**, not a “reproducible AI” mode. The API still returns useful demo content, but it is not from Groq or Gemini.

Other `source` values you may see:

| `source` | Where | Meaning |
|----------|-------|---------|
| `mock` | integration-service | Built-in demo catalog when orchestration is disabled or unreachable |
| `mock_fallback` | integration-service | Orchestration call failed; fell back to demo catalog |
| `fallback` / `fallback_error` | integration-service | Template instruction text when live pack failed |
| `local_stub` | mobile only | Integration unreachable; on-device template |

---

## 2. Create API keys

### Groq (text — vendor suggestions + instruction compose)

1. Open [console.groq.com](https://console.groq.com) and sign in.
2. **API Keys** → **Create API Key**.
3. Copy the key (starts with `gsk_`). Store it in a password manager; Groq shows it once.

Default model in this project: `llama-3.3-70b-versatile`.

### Gemini (vision — reference photo description)

1. Open [aistudio.google.com](https://aistudio.google.com) → **Get API key**.
2. Create a key in a Google Cloud project (free tier is enough for dev).
3. Copy the key.

Default model: `gemini-2.5-flash` (`gemini-2.0-flash` was shut down June 2026).

### Nominatim (GPS → address) — **no API key**

Nominatim is the public OpenStreetMap reverse-geocoding service. SharingBridge calls it from `sharingbridge-ai-orchestration` when:

- `AI_LLM_MODE=live`, and
- instruction-pack request includes `lat` / `lng`.

**You do not sign up for a key.** You only set a descriptive **User-Agent** (required by [Nominatim usage policy](https://operations.osmfoundation.org/policies/nominatim/)):

```env
NOMINATIM_USER_AGENT=SharingBridge/1.0 (contact@yourdomain.org)
```

Use a real app name and contact email. Default if unset: `SharingBridge-AI-Orchestration/1.0`.

**Policy reminders**

- Max ~1 request per second (our flow does one reverse lookup per instruction-pack).
- Do not bulk-geocode or cache aggressively on shared infrastructure without your own Nominatim instance.
- If reverse geocode fails, instruction-pack still works; `location_description` may be omitted.

---

## 3. Local stack — env files

### 3a. Photo service (needed for Gemini vision)

In `sharingbridge-photo-service/.env` (see that repo’s `env.example`):

```env
PORT=8092
CLOUDINARY_*=...
JWT_*=...
```

Start photo-service before testing reference-photo flows.

### 3b. AI orchestration

```powershell
cd D:\kannan\sharingbridge\sharingbridge-ai-orchestration
copy env.example .env
```

Edit `.env`:

```env
PORT=8091
AI_LLM_MODE=live

GROQ_API_KEY=gsk_your_key_here
GROQ_MODEL=llama-3.3-70b-versatile

GEMINI_API_KEY=your_gemini_key_here
GEMINI_VISION_MODEL=gemini-2.5-flash

PHOTO_SERVICE_BASE_URL=http://localhost:8092

NOMINATIM_USER_AGENT=SharingBridge-Local/1.0 (you@example.com)
```

Install and run:

```powershell
python3.13 -m venv .venv
.\.venv\Scripts\Activate.ps1
pip install -r requirements.txt
uvicorn app.main:app --host 0.0.0.0 --port 8091
```

### 3c. Integration service

In `sharingbridge-integration-service/.env`:

```env
AI_ORCHESTRATION_BASE_URL=http://localhost:8091
AI_SUGGEST_VENDORS_ENABLED=true
AI_INSTRUCTION_PACK_ENABLED=true
```

Restart integration-service after changes.

### 3d. Mobile (Flutter)

Point at integration + photo service:

```powershell
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8080 `
  --dart-define=PHOTO_SERVICE_BASE_URL=http://10.0.2.2:8092
```

(Use your machine LAN IP instead of `10.0.2.2` on a physical device.)

---

## 4. Render / production

Set the same variables on each Render service:

**ai-orchestration**

| Variable | Value |
|----------|-------|
| `AI_LLM_MODE` | `live` |
| `GROQ_API_KEY` | secret |
| `GEMINI_API_KEY` | secret |
| `PHOTO_SERVICE_BASE_URL` | `https://<photo-service>.onrender.com` |
| `NOMINATIM_USER_AGENT` | `SharingBridge/1.0 (ops@yourdomain.org)` |

**integration-service**

| Variable | Value |
|----------|-------|
| `AI_ORCHESTRATION_BASE_URL` | `https://<ai-orchestration>.onrender.com` |
| `AI_SUGGEST_VENDORS_ENABLED` | `true` |
| `AI_INSTRUCTION_PACK_ENABLED` | `true` |
| `AI_ORCHESTRATION_SUGGEST_VENDORS_TIMEOUT_MS` | `15000` |
| `AI_ORCHESTRATION_INSTRUCTION_PACK_TIMEOUT_MS` | `60000` |

Also set on **ai-orchestration**: `GEMINI_VISION_MODEL=gemini-2.5-flash` (`gemini-2.0-flash` shut down June 2026).

Redeploy both services after saving env.

---

## 5. Verify live AI

### 5a. Health / config (orchestration)

With orchestration running:

```powershell
curl http://localhost:8091/health
```

Check logs on startup: live mode should load Groq/Gemini clients without “missing API key” warnings.

### 5b. Suggest vendors

```powershell
curl -X POST http://localhost:8080/api/donor/suggest-vendors `
  -H "Content-Type: application/json" `
  -d '{"query_text":"vegetarian meals near T Nagar","manual_area":"Chennai"}'
```

**Live success:** JSON includes `"source": "groq"` (or similar live value).  
**Template:** `"source": "deterministic"` or `"mock"` → check `AI_LLM_MODE` and keys.

### 5c. Instruction pack (with GPS + optional photo)

After uploading a reference photo from the mobile app (or POST to photo-service), call integration instruction-pack with `lat`, `lng`, and `reference_photo_thumbnail_url`.

**Live success:** `"source": "groq+gemini"` when photo URL present; `"source": "groq"` without photo.  
Fields `location_description`, `image_description`, `seeker_appearance_hints` may be populated.

### 5d. Mobile UI

- **Vendor presets** → search → if not live, amber banner explains sample/demo mode.
- **Help a seeker** → after generating instructions → same banner when not live.

No banner when `source` is `groq`, `groq+gemini`, or `gemini`.

---

## 6. Diagnose where the break is (Render logs + health)

Today there is **no secret logging**. Use **non-secret config snapshots** and **request-path log lines** to see which hop failed.

### 6a. On deploy — startup config (no API keys)

Default log level is **`warn`** (`LOG_LEVEL=warn`) on **all four backend APIs** (user-service, integration-service, ai-orchestration, photo-service). Set the same value on each Render service for consistent behaviour. Startup prints **only misconfiguration warnings**, not a full config dump.

**Do not use `LOG_LEVEL=info` on ai-orchestration in production** unless debugging briefly — at `info`, third-party HTTP loggers may print full outbound URLs. Our code logs only safe lines like `[gemini] vision request model=gemini-2.5-flash` (no API keys). Gemini auth uses the `x-goog-api-key` header, not query strings.

After each service deploys, open **Render → service → Logs** and look for:

```text
[startup] config issues: ["AI_SUGGEST_VENDORS_ENABLED=true but orchestration URL is missing"]
```

Or, with `LOG_LEVEL=info`:

```text
[startup] config {"service":"integration-service",...,"ai":{"orchestration_base_url_set":true,...}}
```

**integration-service** startup should show:

| Field | Must be |
|-------|---------|
| `ai.orchestration_base_url_set` | `true` |
| `ai.orchestration_host` | your ai-orchestration hostname |
| `ai.suggest_vendors_flag` | `true` |
| `ai.suggest_vendors_path_active` | `true` |
| `ai.internal_api_key_set` | `true` if ai-orchestration requires a key |

**ai-orchestration** startup should show:

| Field | Must be |
|-------|---------|
| `llm_mode` | `live` |
| `live_llm_enabled` | `true` |
| `groq_configured` | `true` |
| `gemini_configured` | `true` (for photo flows) |

### 6b. Any time — `GET /health` (safe JSON)

```powershell
curl https://<integration-host>.onrender.com/health
curl https://<ai-orchestration-host>.onrender.com/health
```

Integration `/health` includes an `ai` block (same flags as startup). Orchestration `/health` includes `config` (mode + whether keys are set, not the keys themselves).

### 6c. After a mobile “Suggest vendors” — integration logs

Trigger one search, then filter integration logs for `suggest-vendors`:

| Log line | Meaning |
|----------|---------|
| `using mock catalog: AI_ORCHESTRATION_BASE_URL is unset` | Integration env not wired (or old deploy) |
| `using mock catalog: AI_SUGGEST_VENDORS_ENABLED is not true` | Flag off on integration |
| `orchestration failed status=401` | `AI_ORCHESTRATION_INTERNAL_API_KEY` mismatch |
| `orchestration failed code=timeout` | Instruction-pack exceeded timeout (often after enabling live Gemini vision) | Set `AI_ORCHESTRATION_INSTRUCTION_PACK_TIMEOUT_MS=60000` on **integration-service** and redeploy |
| No `location_description` / `seeker_handover_hints` at all | Mobile timed out while orchestration still running | Rebuild mobile app (35s instruction-pack timeout); check for `source: local_stub` banner |
| No `location_description` / `seeker_handover_hints` at all | Integration timed out or fell back to template | Check integration logs for `fallback_error` |
| Nominatim `HTTP 429` in ai-orchestration logs | OSM rate limit | Non-fatal — coordinates fallback used; avoid rapid retests |
| `orchestration failed code=network_error` | Bad URL or orchestration unreachable from integration |
| `orchestration failed status=429 code=rate_limited` + `Body preview: Too Many Requests` | **Render edge** throttling ai-orchestration (plain text, not JSON) | Wait **2 minutes**, try **once**; check integration logs for `[orchestration] ... retry` lines; upgrade Render plan or reduce retests; mobile waits up to 150s while integration retries |
| `orchestration failed status=429 code=invalid_json` or `rate_limited` (other bodies) | Groq/Gemini quota or upstream throttle | Check Groq/Gemini dashboards; integration retries up to 5× with 8–45s backoff |
| `orchestration returned non-live source=deterministic` | Reachable but `AI_LLM_MODE` not `live` on orchestration |
| *(no log line)* | Live path working — success is silent at default `LOG_LEVEL=warn` |

Mobile **“Demo catalog”** banner = integration returned `mock` or `mock_fallback` (integration never got a good orchestration response).

### 6d. API response `source` (quick check)

```powershell
curl -X POST https://<integration-host>.onrender.com/v1/donor-setup/suggest-vendors `
  -H "Content-Type: application/json" `
  -H "Authorization: Bearer <donor-jwt>" `
  -d '{"query_text":"vegetarian meals","location_precision":"manual_area","manual_area":"Chennai"}'
```

Inspect `"source"` in the JSON body (same mapping as §6c).

### 6e. After “Generate instructions” — ai-orchestration logs (safe)

With `LOG_LEVEL=info` (debugging only), each instruction-pack request prints:

```text
[instruction-pack] a1b2c3d4 start has_photo=true
[gemini] vision request model=gemini-2.5-flash
[groq] chat request model=llama-3.3-70b-versatile json=True
[instruction-pack-live] done in 18432ms source=groq+gemini vision=True has_photo=True
[instruction-pack] a1b2c3d4 done in 18432ms source=groq+gemini
```

**Duplicate calls:** count distinct `[instruction-pack] … start` lines — two starts = two end-to-end runs (e.g. mobile retried after timeout, or user tapped twice). HTTP `200` on each does not mean a single user action.

**Latency target:** under **30s** end-to-end for prod UX. Orchestration uses thumbnail-first vision, 3s Nominatim cap, geocode cache, and parallel Nominatim + Gemini. If `[instruction-pack] … done` is routinely above 30s, check Gemini/Groq latency or Nominatim 429s.

---

## 7. Troubleshooting

| Symptom | Likely cause | Fix |
|---------|--------------|-----|
| `source: deterministic` | `AI_LLM_MODE` not `live` | Set `AI_LLM_MODE=live` on orchestration |
| `source: mock` | Integration flags off or wrong `AI_ORCHESTRATION_BASE_URL` | Enable `AI_*_ENABLED`, fix URL |
| `source: mock_fallback` | Orchestration down or 5xx | Start uvicorn; check Render logs |
| `source: fallback_error` | Groq/Gemini error | Check API keys, quotas, model names |
| Mobile: `Instruction pack orchestration failed status=429` | Integration could not get JSON from ai-orchestration (rate limit / throttle) | Same as 429 row in §6c; confirm orchestration `/health` returns `llm_mode: live` |
| No `location_description` | No GPS on request, or Nominatim blocked | Grant location on mobile; set `NOMINATIM_USER_AGENT` |
| No `image_description` | No photo URL, Gemini key, or deprecated model | Upload photo; set `GEMINI_API_KEY`; use `GEMINI_VISION_MODEL=gemini-2.5-flash` (not `gemini-2.0-flash`, shut down June 2026) |
| Mobile banner always shows | Still on deterministic/mock path | Complete steps in §3–§5 |

---

## 8. Cost and safety notes

- Groq and Gemini bill/quote per token; use `deterministic` for automated tests and demos without spend.
- Never commit `.env` files or paste keys into chat/logs.
- Rotate keys if exposed.

---

## See also

- [ai-orchestration-local.md](./ai-orchestration-local.md) — venv and uvicorn on Windows
- [service-startup.md](./service-startup.md) — FastAPI and Node boot sequence on Render
- [AI_IMPLEMENTATION_PLAN.md](../development/AI_IMPLEMENTATION_PLAN.md) — architecture and provider split
- [environment-variables.md](./environment-variables.md) — full env reference
