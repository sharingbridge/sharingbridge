# Environment variables (all services)

**Master index** — the only place with full per-service tables. Other configuration docs link here instead of repeating keys. Each repo also has `env.example` → copy to `.env` (gitignored).

| Service | Config file | Load when |
|---------|-------------|-----------|
| user-service | `sharingbridge-user-service/.env` | `npm start` (dotenv) |
| integration-service | `sharingbridge-integration-service/.env` | `npm start` |
| photo-service | `sharingbridge-photo-service/.env` | `uvicorn` / pytest |
| ai-orchestration | `sharingbridge-ai-orchestration/.env` | `uvicorn` |
| web-app | `sharingbridge-web-app/.env` | `npm run dev` / **build** (`VITE_*` baked into `dist/`) |
| mobile-app | `--dart-define=…` on `flutter run` | compile time (no `.env` in repo) |

**Must match across services:** `DATABASE_URL` (Postgres), `AUTH_TOKEN_SECRET` (+ issuer/audience), `WEB_CORS_ORIGINS` (user-service **and** integration-service, same string), integration `API_BASE_URL` = web `VITE_API_BASE_URL` = mobile `API_BASE_URL`.

Render deploy details: [backend-render.md](./backend-render.md). Auth secrets: [authentication.md](./authentication.md). DB: [database.md](./database.md).

---

## Shared (multiple services)

| Variable | Used on | Purpose |
|----------|---------|---------|
| `DATABASE_URL` | user-service, integration-service, photo-service | Postgres (Supabase in prod) |
| `AUTH_TOKEN_SECRET` | user-service, integration-service, photo-service | HS256 JWT signing — **same value** on all three |
| `AUTH_TOKEN_ISSUER` | same | `sharingbridge-user-service` |
| `AUTH_TOKEN_AUDIENCE` | same | `sharingbridge-clients` |
| `WEB_CORS_ORIGINS` | user-service, integration-service | Browser origin(s) of the dashboard, e.g. `http://localhost:5173` — **not** the API URL |

---

## `sharingbridge-user-service`

| Variable | Local example | Render production |
|----------|---------------|-------------------|
| `PORT` | `8081` | injected by Render — do not set |
| `DATABASE_URL` | `postgresql://…@localhost:5432/sharingbridge` | Supabase URI |
| `AUTH_TOKEN_SECRET` | shared secret | generated, same on integration + photo |
| `AUTH_TOKEN_ISSUER` | `sharingbridge-user-service` | same |
| `AUTH_TOKEN_AUDIENCE` | `sharingbridge-clients` | same |
| `AUTH_TOKEN_TTL_SECONDS` | `3600` | `3600` |
| `WEB_CORS_ORIGINS` | `http://localhost:5173` | `https://<static-site>.onrender.com` |
| `GOOGLE_CLIENT_ID_WEB` | Web OAuth client ID | same as `VITE_GOOGLE_CLIENT_ID` |
| `GOOGLE_CLIENT_ID_ANDROID` | Android OAuth client ID | when mobile uses Google |

---

## `sharingbridge-integration-service`

| Variable | Local example | Render production |
|----------|---------------|-------------------|
| `PORT` | `8080` | injected by Render |
| `DATABASE_URL` | **same** as user-service | same |
| `AUTH_TOKEN_SECRET` | **same** as user-service | same |
| `AUTH_TOKEN_ISSUER` | `sharingbridge-user-service` | same |
| `AUTH_TOKEN_AUDIENCE` | `sharingbridge-clients` | same |
| `WEB_CORS_ORIGINS` | **same string** as user-service | same |
| `PREFERENCES_BACKEND` | `user_service` | `user_service` |
| `USER_SERVICE_BASE_URL` | `http://localhost:8081` | `https://<user-host>.onrender.com` |
| `AI_ORCHESTRATION_BASE_URL` | `http://localhost:8091` | `https://<ai-host>.onrender.com` |
| `AI_ORCHESTRATION_INTERNAL_API_KEY` | shared with ai-orchestration | same |
| `AI_ORCHESTRATION_TIMEOUT_MS` | `15000` | `15000` |
| `AI_SUGGEST_VENDORS_ENABLED` | `true` | `true` |
| `AI_INSTRUCTION_PACK_ENABLED` | `true` | `true` |

---

## `sharingbridge-photo-service`

