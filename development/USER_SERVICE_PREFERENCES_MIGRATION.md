# Donor Preferences → User Service Migration Plan

Status: **Prep complete; remote implementation deferred.**

## Why this exists

For MVP velocity, donor presets are owned by `sharebridge-integration-service`
(file-backed `PreferencesStore`). Long-term, user-scoped state belongs in
`sharebridge-user-service`. This document captures the contract and the
migration steps so the swap is mechanical once the user service publishes
its preferences API baseline.

## Current boundary (in code)

`sharebridge-integration-service/src/preferencesRepository.js` defines
the abstraction the HTTP handlers depend on:

```
listByUser(userId)            -> Promise<Preset[]>
upsertForUser(userId, presets) -> Promise<Preset[]>  // returns full set
init()                         -> Promise<void>
```

Two implementations:

- `LocalPreferencesRepository(store)` — wraps `PreferencesStore` (today).
- `UserServicePreferencesRepository({ baseUrl })` — placeholder; throws
  `not yet implemented` until the user-service baseline ships.

Selection is driven by env:

- `PREFERENCES_BACKEND=local` (default) — file-backed.
- `PREFERENCES_BACKEND=user_service` — requires `USER_SERVICE_BASE_URL`.

## Planned user-service contract

Endpoints (under `sharebridge-user-service`):

- `GET    /v1/users/{user_id}/donor-presets` → `200 { presets: Preset[] }`
- `PUT    /v1/users/{user_id}/donor-presets` → `200 { presets: Preset[] }`
  - Body: `{ presets: Preset[] }` — full upsert; server is responsible
    for dedupe by `(restaurant_name, order_url)` (latest wins) to match
    today's `PreferencesStore` behavior.

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

Auth: forward the donor's auth context (`Authorization: Bearer <token>`
or `X-User-Id` for MVP — see the "minimal auth context" task).

Errors:

- `400 invalid_request` for schema/validation failures.
- `401 unauthorized` if auth context is missing.
- `403 forbidden` if `user_id` in URL does not match auth context.
- `5xx` for upstream/persistence failures.

## Migration steps (when user-service baseline lands)

1. Implement the planned endpoints in `sharebridge-user-service` against
   its persistent store (Postgres per current architecture doc).
2. Replace the body of `UserServicePreferencesRepository` with `fetch()`
   calls to those endpoints, propagating the donor's auth context.
3. Add a roundtrip integration test against a stub user-service (e.g.
   spin up an HTTP fixture that mirrors the contract).
4. Set `PREFERENCES_BACKEND=user_service` and `USER_SERVICE_BASE_URL=...`
   in the integration-service deployment config.
5. Backfill any presets in the file-backed store into user-service via a
   one-shot script. Then retire `PreferencesStore` and
   `LocalPreferencesRepository`.
6. Delete `data/` and the `PreferencesStore` module from
   integration-service.

No mobile-side change is required — the mobile app talks only to
integration-service for donor setup today, and the integration-service
HTTP contract for `/v1/donor-setup/preferences` does not change as part
of the swap.
