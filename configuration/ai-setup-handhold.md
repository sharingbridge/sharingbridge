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

Default model: `gemini-2.0-flash`.

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
GEMINI_VISION_MODEL=gemini-2.0-flash

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

## 6. Troubleshooting

| Symptom | Likely cause | Fix |
|---------|--------------|-----|
| `source: deterministic` | `AI_LLM_MODE` not `live` | Set `AI_LLM_MODE=live` on orchestration |
| `source: mock` | Integration flags off or wrong `AI_ORCHESTRATION_BASE_URL` | Enable `AI_*_ENABLED`, fix URL |
| `source: mock_fallback` | Orchestration down or 5xx | Start uvicorn; check Render logs |
| `source: fallback_error` | Groq/Gemini error | Check API keys, quotas, model names |
| No `location_description` | No GPS on request, or Nominatim blocked | Grant location on mobile; set `NOMINATIM_USER_AGENT` |
| No `image_description` | No photo URL or Gemini key | Upload photo; set `GEMINI_API_KEY` and `PHOTO_SERVICE_BASE_URL` |
| Mobile banner always shows | Still on deterministic/mock path | Complete steps in §3–§5 |

---

## 7. Cost and safety notes

- Groq and Gemini bill/quote per token; use `deterministic` for automated tests and demos without spend.
- Never commit `.env` files or paste keys into chat/logs.
- Rotate keys if exposed.

---

## See also

- [ai-orchestration-local.md](./ai-orchestration-local.md) — venv and uvicorn on Windows
- [AI_IMPLEMENTATION_PLAN.md](../development/AI_IMPLEMENTATION_PLAN.md) — architecture and provider split
- [environment-variables.md](./environment-variables.md) — full env reference