| Variable | Local example | Render production |
|----------|---------------|-------------------|
| `DATABASE_URL` | same Postgres | same |
| `AUTH_TOKEN_SECRET` | same JWT secret | same |
| `AUTH_TOKEN_ISSUER` | `sharingbridge-user-service` | same |
| `AUTH_TOKEN_AUDIENCE` | `sharingbridge-clients` | same |
| `PHOTO_UPLOAD_MOCK` | `true` (no Cloudinary) | `true` until Cloudinary configured |
| `CLOUDINARY_CLOUD_NAME` | when real uploads | set when `PHOTO_UPLOAD_MOCK=false` |
| `CLOUDINARY_API_KEY` | | |
| `CLOUDINARY_API_SECRET` | | |

See [photo-service-local.md](./photo-service-local.md).

---

## `sharingbridge-ai-orchestration` (optional)

| Variable | Typical value |
|----------|----------------|
| `AI_ORCHESTRATION_INTERNAL_API_KEY` | same as integration-service |
| `AI_LLM_MODE` | `deterministic` (MVP) |
| `SHARINGBRIDGE_WEBSITE_URL` | `pending` |
| `OPENAI_API_KEY` | omit for MVP |

See [ai-orchestration-local.md](./ai-orchestration-local.md).

---

## `sharingbridge-web-app` (static site / Vite)

Build-time only (`VITE_*` in `.env` before `npm run build` or `npm run dev`).

| Variable | Local example | Render production |
|----------|---------------|-------------------|
| `VITE_API_BASE_URL` | `http://localhost:8080` | `https://<integration-host>.onrender.com` |
| `VITE_USER_SERVICE_BASE_URL` | `http://localhost:8081` | `https://<user-host>.onrender.com` |
| `VITE_GOOGLE_CLIENT_ID` | Web OAuth client ID | same as `GOOGLE_CLIENT_ID_WEB` |

CORS is **not** set here — set `WEB_CORS_ORIGINS` on both Node backends. See [web-client.md](./web-client.md).

---

## `sharingbridge-mobile-app` (`--dart-define`)

No `.env` file — pass at `flutter run`:

| Define | Purpose |
|--------|---------|
| `GOOGLE_CLIENT_ID` | Android OAuth client ID |
| `USER_SERVICE_BASE_URL` | user-service base URL (no trailing `/`) |
| `API_BASE_URL` | integration-service — **must match** web `VITE_API_BASE_URL` for same data |
| `PHOTO_SERVICE_BASE_URL` | photo-service (optional, for reference photos) |
| `USER_ID` + `AUTH_TOKEN` | dev only — pre-minted JWT (`node scripts/mint-dev-jwt.mjs` in user-service with same `AUTH_TOKEN_SECRET`) |

Emulator: use `10.0.2.2` instead of `localhost`. Physical phone: PC Wi‑Fi IPv4. See [mobile-client.md](./mobile-client.md).

---

## Web dashboard roles (no extra env flags)

| JWT `role` | Web UI | integration `GET /v1/donor-seeker/order-intents` |
|------------|--------|--------------------------------------------------|
| `coordinator` | Full dashboard — donor **email + id** per intent (from Postgres `users`), all reference photos | `dashboard: "coordinator"` — includes `donor_email` when known |
| `donor` | Limited dashboard — no other donors’ ids or emails; photos only if intent ≤ 1 hour old | `dashboard: "limited"` — no `donor_email`; photo URLs redacted after 1 hour |

Google sign-in on web works for any account with `donor` and/or `coordinator` in `user_roles`. Users with both roles get `coordinator` on web and `donor` on mobile.

## Local stack defaults (copy-paste)

| Repo | Key vars |
|------|----------|
| user-service | `DATABASE_URL`, `AUTH_TOKEN_SECRET`, `GOOGLE_CLIENT_ID_WEB`, `WEB_CORS_ORIGINS=http://localhost:5173` |
| integration-service | same `DATABASE_URL` + `AUTH_TOKEN_SECRET`, `USER_SERVICE_BASE_URL=http://localhost:8081`, same `WEB_CORS_ORIGINS` |
| web-app | `VITE_*_BASE_URL` → localhost ports above, `VITE_GOOGLE_CLIENT_ID` |
| photo-service | same DB + JWT; `PHOTO_UPLOAD_MOCK=true` |

Restart Node after `.env` changes. Restart `npm run dev` after web `VITE_*` changes.
