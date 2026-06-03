# SharingBridge Agent Handoff

> **Live coordination doc for AI-assisted coding sessions.** Read this first when picking up the project. Update the "Recently Shipped" and "Next Recommended Tasks" sections as work lands so the next session has fresh context.

## Goal
Deliver the MVP **donor-setup → donor-seeker interaction → vendor redirect → delivery confirmation** flow. The integration service is the platform's facilitator. SharingBridge is never the system of record for money.

## Approach (Locked)
- Backend payment model: provider/vendor-hosted only.
- No platform-owned financial ledger or settlement responsibility.
- Delivery artifact access via technical controls.
- Queue strategy: Redis for MVP, SQS/SNS for scale.
- Backend source-of-truth for user preferences; client cache is non-authoritative.
- Mobile stack: Flutter.
- Backend API stack (MVP): Node.js + NestJS direction; integration-service today is a lightweight Node http server for fast iteration.

## Documentation map

**Status of what is shipped lives in this file** (sections below). Use the table to pick the right doc; avoid stale per-repo README headers (“Initial Setup”).

| If you need… | Read |
|--------------|------|
| Run locally / Render deploy **order** | `configuration/e2e-deployment-sequence.md` |
| Google OAuth + coordinator `user_roles` seed | `configuration/google-auth-setup.md` |
| Auth, JWT, roles | `configuration/authentication.md` |
| **Supabase** tables + `DATABASE_URL` on Render APIs | `configuration/database.md` |
| Render backends + CORS | `configuration/backend-render.md` |
| Web coordinator dashboard | `configuration/web-client.md` |
| Mobile `dart-define` / URLs | `configuration/mobile-client.md` |
| Help a seeker / order intent | `configuration/field-handoff.md` |
| Configuration index | `configuration/README.md` |
| **Manual test steps** | `testing/MANUAL_TESTING_GUIDE.md` |
| BRD steps 1–12 + diagrams | `design/SharingBridge_End_to_End_Workflow.md` |
| Future: payment, delivery proof, vendor bidding | `design/Future_Extensions.md` |
| Donor setup API sequence | `design/Donor_Setup_AI_Search_Sequence.md` |
| Long-term / AWS scale plan (not deploy truth) | `development/IMPLEMENTATION_APPROACH.md` |
| Full system design (many sections **future**) | `design/SharingBridge_Technical_Architecture.md` |
| Preferences file → user-service cutover | `development/USER_SERVICE_PREFERENCES_MIGRATION.md` |
| Development folder index | `development/README.md` |
| BRD assumptions | `requirements/SharingBridge_Business_Requirement.md` |

**Prefer over repo READMEs:** `configuration/*` and `MANUAL_TESTING_GUIDE.md` for runbooks (mobile/user-service READMEs are often outdated).

**OpenAPI contracts:** `design/contracts/donor_setup_suggest_vendors.openapi.yaml`, `donor_setup_preferences.openapi.yaml`, `user_service_donor_presets.openapi.yaml`, `design/contracts/examples/`

## MVP staging (mini vs matured)

The **donor-setup slice** that is live in code is intentionally a **minimal MVP** (“MVP‑0”): flows and APIs are wired end‑to‑end while **preferences and user-service donor data stay file‑backed JSON** (easy local and Render/Railway iteration, with the limits of ephemeral disks and single-instance file stores).

**Matured MVP** means closing the gap with `development/IMPLEMENTATION_APPROACH.md`: attach **managed Postgres** (for example Supabase during free tier) for user‑scoped persistence where the architecture diagram shows a database, plus hosting patterns suited to durability and scale. Product scope stays MVP; infra depth catches up.

`development/USER_SERVICE_PREFERENCES_MIGRATION.md` describes preferences authority and integration ↔ user‑service cutover; this section is only about labeling **what shipped now** versus **what the roadmap stack assumes**.

## Current Implementation Status

