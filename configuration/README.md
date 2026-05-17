# SharingBridge configuration

Operational and deployment configuration by application area. Design specs remain in `design/` and `requirements/`; this folder is for **how to run and wire** the MVP.

| Document | Scope |
|----------|--------|
| [backend-render.md](./backend-render.md) | Host user-service, ai-orchestration, and integration-service on Render |
| [authentication.md](./authentication.md) | Donor JWT and internal service API key |
| [mobile-client.md](./mobile-client.md) | Flutter `dart-define` values and hosted vs local URLs |
| [web-client.md](./web-client.md) | Web dashboard (order initiation history) and CORS |
| [field-handoff.md](./field-handoff.md) | Offer food help flow, guidance (BRD step 4), what is not automated |

**Per-repo templates:** each service repository has `.env.example` and `render.yaml` (where applicable). Node backends load `.env` on `npm start` via dotenv; the web app uses `sharingbridge-web-app/.env` (`VITE_*` at build/dev time).

## Local stack checklist

| Repo | Copy template | Keys to verify for web + mobile |
|------|---------------|----------------------------------|
| `sharingbridge-user-service` | `.env.example` → `.env` | `AUTH_TOKEN_SECRET`, `WEB_CORS_ORIGINS=http://localhost:5173` |
| `sharingbridge-integration-service` | `.env.example` → `.env` | Same `AUTH_TOKEN_SECRET`, `USER_SERVICE_BASE_URL=http://localhost:8081`, `WEB_CORS_ORIGINS=http://localhost:5173`, `PREFERENCES_BACKEND` |
| `sharingbridge-web-app` | `.env.example` → `.env` | `VITE_API_BASE_URL=http://localhost:8080`, `VITE_USER_SERVICE_BASE_URL=http://localhost:8081` |
| `sharingbridge-mobile-app` | — | Mint JWT; `flutter run` with `API_BASE_URL`, `USER_ID`, `AUTH_TOKEN` — [mobile-client.md](./mobile-client.md) |

Restart Node services after editing `.env`. Restart `npm run dev` after changing web `VITE_*`.

## Render checklist

| Step | Doc |
|------|-----|
| Deploy user-service → ai-orchestration → integration | [backend-render.md](./backend-render.md) |
| Set `WEB_CORS_ORIGINS` on **both** Node services to static web URL | [web-client.md](./web-client.md) |
| Static site build env `VITE_*` → hosted API URLs | [web-client.md](./web-client.md) |
| Mobile `API_BASE_URL` + minted JWT | [mobile-client.md](./mobile-client.md) |

**Testing:** [MANUAL_TESTING_GUIDE.md](../testing/MANUAL_TESTING_GUIDE.md) — mobile **§3**, web dashboard **§4**
