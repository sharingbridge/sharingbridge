# Web client configuration

Repository: `sharingbridge-web-app` (Vite + React).

**Deployment order:** [e2e-deployment-sequence.md](./e2e-deployment-sequence.md) (Phases 0–5).

## MVP scope

**Order initiation history** — coordinator dashboard; same API as mobile **Order initiation history**.

## How sign-in works (coordinator web)

1. User opens the site → **Coordinator sign in** screen (minimal copy).
2. **Sign in with Google** (GIS) → browser obtains a Google `id_token`.
3. App calls user-service `POST /v1/auth/google` with `{ "id_token", "client_type": "web" }`.
4. user-service verifies the token, loads **`user_roles`** from Postgres, mints a JWT with `role: coordinator` when that role is present.
5. JWT is stored in **sessionStorage** (`sharingbridge_web_session_v1`) for this site in the browser until **Sign out** or token expiry (~1 hour). Closing **all** tabs for this origin clears it.
6. On successful sign-in, the coordinator **email** is also stored in **localStorage** (same browser only) so the app can offer **Use a different Google account** on later visits.
7. Dashboard calls integration-service with `Authorization: Bearer <jwt>` (coordinators list **all** order intents).
8. On **401** or expiry → sign in again.

**No client secret** in `.env` — only the Web **Client ID** (`VITE_GOOGLE_CLIENT_ID` / `GOOGLE_CLIENT_ID_WEB`).

**Dev / MVP unlock flags** (optional): [environment-variables.md](./environment-variables.md).

### Sign-in screen (first visit vs returning)

| Situation | What you see |
|-----------|----------------|
| **First sign-in on this browser** (no prior coordinator login here) | **Sign in with Google** |
| **Returning** (signed in successfully before on this browser) | **Last signed in as** *email* + Google button + **Use a different Google account** |

**Use a different Google account** calls Google Identity Services `revoke` for the last email, clears the stored hint, and reloads the page so another coordinator (with `user_roles`) can sign in. If revoke fails, use **Sign in with Google** and pick **Use another account** in Google’s dialog.

Chrome may show **Continue as …** on the Google button; that is normal for the same person signing back in.

**Sign out** (dashboard header) clears the SharingBridge session and calls GIS `disableAutoSelect()`.

## Build-time configuration

Copy `env.example` to `.env`:

| Variable | Purpose |
|----------|---------|
| `VITE_API_BASE_URL` | integration-service (no trailing `/`) |
| `VITE_USER_SERVICE_BASE_URL` | user-service for Google sign-in |
| `VITE_GOOGLE_CLIENT_ID` | Web OAuth client ID (same as `GOOGLE_CLIENT_ID_WEB`) |
| `VITE_DEFAULT_USER_ID` | Optional pre-fill for dev sign-in form only |

Full variable list: [environment-variables.md](./environment-variables.md) § web-app. Optional dev/MVP flags: same doc § Optional flags.

Secrets are **not** in `.env` for production builds.

## Backend local env

User-service and integration-service read repo-root `.env` on `npm start` (dotenv). Set `WEB_CORS_ORIGINS` there for local browser dev — see [backend-render.md](./backend-render.md) § Local `.env`.

## CORS (`WEB_CORS_ORIGINS` on both backends)

The web app runs in the **browser**; user-service and integration-service must allow the **page origin** (where Vite or the static site is opened), not the API hostname.

| Where the dashboard runs | Set on **user-service** + **integration-service** |
|--------------------------|---------------------------------------------------|
| Local: http://localhost:5173 | In each repo’s **local** `.env`: `WEB_CORS_ORIGINS=http://localhost:5173` |
| Render static site: `https://….onrender.com` | In **Render** env for **both** services: `WEB_CORS_ORIGINS=https://<your-static-site>.onrender.com` |
| Both local web and hosted web vs same APIs | Render: `http://localhost:5173,https://<your-static-site>.onrender.com` (comma-separated) |

**Not** set in `sharingbridge-web-app/.env` — only on the two Node backends.

Full matrix: [backend-render.md](./backend-render.md) § `WEB_CORS_ORIGINS`. After changing Render values, redeploy **both** services.

## Local run

```powershell
cd sharingbridge-web-app
copy env.example .env
npm install
npm run dev
```

1. Set `WEB_CORS_ORIGINS=http://localhost:5173` on **user-service** and **integration-service**.
2. Follow [google-auth-setup.md](./google-auth-setup.md) for Google client IDs and [coordinator-seed.sql](./coordinator-seed.sql).
3. Open http://localhost:5173 → **Sign in with Google** (accounts with `coordinator` in `user_roles` only).
4. **Refresh** after mobile donor registrations.

Coordinators see **all** donors’ order intents on the integration host pointed to by `VITE_API_BASE_URL`. Mobile donors must use the **same** integration host (`API_BASE_URL`). Localhost and Render stores are separate.

## Deploy (Render static site)

**Blueprint (auto-deploy on `main`):** repo root `render.yaml` — **New +** → **Blueprint** → `sharingbridge-web-app` → set `VITE_GOOGLE_CLIENT_ID` when prompted. Defaults for API URLs match `env.render`.

**Manual static site:**

1. **New +** → **Static Site** → repo `sharingbridge-web-app`, branch `main`.
2. **Build command:** `npm install && npm run build`
3. **Publish directory:** `dist`
4. **Settings → Build & Deploy → Auto-Deploy:** **On Commit**, **or** **After CI Checks Pass** only if `.github/workflows/ci.yml` exists and passes on `main` (this repo includes a `CI` workflow for `npm test`).
5. **Environment** (build-time — set before first deploy):

| Key | Example |
|-----|---------|
| `VITE_API_BASE_URL` | `https://sharingbridge-integration-service.onrender.com` |
| `VITE_USER_SERVICE_BASE_URL` | `https://sharingbridge-user-service.onrender.com` |
| `VITE_GOOGLE_CLIENT_ID` | Web OAuth client ID (same as `GOOGLE_CLIENT_ID_WEB` on user-service) |

5. After deploy, copy the static site URL (e.g. `https://sharingbridge-web.onrender.com`).
6. **Google Console** → Web OAuth client → **Authorized JavaScript origins**: add `https://<your-static-site>.onrender.com` **and** keep `http://localhost:5173` for local dev.
7. On **user-service** and **integration-service**, set `WEB_CORS_ORIGINS` to both origins if needed:  
   `http://localhost:5173,https://sharingbridge-web.onrender.com` → redeploy both.
8. Sign in on the live site with a **coordinator** Google account (`coordinator` in `user_roles`). See [google-auth-setup.md](./google-auth-setup.md) §7.

See [e2e-deployment-sequence.md](./e2e-deployment-sequence.md), [MANUAL_TESTING_GUIDE.md](../testing/MANUAL_TESTING_GUIDE.md) **§4**, and [backend-render.md](./backend-render.md).

## Future

OAuth / federated IdP replaces donor-id + mint-token (see [authentication.md](./authentication.md)).
