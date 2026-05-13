# Donor Preferences → User Service Migration Plan

Status: **Baseline implemented; cutover and tear-down are ops steps.**

## Why this exists

For MVP velocity, donor presets are owned by `sharingbridge-integration-service`
(file-backed `PreferencesStore`). Long-term, user-scoped state belongs in
`sharingbridge-user-service`. This document captures the contract and the
migration steps so the swap is mechanical.

## Current boundary (in code)

`sharingbridge-integration-service/src/preferencesRepository.js` defines
the abstraction the HTTP handlers depend on:

```
listByUser(userId, opts?)              -> Promise<Preset[]>
upsertForUser(userId, presets, opts?)  -> Promise<Preset[]>  // full set after upsert
clearForUser(userId, opts?)            -> Promise<Preset[]>  // always []
removePresetForUser(userId, key, opts?) -> Promise<Preset[]>  // remaining; user-service uses HTTP delete-item
init()                                 -> Promise<void>
```

Integration HTTP: `DELETE /v1/donor-setup/preferences?user_id=<id>` (Bearer required) clears that user’s presets — implemented for local store and delegated to user-service `PUT { presets: [] }` when `PREFERENCES_BACKEND=user_service`. Single-row removal uses `POST /v1/donor-setup/preferences/delete-item`, which forwards to **`POST /v1/users/{user_id}/donor-presets/delete-item`** on user-service (one round-trip; no GET+PUT in integration).

Two implementations:

- `LocalPreferencesRepository(store)` — wraps `PreferencesStore` (default local dev).
- `UserServicePreferencesRepository({ baseUrl })` — calls user-service and forwards `Authorization` from the inbound integration request.

Selection is driven by env:

- `PREFERENCES_BACKEND=local` (default) — file-backed.
- `PREFERENCES_BACKEND=user_service` — requires `USER_SERVICE_BASE_URL`.

## Planned user-service contract

Endpoints (under `sharingbridge-user-service`):

- `GET    /v1/users/{user_id}/donor-presets` → `200 { presets: Preset[] }`
- `PUT    /v1/users/{user_id}/donor-presets` → `200 { presets: Preset[] }`
  - Body: `{ presets: Preset[] }` — full upsert; server is responsible
    for dedupe by `(restaurant_name, order_url)` (latest wins) to match
    today's `PreferencesStore` behavior.
- `POST   /v1/users/{user_id}/donor-presets/delete-item` → `200 { presets: Preset[] }`
  - Body: `{ restaurant_name, order_url }` — removes one row by the same natural key (trimmed).

`Preset` shape (matches existing donor preset payload):

```json
{
  "id": "string (server-assigned)",
  "restaurant_name": "string",
  "order_url": "string (uri)",
  "menu_items": ["string"],
  "app_name": "string",
  "source": "string (e.g. ai_suggestion)",
  "confidence": 0.92,
  "saved_at": "string (ISO 8601, server-assigned)"
}
```

Auth: `Authorization: Bearer <signed token>` from user-service (`POST /v1/auth/token`).
`X-User-Id` is not used.

Errors:

- `400 invalid_request` for schema/validation failures.
- `401` if auth context is missing or token invalid.
- `403` if `user_id` in URL does not match token subject.
- `5xx` for upstream/persistence failures.

## Migration steps (cutover checklist)

1. **User-service baseline** — `GET`/`PUT` donor-presets APIs are live (implemented).
2. **Integration remote repository** — `UserServicePreferencesRepository` uses `fetch()` to those endpoints (implemented).
3. **Backfill file store → user-service** (once per environment, before or right after flip):

   From `sharingbridge-integration-service`, with user-service running and using the **same** `AUTH_TOKEN_SECRET` as local minting expects:

   ```powershell
   cd D:\path\to\sharingbridge-integration-service
   $env:USER_SERVICE_BASE_URL = "http://localhost:8081"   # or production URL
   $env:PREFERENCES_DB_PATH = ".\data\preferences.json"    # default if omitted
   # Optional: $env:BACKFILL_DRY_RUN = "1"                   # log only
   npm run backfill:user-service-presets
   ```

   The script mints a token per `user_id` via `POST /v1/auth/token`, normalizes rows to user-service validation rules (default `source=migrated_from_integration_store`, `confidence=0` when missing), then `PUT`s the full preset list per user.

4. **Flip integration deployment config:** `PREFERENCES_BACKEND=user_service` and `USER_SERVICE_BASE_URL=...`.
5. After traffic is healthy on user-service for presets, **retire** integration’s file store for that environment: stop writing `data/preferences.json`, delete `data/` from that deployment, and eventually remove `PreferencesStore` / `LocalPreferencesRepository` from code when no env needs local mode (optional final cleanup).

No mobile-side change is required — the mobile app talks only to
integration-service for donor setup today, and the integration-service
HTTP contract for `/v1/donor-setup/preferences` does not change as part
of the swap.
