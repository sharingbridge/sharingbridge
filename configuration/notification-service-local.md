# Notification service — local and Render

Repository: `sharingbridge-notification-service` (Node 20).

**Purpose:** When an eco kitchen **commits**, integration-service POSTs here; this service looks up FCM tokens in `device_tokens` and sends **connection-ready** push to mobile.

**Prerequisites:** SQL **M5** — [database-setup-sequence.md](./database-setup-sequence.md). Wire after integration-service is running.

Deploy on Render: [backend-render.md](./backend-render.md) § Notification service. Env keys: [environment-variables.md](./environment-variables.md) § `sharingbridge-notification-service`.

---

## If this step was skipped

| Missing piece | Effect |
|---------------|--------|
| **M5** `device_tokens` | Mobile `PUT /v1/device-tokens` fails; no token storage |
| **notification-service** not running | Integration logs connection-ready; no FCM multicast |
| **`CONNECTION_NOTIFY_WEBHOOK_*`** unset on integration | Same — commit succeeds; no push |
| **Firebase Admin** credentials | Service starts; logs push disabled; no multicast |
| **`google-services.json` + SHA on APK** | Mobile does not register FCM after sign-in |

**Web Connection panel** (`GET /v1/connections/:orderCode`) still works when **M4** is applied — it is the in-app source of truth for emails. Push only alerts the user to open the app.

---

## Prerequisites checklist

| Requirement | Detail |
|-------------|--------|
| Postgres | **M5** — [schema-device-tokens-migration.sql](./schema-device-tokens-migration.sql) |
| Integration webhook | `CONNECTION_NOTIFY_WEBHOOK_URL` + `CONNECTION_NOTIFY_WEBHOOK_SECRET` |
| Firebase project | FCM enabled; Android app `app.sharingbridge` registered |
| Mobile APK | Rebuild after `google-services.json` — [mobile-client.md](./mobile-client.md) § FCM push |

---

## Local run

**Port:** **8093** (photo-service uses **8092**).

```powershell
cd sharingbridge-notification-service
copy env.example .env
# DATABASE_URL — same as integration-service
# WEBHOOK_SECRET — same value as CONNECTION_NOTIFY_WEBHOOK_SECRET on integration
# FIREBASE_SERVICE_ACCOUNT_PATH=.\firebase-adminsdk.json
npm install
npm test
npm start
```

Health: `http://localhost:8093/health`

Integration-service `.env`:

```env
CONNECTION_NOTIFY_WEBHOOK_URL=http://localhost:8093/internal/connection-ready
CONNECTION_NOTIFY_WEBHOOK_SECRET=<same as notification WEBHOOK_SECRET>
```

Restart integration-service after changing webhook env.

---

## Firebase Admin (service account)

1. [Firebase Console](https://console.firebase.google.com/) → **Project settings** → **Service accounts**.
2. **Generate new private key** → save JSON (never commit).
3. **Local:** `FIREBASE_SERVICE_ACCOUNT_PATH` → file path.
4. **Render:** paste full JSON into `FIREBASE_SERVICE_ACCOUNT_JSON`.

This is **not** `google-services.json` (that file is for the mobile app).

---

## Firebase Android app (mobile)

1. Firebase Console → **Add app** → **Android** → package `app.sharingbridge`.
2. Download `google-services.json` → `sharingbridge-mobile-app/android/app/google-services.json`.
3. Add **SHA-1** / **SHA-256** of your signing key in Firebase.
4. Rebuild APK (`flutter build apk` or `flutter run`).

After sign-in, mobile calls `PUT /v1/device-tokens` on integration-service.

---

## Webhook contract

Integration POSTs `POST /internal/connection-ready` with header `X-Webhook-Secret`.

```json
{
  "type": "connection_ready",
  "order_code": "SB-7K2M-9F3",
  "recipient_user_ids": ["user-id-1"],
  "recipient_emails": ["user@example.com"],
  "subject": "SharingBridge — order SB-7K2M-9F3 connection ready",
  "text": "Order SB-7K2M-9F3 — a connection is ready..."
}
```

Notification-service resolves `recipient_user_ids` → `device_tokens` → FCM multicast. Automated email is not implemented yet.

---

## Smoke test

1. notification-service on 8093; integration with matching `CONNECTION_NOTIFY_WEBHOOK_*`.
2. Mobile sign-in → `device_tokens` row in Postgres.
3. Coordinator **Kitchen commit** on Actions → push on initiator/pledger device.

Manual walkthrough: [MANUAL_TESTING_GUIDE.md](../testing/MANUAL_TESTING_GUIDE.md) **§4d**, **§4f**, **§4g**.

---

## Render

[backend-render.md](./backend-render.md) — deploy **after** integration-service; set integration `CONNECTION_NOTIFY_WEBHOOK_URL` to the notification public URL.
