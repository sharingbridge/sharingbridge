# ShareBridge Agent Handoff

> **Live coordination doc for AI-assisted coding sessions.** Read this first when picking up the project. Update the "Recently Shipped" and "Next Recommended Tasks" sections as work lands so the next session has fresh context.

## Goal
Deliver the MVP **donor-setup → donor-seeker interaction → vendor redirect → delivery confirmation** flow. The integration service is the platform's facilitator. ShareBridge is never the system of record for money.

## Approach (Locked)
- Backend payment model: provider/vendor-hosted only.
- No platform-owned financial ledger or settlement responsibility.
- Delivery artifact access via technical controls.
- Queue strategy: Redis for MVP, SQS/SNS for scale.
- Backend source-of-truth for user preferences; client cache is non-authoritative.
- Mobile stack: Flutter.
- Backend API stack (MVP): Node.js + NestJS direction; integration-service today is a lightweight Node http server for fast iteration.

## Site Map (Source of Truth)
- BRD assumptions: `requirements/ShareBridge_Business_Requirement.md`
- Technical architecture: `design/ShareBridge_Technical_Architecture.md`
- Donor setup sequence: `design/Donor_Setup_AI_Search_Sequence.md`
- API contract: `design/contracts/donor_setup_suggest_vendors.openapi.yaml`
- Contract examples: `design/contracts/examples/`
- MVP per-repo execution checklist: `development/MVP_BOOTSTRAP_ISSUES.md`
- Implementation plan: `development/IMPLEMENTATION_APPROACH.md`
- User-service preferences migration plan: `development/USER_SERVICE_PREFERENCES_MIGRATION.md`
- Manual testing guide for shipped modules: `testing/MANUAL_TESTING_GUIDE.md` (index: `testing/README.md`)

## Current Implementation Status

### `sharebridge-integration-service` (donor setup MVP shipped)
- `POST /v1/donor-setup/suggest-vendors` — mock top-5 vendor/menu suggestions.
- `POST /v1/donor-setup/preferences` — save donor presets, `user_id` derived from auth headers.
- `GET /v1/donor-setup/preferences` — fetch presets, header-derived `user_id` (legacy `?user_id=` still accepted).
- File-backed preferences store (`src/preferencesStore.js`) accessed via a `PreferencesRepository` abstraction (`src/preferencesRepository.js`).
  - `LocalPreferencesRepository` is wired today.
  - `UserServicePreferencesRepository` is wired to `sharebridge-user-service` (`GET/PUT /v1/users/{user_id}/donor-presets`) and forwards donor auth headers.
  - Backend selected by `PREFERENCES_BACKEND` env (`local` default, `user_service` requires `USER_SERVICE_BASE_URL`).
- Auth context (`src/authContext.js`): MVP placeholder. Accepts `Authorization: Bearer demo.<user_id>` (preferred) or `X-User-Id` (fallback). Mismatch → `403 user_id_mismatch`. Missing → `401 missing_auth_context` on preferences endpoints.
- HTTP server is exposed as a factory (`createIntegrationServer`) so tests can boot it against a temp DB.
- 32 tests, all green via `npm test`.

### `sharebridge-mobile-app` (donor setup MVP shipped)
- Donor setup screen wired to integration-service: search → suggestions → confirm-and-save.
- Startup loads presets from server, with local `shared_preferences` fallback cache when the server is unreachable.
- HTTP API client (`lib/features/donor_setup/data/http_donor_setup_api_client.dart`) supports request timeout, exponential-backoff retry, and typed exceptions (`DonorSetupNetworkException`, `DonorSetupTimeoutException`, `DonorSetupBadRequestException`, `DonorSetupServerException`, `DonorSetupResponseException`). Mutating saves do not retry on 5xx (no double-write).
- UI surfaces friendly error messages per typed exception.
- `AuthContext` (`lib/features/donor_setup/data/auth_context.dart`) sources `user_id` from `--dart-define=USER_ID=...` (default `demo-user`) and injects `Authorization: Bearer demo.<user_id>` plus `X-User-Id` headers on every API call.
- 15 tests, all green via `flutter test`.

