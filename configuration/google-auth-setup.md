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
| **Coordinator allowlist** | Which Google **emails** get coordinator role on web |

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
3. **Package name** — from `sharingbridge-mobile-app/android/app/build.gradle` → `applicationId` (often `com.example.sharingbridge_mobile_app` or your org id).
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

### 2.4 Windows desktop (optional)

Flutter **Windows** `google_sign_in` may need a **Desktop** OAuth client or use web client + `clientId` in code. For local MVP, prefer **Android emulator** or **Chrome web** for coordinators; Windows desktop Google sign-in is the least documented path.

---

## Part 3 — Coordinator allowlist (local DB)

Coordinators are **not** chosen in Google Console. They are allowlisted **by email** in user-service.

```powershell
cd D:\kannan\sharingbridge\sharingbridge-user-service
copy data\coordinators.json.example data\coordinators.json
```

Edit `data\coordinators.json`:

```json
{
  "emails": [
    "your.name@gmail.com"
  ]
}
```

Use the **same Gmail** you added as a **test user** on the consent screen.

Alternative (no file): in user-service `.env`:

```env
COORDINATOR_EMAILS=your.name@gmail.com,teammate@gmail.com
```

**Rules:**

- Email on allowlist → role **`coordinator`** (may use **web** only).
- Any other Google email → role **`donor`** (may use **mobile** only).
- Donor signing into **web** → `403 wrong_client_role`.
- Coordinator signing into **mobile** → `403 wrong_client_role`.

---

## Part 4 — Environment files

### 4.1 `sharingbridge-user-service/.env`

Copy from `.env.example`:

```powershell
cd D:\kannan\sharingbridge\sharingbridge-user-service
copy .env.example .env
```

Set at minimum:

```env
AUTH_TOKEN_SECRET=your-long-random-secret-shared-with-integration
AUTH_TOKEN_ISSUER=sharingbridge-user-service
AUTH_TOKEN_AUDIENCE=sharingbridge-clients
AUTH_TOKEN_TTL_SECONDS=3600

WEB_CORS_ORIGINS=http://localhost:5173

GOOGLE_CLIENT_ID_WEB=123456789-xxxx.apps.googleusercontent.com
GOOGLE_CLIENT_ID_ANDROID=123456789-yyyy.apps.googleusercontent.com

ALLOW_DEV_TOKEN_MINT=true
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

(Plus your existing AI / preferences vars.)

### 4.3 `sharingbridge-web-app/.env`

```powershell
cd D:\kannan\sharingbridge\sharingbridge-web-app
copy .env.example .env
```

```env
VITE_API_BASE_URL=http://localhost:8080
VITE_USER_SERVICE_BASE_URL=http://localhost:8081
VITE_GOOGLE_CLIENT_ID=<same as GOOGLE_CLIENT_ID_WEB>

# Optional: skip Google until clients are ready
# VITE_ALLOW_DEV_SIGN_IN=true
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
2. Click **Sign in with Google** (GIS).
3. Use an email listed in `coordinators.json`.
4. Dashboard should load; **Refresh** shows order initiations (after a donor registers one on mobile).

**Without Google yet:** set `VITE_ALLOW_DEV_SIGN_IN=true`, ensure `ALLOW_DEV_TOKEN_MINT=true`, use **Dev sign in** on the web page.

### 6.2 Donor (mobile)

```powershell
cd D:\kannan\sharingbridge\sharingbridge-mobile-app
flutter pub get
flutter run -d <device> `
  --dart-define=GOOGLE_CLIENT_ID=<GOOGLE_CLIENT_ID_ANDROID> `
  --dart-define=USER_SERVICE_BASE_URL=http://localhost:8081 `
  --dart-define=API_BASE_URL=http://localhost:8080
```

Android emulator integration URL: `--dart-define=API_BASE_URL=http://10.0.2.2:8080`

1. Tap **Continue with Google**.
2. Use a Google account **not** on the coordinator allowlist (or any account — non-allowlisted emails become donors).
3. Complete **Help a seeker** → copy instructions to register an order intent.
4. On web (coordinator), **Refresh** — you should see that intent (with donor `user_id` in the list).

**Without Google yet:** keep using dev mint:

```powershell
$token = (Invoke-RestMethod -Method POST -Uri http://localhost:8081/v1/auth/token `
  -ContentType application/json -Body '{"user_id":"demo-user","role":"donor"}').token
flutter run --dart-define=API_BASE_URL=http://localhost:8080 `
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

   Do **not** set `VITE_ALLOW_DEV_SIGN_IN` on Render (production).

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

On **user-service** and **integration-service** in Render, set `WEB_CORS_ORIGINS` to **comma-separated** origins if you still develop locally:

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
ALLOW_DEV_TOKEN_MINT=false
```

### 7.4 Coordinator allowlist on Render

Hosted user-service uses its own disk (or env). Either:

- Set `COORDINATOR_EMAILS=you@gmail.com,…` in Render **user-service** environment, **or**
- Use a persistent disk and upload `data/coordinators.json` (advanced).

Local `data/coordinators.json` is **not** copied to Render automatically.

### 7.5 Verify hosted web

1. Open `https://<your-static-site>.onrender.com`.
2. **Sign in with Google** (allowlisted coordinator email).
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
| `403 wrong_client_role` on web | Gmail not on coordinator allowlist | Add email to `data/coordinators.json`; restart user-service |
| `403 wrong_client_role` on mobile | Coordinator email used on phone | Use web for that account, or a non-allowlisted Gmail on mobile |
| `401 invalid_google_token` | Wrong client ID or expired token | Web: `VITE_GOOGLE_CLIENT_ID` = Web client ID; user-service lists same ID in `GOOGLE_CLIENT_ID_WEB` |
| Google popup “access blocked” | App in Testing, user not a test user | Add Gmail under OAuth consent → **Test users** |
| `Failed to fetch` on sign-in | CORS | `WEB_CORS_ORIGINS=http://localhost:5173` on **both** user-service and integration-service; restart |
| Android sign-in fails | Wrong SHA-1 or package name | Re-create Android OAuth client with debug SHA-1 + correct `applicationId` |
| `dev_auth_disabled` | Dev mint off | Set `ALLOW_DEV_TOKEN_MINT=true` for local dev only |

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
- [ ] `data/coordinators.json` lists coordinator Gmail(s)
- [ ] user-service `.env`: Google client IDs, CORS, `AUTH_TOKEN_SECRET`
- [ ] integration-service `.env`: same secret + CORS
- [ ] web `.env`: `VITE_GOOGLE_CLIENT_ID`, API URLs
- [ ] All three services restarted
- [ ] Web sign-in (coordinator) + mobile sign-in (donor) tested
