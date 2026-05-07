# ShareBridge Agent Handoff

## Goal
Deliver a tangible MVP donor setup flow where a donor can enter free-text intent, receive AI-assisted vendor/menu suggestions, confirm one or more options, and persist presets for reuse. The backend is the source of truth for user preferences; mobile uses local cache fallback for resilience.

## Approach (Locked)
- Backend payment model: provider/vendor-hosted only.
- No platform-owned financial ledger or settlement responsibility.
- Delivery artifact access via technical controls.
- Queue strategy: Redis for MVP, SQS/SNS for scale.
- Backend source-of-truth for user preferences; client cache is non-authoritative.
- Mobile stack: Flutter.
- Backend API stack (MVP): Node.js + NestJS direction; current integration-service MVP uses lightweight Node server for rapid loop validation.

## Site Map (Source of Truth)
- BRD assumptions: `requirements/ShareBridge_Business_Requirement.md`
- Technical architecture: `design/ShareBridge_Technical_Architecture.md`
- Donor setup sequence: `design/Donor_Setup_AI_Search_Sequence.md`
- API contract: `design/contracts/donor_setup_suggest_vendors.openapi.yaml`
- Contract examples: `design/contracts/examples/`
- Execution checklist: `development/MVP_BOOTSTRAP_ISSUES.md`
- Implementation plan: `development/IMPLEMENTATION_APPROACH.md`
- User-service preferences migration plan: `development/USER_SERVICE_PREFERENCES_MIGRATION.md`

## Current Implementation Status
- `sharebridge-integration-service`:
  - `POST /v1/donor-setup/suggest-vendors` implemented (mock top-5 suggestions).
  - `POST /v1/donor-setup/preferences` implemented (save presets — `user_id` derived from auth headers).
  - `GET /v1/donor-setup/preferences` implemented (header-derived `user_id`; legacy `?user_id=` still accepted).
  - File-backed preferences store: `src/preferencesStore.js`.
  - HTTP server exposed as a factory (`createIntegrationServer`) so tests can boot it against a temp DB.
  - Preferences access goes through a `PreferencesGateway` abstraction (`src/preferencesGateway.js`): `LocalPreferencesGateway` wraps the file store today; `UserServicePreferencesGateway` is a placeholder for the user-service swap. Backend selected by `PREFERENCES_BACKEND` env (`local` default, `user_service` requires `USER_SERVICE_BASE_URL`).
  - Auth context (`src/authContext.js`): MVP placeholder accepts `Authorization: Bearer demo.<user_id>` (preferred) and `X-User-Id` (fallback). Mismatched header vs body/query `user_id` returns `403 user_id_mismatch`. Missing auth context returns `401 missing_auth_context` on preferences endpoints.
  - Integration tests cover save+fetch roundtrip, repeat-save dedupe, per-user isolation, validation rejection, gateway boundary contract, and header-driven auth flows (`test/preferencesRoundtrip.test.js`, `test/preferencesGateway.test.js`, `test/authContext.test.js`, `test/authContextRoundtrip.test.js`).
  - Tests passing via `npm test`.
- `sharebridge-mobile-app`:
  - Donor setup search wired to backend API.
  - Confirm-and-save wired to preferences endpoint.
  - Startup load from backend by `user_id` with local `shared_preferences` fallback cache.
  - HTTP API client now supports request timeout, exponential-backoff retry, and typed exceptions (`DonorSetupNetworkException`, `DonorSetupTimeoutException`, `DonorSetupBadRequestException`, `DonorSetupServerException`, `DonorSetupResponseException`). Mutating saves do not retry on 5xx (no double-write).
  - UI surfaces friendly error messages per typed exception.
  - `AuthContext` (`lib/features/donor_setup/data/auth_context.dart`) sources `user_id` from `--dart-define=USER_ID=...` (default `demo-user`) and injects `Authorization: Bearer demo.<user_id>` plus `X-User-Id` headers on every API call. Static demo user constant removed from the page.
  - Tests passing via `flutter test`.

## Quick Runbook
- Integration service:
  - `cd sharebridge-integration-service`
  - `npm install`
  - `npm test`
  - `npm start`
  - Health: `http://localhost:8080/health`
  - Preferences endpoints require `Authorization: Bearer demo.<user_id>` (or `X-User-Id`) header.
- Mobile app:
  - `cd sharebridge-mobile-app`
  - `flutter pub get`
  - `flutter test`
  - Windows desktop: `flutter run --dart-define=API_BASE_URL=http://localhost:8080 --dart-define=USER_ID=demo-user`
  - Android emulator: `flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8080 --dart-define=USER_ID=demo-user`

## Next Recommended Tasks
1. ~~Add timeout/retry and typed error mapping in mobile API client.~~ Done.
2. ~~Add integration tests for preferences save+fetch roundtrip and dedupe behavior.~~ Done.
3. ~~Move preference ownership from integration-service mock path toward user-service boundary~~ — gateway abstraction and migration plan landed; remote `UserServicePreferencesGateway` body is deferred until the user-service API baseline ships. See `development/USER_SERVICE_PREFERENCES_MIGRATION.md`.
4. ~~Add minimal auth context (`user_id` from token/headers) instead of static demo user.~~ Done.

## Follow-ups Surfaced This Pass
- Implement `UserServicePreferencesGateway` body (HTTP client to user-service preferences endpoints) once `sharebridge-user-service` publishes its baseline.
- Replace the MVP `Bearer demo.<user_id>` placeholder with a real signed token issued by `sharebridge-user-service` (JWT or session token) and tighten the integration-service auth resolver to verify signatures. Reject `X-User-Id` once the real token issuer ships.
- Backfill any presets in the integration-service file store into the user-service when the migration runs (see migration plan).
