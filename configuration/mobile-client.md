# Mobile client configuration

Repository: `sharingbridge-mobile-app` (Flutter).

## API endpoints

| Use | URL |
|-----|-----|
| **All donor APIs** (setup, suggest-vendors, instruction-pack, presets, order-intents) | **integration-service** only |
| **Sign in** | **Google** in app → `POST /v1/auth/google` on user-service; optional dev `--dart-define=AUTH_TOKEN` (locally minted JWT) |

Mobile must **not** call ai-orchestration directly.

## Local networking and `--dart-define` URLs

The integration and user-service processes listen on **your PC**. The Flutter app runs on an **emulator or phone**, so URLs must reach the PC from **that** device.

### Choose one target (use the same host for all defines)

| Target | `USER_SERVICE_BASE_URL` | `API_BASE_URL` | `PHOTO_SERVICE_BASE_URL` | `WEB_DASHBOARD_URL` |
|--------|-------------------------|----------------|--------------------------|---------------------|
| Android emulator | `http://10.0.2.2:8081` | `http://10.0.2.2:8080` | `http://10.0.2.2:8092` | `http://10.0.2.2:5173` |
| Windows desktop | `http://localhost:8081` | `http://localhost:8080` | `http://localhost:8092` | `http://localhost:5173` |
| Physical Android phone | `http://<PC-LAN-IP>:8081` | `http://<PC-LAN-IP>:8080` | `http://<PC-LAN-IP>:8092` | `http://<PC-LAN-IP>:5173` |
| Hosted (Render) | `https://…user-service…onrender.com` | `https://…integration…onrender.com` | `https://…photo-service…onrender.com` | `https://<static-site>.onrender.com` |

**`<PC-LAN-IP>`** = IPv4 from `ipconfig` (Wi‑Fi adapter), e.g. `192.168.1.3`. Do **not** use `localhost` or `10.0.2.2` on a physical phone.

### Physical phone: same Wi‑Fi as the PC

`192.168.x.x` is a **private LAN** address. The phone must use the **same Wi‑Fi/router** as the PC. It will **not** work if the phone is on mobile data, a different ISP, or isolated guest Wi‑Fi.

1. On the phone browser, open `http://<PC-LAN-IP>:8080/health` → expect `{"ok":true,"service":"integration-service"}`.
2. If that fails, fix network/firewall before debugging the app.
3. After changing `--dart-define`, run **`flutter run` again** (not hot reload).

### USB + `adb reverse` (different networks)

```powershell
$adb = "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe"
& $adb reverse tcp:8080 tcp:8080
& $adb reverse tcp:8081 tcp:8081
& $adb reverse tcp:8092 tcp:8092
```

Then set all three URLs to `http://127.0.0.1:8080`, `:8081`, `:8092`.

### HTTP vs HTTPS (Android security)

| Build | Plain `http://` to LAN / emulator |
|-------|-----------------------------------|
| `flutter run` (debug / profile) | Allowed — cleartext permitted only in debug/profile manifests |
| Release APK | **Blocked** — use `https://` Render URLs for hosted testing |

Full walkthrough: [MANUAL_TESTING_GUIDE.md](../testing/MANUAL_TESTING_GUIDE.md) **§3-host**.

**Neighbourhood dashboard (web)** — home screen tile **Neighbourhood dashboard (web)** opens the donor web app in the browser. **Required** at build time:

```text
--dart-define=WEB_DASHBOARD_URL=<URL from table above>
```

The tile is always visible; it is tappable only when `WEB_DASHBOARD_URL` is set. On the web dashboard, choose **By area** and allow location when prompted so **Distance (m)** loads from your current position.

## `dart-define` (hosted Render)

Use **Google Sign-In** with hosted `USER_SERVICE_BASE_URL` and `GOOGLE_CLIENT_ID` (see [e2e-deployment-sequence.md](./e2e-deployment-sequence.md)). There is no HTTP endpoint to mint a JWT without Google on production.

## Google Sign-In (local, recommended)

