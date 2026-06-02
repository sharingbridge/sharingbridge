# Google Sign-In setup (local development)

Step-by-step guide for **coordinator web** + **donor mobile** using Google OAuth.  
Architecture reference: [authentication.md](./authentication.md).

**Full deploy order (local → Render):** [e2e-deployment-sequence.md](./e2e-deployment-sequence.md).

---

## What you are configuring

| Piece | Purpose |
|-------|---------|
| **Google Cloud project** | OAuth consent + client IDs |
| **Web OAuth client** | `sharingbridge-web-app` (coordinators) |
| **Android OAuth client** | `sharingbridge-mobile-app` (donors) |
| **user-service** | Verifies Google `id_token`, assigns role, mints JWT |
| **Coordinator role** | `user_roles` in Postgres ([coordinator-seed.sql](./coordinator-seed.sql)) — not `.env` |

Official Google docs:

- [Google Cloud Console](https://console.cloud.google.com/)
- [Configure OAuth consent screen](https://support.google.com/cloud/answer/10311615)
- [Create OAuth client ID (credentials)](https://support.google.com/cloud/answer/6158849)
- [Sign in with Google for Web (GIS)](https://developers.google.com/identity/gsi/web/guides/overview)
- [Google Sign-In for Flutter](https://pub.dev/packages/google_sign_in)
- [Verify Google ID tokens (backend)](https://developers.google.com/identity/gsi/web/guides/verify-google-id-token)

---

## Part 1 — Google Cloud project

### 1.1 Create or select a project

1. Open [Google Cloud Console](https://console.cloud.google.com/).
2. Top bar → **Select a project** → **New Project** (e.g. `sharingbridge-dev`).
3. Wait until the project is active.

### 1.2 Enable Google Identity / Sign-In APIs

1. Go to [APIs & Services → Library](https://console.cloud.google.com/apis/library).
2. Search and enable (if prompted):
   - No separate “Google Sign-In API” is always required for basic GIS; the OAuth client is enough for MVP.
3. If mobile sign-in fails with API errors, enable **[Google People API](https://console.cloud.google.com/apis/library/people.googleapis.com)** (optional, some flows use profile scope).

### 1.3 OAuth consent screen

1. [APIs & Services → OAuth consent screen](https://console.cloud.google.com/apis/credentials/consent) (opens **OAuth overview** in the new UI).
2. **User type**
   - **External** — any `@gmail.com` tester (typical for dev). Personal Gmail projects often see **only External** — that is correct.
   - **Internal** — only users in your Google Workspace org.
3. Fill **App name**, **User support email**, **Developer contact email** → **Save**.

**After save you may land on OAuth overview** — not a dead end. Use the left sidebar:

| Sidebar item | Purpose |
|--------------|---------|
| [Data Access](https://console.cloud.google.com/auth/scopes) | Scopes — for Sign in with Google MVP, usually **leave as-is** (empty table is OK) |
| [Audience](https://console.cloud.google.com/auth/audience) | **Test users** — add every Gmail you will sign in with while status is **Testing** |
| [Branding](https://console.cloud.google.com/auth/branding) | Edit app name / logos |

4. **Scopes** — you usually **do not** click **ADD OR REMOVE SCOPES** for MVP. GIS / `google_sign_in` request `openid`, `email`, `profile` at sign-in. Open **Data Access** only to confirm; then go to **Audience**.
5. **Test users** — [Audience](https://console.cloud.google.com/auth/audience) → **Test users** → **+ Add users** → every coordinator and donor Gmail for dev.  
   [Publishing status](https://support.google.com/cloud/answer/10311615#publishing-status) — while **Testing**, only listed test users can sign in (with exceptions for basic profile-only sign-in; still add test users for reliability).

**Old wizard UI:** if you still see **Save and Continue** pages, use Scopes page → **Save and Continue** without adding scopes, then Test users.

---

## Part 2 — OAuth 2.0 Client IDs

Open [APIs & Services → Credentials](https://console.cloud.google.com/apis/credentials) → **+ Create credentials** → **OAuth client ID**.

### 2.1 Web application (coordinator dashboard)

1. Application type: **Web application**.
2. Name: e.g. `SharingBridge Web (local)`.
3. **Authorized JavaScript origins** (exact origin, no path):

   | Environment | Origin |
   |-------------|--------|
   | Local Vite | `http://localhost:5173` |
   | Render static site (later) | `https://your-web-app.onrender.com` |

4. **Authorized redirect URIs** — for GIS button flow you often only need origins; if Google asks for redirects, you can add:
   - `http://localhost:5173`
   - Your production web URL  
   See [GIS setup](https://developers.google.com/identity/gsi/web/guides/get-google-api-clientid).

5. **Create** → copy the **Client ID** (ends with `.apps.googleusercontent.com`).  
   This is **`GOOGLE_CLIENT_ID_WEB`** and **`VITE_GOOGLE_CLIENT_ID`**.

### 2.2 Android (donor mobile app)

1. **+ Create credentials** → **OAuth client ID** → **Android**.
2. Name: e.g. `SharingBridge Android (debug)`.
3. **Package name** — from `sharingbridge-mobile-app/android/app/build.gradle.kts` → `applicationId` (`app.sharingbridge`).
4. **SHA-1 certificate fingerprint** — required for Android.

   **Debug keystore (local `flutter run`):**

   ```powershell
   keytool -list -v -keystore "$env:USERPROFILE\.android\debug.keystore" -alias androiddebugkey -storepass android -keypass android
   ```

   Copy the **SHA-1** line (colon-separated hex).

   [Flutter / Android signing docs](https://docs.flutter.dev/deployment/android#signing-the-app)

5. **Create** → copy **Client ID** → **`GOOGLE_CLIENT_ID_ANDROID`**.

### 2.3 iOS (optional)

Only if you run on iPhone/iPad:

1. Create **iOS** OAuth client in the same Credentials page.
2. Bundle ID from Xcode / `ios/Runner.xcodeproj`.
3. Set `GOOGLE_CLIENT_ID_IOS` in user-service `.env` (code reads it via `googleAuth.js`).

### 2.4 Windows / Linux desktop

**Not supported** for Google Sign-In in the mobile app (`google_sign_in` has no Windows/Linux implementation). The sign-in screen explains this instead of crashing.

| Goal | Approach |
|------|----------|
| Donor + Google + Render/local APIs | **Android emulator** or device — use **Android** OAuth client (§2.2) |
| Coordinator | **Web dashboard** — **Web** OAuth client (§2.1) |
| Donor on Windows desktop (dev only) | `flutter run -d windows` with `--dart-define=AUTH_TOKEN=…` (dev mint on user-service) |

**macOS** `flutter run -d macos` can use the **Web** client ID in `--dart-define=GOOGLE_CLIENT_ID=…`.

---

## Part 3 — Coordinator role (database only)

Coordinators are **not** configured in Google Console or in user-service `.env`. The **`coordinator`** role lives in Postgres **`user_roles`**.

**Bootstrap (local or Supabase):**

1. Sign in once with the coordinator Gmail (mobile as donor is fine) so a row exists in **`users`**, **or** run `npm run import:json` if you migrated legacy data.
2. Edit and run [coordinator-seed.sql](./coordinator-seed.sql) — see [database.md](./database.md) § Coordinator seeding.
3. Sign in on the **web dashboard** with that same Gmail (test user on the OAuth consent screen).

**Rules:**

- **`user_roles` may include both `donor` and `coordinator`** for the same user.
- **Web** sign-in mints JWT `role: coordinator` (requires `coordinator` in `user_roles`).
- **Mobile** sign-in mints JWT `role: donor` (requires `donor`; coordinators can also use the donor app).
- Donor-only account on **web** → `403 wrong_client_role`.

---

## Part 4 — Environment files

### 4.1 `sharingbridge-user-service/.env`

Copy from `env.example`:

```powershell
cd D:\kannan\sharingbridge\sharingbridge-user-service
copy env.example .env
```

Set at minimum:

```env
AUTH_TOKEN_SECRET=your-long-random-secret-shared-with-integration
AUTH_TOKEN_ISSUER=sharingbridge-user-service
AUTH_TOKEN_AUDIENCE=sharingbridge-clients
AUTH_TOKEN_TTL_SECONDS=3600

# Local laptop only — browser origin for Vite (:5173). On Render, set https://<static-site>.onrender.com in the dashboard (both backends).
WEB_CORS_ORIGINS=http://localhost:5173

GOOGLE_CLIENT_ID_WEB=123456789-xxxx.apps.googleusercontent.com
GOOGLE_CLIENT_ID_ANDROID=123456789-yyyy.apps.googleusercontent.com

BYPASS_GOOGLE_SIGN_IN=true
```

`AUTH_TOKEN_SECRET` must **match** integration-service (see below).

Generate a secret (PowerShell):

```powershell
[Convert]::ToBase64String((1..48 | ForEach-Object { Get-Random -Maximum 256 }) -as [byte[]])
```

### 4.2 `sharingbridge-integration-service/.env`

```env
AUTH_TOKEN_SECRET=<same value as user-service>
WEB_CORS_ORIGINS=http://localhost:5173
```

Must match user-service. On **Render**, use `https://<static-site>.onrender.com` (or comma-list with localhost) on **both** services — see [backend-render.md](./backend-render.md).

(Plus your existing AI / preferences vars.)

### 4.3 `sharingbridge-web-app/.env`

```powershell
cd D:\kannan\sharingbridge\sharingbridge-web-app
copy env.example .env
```

```env
VITE_API_BASE_URL=http://localhost:8080
VITE_USER_SERVICE_BASE_URL=http://localhost:8081
VITE_GOOGLE_CLIENT_ID=<same as GOOGLE_CLIENT_ID_WEB>

# Optional: skip Google until clients are ready
# VITE_BYPASS_GOOGLE_SIGN_IN=true
# VITE_DEFAULT_USER_ID=demo-coordinator
```

Restart `npm run dev` after any `VITE_*` change.

---

## Part 5 — Run the stack

Use **three terminals** (see [MANUAL_TESTING_GUIDE.md](../testing/MANUAL_TESTING_GUIDE.md) §2):

| Service | Port | Command |
|---------|------|---------|
| user-service | 8081 | `npm start` |
| integration-service | 8080 | `npm start` |
| web app | 5173 | `npm run dev` |

Health checks:

```powershell
Invoke-RestMethod http://localhost:8081/health
Invoke-RestMethod http://localhost:8080/health
```

---

## Part 6 — Sign in and verify

### 6.1 Coordinator (web)

1. Open [http://localhost:5173](http://localhost:5173).
2. First visit: **Sign in with Google**.
3. Click **Sign in with Google** (GIS). Use a Gmail that has **`coordinator`** in `user_roles` (run [coordinator-seed.sql](./coordinator-seed.sql) first). Pick **Use another account** in Google’s dialog if Chrome pre-selects the wrong Gmail.
4. Dashboard should load; header shows coordinator email when available. **Sign out** clears the session.
5. Next visit on the same browser: sign-in page shows **Last signed in as** *email* and **Use a different Google account** (disconnects that Google profile from this app, then reloads).
6. **Refresh** on the dashboard shows order initiations (after a donor registers one on mobile).

**Without Google yet:** set `VITE_BYPASS_GOOGLE_SIGN_IN=true`, ensure `BYPASS_GOOGLE_SIGN_IN=true`, use **Sign in without Google** on the web page.

### 6.2 Donor (mobile)

**Android emulator** — use `10.0.2.2` for **both** backends (see [MANUAL_TESTING_GUIDE.md](../testing/MANUAL_TESTING_GUIDE.md) §3-host):

```powershell
cd D:\kannan\sharingbridge\sharingbridge-mobile-app
flutter pub get
flutter run -d emulator-5554 `
  --dart-define=GOOGLE_CLIENT_ID=<GOOGLE_CLIENT_ID_ANDROID> `
  --dart-define=USER_SERVICE_BASE_URL=http://10.0.2.2:8081 `
  --dart-define=API_BASE_URL=http://10.0.2.2:8080
```

**Windows desktop:** same URLs with `localhost` (Google Sign-In not supported on Windows — use emulator or dev token).

1. Tap **Continue with Google**.
2. Use a Gmail with **`donor`** in `user_roles` (default for all users). Coordinators with both roles can use mobile as donor and web as coordinator.
3. Complete **Help a seeker** → copy instructions to register an order intent.
4. On web (coordinator), **Refresh** — you should see that intent (with donor `user_id` in the list).

**Without Google yet:** use bypass sign-in (`BYPASS_GOOGLE_SIGN_IN`) or dev token mint:

```powershell
$token = (Invoke-RestMethod -Method POST -Uri http://localhost:8081/v1/auth/token `
  -ContentType application/json -Body '{"user_id":"demo-user","role":"donor"}').token
flutter run -d emulator-5554 `
  --dart-define=USER_SERVICE_BASE_URL=http://10.0.2.2:8081 `
  --dart-define=API_BASE_URL=http://10.0.2.2:8080 `
  --dart-define=AUTH_TOKEN=$token --dart-define=USER_ID=demo-user
```

---

## Part 7 — Render static site + Google (local **and** hosted URL)

Phased checklist: [e2e-deployment-sequence.md](./e2e-deployment-sequence.md) Phases 3–4.

Yes — deploy the web app on [Render Static Sites](https://render.com/docs/static-sites) so you have a stable **HTTPS** URL for Google OAuth and CORS, alongside local dev.

### 7.1 Deploy `sharingbridge-web-app` on Render

1. [Render Dashboard](https://dashboard.render.com/) → **New +** → **Static Site**.
2. Connect repo **`sharingbridge-web-app`**, branch `main`.
3. Settings:

   | Field | Value |
   |-------|--------|
   | Build command | `npm install && npm run build` |
   | Publish directory | `dist` |

4. **Environment** (build-time — required before first deploy):

   | Key | Example |
   |-----|---------|
   | `VITE_API_BASE_URL` | `https://sharingbridge-integration-service.onrender.com` |
   | `VITE_USER_SERVICE_BASE_URL` | `https://sharingbridge-user-service.onrender.com` |
   | `VITE_GOOGLE_CLIENT_ID` | Same **Web** OAuth client ID as local (`….apps.googleusercontent.com`) |

   Do **not** set `VITE_BYPASS_GOOGLE_SIGN_IN` on Render (production).

5. Deploy → copy the site URL, e.g. `https://sharingbridge-web.onrender.com`  
   (Render shows it on the static site **Settings** page.)

Docs: [Render static sites](https://render.com/docs/static-sites), [web-client.md](./web-client.md).

### 7.2 Google Console — add **both** origins

Edit your **Web application** OAuth client:  
[Credentials](https://console.cloud.google.com/apis/credentials) → your Web client → **Edit**.

**Authorized JavaScript origins** — add **both** (no trailing slash, no path):

```text
http://localhost:5173
https://sharingbridge-web.onrender.com
```

Use your real Render hostname if different.

You can use **one** Web OAuth client for local and Render; both origins share the same **Client ID** (`VITE_GOOGLE_CLIENT_ID` / `GOOGLE_CLIENT_ID_WEB`).

### 7.3 Backend CORS on Render (both Node services)

Set in the **Render dashboard** for **user-service** and **integration-service** (local laptop `.env` is not used on Render). Same value on both services. See [backend-render.md](./backend-render.md) § `WEB_CORS_ORIGINS`.

Comma-separated if you still use local Vite against hosted APIs:

```env
WEB_CORS_ORIGINS=http://localhost:5173,https://sharingbridge-web.onrender.com
```

For production-only (no local browser testing against hosted APIs):

```env
WEB_CORS_ORIGINS=https://sharingbridge-web.onrender.com
```

Redeploy **both** services after changing CORS.

Also on **user-service** (Render):

```env
GOOGLE_CLIENT_ID_WEB=<web client id>
GOOGLE_CLIENT_ID_ANDROID=<android client id>
BYPASS_GOOGLE_SIGN_IN=false
```

### 7.4 Coordinator role on Render / Supabase

Grant **`coordinator`** in **`user_roles`** on your Postgres instance (Supabase SQL Editor or psql) using [coordinator-seed.sql](./coordinator-seed.sql). No extra user-service env vars.

### 7.5 Verify hosted web

1. Open `https://<your-static-site>.onrender.com`.
2. **Sign in with Google** (Gmail with `coordinator` in `user_roles`).
3. Mobile app must use **hosted** integration URL (`API_BASE_URL` = same as `VITE_API_BASE_URL`) for intents to appear on the hosted dashboard.

### Order of operations (recommended)

1. Deploy **user-service** + **integration-service** on Render (if not already).
2. Deploy **static site** with `VITE_*` pointing at those URLs.
3. Copy static site URL → add to Google **JavaScript origins**.
4. Update `WEB_CORS_ORIGINS` on both backends → redeploy.
5. Test local (`localhost:5173`) and hosted URLs.

Details: [backend-render.md](./backend-render.md), [web-client.md](./web-client.md).

---

## Troubleshooting

| Symptom | Likely cause | Fix |
|---------|----------------|-----|
| `403 wrong_client_role` on web | Gmail has no `coordinator` in `user_roles` | Run [coordinator-seed.sql](./coordinator-seed.sql) after the user row exists |
| `403 wrong_client_role` on mobile | Missing `donor` in `user_roles` | Sign in again (donor is ensured on each auth); check DB `user_roles` |
| `401 invalid_google_token` | Wrong client ID or expired token | Web: `VITE_GOOGLE_CLIENT_ID` = Web client ID; user-service lists same ID in `GOOGLE_CLIENT_ID_WEB` |
| Google popup “access blocked” | App in Testing, user not a test user | Add Gmail under OAuth consent → **Test users** |
| `Failed to fetch` on sign-in | CORS | `WEB_CORS_ORIGINS=http://localhost:5173` on **both** user-service and integration-service; restart |
| Android sign-in fails | Wrong SHA-1 or package name | Re-create Android OAuth client with debug SHA-1 + correct `applicationId` |
| `dev_auth_disabled` | Dev mint off | Set `BYPASS_GOOGLE_SIGN_IN=true` for local dev only |
| Wrong Google account on sign-in button | Chrome / GIS remembers last account | **Use a different Google account** (after at least one prior sign-in on this browser), or **Sign in with Google** → **Use another account** in Google’s dialog; or **Sign out** then sign in again |

Verify Google token manually (optional):

```powershell
# After GIS sign-in, paste id_token from browser devtools network tab into:
Invoke-RestMethod -Method POST -Uri http://localhost:8081/v1/auth/google `
  -ContentType application/json `
  -Body (@{ id_token = "<paste>"; client_type = "web" } | ConvertTo-Json)
```

---

## Quick checklist

- [ ] Google Cloud project created
- [ ] OAuth consent screen configured + test users added
- [ ] **Web** OAuth client → origins include `http://localhost:5173`
- [ ] **Android** OAuth client → package name + debug SHA-1
- [ ] `user_roles` includes `coordinator` for dashboard Gmail(s) ([coordinator-seed.sql](./coordinator-seed.sql))
- [ ] user-service `.env`: Google client IDs, CORS, `AUTH_TOKEN_SECRET`
- [ ] integration-service `.env`: same secret + CORS
- [ ] web `.env`: `VITE_GOOGLE_CLIENT_ID`, API URLs
- [ ] All three services restarted
- [ ] Web sign-in (coordinator) + mobile sign-in (donor) tested
