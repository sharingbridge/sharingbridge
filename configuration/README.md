# SharingBridge configuration

Operational and deployment configuration by application area. **Full doc map:** [AGENT_HANDOFF.md](../development/AGENT_HANDOFF.md) § Documentation map. Design specs remain in `design/` and `requirements/`; this folder is for **how to run and wire** the MVP.

| Document | Scope |
|----------|--------|
| [e2e-deployment-sequence.md](./e2e-deployment-sequence.md) | **Start here:** phased order (Google → local → Render backends → static site → CORS) |
| [backend-render.md](./backend-render.md) | Host user-service, ai-orchestration, and integration-service on Render |
| [authentication.md](./authentication.md) | Google Sign-In, JWT roles, internal API key |
| [database.md](./database.md) | **Supabase** + local Postgres (manual steps), [schema.sql](./schema.sql) |
| [Future Extensions](../design/Future_Extensions.md) | Roadmap: donor payment status, delivery proof, demand/vendor bidding |
| [google-auth-setup.md](./google-auth-setup.md) | **Step-by-step** Google OAuth + coordinator SQL seed + local `.env` |
| [mobile-client.md](./mobile-client.md) | Flutter `dart-define` values and hosted vs local URLs |
| [web-client.md](./web-client.md) | Web dashboard (order initiation history) and CORS |
| [field-handoff.md](./field-handoff.md) | Offer food help flow, guidance (BRD step 4), what is not automated |
| [photo-service-local.md](./photo-service-local.md) | Reference photo upload (Cloudinary), port 8092, `PHOTO_SERVICE_BASE_URL` |
| [ai-orchestration-local.md](./ai-orchestration-local.md) | **Optional** Python AI: uvicorn, `.venv`, `Activate.ps1` (not in `configuration/`) |

**Per-repo templates:** each service repository has `env.example` (copy to `.env` locally; all `.env*` files are gitignored) and `render.yaml` (where applicable). Node backends load `.env` on `npm start` via dotenv; the web app uses `sharingbridge-web-app/.env` (`VITE_*` at build/dev time).

## Local stack checklist

| Repo | Copy template | Keys to verify for web + mobile |
|------|---------------|----------------------------------|
| `sharingbridge-user-service` | `env.example` → `.env` | **`DATABASE_URL`** (required), `AUTH_TOKEN_SECRET`, `GOOGLE_CLIENT_ID_WEB`, `WEB_CORS_ORIGINS` — [database.md](./database.md), [google-auth-setup.md](./google-auth-setup.md) |
| `sharingbridge-integration-service` | `env.example` → `.env` | **Same `DATABASE_URL`**, same `AUTH_TOKEN_SECRET`, `USER_SERVICE_BASE_URL=http://localhost:8081`, **same** `WEB_CORS_ORIGINS`, `PREFERENCES_BACKEND` — [database.md](./database.md) |
| `sharingbridge-web-app` | `env.example` → `.env` | `VITE_GOOGLE_CLIENT_ID`, `VITE_API_BASE_URL=http://localhost:8080`, `VITE_USER_SERVICE_BASE_URL=http://localhost:8081` |
| `sharingbridge-mobile-app` | — | `GOOGLE_CLIENT_ID`, `USER_SERVICE_BASE_URL`, `API_BASE_URL`, `PHOTO_SERVICE_BASE_URL`; or dev mint — [mobile-client.md](./mobile-client.md) |
| `sharingbridge-photo-service` | `env.example` → `.env` | Same `DATABASE_URL` + `AUTH_TOKEN_SECRET` as user-service; Cloudinary or `PHOTO_UPLOAD_MOCK=true` — [photo-service-local.md](./photo-service-local.md) |
| `sharingbridge-ai-orchestration` | — | **Optional** for live LLM paths — [ai-orchestration-local.md](./ai-orchestration-local.md) (venv stays inside that repo only) |

**Order of setup:** [e2e-deployment-sequence.md](./e2e-deployment-sequence.md) Phase 0 → Phase 1 (Postgres + `.env`) → [MANUAL_TESTING_GUIDE.md](../testing/MANUAL_TESTING_GUIDE.md).

Restart Node services after editing `.env`. Restart `npm run dev` after changing web `VITE_*`.

## Render checklist

Follow [e2e-deployment-sequence.md](./e2e-deployment-sequence.md) Phases 2–5 in order.

| Step | Doc |
|------|-----|
| Create **Supabase** project + tables, then `DATABASE_URL` on both Render Node services | [database.md](./database.md) |
| Deploy user-service → ai-orchestration → integration | [backend-render.md](./backend-render.md) |
| Set `WEB_CORS_ORIGINS` on **both** Node services **in Render** to static site URL (`https://…onrender.com`); keep `http://localhost:5173` in **local** `.env` only | [backend-render.md](./backend-render.md) § WEB_CORS_ORIGINS · [e2e-deployment-sequence.md](./e2e-deployment-sequence.md) Phase 4 |
| Static site build env `VITE_*` → hosted API URLs | [e2e-deployment-sequence.md](./e2e-deployment-sequence.md) Phase 3 |
| Mobile `API_BASE_URL` + Google / JWT | [mobile-client.md](./mobile-client.md) |

**Testing:** [MANUAL_TESTING_GUIDE.md](../testing/MANUAL_TESTING_GUIDE.md) — mobile **§3**, web dashboard **§4**
