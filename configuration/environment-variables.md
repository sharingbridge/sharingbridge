# Environment variables (all services)

**Master index** — the only place with full per-service tables. Other configuration docs link here instead of repeating keys. Each repo also has `env.example` → copy to `.env` (gitignored).

Tables are sorted **A–Z by variable name** to match Render’s environment UI.

| Service | Config file | Load when |
|---------|-------------|-----------|
| user-service | `sharingbridge-user-service/.env` | `npm start` (dotenv) |
| integration-service | `sharingbridge-integration-service/.env` | `npm start` |
| photo-service | `sharingbridge-photo-service/.env` | `uvicorn` / pytest |
| ai-orchestration | `sharingbridge-ai-orchestration/.env` | `uvicorn` |
| web-app | `sharingbridge-web-app/.env` | `npm run dev` / **build** (`VITE_*` baked into `dist/`) |
| mobile-app | `--dart-define=…` on `flutter run` | compile time (no `.env` in repo) |

**Must match across services:** `DATABASE_URL` (Postgres), `AUTH_TOKEN_SECRET` (+ issuer/audience), `WEB_CORS_ORIGINS` (user-service **and** integration-service, same string), integration `API_BASE_URL` = web `VITE_API_BASE_URL` = mobile `API_BASE_URL`, web static site URL = mobile `WEB_DASHBOARD_URL`.

**Payee feed window and radius:** set only on **integration-service** (`DONOR_NEIGHBOURHOOD_WINDOW_HOURS`, `DONOR_NEIGHBOURHOOD_RADIUS_M` in **metres**). Web and mobile read `feed.radius_m` / `neighbourhood.radius_m` from the list API. Per-row distance on the dashboard is **`distance_m`** (metres). See [PRODUCT_ROADMAP.md](../development/PRODUCT_ROADMAP.md).

Render deploy details: [backend-render.md](./backend-render.md). Auth secrets: [authentication.md](./authentication.md). DB: [database.md](./database.md).

---

## `LOG_LEVEL` (all backend APIs)

Set the **same value** on all four Render Web Services if you want consistent verbosity:

| Service | Supports `LOG_LEVEL` |
|---------|----------------------|
| `sharingbridge-user-service` | Yes |
| `sharingbridge-integration-service` | Yes |
| `sharingbridge-ai-orchestration` | Yes |
| `sharingbridge-photo-service` | Yes |
| web-app, mobile-app | No (no server runtime logs) |

| Value | What you see in Render logs |
|-------|----------------------------|
| `warn` (default) | **Warnings/errors only** — startup misconfig, AI mock/fallback, orchestration failures |
| `error` | Errors only |
| `info` | Above + `[startup] config {…}` full non-secret snapshot + “listening on port” |
| `debug` | Same as `info` today (reserved for finer traces later) |

**Secrets are never logged.** Use `GET /health` on any backend for a non-secret `config` / `log_level` snapshot anytime. See [ai-setup-handhold.md](./ai-setup-handhold.md) §6.

---

## Shared (multiple services)

| Variable | Used on | Purpose |
|----------|---------|---------|
| `AUTH_TOKEN_AUDIENCE` | user-service, integration-service, photo-service | `sharingbridge-clients` |
| `AUTH_TOKEN_ISSUER` | same | `sharingbridge-user-service` |
| `AUTH_TOKEN_SECRET` | same | HS256 JWT signing — **same value** on all three |
| `DATABASE_URL` | same | Postgres (Supabase in prod) |
| `WEB_CORS_ORIGINS` | user-service, integration-service | Browser origin(s) of the dashboard, e.g. `http://localhost:5173` — **not** the API URL |

---

## `sharingbridge-user-service`

