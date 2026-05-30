# Authentication and service credentials

SharingBridge uses **Google Sign-In** for production-style identity, plus **SharingBridge JWTs** for API calls. Internal service traffic uses a separate API key.

**Configure in order:** [e2e-deployment-sequence.md](./e2e-deployment-sequence.md).

## Google Sign-In (identity proof)

| | |
|--|--|
| **Purpose** | Prove the human signed in with Google |
| **Configured on** | `sharingbridge-user-service` only |
| **Client setup** | [Google Cloud Console](https://console.cloud.google.com/) → OAuth consent screen + OAuth 2.0 Client IDs |

**Flow**

1. Web or mobile obtains a Google **`id_token`** (GIS / `google_sign_in`).
2. Client calls `POST /v1/auth/google` on **user-service** with `{ "id_token": "…", "client_type": "web" \| "android" \| "ios" \| "mobile" }`.
3. user-service verifies `iss`, `aud`, `exp` via `google-auth-library`.
4. user-service maps `google_sub` → internal `user_id`, loads **roles** from persistence, mints SharingBridge JWT.

**Role assignment**

Roles are read from Postgres **`user_roles`** only — [database.md](./database.md) · [coordinator-seed.sql](./coordinator-seed.sql). There is no email allowlist in `.env` or JSON at runtime.

Every Google user gets **`donor`** ensured at sign-in. **`coordinator`** is granted only via SQL (or legacy JSON import where `user.role` was `coordinator`). Active role at sign-in follows **client rules** below.

**Client rules**

| `client_type` | Allowed role |
|---------------|----------------|
| `web` | **coordinator** only |
| `android` / `ios` / `mobile` | **donor** only |

Wrong combination → HTTP **403** `wrong_client_role`.

---

## Donor JWT (`AUTH_TOKEN_SECRET`)

| | |
|--|--|
| **Purpose** | Authorize API calls to integration-service (and user-service donor-presets) |
| **Set on** | `sharingbridge-user-service`, `sharingbridge-integration-service` |
| **Same value on both** | Yes |
| **Claims** | `sub`, `role` (active session role), `roles` (array, DB mode), `iss`, `aud`, `exp` — see [database.md](./database.md) § JWT |

**Render env (user-service and integration)**

| Key | Typical value |
|-----|----------------|
| `AUTH_TOKEN_SECRET` | long random string (generate once, copy to both) |
| `AUTH_TOKEN_ISSUER` | `sharingbridge-user-service` |
| `AUTH_TOKEN_AUDIENCE` | `sharingbridge-clients` |
| `AUTH_TOKEN_TTL_SECONDS` | `3600` |
| `GOOGLE_CLIENT_ID_WEB` | Web OAuth client ID (not the client secret) |
| `GOOGLE_CLIENT_ID_ANDROID` | Android OAuth client ID (mobile) |
| `WEB_CORS_ORIGINS` | Browser origin of the dashboard: local `http://localhost:5173`; on Render add `https://<static-site>.onrender.com` on **user-service and integration-service** — [backend-render.md](./backend-render.md) |
| `DATABASE_URL` | Postgres (user-service + integration-service, same DB) — [database.md](./database.md) |

**Dev-only mint (tests / manual smoke)**

`POST /v1/auth/token` with `{ "user_id": "…", "role": "donor" \| "coordinator" }` is enabled only when `ALLOW_DEV_TOKEN_MINT=true` on user-service. **Disable in production.**

---

## Authorization (what each role can do)

| Action | Donor (mobile) | Coordinator (web) |
|--------|----------------|-------------------|
| Donor setup / presets | Yes | No |
| Instruction pack + register order intent | Yes | No |
| List own order intents | Yes | No |
| List **all** order intents | No | Yes |

integration-service reads `role` from the JWT. Coordinators receive every donor’s intents on `GET /v1/donor-seeker/order-intents` (optional `?user_id=` filter).

---

## Internal service API key (`AI_ORCHESTRATION_INTERNAL_API_KEY`)

| | |
|--|--|
| **Purpose** | integration-service → ai-orchestration only |
| **Set on** | `sharingbridge-ai-orchestration`, `sharingbridge-integration-service` |
| **HTTP header** | `X-Internal-Api-Key` |
| **Not used on** | mobile app, web app, user-service |

---

## Summary

| Credential / setting | Mobile | Web | Expires? |
|----------------------|--------|-----|----------|
| Google `id_token` | Once per sign-in | Once per sign-in | Short (Google) |
| SharingBridge JWT | Bearer (stored locally) | sessionStorage (web); app secure storage (mobile) | Yes (~1 h) |
| Last coordinator email (web only) | N/A | localStorage (for GIS account switch) | Until revoke / clear site data |
| Coordinator roles | N/A | N/A | Postgres `user_roles` (or legacy file/env until cutover) |
| `DATABASE_URL` | Via APIs | N/A | N/A (service config) |
| `AI_ORCHESTRATION_INTERNAL_API_KEY` | No | No | No (rotate manually) |
| `WEB_CORS_ORIGINS` | N/A | Required on both backends | N/A |

**Step-by-step setup (Google Console, `.env`, coordinators, local run):** [google-auth-setup.md](./google-auth-setup.md)

See also [database.md](./database.md), [web-client.md](./web-client.md), [mobile-client.md](./mobile-client.md), and [MANUAL_TESTING_GUIDE.md](../testing/MANUAL_TESTING_GUIDE.md).
