# Web client configuration

Repository: `sharingbridge-web-app` (Vite + React).

## MVP scope

**Order initiation history** — coordinator-style dashboard; same API as mobile **Order initiation history**.

The site is **configured at build time** (API URL, user id). It loads history automatically on open. **JWT is not typed into the page** in normal use.

## Authentication (recommended: ModHeader)

| Piece | Where it is set |
|-------|------------------|
| Integration API URL | `VITE_API_BASE_URL` in `.env` / Render build env |
| Donor user id | `VITE_USER_ID` in `.env` / Render build env |
| Bearer JWT | **ModHeader** (or similar) adds `Authorization: Bearer …` on requests to integration-service |

The app **does not** send `Authorization` when `VITE_AUTH_MODE=modheader` (default). The browser extension injects the header so the token never appears in the page UI.

### ModHeader setup

1. Install [ModHeader](https://chromewebstore.google.com/detail/modheader/idgpnmonknjnojddfkpgkljpfnnfcklj) (Chrome/Edge).
2. Add header: `Authorization` = `Bearer <jwt>` (mint from user-service).
3. Optional URL filter: your integration host only, e.g. `sharingbridge-integration-service.onrender.com`.
4. Open the web app → **Refresh**. Use **Authentication setup** on the page if you need the steps again.

Mint JWT (PowerShell):

```powershell
$token = (Invoke-RestMethod -Method POST `
  -Uri "https://sharingbridge-user-service.onrender.com/v1/auth/token" `
  -ContentType "application/json" -Body '{"user_id":"demo-user"}').token
```

Paste into ModHeader (not into the website). Token expires in ~1 hour.

### Local dev without ModHeader

In `.env` (gitignored):

```env
VITE_AUTH_MODE=env
VITE_AUTH_TOKEN=<paste-jwt-here>
```

Never commit real tokens.

## CORS (required for browsers)

integration-service must allow the web origin in `WEB_CORS_ORIGINS`:

| Environment | Example |
|-------------|---------|
| Local `npm run dev` | `http://localhost:5173` |
| Render static site | `https://your-web-service.onrender.com` |

Use **production origins only** on production integration (omit localhost). Redeploy integration after changing.

## Build-time variables

| Variable | Purpose |
|----------|---------|
| `VITE_API_BASE_URL` | integration-service base URL (no trailing `/`) |
| `VITE_USER_ID` | donor id for `user_id` query param |
| `VITE_AUTH_MODE` | `modheader` (default) or `env` |
| `VITE_AUTH_TOKEN` | only when `VITE_AUTH_MODE=env` |

## Local run

```powershell
cd sharingbridge-web-app
copy .env.example .env
npm install
npm run dev
```

Open http://localhost:5173. Configure ModHeader, then **Refresh**.

## Deploy (Render static site)

- Build: `npm install && npm run build`
- Publish directory: `dist`
- Build env: `VITE_API_BASE_URL`, `VITE_USER_ID`
- Set integration `WEB_CORS_ORIGINS` to the static site URL

See [MANUAL_TESTING_GUIDE.md](../testing/MANUAL_TESTING_GUIDE.md) §3h.
