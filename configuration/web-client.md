# Web client configuration

Repository: `sharingbridge-web-app` (Vite + React).

**Deployment order:** [e2e-deployment-sequence.md](./e2e-deployment-sequence.md) (Phases 0–5).

## Scope

**Order initiation history** and **Actions** workspace (pledges, kitchen commitments) on web — same integration API as mobile. View depends on JWT `role`:

| `role` | UI |
|--------|-----|
| `coordinator` | Full dashboard — **Initiations** \| **Actions** \| **Map** tabs; initiator email on each intent |
| `initiator` | Limited dashboard — neighbourhood window from integration `feed`; no other initiators’ emails |

## How sign-in works

1. User opens the site → **Sign in** screen.
2. **Sign in with Google** (GIS) → browser obtains a Google `id_token`.
3. App calls user-service `POST /v1/auth/google` with `{ "id_token", "client_type": "web" }`.
4. user-service verifies the token, loads **`user_roles`**, mints JWT `role: coordinator` when that role exists, otherwise `initiator`.
5. JWT is stored in **sessionStorage** until **Sign out** or expiry (~1 hour).
6. Coordinators: **email** stored in **localStorage** for **Use a different Google account** on later visits.
7. Dashboard calls `GET /v1/order-intents` (alias for `/v1/donor-seeker/order-intents`) with `Authorization: Bearer <jwt>`. **Initiators** may add `near_lat` / `near_lng`; server applies `DONOR_NEIGHBOURHOOD_*` and returns `feed` + `since` for UI copy. **Coordinators** get the full list by default; the same optional query params (`since`, `near_lat`/`near_lng`, `locality_key`) filter via geo SQL in integration-service ([database.md](./database.md)). Integration redacts fields for initiator JWTs.
8. Toolbar **Initiations** | **Actions** | **Map** — **Actions** loads `GET /v1/demand/board` (pledges, demand lines, kitchen commitments). Requires `seeker_demands` table ([schema-seeker-demands-migration.sql](./schema-seeker-demands-migration.sql)). Coordinators may pass scope query params (`since`, `near_lat`/`near_lng`, `locality_key`) on list and demand board.
9. **Data boundaries banner** — above the tabs, every view shows **Time**, **Area**, **Sort**, and **Limit** (from API `feed` + `neighbourhood`).
10. On **401** or expiry → sign in again.

**No client secret** in `.env` — only the Web **Client ID** (`VITE_GOOGLE_CLIENT_ID` / `GOOGLE_CLIENT_ID_WEB`).

### Order list grouping

| Mode | Who | Behavior |
|------|-----|----------|
| **By initiator** | Coordinator | Sections per `user_id` (coordinator default) |
| **By day** | Coordinator + initiator | Sections per calendar day (newest first) |
| **By area** | Coordinator + initiator | Sections per `locality_key` / `location_label`; rows without location under **No location on record** |

### List columns (planned — [PRODUCT_MODEL.md](../development/PRODUCT_MODEL.md))

| Column | Field | Notes |
|--------|-------|--------|
| **Order intent taken** | `created_at` | When the initiator registered the intent — not a vendor order. Optional elapsed from `created_at`. |
| **Delivered at** | `delivered_at` | Always shown; **—** when null until delivery-partner flow sets it. |
| **Distance (m)** | `distance_m` | Metres from browser `near_lat` / `near_lng`; list sorted **nearest first** when distance is present. |

**By area** always reads a **fresh** browser position (`maximumAge: 0`, no cached coords), reloads the list with `near_lat` / `near_lng`, then shows **Distance (m)** sorted nearest first. If location is denied or unavailable, a dialog appears and the view stays on the previous grouping (**By day** or **By initiator**). **Refresh** in **By area** mode repeats the same fresh-location fetch. **Home** clears the selected row.

### Coordinator dashboard scope (time + area)

Coordinators see a **scope toolbar** above the data boundaries banner (not shown to initiators on the limited dashboard).

| Control | Maps to API | Effect |
|---------|-------------|--------|
| **Time window** | `since` query (`2h`, `24h`, `7d`, `30d`, or omit for all time) | Filters order intents and demand-board rows by `created_at` / `updated_at` |
| **Area → All areas** | (no geo params) | All postal areas on this integration host |
| **Area → Near my location** | `near_lat`, `near_lng` (+ server default radius) | Browser GPS required on **Apply scope**; sorts by distance when handover GPS exists |
| **Area → Postal area key** | `locality_key` (e.g. `IN:TN:600001`) | Includes that key and sub-areas per [locality_key](./database.md) rules |
| **Apply scope** | — | Reloads **Initiations**, **Map**, and **Actions** with the same filters |
| **Reset** | — | Clears draft controls to all time + all areas (click **Apply scope** to reload) |

