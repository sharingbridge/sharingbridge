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

## Backend local env

User-service and integration-service read repo-root `.env` on `npm start` (dotenv). Set `WEB_CORS_ORIGINS` there for local browser dev — see [backend-render.md](./backend-render.md) § Local `.env`.

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

Order intents are **per user id** and **per integration API** (localhost file store vs Render are separate). Sign in with the same donor id you used on mobile, and point `VITE_API_BASE_URL` at the same integration host as mobile `API_BASE_URL`.

## Deploy (Render static site)

1. **New +** → **Static Site** → repo `sharingbridge-web-app`, branch `main`.
2. **Build command:** `npm install && npm run build`
3. **Publish directory:** `dist`
4. **Environment** (build-time — set before first deploy):

| Key | Example |
|-----|---------|
| `VITE_API_BASE_URL` | `https://sharingbridge-integration-service.onrender.com` |
| `VITE_USER_SERVICE_BASE_URL` | `https://sharingbridge-user-service.onrender.com` |
| `VITE_DEFAULT_USER_ID` | `demo-user` (optional pre-fill) |

5. After deploy, copy the static site URL (e.g. `https://sharingbridge-web.onrender.com`).
6. On **user-service** and **integration-service** in Render, set `WEB_CORS_ORIGINS` to that URL only (no trailing path). Redeploy both backends.
7. Sign in on the live site with a donor id that has order intents on **that** integration host.

See [MANUAL_TESTING_GUIDE.md](../testing/MANUAL_TESTING_GUIDE.md) **§4** and [backend-render.md](./backend-render.md).

## Future

OAuth / federated IdP replaces donor-id + mint-token (see [authentication.md](./authentication.md)).
