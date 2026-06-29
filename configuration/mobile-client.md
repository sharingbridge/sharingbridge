# Mobile client configuration

Repository: `sharingbridge-mobile-app` (Flutter).

## API endpoints

| Use | URL |
|-----|-----|
| **All initiator APIs** (setup, suggest-vendors, instruction-pack, presets, order-intents, seeker-demands, device-tokens) | **integration-service** only |
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

**Neighbourhood dashboard (web)** — home screen tile **Neighbourhood dashboard (web)** opens the web dashboard in the browser. **Required** at build time:

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

Reference photos (optional on **Help a seeker**) upload to **photo-service** when the initiator taps **Get AI delivery instructions**. See [photo-service-local.md](./photo-service-local.md).

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

Tap **Continue with Google** on launch. Mobile mints JWT `role: initiator`; users with both `donor`/`initiator` and `coordinator` in `user_roles` may use web and mobile with the same Gmail.

## Dev token fallback (no Google)

Mint on the PC with the same `AUTH_TOKEN_SECRET` as your local user-service `.env`. From an **emulator**, point the app at `10.0.2.2`:

```powershell
cd D:\kannan\sharingbridge\sharingbridge-user-service
$token = node scripts/mint-dev-jwt.mjs demo-user initiator
cd ..\sharingbridge-mobile-app
flutter run -d emulator-5554 `
  --dart-define=USER_SERVICE_BASE_URL=http://10.0.2.2:8081 `
  --dart-define=API_BASE_URL=http://10.0.2.2:8080 `
  --dart-define=USER_ID=demo-user `
  --dart-define=AUTH_TOKEN=$token
```

**Web dashboard (coordinator):** [web-client.md](./web-client.md) lists all initiators’ order intents when `VITE_API_BASE_URL` matches mobile `API_BASE_URL` (same integration host).

## Release APK (`flutter build apk --release`)

Use a **release** build for sideloading to testers, physical devices without USB debugging, or before Play Store upload. **`--dart-define` values are baked in at compile time** — same set as `flutter run`, but hosted URLs must use **`https://`** (release blocks plain `http://` to LAN IPs).

### Before you build