### Other repos
- `sharebridge-user-service`: MVP skeleton bootstrapped (Node HTTP service + tests) with:
  - donor user model storage (`id`, `phone`, `email`, `created_at`) via file-backed `UserStore`.
  - `POST /v1/auth/demo-token` issuing `demo.<user_id>` tokens.
  - `GET/PUT /v1/users/{user_id}/donor-presets` with preset validation and dedupe by `(restaurant_name, order_url)` (latest wins).
  - auth handling aligned with integration-service semantics for 401 (`missing_auth_context`) and 403 (`user_id_mismatch`).
  - 3 roundtrip tests green for token issue, presets upsert/list, and 401/403 auth paths.
- `sharebridge-api-gateway`, `sharebridge-order-service`, `sharebridge-notification-service`, `sharebridge-ai-safety`, `sharebridge-photo-service`, `sharebridge-web-app`, `sharebridge-infra`, `sharebridge-deployment`: README only, no code yet.

## Quick Runbook

Integration service:
- `cd sharebridge-integration-service`
- `npm install`
- `npm test`
- `npm start` → listens on `http://localhost:8080`
- Health: `GET /health`
- Preferences endpoints require `Authorization: Bearer demo.<user_id>` (or `X-User-Id`).

Mobile app:
- `cd sharebridge-mobile-app`
- `flutter pub get`
- `flutter test`
- Windows desktop: `flutter run --dart-define=API_BASE_URL=http://localhost:8080 --dart-define=USER_ID=demo-user`
- Android emulator: `flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8080 --dart-define=USER_ID=demo-user`

Manual end-to-end and API smoke steps live in `testing/MANUAL_TESTING_GUIDE.md`.

## Next Recommended Tasks

Tasks #1-#4 are complete. Remaining priority order:

1. **Replace the `Bearer demo.<user_id>` placeholder with a real signed token** issued by the user-service. Tighten the integration-service auth resolver to verify signatures. Reject `X-User-Id` once the real token issuer is in place.

## Follow-ups Surfaced in Prior Sessions
- Backfill any presets in the integration-service file store into user-service when the migration runs (covered in the migration plan).
- The integration-service file-backed store (`PreferencesStore`) and `LocalPreferencesRepository` retire once the migration completes.

## Recently Shipped (chronological, newest last)
- `feat`: donor-setup `suggest-vendors` mock endpoint + tests.
- `feat`: donor-setup preset save endpoint.
- `feat`: persist donor presets per user and add preferences fetch.
- `feat`: scaffold Flutter day-1 donor-setup baseline + wire suggest-vendors API client.
- `feat`: complete mobile preset confirm-save flow and add platforms.
- `feat`: load presets from server with local cache fallback.
- `feat`: add timeout, retry, and typed errors to donor setup API client (mobile).
- `test`: add HTTP roundtrip tests for donor preferences save and dedupe (integration-service).
- `refactor`: introduce preferences repository boundary toward user-service (integration-service) — abstraction now named `PreferencesRepository` (was `PreferencesGateway` to avoid edge-gateway terminology clash).
- `feat`: derive user_id from auth headers on preferences endpoints (integration-service).
- `feat`: send donor identity via auth headers from mobile app.
- `docs`: add `testing/` folder with `MANUAL_TESTING_GUIDE.md` for shipped modules.
- `docs`: clean up unused `prompting/` folders, retire `development/PROMPTS.md`, and refocus README + CALL_FOR_CONTRIBUTORS on AGENT_HANDOFF as the live coordination doc.
- `feat`: bootstrap `sharebridge-user-service` skeleton with demo-token auth endpoint, donor-presets GET/PUT APIs, file-backed donor model/preset storage, and green roundtrip tests for token + presets + 401/403 auth paths.
- `ci`: add minimal GitHub Actions CI workflows for `sharebridge-integration-service` (Node 20, `npm install`, `npm test`) and `sharebridge-mobile-app` (Flutter stable, `flutter pub get`, `flutter test`) on push/PR.
- `feat`: mobile donor-setup polish — replace hard-coded manual area with editable field, distinguish empty server presets from server-unreachable fallback behavior, and add clear cache/sign-out action; extend widget tests for new behaviors.
- `feat`: wire `UserServicePreferencesRepository` to live user-service donor-presets APIs, forward auth headers from integration-service requests, propagate upstream 4xx errors, and add coverage for repository HTTP behavior plus integration-to-user-service roundtrip path.
