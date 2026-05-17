# Web client configuration

Repository: `sharingbridge-web-app` (Vite + React).

## MVP scope

**Order initiation history** — same data as mobile **Order initiation history**, for desktop browsers and coordinators.

## API

| Call | Service |
|------|---------|
| Mint JWT | user-service `POST /v1/auth/token` |
| List initiations | integration-service `GET /v1/donor-seeker/order-intents` |

The web app does **not** call ai-orchestration directly.

## CORS (required for browsers)

integration-service must allow the web origin:

| Environment | `WEB_CORS_ORIGINS` example |
|-------------|----------------------------|
| Local dev | `http://localhost:5173` |
| Render static site | `https://your-web-service.onrender.com` |

Comma-separate multiple origins. Use `*` only for local experiments.

Redeploy integration-service after changing this variable.

## Environment (build-time)

Copy `.env.example` to `.env` for `npm run dev` / `npm run build`:

| Variable | Purpose |
|----------|---------|
| `VITE_API_BASE_URL` | integration-service base URL (no trailing slash) |
| `VITE_USER_ID` | default user id in the connection form |

JWT is **not** baked into the build; paste per session in the UI (or use sessionStorage after Connect).

## Local run

```powershell
cd sharingbridge-web-app
npm install
npm run dev
```

See [MANUAL_TESTING_GUIDE.md](../testing/MANUAL_TESTING_GUIDE.md) §3h.
