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
4. user-service maps `google_sub` → internal `user_id`, assigns **role**, mints SharingBridge JWT.

**Role assignment (local DB)**

- File: `sharingbridge-user-service/data/coordinators.json` → `{ "emails": ["coord@example.com"] }`
- Env: `COORDINATOR_EMAILS` (comma-separated, merged with file)
- Allowlisted email → role **`coordinator`**; otherwise **`donor`**

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
| **Claims** | `sub` (user id), `role` (`donor` \| `coordinator`), `iss`, `aud`, `exp` |

**Render env (user-service and integration)**

| Key | Typical value |
|-----|----------------|
| `AUTH_TOKEN_SECRET` | long random string (generate once, copy to both) |
| `AUTH_TOKEN_ISSUER` | `sharingbridge-user-service` |
| `AUTH_TOKEN_AUDIENCE` | `sharingbridge-clients` |
| `AUTH_TOKEN_TTL_SECONDS` | `3600` |
| `GOOGLE_CLIENT_ID_WEB` | Web OAuth client ID (not the client secret) |
| `GOOGLE_CLIENT_ID_ANDROID` | Android OAuth client ID (mobile) |
| `WEB_CORS_ORIGINS` | web app origin(s) |

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
| SharingBridge JWT | Bearer (stored locally) | sessionStorage | Yes (~1 h) |
| Coordinator allowlist | N/A | N/A | N/A (file/env) |
| `AI_ORCHESTRATION_INTERNAL_API_KEY` | No | No | No (rotate manually) |
| `WEB_CORS_ORIGINS` | N/A | Required on both backends | N/A |

**Step-by-step setup (Google Console, `.env`, coordinators, local run):** [google-auth-setup.md](./google-auth-setup.md)

See also [web-client.md](./web-client.md), [mobile-client.md](./mobile-client.md), and [MANUAL_TESTING_GUIDE.md](../testing/MANUAL_TESTING_GUIDE.md).