Header **Refresh** on Initiations/Map reapplies the last applied scope. On **Actions**, refresh bumps the demand fetch with the same scope.

Product flows (eco kitchens, connection): [Eco_Kitchen_Initiation_Flow.md](../design/Eco_Kitchen_Initiation_Flow.md).

### Order operations (Phase A)

| Action | Who | UI |
|--------|-----|-----|
| **Mark payment done** | Initiator (own row) | Confirmation dialog; sets `payment_status` → `paid_externally` |
| **Mark delivered** | Coordinator | Confirmation dialog; sets `delivery_status` → `delivered` and `delivered_at` |

List rows show **Payment** and **Delivery** status chips. Phase B (delivery-partner photo proof) is not live yet — coordinators manually mark delivered today.

**Deploy note:** scope filtering on `GET /v1/demand/board` requires integration-service **June 2026+** (`feed` on list + demand responses). Web-only deploy against an older API still shows the boundaries banner for order intents but demand filtering may not match.

**Code:** `sharingbridge-web-app` — `CoordinatorScopeToolbar.tsx`, `DashboardBoundariesBanner.tsx`, `coordinatorScope.ts`, `feedScope.ts`; `DemandBoardPanel.tsx` passes scope query to the demand API.

### Sign-in screen (first visit vs returning)

| Situation | What you see |
|-----------|----------------|
| **First sign-in on this browser** (no prior coordinator login here) | **Sign in with Google** |
| **Returning** (signed in successfully before on this browser) | **Last signed in as** *email* + Google button + **Use a different Google account** |

**Use a different Google account** calls Google Identity Services `revoke` for the last email, clears the stored hint, and reloads the page so another coordinator (with `user_roles`) can sign in. If revoke fails, use **Sign in with Google** and pick **Use another account** in Google’s dialog.

Chrome may show **Continue as …** on the Google button; that is normal for the same person signing back in.

**Sign out** (dashboard header) clears the SharingBridge session and calls GIS `disableAutoSelect()`.

## Build-time configuration

Copy `env.example` → `.env`. All `VITE_*` keys: [environment-variables.md](./environment-variables.md) § `sharingbridge-web-app`.

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
3. Open http://localhost:5173 → **Sign in with Google** (coordinator or initiator accounts).
4. **Refresh** after mobile initiator registrations.

Coordinators see **all** initiators’ order intents on the integration host pointed to by `VITE_API_BASE_URL`. Mobile must use the **same** integration host (`API_BASE_URL`). Localhost and Render stores are separate.

## Deploy (Render static site)

**Blueprint (auto-deploy on `main`):** repo root `render.yaml` — **New +** → **Blueprint** → `sharingbridge-web-app` → set `VITE_GOOGLE_CLIENT_ID` when prompted. Defaults for API URLs match `env.render`.

**Manual static site:**

1. **New +** → **Static Site** → repo `sharingbridge-web-app`, branch `main`.
2. **Build command:** `npm install && npm run build`
3. **Publish directory:** `dist`
4. **Settings → Build & Deploy → Auto-Deploy:** **On Commit**, **or** **After CI Checks Pass** only if `.github/workflows/ci.yml` exists and passes on `main` (this repo includes a `CI` workflow for `npm test`).
5. **Environment** (build-time): set `VITE_*` per [environment-variables.md](./environment-variables.md) § web-app (**Render production** column). Set `VITE_GOOGLE_CLIENT_ID` when using Blueprint.

6. After deploy, copy the static site URL (e.g. `https://sharingbridge-web.onrender.com`).
7. **Google Console** → Web OAuth client → **Authorized JavaScript origins**: add `https://<your-static-site>.onrender.com` **and** keep `http://localhost:5173` for local dev.
8. On **user-service** and **integration-service**, set `WEB_CORS_ORIGINS` to both origins if needed:  
   `http://localhost:5173,https://sharingbridge-web.onrender.com` → redeploy both.
9. Sign in on the live site with a **coordinator** Google account (`coordinator` in `user_roles`). See [google-auth-setup.md](./google-auth-setup.md) §7.

See [e2e-deployment-sequence.md](./e2e-deployment-sequence.md), [MANUAL_TESTING_GUIDE.md](../testing/MANUAL_TESTING_GUIDE.md) **§4**, and [backend-render.md](./backend-render.md).

## Future

OAuth / federated IdP replaces dev user-id + mint-token (see [authentication.md](./authentication.md)).