**Windows / Linux desktop:** `google_sign_in` is **not supported** — the app shows an explanation instead of `MissingPluginException`. Use an **Android emulator**, a physical Android device, or **macOS** for Google auth. Desktop dev fallback: `--dart-define=AUTH_TOKEN=…` (JWT from `node scripts/mint-dev-jwt.mjs` in user-service with the same `AUTH_TOKEN_SECRET`).

Full checklist: [google-auth-setup.md](./google-auth-setup.md).

**Android emulator** (both URLs must use the host alias — not `localhost`):

```powershell
cd D:\kannan\sharingbridge\sharingbridge-mobile-app
flutter run -d emulator-5554 `
  --dart-define=GOOGLE_CLIENT_ID=<Android OAuth client ID from Google Cloud> `
  --dart-define=USER_SERVICE_BASE_URL=http://10.0.2.2:8081 `
  --dart-define=API_BASE_URL=http://10.0.2.2:8080 `
  --dart-define=PHOTO_SERVICE_BASE_URL=http://10.0.2.2:8092 `
  --dart-define=WEB_DASHBOARD_URL=http://10.0.2.2:5173
```

Reference photos (optional on **Help a seeker**) upload to **photo-service** when the donor taps **Get AI delivery instructions**. See [photo-service-local.md](./photo-service-local.md).

**Physical Android phone** (replace `192.168.1.3` with your `ipconfig` IPv4; **same Wi‑Fi as PC**):

```powershell
flutter run -d <device_id> `
  --dart-define=GOOGLE_CLIENT_ID=<Android OAuth client ID> `
  --dart-define=USER_SERVICE_BASE_URL=http://192.168.1.3:8081 `
  --dart-define=API_BASE_URL=http://192.168.1.3:8080 `
  --dart-define=PHOTO_SERVICE_BASE_URL=http://192.168.1.3:8092 `
  --dart-define=WEB_DASHBOARD_URL=http://192.168.1.3:5173
```

**Windows desktop** (Google Sign-In not supported; use dev token or emulator):

```powershell
flutter run -d windows `
  --dart-define=GOOGLE_CLIENT_ID=... `
  --dart-define=USER_SERVICE_BASE_URL=http://localhost:8081 `
  --dart-define=API_BASE_URL=http://localhost:8080
```

Tap **Continue with Google** on launch. Mobile mints JWT `role: donor`; users with both `donor` and `coordinator` in `user_roles` may use web and mobile with the same Gmail.

## Dev token fallback (no Google)

Mint on the PC with the same `AUTH_TOKEN_SECRET` as your local user-service `.env`. From an **emulator**, point the app at `10.0.2.2`:

```powershell
cd D:\kannan\sharingbridge\sharingbridge-user-service
$token = node scripts/mint-dev-jwt.mjs demo-user donor
cd ..\sharingbridge-mobile-app
flutter run -d emulator-5554 `
  --dart-define=USER_SERVICE_BASE_URL=http://10.0.2.2:8081 `
  --dart-define=API_BASE_URL=http://10.0.2.2:8080 `
  --dart-define=USER_ID=demo-user `
  --dart-define=AUTH_TOKEN=$token
```

**Web dashboard (coordinator):** [web-client.md](./web-client.md) lists all donors’ order intents when `VITE_API_BASE_URL` matches mobile `API_BASE_URL` (same integration host).

## Navigation (Home)

After sign-in, the app uses an inner navigator with **SharingBridge** (hub) as the root route.

| Screen | App bar |
|--------|---------|
| Hub (`AppHomePage`) | Title only — no Back or Home |
| Vendor presets, Help a seeker, Order initiation history, detail | **Back** + labeled **Home** → returns to the hub |

Rebuild or `flutter run` after pulling; an older APK will not show Home.

## Main flows

| Screen | Backend |
|--------|---------|
| Vendor presets | integration — suggest-vendors, save/load presets |
| Help a seeker | instruction-pack + `POST …/order-intents` on copy — see [field-handoff.md](./field-handoff.md) |
| Order initiation history | `GET …/order-intents` — list grouped **by day**, detail on tap |

Offline: presets may cache in `shared_preferences` when integration is unreachable.

See [MANUAL_TESTING_GUIDE.md](../testing/MANUAL_TESTING_GUIDE.md) **§3** (mobile); web dashboard **§4**.
