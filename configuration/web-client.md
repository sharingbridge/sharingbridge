# Web client configuration

Repository: `sharingbridge-web-app` (Vite + React).

**Deployment order:** [e2e-deployment-sequence.md](./e2e-deployment-sequence.md) (Phases 0–5).

## MVP scope

**Order initiation history** — coordinator dashboard; same API as mobile **Order initiation history**.

## How sign-in works (coordinator web)

1. User opens the site → **Sign in** screen.
2. **Sign in with Google** (GIS) → browser obtains a Google `id_token`.
3. App calls user-service `POST /v1/auth/google` with `{ "id_token", "client": "web" }`.
4. user-service verifies the token, checks the **coordinator allowlist** (`data/coordinators.json` / `COORDINATOR_EMAILS`), mints a JWT with `role: coordinator`.
5. JWT is stored in **sessionStorage** (this browser tab only).
6. Dashboard calls integration-service with `Authorization: Bearer <jwt>` (coordinators list **all** order intents).
7. On **401** or expiry → sign in again.

**No client secret** in `.env` — only the Web **Client ID** (`VITE_GOOGLE_CLIENT_ID` / `GOOGLE_CLIENT_ID_WEB`).

**Local dev fallback:** `VITE_ALLOW_DEV_SIGN_IN=true` + user-service `ALLOW_DEV_TOKEN_MINT=true` → **Dev sign in** (coordinator role). See [google-auth-setup.md](./google-auth-setup.md).

## Build-time configuration

Copy `.env.example` to `.env`:

| Variable | Purpose |
|----------|---------|
| `VITE_API_BASE_URL` | integration-service (no trailing `/`) |
| `VITE_USER_SERVICE_BASE_URL` | user-service for Google sign-in |
| `VITE_GOOGLE_CLIENT_ID` | Web OAuth client ID (same as `GOOGLE_CLIENT_ID_WEB`) |
| `VITE_ALLOW_DEV_SIGN_IN` | Optional local **Dev sign in** only |
| `VITE_DEFAULT_USER_ID` | Optional pre-fill for dev sign-in form only |

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

1. Set `WEB_CORS_ORIGINS=http://localhost:5173` on **user-service** and **integration-service**.
2. Follow [google-auth-setup.md](./google-auth-setup.md) for Google client IDs and `data/coordinators.json`.
3. Open http://localhost:5173 → **Sign in with Google** (coordinator emails only).
4. **Refresh** after mobile donor registrations.

Coordinators see **all** donors’ order intents on the integration host pointed to by `VITE_API_BASE_URL`. Mobile donors must use the **same** integration host (`API_BASE_URL`). Localhost and Render stores are separate.

## Deploy (Render static site)

1. **New +** → **Static Site** → repo `sharingbridge-web-app`, branch `main`.
2. **Build command:** `npm install && npm run build`
3. **Publish directory:** `dist`
4. **Environment** (build-time — set before first deploy):

| Key | Example |
|-----|---------|
| `VITE_API_BASE_URL` | `https://sharingbridge-integration-service.onrender.com` |
| `VITE_USER_SERVICE_BASE_URL` | `https://sharingbridge-user-service.onrender.com` |
| `VITE_GOOGLE_CLIENT_ID` | Web OAuth client ID (same as `GOOGLE_CLIENT_ID_WEB` on user-service) |

5. After deploy, copy the static site URL (e.g. `https://sharingbridge-web.onrender.com`).
6. **Google Console** → Web OAuth client → **Authorized JavaScript origins**: add `https://<your-static-site>.onrender.com` **and** keep `http://localhost:5173` for local dev.
7. On **user-service** and **integration-service**, set `WEB_CORS_ORIGINS` to both origins if needed:  
   `http://localhost:5173,https://sharingbridge-web.onrender.com` → redeploy both.
8. Sign in on the live site with a **coordinator** Google account (allowlisted on user-service). See [google-auth-setup.md](./google-auth-setup.md) §7.

See [e2e-deployment-sequence.md](./e2e-deployment-sequence.md), [MANUAL_TESTING_GUIDE.md](../testing/MANUAL_TESTING_GUIDE.md) **§4**, and [backend-render.md](./backend-render.md).

## Future

OAuth / federated IdP replaces donor-id + mint-token (see [authentication.md](./authentication.md)).
