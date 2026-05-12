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

## MVP staging (mini vs matured)

The **donor-setup slice** that is live in code is intentionally a **minimal MVP** (“MVP‑0”): flows and APIs are wired end‑to‑end while **preferences and user-service donor data stay file‑backed JSON** (easy local and Render/Railway iteration, with the limits of ephemeral disks and single-instance file stores).

**Matured MVP** means closing the gap with `development/IMPLEMENTATION_APPROACH.md`: attach **managed Postgres** (for example Supabase during free tier) for user‑scoped persistence where the architecture diagram shows a database, plus hosting patterns suited to durability and scale. Product scope stays MVP; infra depth catches up.

`development/USER_SERVICE_PREFERENCES_MIGRATION.md` describes preferences authority and integration ↔ user‑service cutover; this section is only about labeling **what shipped now** versus **what the roadmap stack assumes**.

## Current Implementation Status

### `sharebridge-integration-service` (donor setup MVP shipped)
- `POST /v1/donor-setup/suggest-vendors` — mock top-5 vendor/menu suggestions.
- `POST /v1/donor-setup/preferences` — save donor presets, `user_id` derived from auth headers.
- `GET /v1/donor-setup/preferences` — fetch presets, header-derived `user_id` (legacy `?user_id=` still accepted).
- File-backed preferences store (`src/preferencesStore.js`) accessed via a `PreferencesRepository` abstraction (`src/preferencesRepository.js`).
  - `LocalPreferencesRepository` is wired today.
  - `UserServicePreferencesRepository` is wired to `sharebridge-user-service` (`GET/PUT /v1/users/{user_id}/donor-presets`) and forwards donor auth headers.
  - Backend selected by `PREFERENCES_BACKEND` env (`local` default, `user_service` requires `USER_SERVICE_BASE_URL`).
- Auth context (`src/authContext.js`): verifies signed bearer tokens (HS256) issued by user-service. `X-User-Id` fallback is removed. Missing/invalid token → `401 missing_auth_context`; URL/payload mismatch vs token subject → `403 user_id_mismatch`.
- HTTP server is exposed as a factory (`createIntegrationServer`) so tests can boot it against a temp DB.
- 32 tests, all green via `npm test`; `npm run backfill:user-service-presets` migrates `data/preferences.json` → user-service (see migration doc).

### `sharebridge-mobile-app` (donor setup MVP shipped)
- Donor setup screen wired to integration-service: search → suggestions → confirm-and-save.
- Startup loads presets from server, with local `shared_preferences` fallback cache when the server is unreachable.
- HTTP API client (`lib/features/donor_setup/data/http_donor_setup_api_client.dart`) supports request timeout, exponential-backoff retry, and typed exceptions (`DonorSetupNetworkException`, `DonorSetupTimeoutException`, `DonorSetupBadRequestException`, `DonorSetupServerException`, `DonorSetupResponseException`). Mutating saves do not retry on 5xx (no double-write).
- UI surfaces friendly error messages per typed exception.
- `AuthContext` (`lib/features/donor_setup/data/auth_context.dart`) sources `user_id` from `--dart-define=USER_ID=...` and signed token from `--dart-define=AUTH_TOKEN=...`, and sends only `Authorization: Bearer <token>`.
- Donor Setup list shows **full `menu_items`** per suggestion (not only the first item); integration-service **suggest-vendors** mock is still **query-independent** (fixed venues/menus until real search ships).
- Donor Setup app bar opens **Saved presets**: server-backed list with **Copy link** / **Open link** (`url_launcher`) on each preset’s `order_url`; pull-to-refresh.
- 19 tests, all green via `flutter test`.

### Other repos
- `sharebridge-user-service`: MVP skeleton bootstrapped (Node HTTP service + tests) with:
  - donor user model storage (`id`, `phone`, `email`, `created_at`) via file-backed `UserStore`.
  - `POST /v1/auth/token` issuing signed bearer tokens (JWT HS256).
  - `GET/PUT /v1/users/{user_id}/donor-presets` with preset validation and dedupe by `(restaurant_name, order_url)` (latest wins).
  - auth handling aligned with integration-service semantics for 401 (`missing_auth_context`) and 403 (`user_id_mismatch`).
  - **35** Node tests green via `npm test` (HTTP roundtrips + preset validation/`UserStore` + `tokenService`/`authContext` unit coverage).
  - GitHub Actions CI: Node 20, `npm install`, `npm test` on push/PR; branch protection on `main` requires passing check **`test`** (alongside existing review/signature rules).
