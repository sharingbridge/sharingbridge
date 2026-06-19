# Authentication and service credentials

SharingBridge uses **Google Sign-In** for production-style identity, plus **SharingBridge JWTs** for API calls. Internal service traffic uses a separate API key.

**Configure in order:** [e2e-deployment-sequence.md](./e2e-deployment-sequence.md).

**Vocabulary:** Signed-in mobile users are **initiators** (who register intents/demands). Legacy DB/API identifiers still use `donor` in places — see [PRODUCT_MODEL.md](../development/PRODUCT_MODEL.md). There is **no** `payee` JWT role. Use **initiator** for registration and **payer** for who pays the vendor; **payee** means payment recipient (vendor/kitchen) only — see [PRODUCT_MODEL.md](../development/PRODUCT_MODEL.md). Shipped MVP: initiator and payer are usually the same person.

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

Every Google user gets legacy **`donor`** ensured at sign-in (`INSERT … ON CONFLICT DO NOTHING`). Brownfield DBs may also have an **`initiator`** row from [schema-initiator-role-migration.sql](./schema-initiator-role-migration.sql). **`coordinator`** is granted via SQL ([coordinator-seed.sql](./coordinator-seed.sql)). A user may have **multiple** rows in `user_roles`.

**Client rules (which hat for this JWT)**

| `client_type` | Requires in `user_roles` | JWT `role` minted |
|---------------|--------------------------|-------------------|
| `web` | `donor` and/or `initiator` and/or `coordinator` | `coordinator` if present, else `initiator` |
| `android` / `ios` / `mobile` | `donor` and/or `initiator` | `initiator` (even if they also have `coordinator`) |

JWT also includes `roles` (full array). Integration-service formats list responses by minted `role` (coordinator = full dashboard; initiator = limited dashboard with photo redaction).

Wrong combination → HTTP **403** `wrong_client_role` (e.g. `no_app_role` on web with no roles, or mobile with `no_initiator_role`).

---

## SharingBridge JWT (`AUTH_TOKEN_SECRET`)

| | |
|--|--|
| **Purpose** | Authorize API calls to integration-service (and user-service preset APIs) |
| **Set on** | `sharingbridge-user-service`, `sharingbridge-integration-service` |
| **Same value on both** | Yes |
| **Claims** | `sub`, `role` (active session role), `roles` (array, DB mode), `iss`, `aud`, `exp` — see [database.md](./database.md) § JWT |

**Service env keys:** [environment-variables.md](./environment-variables.md) (JWT, Google client IDs, `WEB_CORS_ORIGINS`, `DATABASE_URL`). Postgres setup: [database.md](./database.md).

---

## Initiator vendor presets (user-service authority)

Migration from integration file store is **complete**. Presets live in Postgres only:

```text
Mobile / Web  →  integration-service  →  user-service  →  donor_presets
```

- Integration requires `USER_SERVICE_BASE_URL` and forwards preset CRUD to user-service.
- Clients may call `/v1/initiator-setup/preferences` (alias for `/v1/donor-setup/preferences`).
- `LocalPreferencesRepository` in integration-service is **tests only**.

**Clear presets in dev:** app **Clear all**, `DELETE /v1/initiator-setup/preferences` with Bearer token, or SQL `UPDATE donor_presets SET presets_json = '[]'::jsonb WHERE user_id = '…'`.

OpenAPI: [donor_setup_preferences.openapi.yaml](../design/contracts/donor_setup_preferences.openapi.yaml), [user_service_donor_presets.openapi.yaml](../design/contracts/user_service_donor_presets.openapi.yaml).

---

## Authorization (what each role can do)

| Action | Initiator (mobile) | Coordinator (web) |
|--------|-------------------|-------------------|
| Vendor preset setup / presets | Yes | No |
| Instruction pack + register order intent | Yes | No |
| List own order intents | Yes | No |
| List **all** order intents | No | Yes |
| Record seeker demand / pledge | Yes | Yes (pledge) |
| Kitchen commit (`vendor-bids`) | No | Yes (MVP) |

integration-service reads `role` from the JWT. JWT `role` `donor` is treated as initiator capability. Coordinators receive every initiator’s intents on `GET /v1/order-intents` (alias for `/v1/donor-seeker/order-intents`; optional `?user_id=` filter).

**Sign in without Google (local only)**

**Dev-only JWT** (scripts, mobile `--dart-define=AUTH_TOKEN`): sign locally with the same `AUTH_TOKEN_SECRET` — `node scripts/mint-dev-jwt.mjs <user_id> [initiator|coordinator]` in user-service. Legacy `donor` is accepted and normalized to `initiator`. There is no HTTP “mint token without Google” endpoint.

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
