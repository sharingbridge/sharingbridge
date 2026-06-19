# API contracts (`design/contracts/`)

OpenAPI specs for **published HTTP surfaces**. These are not auto-generated from code — update them when the matching route contract changes.

## Covered (maintained)

| File | Service | Routes |
|------|---------|--------|
| [donor_setup_suggest_vendors.openapi.yaml](./donor_setup_suggest_vendors.openapi.yaml) | integration-service | `POST /v1/donor-setup/suggest-vendors` |
| [donor_setup_preferences.openapi.yaml](./donor_setup_preferences.openapi.yaml) | integration-service | `GET/POST/DELETE /v1/donor-setup/preferences`, `POST …/delete-item` |
| [user_service_donor_presets.openapi.yaml](./user_service_donor_presets.openapi.yaml) | user-service | `GET/PUT /v1/users/{id}/donor-presets`, `POST …/delete-item` |

Examples: [examples/](./examples/) (suggest-vendors request/response only).

## Not yet specified here

Implemented in code but **no OpenAPI file yet** (see integration `src/server.js` and [STATUS.md](../../development/STATUS.md)):

- `POST /v1/donor-seeker/instruction-pack`
- `POST/GET/PATCH /v1/donor-seeker/order-intents`
- `POST/GET /v1/seeker-demands`
- `GET /v1/standard-offers`
- `GET /v1/demand/board`
- `POST /v1/pledges`, `POST /v1/vendor-bids`
- `GET /v1/connections/{orderCode}`
- `PUT /v1/device-tokens`

photo-service and notification-service define their contracts in repo READMEs / [notification-service-local.md](../../configuration/notification-service-local.md).

## When to add a contract

Add or extend OpenAPI when:

1. A route is stable enough for mobile/web/codegen consumers.
2. You change request/response shape — update the YAML in the **same commit** as the code.

Prefer one file per bounded context (e.g. `marketplace.openapi.yaml`, `donor_seeker_handoff.openapi.yaml`) rather than one giant spec.
