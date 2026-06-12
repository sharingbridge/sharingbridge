# Payee Preferences → User Service

Status: **Runtime cutover complete** — integration-service always uses user-service (`USER_SERVICE_BASE_URL`). Presets live in Postgres table `donor_presets`. Marketplace catalog is Postgres `standard_offers` (M3 seed) — not `test/fixtures/standardOffersCatalog.js` (tests only).

## Architecture

```
Mobile / Web  →  integration-service  →  user-service  →  Postgres (donor_presets)
```

- **No** file-backed preset store at `npm start` (no `PREFERENCES_BACKEND`, no repo `data/` directory).
- **Tests** still use `LocalPreferencesRepository` + temp `PreferencesStore` files.

## Repository contract

`sharingbridge-integration-service/src/preferencesRepository.js`:

- `UserServicePreferencesRepository` — production
- `LocalPreferencesRepository` — unit tests only

Integration HTTP delegates preset CRUD to user-service:

- `GET/PUT /v1/donor-setup/preferences` → user-service donor-presets API
- `DELETE` → `PUT { presets: [] }`
- `POST …/delete-item` → `POST …/donor-presets/delete-item`

## One-off legacy import

If you still have an exported `preferences.json` from an old local deployment:

```text
cd sharingbridge-integration-service
set USER_SERVICE_BASE_URL=http://localhost:8081
set LEGACY_PREFERENCES_JSON_PATH=C:\path\to\preferences.json
npm run backfill:user-service-presets
```

`BACKFILL_DRY_RUN=1` previews without writing.

## Clearing presets in dev

- App **Clear all**, or
- `DELETE /v1/donor-setup/preferences` with Bearer token, or
- SQL: `UPDATE donor_presets SET presets_json = '[]'::jsonb WHERE user_id = '…'`

## OpenAPI

- [donor_setup_preferences.openapi.yaml](../design/contracts/donor_setup_preferences.openapi.yaml) — integration surface
- [user_service_donor_presets.openapi.yaml](../design/contracts/user_service_donor_presets.openapi.yaml) — persistence API
