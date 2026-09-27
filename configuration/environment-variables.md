# Environment variables (all services)

**Master index** — the only place with full per-service tables. Other configuration docs link here instead of repeating keys. Each repo also has `env.example` → copy to `.env` (gitignored).

Tables are sorted **A–Z by variable name** to match Render’s environment UI.

| Service | Config file | Load when |
|---------|-------------|-----------|
| ai-orchestration | `sharingbridge-ai-orchestration/.env` | `uvicorn` |
| integration-service | `sharingbridge-integration-service/.env` | export vars then `mvn spring-boot:run` |
| mobile-app | `--dart-define=…` on `flutter run` | compile time (no `.env` in repo) |
| notification-service | `sharingbridge-notification-service/.env` (export into shell) | `mvn spring-boot:run` |
| photo-service | `sharingbridge-photo-service/.env` | `uvicorn` / pytest |
| user-service | `sharingbridge-user-service/.env` (export into shell) or IDE env | `dotnet run --project src/SharingBridge.UserService` |
| web-app | `sharingbridge-web-app/.env` | `npm run dev` / **build** (`VITE_*` baked into `dist/`) |

**Must match across services:** `DATABASE_URL` (Postgres), `AUTH_TOKEN_SECRET` (+ issuer/audience), `WEB_CORS_ORIGINS` (user-service **and** integration-service, same string), web `VITE_INTG_SRVC_BASE_URL` = mobile `INTG_SRVC_BASE_URL` (same integration-service host), web static site URL = mobile `WEB_DASHBOARD_URL`.

**Initiator feed window and radius:** set only on **integration-service** (`DONOR_NEIGHBOURHOOD_WINDOW_HOURS`, `DONOR_NEIGHBOURHOOD_RADIUS_M` in **metres**). Web and mobile read `feed.radius_m` / `neighbourhood.radius_m` from the list API. Per-row distance on the dashboard is **`distance_m`** (metres). See [PRODUCT_MODEL.md](../development/PRODUCT_MODEL.md).

**Spatial schema (integration-service only):** **`GIS_SCHEMA`** is **required** — must match [schema-spatial-bootstrap.sql](./schema-spatial-bootstrap.sql) (use `extensions` on Supabase).

Render deploy details: [backend-render.md](./backend-render.md). Auth secrets: [authentication.md](./authentication.md). DB: [database.md](./database.md).

---

## `LOG_LEVEL` (all backend APIs)

Set the **same value** on all five Render Web Services if you want consistent verbosity:

| Service | Supports `LOG_LEVEL` |
|---------|----------------------|
| `sharingbridge-ai-orchestration` | Yes |
| `sharingbridge-integration-service` | Yes |
| `sharingbridge-notification-service` | Yes |
| `sharingbridge-photo-service` | Yes |
| `sharingbridge-user-service` | Yes |
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
| `DATABASE_URL` | same | Postgres (Supabase in prod). For **long-lived** API processes prefer **session** pooler (`*.pooler.supabase.com:5432`). Transaction mode (`:6543`) suits serverless; Npgsql/.NET hung on `:6543` — see [Database client pool & retry](#database-client-pool--retry-standard). |
| `WEB_CORS_ORIGINS` | user-service, integration-service | Browser origin(s) of the dashboard, **comma-separated** (never semicolons), e.g. `http://localhost:5173` — **not** the API URL. Production includes custom domains: `https://sharingbridge.org,https://www.sharingbridge.org,https://<static-site>.onrender.com` |

---

## Database client pool & retry (standard)

**Shipped first on** `sharingbridge-user-service` (C# / Npgsql). **Apply the same env contract** when hardening or rewriting other Postgres clients (`integration-service`, `photo-service`, `notification-service`).

| Variable | Default | Purpose |
|----------|---------|---------|
| `DB_COMMAND_TIMEOUT_SECONDS` | `30` | Query / command timeout |
| `DB_CONNECTION_IDLE_LIFETIME_SECONDS` | `60` | Drop idle pooled connections after N seconds |
| `DB_POOL_MAX` | `5` | Max pooled connections (keep modest on free tier) |
| `DB_POOL_MIN` | `0` | Min pooled connections |
| `DB_POOLING` | `true` | Client-side connection pooling on/off |
| `DB_RETRY_BASE_DELAY_MS` | `200` | Backoff base (`delay ≈ base × attempt²`) |
| `DB_RETRY_MAX_ATTEMPTS` | `3` | Transient DB retries (timeouts / stream errors) |
| `DB_SUPABASE_POOL_6543_4TR_5432_4SESN` | `5432` | (.NET) On `*.pooler.supabase.com`: `5432` \| `6543` only; other values fail startup |
| `DB_TIMEOUT_SECONDS` | `30` | Connect timeout |

**Rollout:**

| Service | Today | Next step |
|---------|--------|-----------|
| user-service (C#) | **Done** — reads these env vars; `GET /health` → `config.data_access` | Keep defaults unless tuning |
| notification-service (Spring) | **Done** — reads these env vars; `GET /health` → `config.data_access` | Keep defaults unless tuning |
| photo-service (Python) | App-specific | Align naming when next DB hardening pass |
| integration-service (Spring) | **Done** — Hikari reads `DB_*`; Render Docker | Keep defaults unless tuning |

Do **not** put passwords or full URIs in these knobs — only pool/retry behaviour. Connection identity stays in `DATABASE_URL`.

---

## `sharingbridge-user-service`

**Template:** `sharingbridge-user-service/.env.example` → copy to `.env`.  
**Run:** export vars into the shell / IDE, then `dotnet run --project src/SharingBridge.UserService` (ASP.NET does not load `.env` automatically — [backend-render.md § Local .env](./backend-render.md#local-env-not-used-on-render)).

| Variable | Local example | Render production |
|----------|---------------|-------------------|
| `AUTH_TOKEN_AUDIENCE` | `sharingbridge-clients` | same |
| `AUTH_TOKEN_ISSUER` | `sharingbridge-user-service` | same |
| `AUTH_TOKEN_SECRET` | shared secret | generated, same on integration + photo |
| `AUTH_TOKEN_TTL_SECONDS` | `3600` | `3600` |
| `DATABASE_URL` | `postgresql://…@localhost:5432/sharingbridge` | Supabase URI (session pooler `:5432` preferred for .NET) |
| `DB_COMMAND_TIMEOUT_SECONDS` | `30` | Query timeout |
| `DB_CONNECTION_IDLE_LIFETIME_SECONDS` | `60` | Drop idle pooled connections after N seconds |
| `DB_POOL_MAX` | `5` | Max pooled connections (keep modest on free tier) |
| `DB_POOL_MIN` | `0` | Min pooled connections |
| `DB_POOLING` | `true` | Client connection pooling on/off |
| `DB_RETRY_BASE_DELAY_MS` | `200` | Base backoff for retries (`delay = base * attempt²`) |
| `DB_RETRY_MAX_ATTEMPTS` | `3` | Transient DB retries on Google sign-in path |
| `DB_SUPABASE_POOL_6543_4TR_5432_4SESN` | `5432` | On `*.pooler.supabase.com`, force pooler port: **`5432`** (session, default when unset) or **`6543`** (transaction). Any other value fails startup. |
| `DB_TIMEOUT_SECONDS` | `30` | Connect timeout |
| `GOOGLE_CLIENT_ID_ANDROID` | Android OAuth client ID | when mobile uses Google |
| `GOOGLE_CLIENT_ID_WEB` | Web OAuth client ID | same as `VITE_GOOGLE_CLIENT_ID` |
| `LOG_LEVEL` | `warn` | `error`, `warn`, `info`, or `debug` — see [LOG_LEVEL](#log_level-all-backend-apis) |
| `PORT` | `8081` | injected by Render — do not set |
| `WEB_CORS_ORIGINS` | `http://localhost:5173` | `https://sharingbridge.org,https://www.sharingbridge.org,…` |

---

## `sharingbridge-integration-service`

| Variable | Local example | Render production |
|----------|---------------|-------------------|
| `AI_INSTRUCTION_PACK_ENABLED` | `true` | `true` |
| `AI_ORCHESTRATION_BASE_URL` | `http://localhost:8091` | `https://<ai-host>.onrender.com` |
| `AI_ORCHESTRATION_INSTRUCTION_PACK_RETRY_MAX_ATTEMPTS` | `5` | overrides default for instruction-pack only |
| `AI_ORCHESTRATION_INSTRUCTION_PACK_TIMEOUT_MS` | `60000` | `60000` — instruction-pack only (Nominatim + Gemini vision + Groq) |
| `AI_ORCHESTRATION_INTERNAL_API_KEY` | shared with ai-orchestration | same |
| `AI_ORCHESTRATION_RETRY_BASE_DELAY_MS` | `8000` | backoff step for instruction-pack retries |
| `AI_ORCHESTRATION_RETRY_MAX_ATTEMPTS` | `5` | default retries on 429/502/503 for all orchestration routes |
| `AI_ORCHESTRATION_RETRY_MAX_DELAY_MS` | `45000` | max wait between retries |
| `AI_ORCHESTRATION_SUGGEST_VENDORS_RETRY_MAX_ATTEMPTS` | — | overrides default for suggest-vendors only |
| `AI_ORCHESTRATION_SUGGEST_VENDORS_TIMEOUT_MS` | `15000` | `15000` — suggest-vendors only |
| `AI_SUGGEST_VENDORS_ENABLED` | `true` | `true` |
| `AUTH_TOKEN_AUDIENCE` | `sharingbridge-clients` | same |
| `AUTH_TOKEN_ISSUER` | `sharingbridge-user-service` | same |
| `AUTH_TOKEN_SECRET` | **same** as user-service | same |
| `CONNECTION_NOTIFY_WEBHOOK_SECRET` | *(unset)* | Shared secret sent as `X-Webhook-Secret` — must match notification-service `WEBHOOK_SECRET` |
| `CONNECTION_NOTIFY_WEBHOOK_URL` | *(unset)* | Optional — POST JSON when eco kitchen commits (`connection_ready`); for notification-service or mailer |
| `DATABASE_URL` | **same** as user-service | same — prefer Supabase **session** pooler (`:5432`) for this long-lived process |
| `DB_COMMAND_TIMEOUT_SECONDS` | `30` | Query timeout — [shared standard](#database-client-pool--retry-standard) |
| `DB_CONNECTION_IDLE_LIFETIME_SECONDS` | `60` | Drop idle pooled connections after N seconds |
| `DB_POOL_MAX` | `5` | Max pooled connections |
| `DB_POOL_MIN` | `0` | Min pooled connections |
| `DB_POOLING` | `true` | Client connection pooling on/off |
| `DB_RETRY_BASE_DELAY_MS` | `200` | Backoff base |
| `DB_RETRY_MAX_ATTEMPTS` | `3` | Transient DB retries |
| `DB_SUPABASE_POOL_6543_4TR_5432_4SESN` | `5432` | `5432` \| `6543` only; other values fail startup |
| `DB_TIMEOUT_SECONDS` | `30` | Connect timeout |
| `GEOCODER_PROVIDER` | *(unset — implicit `nominatim`)* | **Reserved** — future switch for reverse-geocode backend; v1 always Nominatim. See [Location_Services_Vendor_Abstraction.md](../design/Location_Services_Vendor_Abstraction.md) |
| `GIS_SCHEMA` | `extensions` | **Required.** Spatial extension schema — must match [schema-spatial-bootstrap.sql](./schema-spatial-bootstrap.sql) |
| `INITIATOR_NEIGHBOURHOOD_RADIUS_M` | `5000` | `5000` (`near_lat` / `near_lng` filter radius in **metres**; capped at 50000 server-side) |
| `INITIATOR_NEIGHBOURHOOD_WINDOW_HOURS` | `2` | `2` (initiator list `since`, photo redaction; 1–72) |
| `LOG_LEVEL` | `warn` | `error`, `warn`, `info`, or `debug` — see [LOG_LEVEL](#log_level-all-backend-apis) |
| `NOMINATIM_USER_AGENT` | `SharingBridge-Integration-Service/1.0` | same — GPS → postal `locality_key` (`IN:TN:600115`) via Nominatim reverse geocode |
| `ORDER_INTENT_LIST_MAX_ROWS` | `100` | `100` (max rows per dashboard list) |
| `PORT` | `8080` | injected by Render — do not set |
| `USER_SERVICE_BASE_URL` | `http://localhost:8081` (required) | `https://<user-host>.onrender.com` — initiator vendor presets in Postgres |
| `WEB_CORS_ORIGINS` | **same string** as user-service | same |

---

## `sharingbridge-notification-service`

**Runtime:** Spring Boot 3 / Java 21 (Docker on Render).  
**Template:** `.env.example` → `.env`, then export into the shell before `mvn spring-boot:run`.

| Variable | Local example | Render production |
|----------|---------------|-------------------|
| `DATABASE_URL` | **same** as integration-service | same — reads `device_tokens` |
| `DB_COMMAND_TIMEOUT_SECONDS` | `30` | Query timeout |
| `DB_CONNECTION_IDLE_LIFETIME_SECONDS` | `60` | Idle drop |
| `DB_POOL_MAX` | `5` | Max pooled connections |
| `DB_POOL_MIN` | `0` | Min pooled connections |
| `DB_POOLING` | `true` | Client connection pooling on/off |
| `DB_RETRY_BASE_DELAY_MS` | `200` | Backoff base |
| `DB_RETRY_MAX_ATTEMPTS` | `3` | Transient DB retries |
| `DB_SUPABASE_POOL_6543_4TR_5432_4SESN` | `5432` | `5432` \| `6543` only; other values fail startup |
| `DB_TIMEOUT_SECONDS` | `30` | Connect timeout |
| `FIREBASE_SERVICE_ACCOUNT_JSON` | *(optional locally if using PATH)* | **Preferred on Render** — paste full Admin SDK JSON from Firebase Console (see below) |
| `FIREBASE_SERVICE_ACCOUNT_PATH` | `.\firebase-adminsdk.json` | **Do not use on Render** — local `.env` only; path to downloaded Admin SDK key file |
| `LOG_LEVEL` | `warn` | `error`, `warn`, `info`, or `debug` — see [LOG_LEVEL](#log_level-all-backend-apis) |
| `PORT` | `8093` (local — photo-service uses 8092) | injected by Render |
| `WEBHOOK_SECRET` | **same** as integration `CONNECTION_NOTIFY_WEBHOOK_SECRET` | same |

**Firebase Admin credentials — set one, not both:**

| Where | Use |
|-------|-----|
| **Render** | `FIREBASE_SERVICE_ACCOUNT_JSON` only — paste the entire downloaded JSON into the env var |
| **Local** | `FIREBASE_SERVICE_ACCOUNT_PATH` pointing at the file on disk, **or** `FIREBASE_SERVICE_ACCOUNT_JSON` inline |

**How to get the JSON (not `google-services.json`):** Firebase Console → **Project settings** → **Service accounts** → **Firebase Admin SDK** → **Generate new private key**. That file is server-only; mobile uses separate `android/app/google-services.json` in the same Firebase project. Detail: [notification-service-local.md](./notification-service-local.md).

Webhook route: `POST /internal/connection-ready` — set integration `CONNECTION_NOTIFY_WEBHOOK_URL` to this URL.

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
| `DATABASE_URL` | same Postgres | same — prefer session pooler (`:5432`) |
| `DB_COMMAND_TIMEOUT_SECONDS` | `30` | **Planned** — [shared standard](#database-client-pool--retry-standard) |
| `DB_CONNECTION_IDLE_LIFETIME_SECONDS` | `60` | **Planned** |
| `DB_POOL_MAX` | `5` | **Planned** |
| `DB_POOL_MIN` | `0` | **Planned** |
| `DB_POOLING` | `true` | **Planned** |
| `DB_RETRY_BASE_DELAY_MS` | `200` | **Planned** |
| `DB_RETRY_MAX_ATTEMPTS` | `3` | **Planned** |
| `DB_SUPABASE_POOL_6543_4TR_5432_4SESN` | `5432` | **Planned** |
| `DB_TIMEOUT_SECONDS` | `30` | **Planned** |
| `LOG_LEVEL` | `warn` | `error`, `warn`, `info`, or `debug` — see [LOG_LEVEL](#log_level-all-backend-apis) |

See [photo-service-local.md](./photo-service-local.md).

---

## `sharingbridge-ai-orchestration` (optional)

| Variable | Example value | Used for |
|----------|---------------|----------|
| `AI_LLM_MODE` | `deterministic` or `live` | `deterministic` = template/mock output; `live` = real Groq + Gemini calls |
| `AI_ORCHESTRATION_INTERNAL_API_KEY` | same as integration-service | Internal service-to-service auth header (`X-Internal-Api-Key`) |
| `GEMINI_API_KEY` | `AIza...` | Gemini vision for `image_description` + `seeker_appearance_hints` |
| `GEMINI_VISION_MODEL` | `gemini-2.5-flash` | Gemini model for image analysis (`gemini-2.0-flash` shut down June 2026) |
| `GROQ_API_KEY` | `gsk_...` | Groq text generation for `suggest-vendors` (vendor preset suggestions) and instruction-pack composition |
| `GROQ_MODEL` | `openai/gpt-oss-120b` | Groq model for text paths above (`llama-3.3-70b-versatile` retired 2026-08-16 on free/dev) |
| `LOG_LEVEL` | `warn` | `error`, `warn`, `info`, or `debug` — see [LOG_LEVEL](#log_level-all-backend-apis) |
| `NOMINATIM_USER_AGENT` | `SharingBridge/1.0 (ops@yourdomain.org)` | OSM reverse geocode identification (no API key needed) |
| `PHOTO_SERVICE_BASE_URL` | `https://<photo-host>.onrender.com` | Source of signed image URLs that Gemini can fetch |
| `SHARINGBRIDGE_WEBSITE_URL` | `pending` | Courier instruction text reference only (not an API endpoint) |

`deterministic` = template/mock (not live AI). See [ai-setup-handhold.md](./ai-setup-handhold.md).

Provider split: [AI_PLAN.md](../development/AI_PLAN.md) § *Provider split*.

See [ai-orchestration-local.md](./ai-orchestration-local.md) and [ai-setup-handhold.md](./ai-setup-handhold.md).

---

## `sharingbridge-web-app` (static site / Vite)

Build-time only (`VITE_*` in `.env` before `npm run build` or `npm run dev`).

| Variable | Local example | Render production |
|----------|---------------|-------------------|
| `VITE_GOOGLE_CLIENT_ID` | Web OAuth client ID | same as `GOOGLE_CLIENT_ID_WEB` |
| `VITE_GOOGLE_MAPS_API_KEY` | optional — Maps JavaScript API | same — enables **Map** tab on dashboard |
| `VITE_INTG_SRVC_BASE_URL` | `http://localhost:8080` | `https://<integration-host>.onrender.com` |
| `VITE_USER_SERVICE_BASE_URL` | `http://localhost:8081` | `https://<user-host>.onrender.com` |

CORS is **not** set here — set `WEB_CORS_ORIGINS` on both Node backends. See [web-client.md](./web-client.md).

---

## `sharingbridge-mobile-app` (`--dart-define`)

No `.env` file — pass at **`flutter run`** / **`flutter build apk --release`** / **`flutter build appbundle --release`** (compile time). Re-run the build after changing defines (hot reload is not enough).

| Define | Local example | Production (Render) |
|--------|---------------|---------------------|
| `AUTH_TOKEN` | dev only — pre-minted JWT (`dotnet run --project tools/MintDevJwt -- <user_id> [role]` in user-service) | omit — use Google Sign-In |
| `GOOGLE_CLIENT_ID` | Android OAuth client ID from Google Cloud | same |
| `HANDOVER_MAP_ENABLED` | `true` / `false` | **Map screen vs coordinate form** — pass `true` when you want the cab-style picker (recommended). Gradle may auto-add `true` when `GOOGLE_MAPS_API_KEY` is in `local.properties` and you omit this flag; explicit `true` is always correct for map builds. |
| `INTG_SRVC_BASE_URL` | `http://10.0.2.2:8080` (emulator) or `http://<PC-LAN-IP>:8080` (phone) | `https://<integration-host>.onrender.com` — **must match** web `VITE_INTG_SRVC_BASE_URL` |
| `PHOTO_SERVICE_BASE_URL` | `http://10.0.2.2:8092` or `http://<PC-LAN-IP>:8092` | `https://<photo-host>.onrender.com` |
| `USER_ID` | dev only — pairs with `AUTH_TOKEN` | omit |
| `USER_SERVICE_BASE_URL` | `http://10.0.2.2:8081` or `http://<PC-LAN-IP>:8081` | `https://<user-host>.onrender.com` |
| `WEB_DASHBOARD_URL` | `http://10.0.2.2:5173` (emulator) or `http://<PC-LAN-IP>:5173` (phone) | `https://sharingbridge.org` (custom domain) or `https://<static-site>.onrender.com` — **required** for home-screen **Neighbourhood dashboard (web)** link |

`WEB_DASHBOARD_URL` is the deployed **sharingbridge-web-app** origin (same URL you open in the browser for the coordinator/initiator dashboard). Without it, the home tile is visible but disabled. See [mobile-client.md](./mobile-client.md).

Emulator: use `10.0.2.2` instead of `localhost`. Physical phone: PC Wi‑Fi IPv4. Map picker setup: [mobile-client.md § Handover location](./mobile-client.md#handover-location--map-picker-address-pickup-note). Vendor strategy: [Location_Services_Vendor_Abstraction.md](../design/Location_Services_Vendor_Abstraction.md).

**Google Maps API key (Android only):** `GOOGLE_MAPS_API_KEY` in `android/local.properties` — **not** in `--dart-define`. Controls **native map tiles** only.

**Map picker UI:** `--dart-define=HANDOVER_MAP_ENABLED=true` on the same `flutter run` / `flutter build` line. You need **both** the key (tiles) and `true` (map widget). `--dart-define=HANDOVER_MAP_ENABLED=false` forces the coordinate form even when a key is present.

---

## Web dashboard roles (no extra env flags)

| JWT `role` | Web UI | integration `GET /v1/order-intents` |
|------------|--------|-------------------------------------|
| `coordinator` | Full dashboard — initiator **email + id** per intent (from Postgres `users`), all reference photos; optional list filters `since`, `near_lat`/`near_lng`, `locality_key` (no default time cap) | `dashboard: "coordinator"` — includes `initiator_email` (and deprecated `donor_email`) when known |
| `initiator` | Limited dashboard — list capped to **`since=Nh`** (`DONOR_NEIGHBOURHOOD_WINDOW_HOURS`, default 2); optional `near_lat`/`near_lng`; no other initiators’ ids or emails; photos only within that window | `dashboard: "limited"` — response includes `since`, `feed`; no initiator email on others’ rows; photo URLs redacted outside window |

Google sign-in on web works for any account with `donor`/`initiator` and/or `coordinator` in `user_roles`. Users with both roles get `coordinator` on web and `initiator` on mobile.

## Local stack defaults (copy-paste)

| Repo | Key vars |
|------|----------|
| integration-service | `AUTH_TOKEN_SECRET`, `DATABASE_URL`, `GIS_SCHEMA=extensions`, `USER_SERVICE_BASE_URL=http://localhost:8081`, `WEB_CORS_ORIGINS=http://localhost:5173`, optional `CONNECTION_NOTIFY_WEBHOOK_URL=http://localhost:8093/internal/connection-ready` |
| mobile-app | `INTG_SRVC_BASE_URL`, `USER_SERVICE_BASE_URL`, `PHOTO_SERVICE_BASE_URL`, `GOOGLE_CLIENT_ID`, `WEB_DASHBOARD_URL=http://10.0.2.2:5173` (emulator) — all via `--dart-define` on `flutter run` |
| notification-service | `DATABASE_URL`, `WEBHOOK_SECRET`, `FIREBASE_SERVICE_ACCOUNT_PATH` or `FIREBASE_SERVICE_ACCOUNT_JSON` — [notification-service-local.md](./notification-service-local.md) |
| photo-service | `AUTH_TOKEN_SECRET`, `CLOUDINARY_*`, `DATABASE_URL` |
| user-service | `AUTH_TOKEN_SECRET`, `DATABASE_URL` (session pooler `:5432`), `GOOGLE_CLIENT_ID_WEB`, `WEB_CORS_ORIGINS=http://localhost:5173` — from `.env.example`; optional `DB_POOL_*` / `DB_RETRY_*` |
| web-app | `VITE_INTG_SRVC_BASE_URL`, `VITE_GOOGLE_CLIENT_ID`, `VITE_USER_SERVICE_BASE_URL` → localhost ports above |

Restart Node after `.env` changes. Re-export user-service env after `.env` edits. Restart `npm run dev` after web `VITE_*` changes. Rebuild mobile after any `--dart-define` change.