### `sharingbridge-integration-service` (donor setup + AI bridge shipped)
- `POST /v1/donor-setup/suggest-vendors` — mock top-5 by default; calls `sharingbridge-ai-orchestration` when `AI_SUGGEST_VENDORS_ENABLED` + `AI_ORCHESTRATION_BASE_URL` are set (falls back to mock on upstream failure).
- `POST /v1/donor-seeker/instruction-pack` — delivery instruction narrative; calls orchestration when `AI_INSTRUCTION_PACK_ENABLED` (server-side fallback template otherwise).
- `src/aiOrchestrationClient.js`, `src/instructionPack.js`, `.env.example` for local three-service stack.
- `POST /v1/donor-setup/preferences` — save donor presets, `user_id` derived from auth headers.
- `GET /v1/donor-setup/preferences` — fetch presets, header-derived `user_id` (legacy `?user_id=` still accepted).
- File-backed preferences store (`src/preferencesStore.js`) accessed via a `PreferencesRepository` abstraction (`src/preferencesRepository.js`).
  - `LocalPreferencesRepository` is wired today.
  - `UserServicePreferencesRepository` is wired to `sharingbridge-user-service` (`GET/PUT /v1/users/{user_id}/donor-presets`, **`POST …/donor-presets/delete-item`** for single-row delete) and forwards donor auth headers.
  - Backend selected by `PREFERENCES_BACKEND` env (`local` default, `user_service` requires `USER_SERVICE_BASE_URL`).
- Auth context (`src/authContext.js`): verifies signed bearer tokens (HS256) issued by user-service. `X-User-Id` fallback is removed. Missing/invalid token → `401 missing_auth_context`; URL/payload mismatch vs token subject → `403 user_id_mismatch`.
- HTTP server is exposed as a factory (`createIntegrationServer`) so tests can boot it against a temp DB.
- `DELETE /v1/donor-setup/preferences?user_id=…` clears all presets for the authed user (local store `clearForUser`; user-service mode uses `PUT` with `[]`). Mobile **Saved presets → Clear all** calls this and clears offline cache.
- `POST /v1/donor-setup/preferences/delete-item` removes one preset by `(restaurant_name, order_url)`; user-service mode calls **`POST /v1/users/{id}/donor-presets/delete-item`** (no GET+PUT read-modify-write).
- 42 tests, all green via `npm test`; `npm run backfill:user-service-presets` migrates `data/preferences.json` → user-service (see migration doc).

### `sharingbridge-mobile-app` (donor setup MVP shipped; Offer food help handoff)
- **Home hub** (`lib/presentation/app_home_page.dart`): entry to **Donor setup** vs **Offer food help**.
- **Donor–seeker interaction (`Offer food help`):** three steps shipped — **Quick guidance** (fixed copy, BRD step 4) → **optional reference photo** + verbal notes → **instruction-pack API** (`POST /v1/donor-seeker/instruction-pack` via integration; local stub fallback if API unreachable) → **Copy** + preset **Open …** deep links. **Planned:** cloud photo upload + geo, live LLM (`AI_LLM_MODE=openai`), delivery acknowledgement, donor↔delivery photo match. **Deferred:** `sharingbridge-location-safety` (geo scoring archived) — see `IMPLEMENTATION_APPROACH.md` **AI interactions** and `AI_PLATFORM_INTEGRATION.md`.
- Donor setup screen wired to integration-service: search → suggestions → confirm-and-save.
- Startup loads presets from server, with local `shared_preferences` fallback cache when the server is unreachable.
- HTTP API client (`lib/features/donor_setup/data/http_donor_setup_api_client.dart`) supports request timeout, exponential-backoff retry, and typed exceptions (`DonorSetupNetworkException`, `DonorSetupTimeoutException`, `DonorSetupBadRequestException`, `DonorSetupServerException`, `DonorSetupResponseException`). Mutating saves do not retry on 5xx (no double-write).
- UI surfaces friendly error messages per typed exception.
- `AuthContext` (`lib/features/donor_setup/data/auth_context.dart`) sources `user_id` from `--dart-define=USER_ID=...` and signed token from `--dart-define=AUTH_TOKEN=...`, and sends only `Authorization: Bearer <token>`.
- Donor Setup list shows **full `menu_items`** per suggestion (not only the first item); **suggest-vendors** is query-ranked when orchestration flags are on, else fixed mock.
- Donor Setup: suggestion rows include **Copy link**, **Open vendor page**, **Suggest again** (re-runs search); after **Confirm and Save** the full suggestion list stays visible (only checkboxes clear) and a **SnackBar** confirms save. App bar **Saved presets**: **Copy link** / **Open link**; per-row **Remove**; **Clear all** (`DELETE` + offline cache).
- **Order initiation history** on home hub; `POST/GET /v1/donor-seeker/order-intents` via `HttpOrderIntentClient`.
- **Google Sign-In** (donor): `google_sign_in` → user-service `POST /v1/auth/google` (`client_type` mobile); JWT `role: donor` (users may also have `coordinator` in `user_roles` for web).
- 53+ tests green via `flutter test` (see repo CI).