| Item | Where |
|------|--------|
| Flutter SDK + Android SDK | `flutter doctor` |
| API URLs + Google client | `--dart-define` on the command below ([environment-variables.md](./environment-variables.md) § mobile) |
| Optional handover map | `GOOGLE_MAPS_API_KEY` in `local.properties` **and** `--dart-define=HANDOVER_MAP_ENABLED=true` ([§ Handover map](#handover-map-picker--two-settings-not-one)) |
| Optional FCM push | `android/app/google-services.json` + Firebase SHA fingerprints — [§ FCM push](#fcm-push-connection-ready) |
| Release signing | Debug keystore today (`build.gradle.kts` TODO); configure `key.properties` before Play Store |

### Hosted Render (typical)

Replace placeholders with your Render URLs (must match web `VITE_API_BASE_URL` / `VITE_USER_SERVICE_BASE_URL`):

```powershell
cd D:\kannan\sharingbridge\sharingbridge-mobile-app
flutter pub get
flutter build apk --release `
  --dart-define=GOOGLE_CLIENT_ID=<Android OAuth client ID> `
  --dart-define=USER_SERVICE_BASE_URL=https://<your-user-service>.onrender.com `
  --dart-define=API_BASE_URL=https://<your-integration-service>.onrender.com `
  --dart-define=PHOTO_SERVICE_BASE_URL=https://<your-photo-service>.onrender.com `
  --dart-define=WEB_DASHBOARD_URL=https://<your-static-site>.onrender.com
```

Add `--dart-define=HANDOVER_MAP_ENABLED=true` when shipping the map picker (with `GOOGLE_MAPS_API_KEY` in `local.properties`). See [§ Handover map](#handover-map-picker--two-settings-not-one).

**Output:** `build\app\outputs\flutter-apk\app-release.apk`

**Install on a connected phone** (USB debugging on):

```powershell
$adb = "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe"
& $adb install -r build\app\outputs\flutter-apk\app-release.apk
```

Or copy the APK to the device and open it (allow install from unknown sources if prompted).

### Handover map picker — two settings, not one

The map picker needs **both** of these at build time. They are **not** interchangeable:

| Setting | Where | What it controls |
|---------|--------|------------------|
| **`GOOGLE_MAPS_API_KEY`** | `android/local.properties` only | Native Google Maps SDK (manifest) — **map tiles** |
| **`HANDOVER_MAP_ENABLED`** | `--dart-define=HANDOVER_MAP_ENABLED=true\|false` | Dart compile-time — **map screen vs coordinate form** |

`local.properties` is read by **Gradle/Android only**. Flutter/Dart does **not** see the API key, so the key alone does **not** switch the UI to the map picker.

**Recommended (map picker on):** set the key **and** pass the flag on every `flutter run` / `flutter build apk` / `flutter build appbundle`:

```powershell
flutter build apk --release `
  --dart-define=HANDOVER_MAP_ENABLED=true `
  --dart-define=GOOGLE_CLIENT_ID=<Android OAuth client ID> `
  --dart-define=USER_SERVICE_BASE_URL=https://<your-user-service>.onrender.com `
  --dart-define=API_BASE_URL=https://<your-integration-service>.onrender.com `
  --dart-define=PHOTO_SERVICE_BASE_URL=https://<your-photo-service>.onrender.com `
  --dart-define=WEB_DASHBOARD_URL=https://<your-static-site>.onrender.com
```

(With `GOOGLE_MAPS_API_KEY=AIza…` in `android/local.properties`.)

**Form only (no map UI):**

```powershell
flutter build apk --release `
  --dart-define=HANDOVER_MAP_ENABLED=false `
  --dart-define=GOOGLE_CLIENT_ID=... `
  ...
```

**Gradle convenience (optional):** if `GOOGLE_MAPS_API_KEY` is non-empty in `local.properties` and you **omit** `HANDOVER_MAP_ENABLED` on the command line, `android/app/build.gradle.kts` merges `HANDOVER_MAP_ENABLED=true` into Gradle’s `dart-defines`. That can save typing on `flutter run`, but **passing `--dart-define=HANDOVER_MAP_ENABLED=true` explicitly is clearer and always correct** when you want the map.

**Do not** pass `HANDOVER_MAP_ENABLED=true` without `GOOGLE_MAPS_API_KEY` in `local.properties` — the map screen may show but tiles will not load. **Never** put the Maps API key in `--dart-define`.

Same rules apply to `flutter run`. See [environment-variables.md](./environment-variables.md) § mobile.

### Play Store (optional)

```powershell
flutter build appbundle --release `
  --dart-define=GOOGLE_CLIENT_ID=... `
  --dart-define=USER_SERVICE_BASE_URL=https://... `
  --dart-define=API_BASE_URL=https://... `
  --dart-define=PHOTO_SERVICE_BASE_URL=https://... `
  --dart-define=WEB_DASHBOARD_URL=https://...
```

Upload `build\app\outputs\bundle\release\app-release.aab` in Google Play Console. Configure a release keystore in `android/app/build.gradle.kts` first (not debug signing).

Manual walkthrough: [MANUAL_TESTING_GUIDE.md](../testing/MANUAL_TESTING_GUIDE.md) **§3-build**. Deploy context: [e2e-deployment-sequence.md](./e2e-deployment-sequence.md) § Mobile.

## Navigation (Home)

After sign-in, the app uses an inner navigator with **SharingBridge** (hub) as the root route.

| Screen | App bar |
|--------|---------|
| Hub (`AppHomePage`) | Title only — no Back or Home |
| Vendor presets, Help a seeker, Start initiation, Initiations, detail | **Back** + labeled **Home** → returns to the hub |

Rebuild or `flutter run` after pulling; an older APK will not show Home.

## Main flows

| Screen | Backend |
|--------|---------|
| Vendor presets | integration — suggest-vendors, save/load presets |
| Help a seeker | **Direct order** — instruction-pack + `POST …/order-intents` — [field-handoff.md](./field-handoff.md) |
| Start initiation | Route picker: **Direct order**, **Eco kitchen · open for pledging**, **Eco kitchen · I pay** |
| Eco kitchen routes | `POST /v1/seeker-demands` with `initiation_route` — web **Actions** tab (pledge + kitchen commit) |
| Initiations | `GET …/order-intents` + seeker demands — merged list |

Initiation routes: [Eco_Kitchen_Initiation_Flow.md](../design/Eco_Kitchen_Initiation_Flow.md).

## Handover location — map picker, address, pickup note

**Reading sequence:** [README.md § Natural reading order](../README.md#documentation-guide) — step **13** (after [field-handoff.md](./field-handoff.md), [Location_Services_Vendor_Abstraction.md](../design/Location_Services_Vendor_Abstraction.md), [Handover_Location_Map_Picker.md](../design/Handover_Location_Map_Picker.md)).

All initiation routes share **`HandoverLocationPicker`** on mobile (eco kitchen + **Help a seeker**).

| Doc | Purpose |
|-----|---------|
| [Handover_Location_Map_Picker.md](../design/Handover_Location_Map_Picker.md) | Map picker UX, API, eco menu behaviour |
| [Location_Services_Vendor_Abstraction.md](../design/Location_Services_Vendor_Abstraction.md) | **Vendor strategy** — one vendor per capability, adapter seams, env keys |

**Vendor model (v1):** Google **map tiles** from `GOOGLE_MAPS_API_KEY` in `android/local.properties`; **map screen vs form** from `--dart-define=HANDOVER_MAP_ENABLED=true|false` (Gradle may auto-add `true` when the key is set and the flag is omitted — see [§ Release APK § Handover map](#handover-map-picker--two-settings-not-one)). **Address + postal area** always from integration-service (`GET /v1/geocode/reverse` → Nominatim).

When `HANDOVER_MAP_ENABLED=true` and the native key is set, the initiator sees a **cab-style map** (pan map, fixed pin). With `HANDOVER_MAP_ENABLED=false` (or unset and no Gradle auto-inject), the app uses editable coordinate fields (`HandoverLocationConfirmCard`).

| Field on screen | API field | Source |
|-----------------|-----------|--------|
| **Address** | (display; not stored separately today) | `GET /v1/geocode/reverse` → Nominatim on integration-service |
| **Pickup note** (landmark / gate) | `location_label` | User (required, ≥3 characters) |
| **Postal area** | `locality_key` | Server reverse-geocode from map pin |
| Coordinates | `location_lat`, `location_lng` | Map pin centre / GPS |

### Google Maps setup (Android)

1. Enable **Maps SDK for Android** in Google Cloud; create an API key restricted to `app.sharingbridge` + debug/release SHA-1.
2. `android/local.properties`: `GOOGLE_MAPS_API_KEY=AIza…` (see `local.properties.example`) — **tiles only**; Dart does not read this file.
3. Pass **`--dart-define=HANDOVER_MAP_ENABLED=true`** on `flutter run` / `flutter build apk` (or rely on Gradle auto-inject when the key is set — explicit `true` is clearer).

Optional: `--dart-define=HANDOVER_MAP_ENABLED=false` to force the coordinate form.

Maps tiles use Google; **address and postal area** use integration-service (same Nominatim path as menu resolution) — no Google Geocoding API required for v1.

### Label vs vendor delivery address

- **Pickup note** = where to meet (`location_label`) — not the Swiggy/Zomato checkout address.
- **Handover notes** (`verbal_handover_notes`) = appearance, dietary, gate codes, etc.

### Refresh GPS and menu reload (eco kitchen flows)

GPS is **not** derived from the label. The standard menu and **Postal area** line use **latitude/longitude only** (`GET /v1/standard-offers?location_lat=…&location_lng=…`); the server reverse-geocodes coordinates to `locality_key`.

| Control | Updates lat/lng? | Updates label? | Reloads menu? |
|---------|------------------|----------------|---------------|
| **Allow location & load menu** (first tap) | Yes — device GPS | No | Yes |
| **Refresh GPS** on confirm card | Yes — device GPS | No — keeps typed text | **Yes — automatic** |
| Manual edit of lat/lng on card | Yes | No | **Clears menu** — **Reload menu for updated coordinates** appears; menu item, units, notes, photo, and submit stay disabled until reload |
| Manual edit of label only | No | Yes | No |

The separate reload control is **only shown** when coordinates have been edited by hand and no longer match the menu that was loaded. After **Refresh GPS**, the app reloads the menu automatically and hides the reload button again.

### Refresh GPS behaviour (Help a seeker)

| Control | Updates lat/lng? | Updates label? |
|---------|------------------|----------------|
| **Refresh GPS** / **Recapture handover location** | Yes — new device position | **No** — keeps text you already typed |
| Manual edit of lat/lng fields | Yes | No |
| Manual edit of label field | No | Yes |

## FCM push (connection-ready)

**Optional** — requires notification-service on Render and Firebase setup.

| Step | Action |
|------|--------|
| 1 | Run [schema-device-tokens-migration.sql](./schema-device-tokens-migration.sql) on Postgres |
| 2 | Deploy [notification-service](./notification-service-local.md) + wire `CONNECTION_NOTIFY_WEBHOOK_*` on integration-service |
| 3 | Firebase Console → Android app package `app.sharingbridge` |
| 4 | Download `google-services.json` → `sharingbridge-mobile-app/android/app/google-services.json` (template: `google-services.json.example`) |
| 5 | Add APK signing **SHA-1** / **SHA-256** in Firebase (debug keystore for dev; release keystore for production) |
| 6 | Rebuild APK — [§ Release APK](#release-apk-flutter-build-apk---release) — after sign-in, app registers token via `PUT /v1/device-tokens` |

Push fires when a coordinator records a **kitchen commit** on the Actions tab and integration-service POSTs to the notification webhook. Users can still open **Connection** in the web dashboard without push.

Offline: presets may cache in `shared_preferences` when integration is unreachable.

See [MANUAL_TESTING_GUIDE.md](../testing/MANUAL_TESTING_GUIDE.md) **§3** (mobile); web dashboard **§4**.