| Variable | Local example | Render production |
|----------|---------------|-------------------|
| `AUTH_TOKEN_AUDIENCE` | `sharingbridge-clients` | same |
| `AUTH_TOKEN_ISSUER` | `sharingbridge-user-service` | same |
| `AUTH_TOKEN_SECRET` | shared secret | generated, same on integration + photo |
| `AUTH_TOKEN_TTL_SECONDS` | `3600` | `3600` |
| `DATABASE_URL` | `postgresql://…@localhost:5432/sharingbridge` | Supabase URI |
| `GOOGLE_CLIENT_ID_ANDROID` | Android OAuth client ID | when mobile uses Google |
| `GOOGLE_CLIENT_ID_WEB` | Web OAuth client ID | same as `VITE_GOOGLE_CLIENT_ID` |
| `LOG_LEVEL` | `warn` | `error`, `warn`, `info`, or `debug` — see [LOG_LEVEL](#log_level-all-backend-apis) |
| `PORT` | `8081` | injected by Render — do not set |
| `WEB_CORS_ORIGINS` | `http://localhost:5173` | `https://<static-site>.onrender.com` |

---

## `sharingbridge-integration-service`

| Variable | Local example | Render production |
|----------|---------------|-------------------|
| `AI_INSTRUCTION_PACK_ENABLED` | `true` | `true` |
| `AI_ORCHESTRATION_BASE_URL` | `http://localhost:8091` | `https://<ai-host>.onrender.com` |
| `AI_ORCHESTRATION_INTERNAL_API_KEY` | shared with ai-orchestration | same |
| `AI_ORCHESTRATION_SUGGEST_VENDORS_TIMEOUT_MS` | `15000` | `15000` — suggest-vendors only |
| `AI_ORCHESTRATION_INSTRUCTION_PACK_TIMEOUT_MS` | `60000` | `60000` — instruction-pack only (Nominatim + Gemini vision + Groq) |
| `AI_ORCHESTRATION_RETRY_MAX_ATTEMPTS` | `5` | default retries on 429/502/503 for all orchestration routes |
| `AI_ORCHESTRATION_SUGGEST_VENDORS_RETRY_MAX_ATTEMPTS` | — | overrides default for suggest-vendors only |
| `AI_ORCHESTRATION_INSTRUCTION_PACK_RETRY_MAX_ATTEMPTS` | `5` | overrides default for instruction-pack only |
| `AI_ORCHESTRATION_RETRY_BASE_DELAY_MS` | `8000` | backoff step for instruction-pack retries |
| `AI_ORCHESTRATION_RETRY_MAX_DELAY_MS` | `45000` | max wait between retries |
| `AI_SUGGEST_VENDORS_ENABLED` | `true` | `true` |
| `AI_MOCK_FALLBACK_ENABLED` | `true` (local dev) | **unset** — production returns HTTP 503 when orchestration fails |
| `AUTH_TOKEN_AUDIENCE` | `sharingbridge-clients` | same |
| `AUTH_TOKEN_ISSUER` | `sharingbridge-user-service` | same |
| `AUTH_TOKEN_SECRET` | **same** as user-service | same |
| `DATABASE_URL` | **same** as user-service | same |
| `INITIATOR_NEIGHBOURHOOD_RADIUS_M` | `5000` | `5000` (`near_lat` / `near_lng` filter radius in **metres**; capped at 50000 server-side) |
| `INITIATOR_NEIGHBOURHOOD_WINDOW_HOURS` | `2` | `2` (initiator list `since`, photo redaction; 1–72) |
| `NOMINATIM_USER_AGENT` | `SharingBridge-Integration-Service/1.0` | same — GPS → postal `locality_key` (`IN:TN:600115`) via reverse geocode |
| `LOG_LEVEL` | `warn` | `error`, `warn`, `info`, or `debug` — see [LOG_LEVEL](#log_level-all-backend-apis) |
| `ORDER_INTENT_LIST_MAX_ROWS` | `100` | `100` (max rows per dashboard list) |
| `PORT` | `8080` | injected by Render — do not set |
| `USER_SERVICE_BASE_URL` | `http://localhost:8081` (required) | `https://<user-host>.onrender.com` — payee presets in Postgres |
| `WEB_CORS_ORIGINS` | **same string** as user-service | same |

---

## `sharingbridge-photo-service`

| Variable | Local example | Render production |
|----------|---------------|-------------------|
| `AUTH_TOKEN_AUDIENCE` | `sharingbridge-clients` | same |
| `AUTH_TOKEN_ISSUER` | `sharingbridge-user-service` | same |
| `AUTH_TOKEN_SECRET` | same JWT secret | same |
| `CLOUDINARY_API_KEY` | from [Cloudinary console](https://cloudinary.com/console) | required |
| `CLOUDINARY_API_SECRET` | | required |
| `CLOUDINARY_CLOUD_NAME` | | required |
| `CLOUDINARY_URL` | optional alternative to the three keys above | `cloudinary://…` |
| `DATABASE_URL` | same Postgres | same |
| `LOG_LEVEL` | `warn` | `error`, `warn`, `info`, or `debug` — see [LOG_LEVEL](#log_level-all-backend-apis) |

See [photo-service-local.md](./photo-service-local.md).

---

## `sharingbridge-ai-orchestration` (optional)

| Variable | Example value | Used for |
|----------|---------------|----------|
| `AI_LLM_MODE` | `deterministic` or `live` | `deterministic` = template/mock output; `live` = real Groq + Gemini calls |
| `AI_ORCHESTRATION_INTERNAL_API_KEY` | same as integration-service | Internal service-to-service auth header (`X-Internal-Api-Key`) |
| `GROQ_API_KEY` | `gsk_...` | Groq text generation for `suggest-vendors` (vendor preset suggestions) and instruction-pack composition |
| `GROQ_MODEL` | `llama-3.3-70b-versatile` | Groq model for text paths above |
| `GEMINI_API_KEY` | `AIza...` | Gemini vision for `image_description` + `seeker_appearance_hints` |
| `GEMINI_VISION_MODEL` | `gemini-2.5-flash` | Gemini model for image analysis (`gemini-2.0-flash` shut down June 2026) |
| `PHOTO_SERVICE_BASE_URL` | `https://<photo-host>.onrender.com` | Source of signed image URLs that Gemini can fetch |
| `NOMINATIM_USER_AGENT` | `SharingBridge/1.0 (ops@yourdomain.org)` | OSM reverse geocode identification (no API key needed) |
| `SHARINGBRIDGE_WEBSITE_URL` | `pending` | Courier instruction text reference only (not an API endpoint) |
| `LOG_LEVEL` | `warn` | `error`, `warn`, `info`, or `debug` — see [LOG_LEVEL](#log_level-all-backend-apis) |

`deterministic` = template/mock (not live AI). See [ai-setup-handhold.md](./ai-setup-handhold.md).

Provider split: [AI_IMPLEMENTATION_PLAN.md](../development/AI_IMPLEMENTATION_PLAN.md) § *Provider split*.

See [ai-orchestration-local.md](./ai-orchestration-local.md) and [ai-setup-handhold.md](./ai-setup-handhold.md).

---

## `sharingbridge-web-app` (static site / Vite)

Build-time only (`VITE_*` in `.env` before `npm run build` or `npm run dev`).

| Variable | Local example | Render production |
|----------|---------------|-------------------|
| `VITE_API_BASE_URL` | `http://localhost:8080` | `https://<integration-host>.onrender.com` |
| `VITE_GOOGLE_CLIENT_ID` | Web OAuth client ID | same as `GOOGLE_CLIENT_ID_WEB` |
| `VITE_USER_SERVICE_BASE_URL` | `http://localhost:8081` | `https://<user-host>.onrender.com` |
| `VITE_GOOGLE_MAPS_API_KEY` | optional — Maps JavaScript API | same — enables **Map** tab on dashboard |

CORS is **not** set here — set `WEB_CORS_ORIGINS` on both Node backends. See [web-client.md](./web-client.md).

---

## `sharingbridge-mobile-app` (`--dart-define`)

No `.env` file — pass at **`flutter run`** / release build (compile time). Re-run `flutter run` after changing defines (hot reload is not enough).

| Define | Local example | Production (Render) |
|--------|---------------|---------------------|
| `API_BASE_URL` | `http://10.0.2.2:8080` (emulator) or `http://<PC-LAN-IP>:8080` (phone) | `https://<integration-host>.onrender.com` — **must match** web `VITE_API_BASE_URL` |
| `AUTH_TOKEN` | dev only — pre-minted JWT (`node scripts/mint-dev-jwt.mjs` in user-service) | omit — use Google Sign-In |
| `GOOGLE_CLIENT_ID` | Android OAuth client ID from Google Cloud | same |
| `PHOTO_SERVICE_BASE_URL` | `http://10.0.2.2:8092` or `http://<PC-LAN-IP>:8092` | `https://<photo-host>.onrender.com` |
| `USER_ID` | dev only — pairs with `AUTH_TOKEN` | omit |
| `USER_SERVICE_BASE_URL` | `http://10.0.2.2:8081` or `http://<PC-LAN-IP>:8081` | `https://<user-host>.onrender.com` |
| `WEB_DASHBOARD_URL` | `http://10.0.2.2:5173` (emulator) or `http://<PC-LAN-IP>:5173` (phone) | `https://<static-site>.onrender.com` — **required** for home-screen **Neighbourhood dashboard (web)** link |

`WEB_DASHBOARD_URL` is the deployed **sharingbridge-web-app** origin (same URL you open in the browser for the payee/coordinator dashboard). Without it, the home tile is visible but disabled. See [mobile-client.md](./mobile-client.md).

Emulator: use `10.0.2.2` instead of `localhost`. Physical phone: PC Wi‑Fi IPv4. See [mobile-client.md](./mobile-client.md).

---

## Web dashboard roles (no extra env flags)

| JWT `role` | Web UI | integration `GET /v1/donor-seeker/order-intents` |
|------------|--------|--------------------------------------------------|
| `coordinator` | Full dashboard — payee **email + id** per intent (from Postgres `users`), all reference photos; optional list filters `since`, `near_lat`/`near_lng`, `locality_key` (no default time cap) | `dashboard: "coordinator"` — includes `donor_email` when known |
| `payee` | Limited dashboard — list capped to **`since=Nh`** (`DONOR_NEIGHBOURHOOD_WINDOW_HOURS`, default 2); optional `near_lat`/`near_lng`; no other payees’ ids or emails; photos only within that window | `dashboard: "limited"` — response includes `since`, `feed`; no `donor_email`; photo URLs redacted outside window |

Google sign-in on web works for any account with `payee` and/or `coordinator` in `user_roles`. Users with both roles get `coordinator` on web and `payee` on mobile.

## Local stack defaults (copy-paste)

| Repo | Key vars |
|------|----------|
| integration-service | `AUTH_TOKEN_SECRET`, `DATABASE_URL`, `USER_SERVICE_BASE_URL=http://localhost:8081`, `WEB_CORS_ORIGINS=http://localhost:5173` |
| photo-service | `AUTH_TOKEN_SECRET`, `CLOUDINARY_*`, `DATABASE_URL` |
| user-service | `AUTH_TOKEN_SECRET`, `DATABASE_URL`, `GOOGLE_CLIENT_ID_WEB`, `WEB_CORS_ORIGINS=http://localhost:5173` |
| web-app | `VITE_API_BASE_URL`, `VITE_GOOGLE_CLIENT_ID`, `VITE_USER_SERVICE_BASE_URL` → localhost ports above |
| mobile-app | `API_BASE_URL`, `USER_SERVICE_BASE_URL`, `PHOTO_SERVICE_BASE_URL`, `GOOGLE_CLIENT_ID`, `WEB_DASHBOARD_URL=http://10.0.2.2:5173` (emulator) — all via `--dart-define` on `flutter run` |

Restart Node after `.env` changes. Restart `npm run dev` after web `VITE_*` changes. Rebuild mobile after any `--dart-define` change.