### `sharingbridge-user-service`
- **`PostgresUserStore`** + **`POST /v1/auth/google`** (roles from `user_roles`; coordinator via [coordinator-seed.sql](../configuration/coordinator-seed.sql)).
- `POST /v1/auth/token` (dev mint when `BYPASS_GOOGLE_SIGN_IN=true`).
- `GET/PUT /v1/users/{user_id}/donor-presets`, **`POST …/delete-item`**; JWT HS256 mint/verify.
- **37+** Node tests; CI on push/PR.

### `sharingbridge-web-app` (coordinator dashboard)
- Vite + React: **Google Sign-In** (GIS), order initiation history, coordinator list-all via integration-service.
- Deploy: Render static site; config [configuration/web-client.md](../configuration/web-client.md), test **MANUAL_TESTING_GUIDE §4**.

### Other repos
- `sharingbridge-ai-orchestration`: deterministic MVP (FastAPI); live LLM optional.
- `sharingbridge-api-gateway`, `sharingbridge-order-service`, `sharingbridge-notification-service`, `sharingbridge-photo-service`, `sharingbridge-infra`, `sharingbridge-deployment`: README / not started.
- `sharingbridge-location-safety`: **archived**. **Next slice:** photo-service, order ops per [design/Future_Extensions.md](../design/Future_Extensions.md).

## Quick Runbook

Integration service:
- `cd sharingbridge-integration-service`
- `npm install`
- `npm test`
- `npm start` → listens on `http://localhost:8080`
- Health: `GET /health`
- Preferences endpoints require a valid signed bearer token from user-service.

Mobile app:
- `cd sharingbridge-mobile-app`
- `flutter pub get`
- `flutter test`
- **Google (recommended):** see [configuration/mobile-client.md](../configuration/mobile-client.md) and **MANUAL_TESTING_GUIDE §3-auth**.
- **Dev mint fallback:** `POST http://localhost:8081/v1/auth/token` with `{"user_id":"demo-user","role":"donor"}` → `--dart-define=AUTH_TOKEN=<token>`.
- Android emulator: `--dart-define=API_BASE_URL=http://10.0.2.2:8080` (plus Google or AUTH_TOKEN as above).

Product workflow (BRD steps 1–12, Mermaid diagrams, shipped vs planned): `design/SharingBridge_End_to_End_Workflow.md`.

Manual end-to-end and API smoke steps live in `testing/MANUAL_TESTING_GUIDE.md` (includes **§3d–3e**: why suggest/mock looks static, how to **clear saved presets** on disk or via user-service `PUT`, local **merge** vs user-service **replace**).

## Post-ship checklist (after `main` pushes or large merges)

Do this before starting the next feature thread:

1. **CI on GitHub** — Open the latest workflow run on `main` for each repo you changed (for example `sharingbridge-user-service`, `sharingbridge-integration-service`, `sharingbridge-mobile-app`, or the coordination repo `sharingbridge`). Confirm the **`test`** job (and any other required checks) are green; fix failures before layering more changes.
2. **Manual smoke** — Short pass from `testing/MANUAL_TESTING_GUIDE.md`: mint token, suggest, save presets, single-row delete (`delete-item`), clear all, mobile **Copy link** / **Suggest again** / saved-presets flows.
3. **Branch protection alignment** — If org rules expect PRs + required checks (and direct `main` pushes only work via bypass), use **feature branches + PRs** next time so reviews and status checks run normally.
4. **Roadmap next slice** — After the above, pick the next MVP milestone from `development/IMPLEMENTATION_APPROACH.md` and the BRD (e.g. donor-seeker flow, real vendor search replacing mock suggest, managed DB for durability).

