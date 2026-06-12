# Payee preferences — user-service authority

Status: **complete** — no file import path remains.

## Architecture

```text
Mobile / Web  →  integration-service  →  user-service  →  Postgres (donor_presets)
```

- Integration **`npm start`** requires `USER_SERVICE_BASE_URL` and forwards preset CRUD to user-service.
- `LocalPreferencesRepository` + `PreferencesStore` exist **only for automated tests** (temp files under the OS temp directory).

## Clearing presets in dev

- App **Clear all**, or
- `DELETE /v1/donor-setup/preferences` with Bearer token, or
- SQL: `UPDATE donor_presets SET presets_json = '[]'::jsonb WHERE user_id = '…'`

## OpenAPI

- [donor_setup_preferences.openapi.yaml](../design/contracts/donor_setup_preferences.openapi.yaml) — integration surface
- [user_service_donor_presets.openapi.yaml](../design/contracts/user_service_donor_presets.openapi.yaml) — persistence API