- `sharebridge-api-gateway`, `sharebridge-order-service`, `sharebridge-notification-service`, `sharebridge-ai-safety`, `sharebridge-photo-service`, `sharebridge-web-app`, `sharebridge-infra`, `sharebridge-deployment`: README only, no code yet.

## Quick Runbook

Integration service:
- `cd sharebridge-integration-service`
- `npm install`
- `npm test`
- `npm start` → listens on `http://localhost:8080`
- Health: `GET /health`
- Preferences endpoints require a valid signed bearer token from user-service.

Mobile app:
- `cd sharebridge-mobile-app`
- `flutter pub get`
- `flutter test`
- Fetch token first: `POST http://localhost:8081/v1/auth/token` with `{"user_id":"demo-user"}` and copy `token`.
- Windows desktop: `flutter run --dart-define=API_BASE_URL=http://localhost:8080 --dart-define=USER_ID=demo-user --dart-define=AUTH_TOKEN=<token>`
- Android emulator: `flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8080 --dart-define=USER_ID=demo-user --dart-define=AUTH_TOKEN=<token>`

Manual end-to-end and API smoke steps live in `testing/MANUAL_TESTING_GUIDE.md` (includes **§3d–3e**: why suggest/mock looks static, how to **clear saved presets** on disk or via user-service `PUT`, local **merge** vs user-service **replace**).

## Next Recommended Tasks

Tasks #1-#5 are complete. Remaining priority order:

1. **Operational hardening for token flow (post‑MVP / AWS path).**
   - Render/Railway MVP uses dashboard env vars; centralized secret managers are **deferred** — see `development/IMPLEMENTATION_APPROACH.md` tech-debt note.
   - When ready: managed secret storage per environment, rotate dev default, disallow fallback outside local dev.
   - Add explicit token-expiry refresh flow in mobile UX.

2. **Cutover validation then code removal (optional final cleanup).**
   - Run backfill + `PREFERENCES_BACKEND=user_service` in a staging environment; confirm donor-setup flows.
   - Remove `PreferencesStore` / `LocalPreferencesRepository` when no deployment needs local file mode.

## Follow-ups Surfaced in Prior Sessions
- Backfill tooling: `sharebridge-integration-service` → `npm run backfill:user-service-presets` (documented in `development/USER_SERVICE_PREFERENCES_MIGRATION.md`).
- Retire integration-service file-backed store and `LocalPreferencesRepository` after production cutover is verified (not yet removed from code).

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
- `feat`: replace demo auth with signed token flow — user-service now mints JWT tokens, integration-service verifies token signature/claims and rejects `X-User-Id` fallback, mobile sends bearer token via `AUTH_TOKEN`; test suites updated and green.
- `feat`: add `backfill:user-service-presets` script and tests to migrate `PreferencesStore` JSON into user-service via signed tokens.
- `ci`: add GitHub Actions workflow for `sharebridge-user-service` (Node 20, `npm test`).
- `test`: expand `sharebridge-user-service` with `tokenService` and `authContext` unit tests; read token defaults from env at mint/verify time for test isolation.
- `test`: add `UserStore` file-backed persistence/dedupe tests, HTTP edges (`/health`, 404, invalid JSON, validation, URL-encoded `user_id`), and trim phone/email on merge-in to match create behavior.
- `docs`: refresh `USER_SERVICE_PREFERENCES_MIGRATION.md` for current contract and backfill; document Render/Railway secret-manager tech debt in `IMPLEMENTATION_APPROACH.md`.
- `docs`: clarify **MVP staging (mini vs matured)** in `AGENT_HANDOFF.md` and tie donor-setup file persistence to the Supabase-oriented roadmap in `IMPLEMENTATION_APPROACH.md`.
- `feat` (mobile): Saved presets screen + navigation from Donor Setup; copy/open order URLs for manual deep-link checks; docs/test counts updated (`MANUAL_TESTING_GUIDE.md`).
- `fix` (mobile): Donor Setup suggestion tiles show full menu list + app name; manual guide notes mock suggest-vendors ignores `query_text`.
- `fix` (mobile): After **Confirm and Save Presets**, reload preferences from the server and clear selection so the on-screen list matches saved choices (empty server list clears the list).