## GitHub: `sharingbridge` org and repository slugs

Organization: **`sharingbridge`** (`https://github.com/sharingbridge`). Set each clone’s `origin` to `https://github.com/sharingbridge/<slug>.git` (run `scripts/set-remotes-sharingbridge.ps1` from the coordination repo to batch-update).

| Role | Slug |
|------|------|
| Coordination / docs | `sharingbridge` |
| User service | `sharingbridge-user-service` |
| Integration | `sharingbridge-integration-service` |
| Mobile / web apps | `sharingbridge-mobile-app`, `sharingbridge-web-app` |
| Photo / AI | `sharingbridge-photo-service`, `sharingbridge-ai-orchestration` |
| Not in Track A MVP | `sharingbridge-api-gateway`, `sharingbridge-order-service`, `sharingbridge-notification-service`, `sharingbridge-location-safety` (archived) |

Local folder names may differ from slugs; **git only cares about `origin`**. Package names in `pubspec.yaml` / `package.json` are unchanged by remote URL updates.

## Next Recommended Tasks

Tasks #1-#5 are complete. Remaining priority order:

1. **Neighbourhood + donor-safe dashboards** — [Future_Extensions.md](../design/Future_Extensions.md) Phase A.2–A.4 (geo on intent, `since=1h` feeds, donor web without email, photos ≤1h); then AI descriptions + embeddings per [IMPLEMENTATION_APPROACH.md](./IMPLEMENTATION_APPROACH.md) donor–seeker slice (phases B–D).
2. **Operational hardening for token flow (post‑MVP / AWS path).**
   - Render/Railway MVP uses dashboard env vars; centralized secret managers are **deferred** — see `development/IMPLEMENTATION_APPROACH.md` tech-debt note.
   - When ready: managed secret storage per environment, rotate dev default, disallow fallback outside local dev.
   - Add explicit token-expiry refresh flow in mobile UX.

3. **Cutover validation then code removal (optional final cleanup).**
   - Run backfill + `PREFERENCES_BACKEND=user_service` in a staging environment; confirm donor-setup flows.
   - Remove `PreferencesStore` / `LocalPreferencesRepository` when no deployment needs local file mode.

4. **Track A — hosted MVP backend.** [configuration/backend-render.md](../configuration/backend-render.md). Smoke: MANUAL_TESTING_GUIDE **§6** (hosted); web dashboard **§4**. Then **Track B:** `sharingbridge-photo-service` + mobile upload.
5. **AI descriptions + embeddings** — [IMPLEMENTATION_APPROACH.md](./IMPLEMENTATION_APPROACH.md) § donor–seeker field slice; optional `AI_LLM_MODE=openai`; Cloudinary TTL (1–2h) aligned with secure-link policy.

