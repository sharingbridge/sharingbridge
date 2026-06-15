# Notification service — local and Render

Repository: `sharingbridge-notification-service` (Node 20).

**Purpose:** When an eco kitchen **commits** on an order, integration-service POSTs to this service; it looks up FCM tokens in Postgres (`device_tokens`) and sends **connection-ready** push notifications.

**Optional:** Connection lookup in the web **Actions** tab works without this service. Push is additive.

Deploy on Render: [backend-render.md](./backend-render.md) § Notification service. Env keys: [environment-variables.md](./environment-variables.md) § `sharingbridge-notification-service`.

---

## Prerequisites

| Requirement | Detail |
|-------------|--------|
| Postgres | `device_tokens` table — run [schema-device-tokens-migration.sql](./schema-device-tokens-migration.sql) (M5 in [database-setup-sequence.md](./database-setup-sequence.md)) |
| Integration webhook | `CONNECTION_NOTIFY_WEBHOOK_URL` + `CONNECTION_NOTIFY_WEBHOOK_SECRET` on integration-service |
| Firebase project | FCM enabled; Android app `app.sharingbridge` registered |
| Mobile APK | Rebuild after adding `google-services.json` — [mobile-client.md](./mobile-client.md) § FCM push |

---

## Local run

**Port:** use **8093** locally so photo-service can keep **8092**.

```powershell
cd sharingbridge-notification-service
copy env.example .env
# DATABASE_URL — same as integration-service
# WEBHOOK_SECRET — same value you will set as CONNECTION_NOTIFY_WEBHOOK_SECRET on integration-service
# FIREBASE_SERVICE_ACCOUNT_PATH=.\firebase-adminsdk.json
npm install
npm test
npm start
```

Health: `http://localhost:8093/health`

Wire integration-service `.env`:

```env
CONNECTION_NOTIFY_WEBHOOK_URL=http://localhost:8093/internal/connection-ready
CONNECTION_NOTIFY_WEBHOOK_SECRET=<same as notification WEBHOOK_SECRET>
```

Restart integration-service after changing webhook env.

---

## Firebase Admin (service account)

1. [Firebase Console](https://console.firebase.google.com/) → your project → **Project settings** → **Service accounts**.
2. **Generate new private key** → save JSON (never commit — listed in repo `.gitignore`).
3. **Local:** set `FIREBASE_SERVICE_ACCOUNT_PATH` to that file path.
4. **Render:** paste the **entire JSON** into secret env `FIREBASE_SERVICE_ACCOUNT_JSON` (single line is fine).

Without Firebase credentials the service starts but logs `[fcm] … push delivery disabled` and skips multicast.

---

## Firebase Android app (mobile)

1. Firebase Console → **Add app** → **Android** → package name `app.sharingbridge`.
2. Download `google-services.json` → place in `sharingbridge-mobile-app/android/app/google-services.json` (see `google-services.json.example` in repo).
3. Add **SHA-1** / **SHA-256** of your signing key under the Android app in Firebase (debug keystore for dev builds; release keystore for production APK).
4. Rebuild the APK (`flutter build apk` or `flutter run` on device).

After sign-in, mobile calls `PUT /v1/device-tokens` on integration-service with the FCM token.

---

## Webhook contract

Integration-service POSTs to `POST /internal/connection-ready` with header `X-Webhook-Secret` when `CONNECTION_NOTIFY_WEBHOOK_SECRET` is set.

Example body:

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

Notification-service resolves `recipient_user_ids` → rows in `device_tokens` → FCM multicast. Email (Resend/SendGrid) is not implemented yet.

---

## Smoke test (local)

1. Run notification-service on 8093 with webhook secret set.
2. Run integration-service with matching `CONNECTION_NOTIFY_WEBHOOK_*`.
3. Sign in on mobile → confirm `device_tokens` row in Postgres.
4. Coordinator commits kitchen on Actions → check notification-service logs for multicast result.

---

## Render

See [backend-render.md](./backend-render.md) — deploy **after** integration-service; copy notification public URL into integration `CONNECTION_NOTIFY_WEBHOOK_URL`.
