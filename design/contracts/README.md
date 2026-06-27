# API contracts (`design/contracts/`)

OpenAPI specs for **published HTTP surfaces**. These are not auto-generated from code — update them when the matching route contract changes.

**Naming:** Prefer **initiator** in new specs and client paths. Legacy `/v1/donor-*` routes and `donor_email` response fields remain accepted — see [PRODUCT_MODEL.md](../../development/PRODUCT_MODEL.md).

## Covered (maintained)

| File | Service | Routes |
|------|---------|--------|
| [donor_setup_suggest_vendors.openapi.yaml](./donor_setup_suggest_vendors.openapi.yaml) | integration-service | `POST /v1/donor-setup/suggest-vendors` (alias `/v1/initiator-setup/suggest-vendors`) |
| [donor_setup_preferences.openapi.yaml](./donor_setup_preferences.openapi.yaml) | integration-service | `GET/POST/DELETE /v1/donor-setup/preferences`, `POST …/delete-item` (aliases under `/v1/initiator-setup/…`) |
| [user_service_donor_presets.openapi.yaml](./user_service_donor_presets.openapi.yaml) | user-service | `GET/PUT /v1/users/{id}/donor-presets`, `POST …/delete-item` |
| [initiator_handoff.openapi.yaml](./initiator_handoff.openapi.yaml) | integration-service | `POST /v1/instruction-pack`, `GET/POST/PATCH /v1/order-intents`, `GET /v1/connections/{orderCode}`, `PUT /v1/device-tokens` |
| [marketplace.openapi.yaml](./marketplace.openapi.yaml) | integration-service | `GET /v1/standard-offers`, `GET/POST /v1/seeker-demands`, `GET /v1/demand/board`, `POST /v1/pledges`, `POST /v1/vendor-bids` |

Examples: [examples/](./examples/) (suggest-vendors request/response only).

## Auth (all integration routes above)

Bearer JWT from user-service. Mobile mints `role: initiator`; web mints `coordinator` or `initiator`. Legacy JWT `role: donor` is treated as initiator. See [authentication.md](../../configuration/authentication.md).

## Not in OpenAPI yet

- `GET /v1/geocode/reverse` — reverse geocode for handover map picker; contract in [Handover_Location_Map_Picker.md](../Handover_Location_Map_Picker.md) and [Location_Services_Vendor_Abstraction.md](../Location_Services_Vendor_Abstraction.md)
- photo-service (`POST /v1/photos/upload`) — [photo-service-local.md](../../configuration/photo-service-local.md)
- notification-service webhook — [notification-service-local.md](../../configuration/notification-service-local.md)

## When to add or change a contract

1. A route is stable enough for mobile/web/codegen consumers.
2. You change request/response shape — update the YAML in the **same commit** as the code.

Prefer one file per bounded context rather than one giant spec.