## Follow-ups Surfaced in Prior Sessions
- Backfill tooling: `sharingbridge-integration-service` → `npm run backfill:user-service-presets` (documented in `development/USER_SERVICE_PREFERENCES_MIGRATION.md`).
- Retire integration-service file-backed store and `LocalPreferencesRepository` after production cutover is verified (not yet removed from code).
- **Order operations + neighbourhood dashboards:** donor web PII rules, geo feeds — `design/Future_Extensions.md` Phase A; AI/embeddings — `development/IMPLEMENTATION_APPROACH.md`.
- **Order operations roadmap:** donor marks payment done on record; later delivery-partner photo + `delivered`; future locality demand + vendor bidding — `design/Future_Extensions.md`.

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
- `feat`: bootstrap `sharingbridge-user-service` skeleton with demo-token auth endpoint, donor-presets GET/PUT APIs, file-backed donor model/preset storage, and green roundtrip tests for token + presets + 401/403 auth paths.
- `ci`: add minimal GitHub Actions CI workflows for `sharingbridge-integration-service` (Node 20, `npm install`, `npm test`) and `sharingbridge-mobile-app` (Flutter stable, `flutter pub get`, `flutter test`) on push/PR.
- `feat`: mobile donor-setup polish — replace hard-coded manual area with editable field, distinguish empty server presets from server-unreachable fallback behavior, and add clear cache/sign-out action; extend widget tests for new behaviors.
- `feat`: wire `UserServicePreferencesRepository` to live user-service donor-presets APIs, forward auth headers from integration-service requests, propagate upstream 4xx errors, and add coverage for repository HTTP behavior plus integration-to-user-service roundtrip path.
- `feat`: replace demo auth with signed token flow — user-service now mints JWT tokens, integration-service verifies token signature/claims and rejects `X-User-Id` fallback, mobile sends bearer token via `AUTH_TOKEN`; test suites updated and green.
- `feat`: add `backfill:user-service-presets` script and tests to migrate `PreferencesStore` JSON into user-service via signed tokens.
- `ci`: add GitHub Actions workflow for `sharingbridge-user-service` (Node 20, `npm test`).
- `test`: expand `sharingbridge-user-service` with `tokenService` and `authContext` unit tests; read token defaults from env at mint/verify time for test isolation.
- `test`: add `UserStore` file-backed persistence/dedupe tests, HTTP edges (`/health`, 404, invalid JSON, validation, URL-encoded `user_id`), and trim phone/email on merge-in to match create behavior.
- `docs`: refresh `USER_SERVICE_PREFERENCES_MIGRATION.md` for current contract and backfill; document Render/Railway secret-manager tech debt in `IMPLEMENTATION_APPROACH.md`.
- `docs`: clarify **MVP staging (mini vs matured)** in `AGENT_HANDOFF.md` and tie donor-setup file persistence to the Supabase-oriented roadmap in `IMPLEMENTATION_APPROACH.md`.
- `feat` (mobile): Saved presets screen + navigation from Donor Setup; copy/open order URLs for manual deep-link checks; docs/test counts updated (`MANUAL_TESTING_GUIDE.md`).
- `fix` (mobile): Donor Setup suggestion tiles show full menu list + app name; manual guide notes mock suggest-vendors ignores `query_text`.
- `fix` (mobile): After **Confirm and Save Presets**, keep the full mock suggestion list and clear only checkboxes; avoid stale `_loadInitialPresets` overwriting search results; snackbar on save.
- `feat`: integration-service **`DELETE` donor-setup preferences** + `POST …/delete-item`; mobile **Clear all** + per-row **Remove**; user-service **`POST …/donor-presets/delete-item`** (single HTTP delete); OpenAPI: `donor_setup_preferences.openapi.yaml`, `user_service_donor_presets.openapi.yaml`.
- `feat` (mobile): Donor Setup **Copy link**, **Open vendor page**, **Suggest again**; integration README + manual guide + migration doc aligned to current counts and flows.
- `feat` (mobile): Home hub + donor–seeker **Offer food help** flow (consent, safety gate, beneficiary notes, local draft persistence); `flutter test` count **30**.
- `feat` (mobile): **Offer food help** redesign — dignity + photo-consent guidance; stub delivery instructions + copy; vendor deep links after copy; remove field draft persistence; `flutter test` **32**.
- `feat` (mobile): **Offer food help** — 3-step flow, optional `image_picker` reference photo, async `requestStubDeliveryInstructions` AI placeholder, `Card.filled` instruction area; `flutter test` **34**.
- `docs`: **AI interactions — donor–seeker field slice** in `IMPLEMENTATION_APPROACH.md` (safety, deep links, instruction-pack template, photo match); photo-service / location-safety notes (latter deferred).
- `docs`: **AI platform integration** — `AI_PLATFORM_INTEGRATION.md` (LangChain orchestration, hosting, mobile/backend bridges).
- `docs`: BRD + Technical Architecture aligned — **Location Safety Module** / `sharingbridge-location-safety` (rule-based geo; not LLM); photo/face in `sharingbridge-photo-service`.
