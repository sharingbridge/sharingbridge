# Web client configuration

Repository: `sharingbridge-web-app` (Vite + React).

## MVP scope

**Order initiation history** — coordinator dashboard; same API as mobile **Order initiation history**.

## How sign-in works (normal SPA pattern)

1. User opens the site → **Sign in** screen.
2. App calls user-service `POST /v1/auth/token` with `{"user_id":"…"}`.
3. JWT is stored in **sessionStorage** (this browser tab only).
4. Dashboard calls integration-service with `Authorization: Bearer <jwt>`.
5. On **401** or expiry → sign in again.

No ModHeader, no pasting tokens into a form on the dashboard, no PowerShell for normal use.

## Build-time configuration

Copy `.env.example` to `.env`:

| Variable | Purpose |
|----------|---------|
| `VITE_API_BASE_URL` | integration-service (no trailing `/`) |
| `VITE_USER_SERVICE_BASE_URL` | user-service for sign-in |
| `VITE_DEFAULT_USER_ID` | pre-filled donor id on sign-in form only |

Secrets are **not** in `.env` for production builds.

## CORS (both backends)

Browsers require allowed origins on **both** services:

| Service | Env | Example (local dev) |
|---------|-----|---------------------|
| integration-service | `WEB_CORS_ORIGINS` | `http://localhost:5173` |
| user-service | `WEB_CORS_ORIGINS` | `http://localhost:5173` |

Production: list **only** your deployed web URL (omit localhost). Redeploy after changes.

## Local run

```powershell
cd sharingbridge-web-app
copy .env.example .env
npm install
npm run dev
```

1. Set `WEB_CORS_ORIGINS=http://localhost:5173` on **user-service** and **integration-service** (local or Render).
2. Open http://localhost:5173 → enter donor id (e.g. `demo-user`) → **Sign in**.
3. **Refresh** after mobile registrations.

## Deploy (Render static site)

- Build: `npm install && npm run build`
- Publish: `dist/`
- Build env: `VITE_API_BASE_URL`, `VITE_USER_SERVICE_BASE_URL`, optional `VITE_DEFAULT_USER_ID`
- CORS on both backends → static site URL

See [MANUAL_TESTING_GUIDE.md](../testing/MANUAL_TESTING_GUIDE.md) §3h.

## Future

OAuth / federated IdP replaces donor-id + mint-token (see [authentication.md](./authentication.md)).
