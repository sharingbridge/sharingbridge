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

**Must match across services:** `DATABASE_URL` (Postgres), `AUTH_TOKEN_SECRET` (+ issuer/audience), `WEB_CORS_ORIGINS` (user-service **and** integration-service, same string), integration `API_BASE_URL` = web `VITE_API_BASE_URL` = mobile `API_BASE_URL`.

**Donor feed window and radius:** set only on **integration-service** (`DONOR_NEIGHBOURHOOD_WINDOW_HOURS`, `DONOR_NEIGHBOURHOOD_RADIUS_KM`). Web and mobile read applied values from the list API response (`feed`, `since`, `neighbourhood`). List geo filters use **PostGIS** (`ST_DWithin` on `order_intents.location`) when the DB has the MVP geo columns — [database.md](./database.md). Dashboard columns and sort: [PRODUCT_ROADMAP.md](../development/PRODUCT_ROADMAP.md).

Render deploy details: [backend-render.md](./backend-render.md). Auth secrets: [authentication.md](./authentication.md). DB: [database.md](./database.md).

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
| `PORT` | `8081` | injected by Render — do not set |
| `WEB_CORS_ORIGINS` | `http://localhost:5173` | `https://<static-site>.onrender.com` |

---

## `sharingbridge-integration-service`

| Variable | Local example | Render production |
|----------|---------------|-------------------|
| `AI_INSTRUCTION_PACK_ENABLED` | `true` | `true` |
| `AI_ORCHESTRATION_BASE_URL` | `http://localhost:8091` | `https://<ai-host>.onrender.com` |
| `AI_ORCHESTRATION_INTERNAL_API_KEY` | shared with ai-orchestration | same |
| `AI_ORCHESTRATION_TIMEOUT_MS` | `15000` | `15000` |
| `AI_SUGGEST_VENDORS_ENABLED` | `true` | `true` |
| `AUTH_TOKEN_AUDIENCE` | `sharingbridge-clients` | same |
| `AUTH_TOKEN_ISSUER` | `sharingbridge-user-service` | same |
| `AUTH_TOKEN_SECRET` | **same** as user-service | same |
| `DATABASE_URL` | **same** as user-service | same |
| `DONOR_LOCALITY_GRID_DECIMALS` | `2` | `2` (locality_key grid; 1–4) |
| `DONOR_NEIGHBOURHOOD_RADIUS_KM` | `5` | `5` (`near_lat` / `near_lng` filter radius in **km**; per-row **`distance_m`** in API is **metres**) |
| `DONOR_NEIGHBOURHOOD_WINDOW_HOURS` | `2` | `2` (donor list `since`, photo redaction; 1–72) |
| `ORDER_INTENT_LIST_MAX_ROWS` | `100` | `100` (**planned** — not enforced in code yet; max rows per list) |
| `PORT` | `8080` | injected by Render — do not set |
| `USER_SERVICE_BASE_URL` | `http://localhost:8081` (required) | `https://<user-host>.onrender.com` — donor presets in Postgres |
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

See [photo-service-local.md](./photo-service-local.md).

---

## `sharingbridge-ai-orchestration` (optional)

| Variable | Typical value |
|----------|----------------|
| `AI_LLM_MODE` | `deterministic` (MVP) |
| `AI_ORCHESTRATION_INTERNAL_API_KEY` | same as integration-service |
| `OPENAI_API_KEY` | omit for MVP |
| `SHARINGBRIDGE_WEBSITE_URL` | `pending` |

See [ai-orchestration-local.md](./ai-orchestration-local.md).

---

## `sharingbridge-web-app` (static site / Vite)

Build-time only (`VITE_*` in `.env` before `npm run build` or `npm run dev`).

| Variable | Local example | Render production |
|----------|---------------|-------------------|
| `VITE_API_BASE_URL` | `http://localhost:8080` | `https://<integration-host>.onrender.com` |
| `VITE_GOOGLE_CLIENT_ID` | Web OAuth client ID | same as `GOOGLE_CLIENT_ID_WEB` |
| `VITE_USER_SERVICE_BASE_URL` | `http://localhost:8081` | `https://<user-host>.onrender.com` |

CORS is **not** set here — set `WEB_CORS_ORIGINS` on both Node backends. See [web-client.md](./web-client.md).

---

## `sharingbridge-mobile-app` (`--dart-define`)

No `.env` file — pass at `flutter run`:

| Define | Purpose |
|--------|---------|
| `API_BASE_URL` | integration-service — **must match** web `VITE_API_BASE_URL` for same data |
| `AUTH_TOKEN` | dev only — pre-minted JWT (`node scripts/mint-dev-jwt.mjs` in user-service with same `AUTH_TOKEN_SECRET`) |
| `GOOGLE_CLIENT_ID` | Android OAuth client ID |
| `PHOTO_SERVICE_BASE_URL` | photo-service (optional, for reference photos) |
| `USER_ID` | dev only — pairs with `AUTH_TOKEN` |
| `USER_SERVICE_BASE_URL` | user-service base URL (no trailing `/`) |

Emulator: use `10.0.2.2` instead of `localhost`. Physical phone: PC Wi‑Fi IPv4. See [mobile-client.md](./mobile-client.md).

---

## Web dashboard roles (no extra env flags)

| JWT `role` | Web UI | integration `GET /v1/donor-seeker/order-intents` |
|------------|--------|--------------------------------------------------|
| `coordinator` | Full dashboard — donor **email + id** per intent (from Postgres `users`), all reference photos; optional list filters `since`, `near_lat`/`near_lng`, `locality_key` (no default time cap) | `dashboard: "coordinator"` — includes `donor_email` when known |
| `donor` | Limited dashboard — list capped to **`since=Nh`** (`DONOR_NEIGHBOURHOOD_WINDOW_HOURS`, default 2); optional `near_lat`/`near_lng`; no other donors’ ids or emails; photos only within that window | `dashboard: "limited"` — response includes `since`, `feed`; no `donor_email`; photo URLs redacted outside window |

Google sign-in on web works for any account with `donor` and/or `coordinator` in `user_roles`. Users with both roles get `coordinator` on web and `donor` on mobile.

## Local stack defaults (copy-paste)

| Repo | Key vars |
|------|----------|
| integration-service | `AUTH_TOKEN_SECRET`, `DATABASE_URL`, `USER_SERVICE_BASE_URL=http://localhost:8081`, `WEB_CORS_ORIGINS=http://localhost:5173` |
| photo-service | `AUTH_TOKEN_SECRET`, `CLOUDINARY_*`, `DATABASE_URL` |
| user-service | `AUTH_TOKEN_SECRET`, `DATABASE_URL`, `GOOGLE_CLIENT_ID_WEB`, `WEB_CORS_ORIGINS=http://localhost:5173` |
| web-app | `VITE_API_BASE_URL`, `VITE_GOOGLE_CLIENT_ID`, `VITE_USER_SERVICE_BASE_URL` → localhost ports above |

Restart Node after `.env` changes. Restart `npm run dev` after web `VITE_*` changes.
