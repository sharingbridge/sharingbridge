# SharingBridge Agent Handoff

> **Live coordination doc for AI-assisted coding sessions.** Read this first when picking up the project. Update the "Recently Shipped" and "Next Recommended Tasks" sections as work lands so the next session has fresh context.

## Goal
Deliver the MVP **donor-setup → donor-seeker interaction → vendor redirect → delivery confirmation** flow. **`sharingbridge-integration-service` is the Experience API** (shared BFF): mobile and web call it exclusively; it composes user-service, ai-orchestration, and order-intent Postgres. SharingBridge is never the system of record for money.

## Approach (Locked)
- Backend payment model: provider/vendor-hosted only.
- No platform-owned financial ledger or settlement responsibility.
- Delivery artifact access via technical controls.
- Queue strategy: Redis for MVP, SQS/SNS for scale.
- Backend source-of-truth for user preferences; client cache is non-authoritative.
- Mobile stack: Flutter.
- Backend API stack (MVP): plain **Node.js 20** HTTP servers (integration + user-service); NestJS is a scale target only.
- Architecture labels: **Experience API / shared BFF** = integration-service; **Process** = ai-orchestration, photo-service; **System** = user-service + Postgres. See `design/SharingBridge_Technical_Architecture.md` § As-built.

## Documentation map

**Master index:** [README.md § Documentation guide](../README.md#documentation-guide) — reading order, authority, phase naming.

**Status of what is shipped lives in this file** (sections below). Use the table to pick the right doc; avoid stale per-repo README headers (“Initial Setup”).

| If you need… | Read |
|--------------|------|
| **Which doc to read first** | `README.md` § Documentation guide |
| Run locally / Render deploy **order** | `configuration/e2e-deployment-sequence.md` |
| **SQL migrations in order** | `configuration/database-setup-sequence.md` |
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
| Order-ops supplement (payment, delivery proof) | `design/Future_Extensions.md` (A–B only; marketplace → PRODUCT_ROADMAP) |
| **Product roadmap** (glossary, marketplace, configurator) | `development/PRODUCT_ROADMAP.md` + `design/Configurator_Role_and_Unified_Initiation.md` |
| **AI full plan** (presets, descriptions, seeker ID; LangChain vs direct) | `development/AI_IMPLEMENTATION_PLAN.md` |
| Vendor preset setup API sequence | `design/Donor_Setup_AI_Search_Sequence.md` |
| Long-term / AWS scale plan (not deploy truth) | `development/IMPLEMENTATION_APPROACH.md` |
| Full system design + **as-built MVP** (Experience API, stack truth) | `design/SharingBridge_Technical_Architecture.md` § As-built |
| Live AI setup (Groq, Gemini, Nominatim) | `configuration/ai-setup-handhold.md` |
| Preferences architecture (user-service authority) | `development/USER_SERVICE_PREFERENCES_MIGRATION.md` |
| Development folder index | `development/README.md` |
| BRD assumptions | `requirements/SharingBridge_Business_Requirement.md` |

**Prefer over repo READMEs:** `configuration/*` and `MANUAL_TESTING_GUIDE.md` for runbooks (mobile/user-service READMEs are often outdated).

**OpenAPI contracts:** `design/contracts/donor_setup_suggest_vendors.openapi.yaml`, `donor_setup_preferences.openapi.yaml`, `user_service_donor_presets.openapi.yaml`, `design/contracts/examples/`

## Persistence model (current)

**Production** uses **Postgres only** for durable state. Both Node services **require `DATABASE_URL` at startup** — no JSON file store and no in-memory marketplace catalog in `src/`.

| Data | Store | Notes |
|------|--------|--------|
| Users, roles, presets | user-service → `users`, `user_roles`, `donor_presets` | integration forwards via `USER_SERVICE_BASE_URL` |
| Order intents | integration → `order_intents` | PostGIS `locality_key` / `location` |
| Seeker demands | integration → `seeker_demands` | Mobile **Record seeker demand** |
| Marketplace | integration → `standard_offers`, `meal_pledges`, `vendor_bids` | SQL **M1–M3** in [database-setup-sequence.md](../configuration/database-setup-sequence.md); startup probes M2 `standard_offer_id` columns |
| Standard menu catalog | `standard_offers` (M3 seed) | Test mirror: `sharingbridge-integration-service/test/fixtures/standardOffersCatalog.js` — keep in sync with [seed-standard-offers.sql](../configuration/seed-standard-offers.sql) |

**Tests only:** `LocalPreferencesRepository` + temp `PreferencesStore`, and `test/support/inMemoryMarketplaceStore.js`, are injected in route tests — not wired at `npm start`.

## Current Implementation Status

### `sharingbridge-integration-service` (vendor preset setup + AI bridge shipped)
- `POST /v1/donor-setup/suggest-vendors` — mock top-5 by default; calls `sharingbridge-ai-orchestration` when `AI_SUGGEST_VENDORS_ENABLED` + `AI_ORCHESTRATION_BASE_URL` are set (falls back to mock on upstream failure).
- `POST /v1/donor-seeker/instruction-pack` — delivery instruction narrative; calls orchestration when `AI_INSTRUCTION_PACK_ENABLED` (server-side fallback template otherwise).
- `src/aiOrchestrationClient.js`, `src/instructionPack.js`, `.env.example` for local three-service stack.
- `POST /v1/donor-setup/preferences` — save payee presets, `user_id` derived from auth headers.
- `GET /v1/donor-setup/preferences` — fetch presets, header-derived `user_id` (legacy `?user_id=` still accepted).
- `PreferencesRepository` abstraction (`src/preferencesRepository.js`): production uses **`UserServicePreferencesRepository`** → `sharingbridge-user-service` (`GET/PUT /v1/users/{user_id}/donor-presets`, **`POST …/donor-presets/delete-item`**). Requires **`USER_SERVICE_BASE_URL`**. `LocalPreferencesRepository` + `PreferencesStore` are **tests only**.
- Auth context (`src/authContext.js`): verifies signed bearer tokens (HS256) issued by user-service. `X-User-Id` fallback is removed. Missing/invalid token → `401 missing_auth_context`; URL/payload mismatch vs token subject → `403 user_id_mismatch`.
- HTTP server is exposed as a factory (`createIntegrationServer`) so tests can boot it against a temp DB.
- `DELETE /v1/donor-setup/preferences?user_id=…` clears all presets for the authed user (local store `clearForUser`; user-service mode uses `PUT` with `[]`). Mobile **Saved presets → Clear all** calls this and clears offline cache.
- `POST /v1/donor-setup/preferences/delete-item` removes one preset by `(restaurant_name, order_url)`; user-service mode calls **`POST /v1/users/{id}/donor-presets/delete-item`** (no GET+PUT read-modify-write).
- **Seeker demand + marketplace:** `POST /v1/seeker-demands`, `GET /v1/seeker-demands`, `GET /v1/standard-offers`, `POST /v1/pledges`, `POST /v1/vendor-bids`, `GET /v1/demand/board` — Postgres via `PostgresSeekerDemandStore` / `PostgresMarketplaceStore`; SQL **M1–M3** + `NOMINATIM_USER_AGENT` for GPS → postal `locality_key`. No pilot catalog or in-memory marketplace in `src/`.
- Production AI: `AI_MOCK_FALLBACK_ENABLED` defaults **false** — orchestration failures return **503** instead of template/mock text.
- `npm test` (135+ tests).

### `sharingbridge-mobile-app` (vendor preset setup MVP shipped; field + seeker demand)
- **Home hub** (`lib/presentation/app_home_page.dart`): **Vendor presets**, **Help a seeker** (About gate before field flow), **Record seeker demand**, order history, web dashboard link.
- **Payee–seeker interaction (`Help a seeker`):** three steps shipped — **Quick guidance** → **optional reference photo** + verbal notes → **instruction-pack API** (GPS requested **before** instruction generation; same coords reused on copy/register) → **Copy** + preset **Open …** deep links. **Planned:** live LLM + image/location descriptions + seeker hints — see `AI_IMPLEMENTATION_PLAN.md`. **Deferred:** `sharingbridge-location-safety` (geo scoring archived).
- Vendor preset setup screen wired to integration-service: search → suggestions → confirm-and-save.
- Startup loads presets from server, with local `shared_preferences` fallback cache when the server is unreachable.
- HTTP API client (`lib/features/donor_setup/data/http_donor_setup_api_client.dart`) supports request timeout, exponential-backoff retry, and typed exceptions (`PayeeSetupNetworkException`, `PayeeSetupTimeoutException`, `PayeeSetupBadRequestException`, `PayeeSetupServerException`, `PayeeSetupResponseException`). Mutating saves do not retry on 5xx (no double-write).
- UI surfaces friendly error messages per typed exception.
- `AuthContext` (`lib/features/donor_setup/data/auth_context.dart`) sources `user_id` from `--dart-define=USER_ID=...` and signed token from `--dart-define=AUTH_TOKEN=...`, and sends only `Authorization: Bearer <token>`.
- Vendor preset setup list shows **full `menu_items`** per suggestion (not only the first item); **suggest-vendors** is query-ranked when orchestration flags are on, else fixed mock.
- Vendor preset setup: suggestion rows include **Copy link**, **Open vendor page**, **Suggest again** (re-runs search); after **Confirm and Save** the full suggestion list stays visible (only checkboxes clear) and a **SnackBar** confirms save. App bar **Saved presets**: **Copy link** / **Open link**; per-row **Remove**; **Clear all** (`DELETE` + offline cache).
- **Record seeker demand** on home hub; `POST /v1/seeker-demands` via `HttpSeekerDemandClient` (`features/seeker_demand/`).
- **Order initiation history** on home hub; `POST/GET /v1/donor-seeker/order-intents` via `HttpOrderIntentClient`.
- **Google Sign-In** (payee): `google_sign_in` → user-service `POST /v1/auth/google` (`client_type` mobile); JWT `role: payee` (users may also have `coordinator` in `user_roles` for web).
- 53+ tests green via `flutter test` (see repo CI).

### `sharingbridge-user-service`
- **`PostgresUserStore`** + **`POST /v1/auth/google`** (roles from `user_roles`; coordinator via [coordinator-seed.sql](../configuration/coordinator-seed.sql)).
- Dev JWT: `node scripts/mint-dev-jwt.mjs` in user-service (no HTTP mint endpoint).
- `GET/PUT /v1/users/{user_id}/donor-presets`, **`POST …/delete-item`**; JWT HS256 mint/verify.
- **37+** Node tests; CI on push/PR.

### `sharingbridge-web-app` (coordinator + payee dashboard)
- Vite + React: **Google Sign-In** (GIS), order initiation history (List / Map / Demand toolbar), AI fields on detail (`location_description`, `seeker_handover_hints`, etc.), Demand board via `GET /v1/demand/board`.
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
- **Dev mint fallback:** `node scripts/mint-dev-jwt.mjs demo-user payee` → `--dart-define=AUTH_TOKEN=<token>`.
- Android emulator: `--dart-define=API_BASE_URL=http://10.0.2.2:8080` (plus Google or AUTH_TOKEN as above).

Product workflow (BRD steps 1–12, Mermaid diagrams, shipped vs planned): `design/SharingBridge_End_to_End_Workflow.md`.

Manual end-to-end and API smoke steps live in `testing/MANUAL_TESTING_GUIDE.md` (includes **§3d–3e**: why suggest/mock looks static, how to **clear saved presets** via app or Postgres; marketplace **M1–M3** for Demand tab and standard menu picker).

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

1. **Neighbourhood dashboard UX (June 4 memos)** — [PRODUCT_ROADMAP.md](./PRODUCT_ROADMAP.md): list columns **Order intent taken** (`created_at`), **Delivered at** (`delivered_at`, often empty until Phase B), **Distance (m)**; elapsed from **created_at** only; sort by distance asc; payee neighbourhood photos; mobile→web link.
2. **Neighbourhood + payee-safe dashboards (broader)** — [Future_Extensions.md](../design/Future_Extensions.md) Phase A.2–A.4; then AI descriptions + embeddings per [IMPLEMENTATION_APPROACH.md](./IMPLEMENTATION_APPROACH.md) payee–seeker slice (phases B–D).
3. **Operational hardening for token flow (post‑MVP / AWS path).**
   - Render/Railway MVP uses dashboard env vars; centralized secret managers are **deferred** — see `development/IMPLEMENTATION_APPROACH.md` tech-debt note.
   - When ready: managed secret storage per environment, rotate dev default, disallow fallback outside local dev.
   - Add explicit token-expiry refresh flow in mobile UX.

4. **Track A — hosted MVP backend.** [configuration/backend-render.md](../configuration/backend-render.md). Smoke: MANUAL_TESTING_GUIDE **§6** (hosted); web dashboard **§4**. Run marketplace **M1–M3** before testing Demand tab / standard menu picker. Then **Track B:** `sharingbridge-photo-service` + mobile upload.
5. **AI descriptions + embeddings** — [IMPLEMENTATION_APPROACH.md](./IMPLEMENTATION_APPROACH.md) § payee–seeker field slice; optional `AI_LLM_MODE=openai`; Cloudinary TTL (1–2h) aligned with secure-link policy.

## Follow-ups Surfaced in Prior Sessions
- `LocalPreferencesRepository` / `PreferencesStore` remain for **automated tests only**; production uses user-service Postgres.
- **Neighbourhood dashboard (June 2026):** columns **Order intent taken**, **Delivered at**, **Distance (m)**; sort `distance_m` asc; `delivered_at` column — `development/PRODUCT_ROADMAP.md`.
- **Order operations + neighbourhood dashboards:** `design/Future_Extensions.md` Phase A; AI/embeddings — `development/IMPLEMENTATION_APPROACH.md`.
- **Order operations roadmap:** payee marks payment done on record; later delivery-partner photo + `delivered`; future locality demand + vendor bidding — `design/Future_Extensions.md`.

## Recently Shipped (chronological, newest last)
- `feat`: donor-setup `suggest-vendors` mock endpoint + tests.
- `feat`: donor-setup preset save endpoint.
- `feat`: persist payee presets per user and add preferences fetch.
- `feat`: scaffold Flutter day-1 donor-setup baseline + wire suggest-vendors API client.
- `feat`: complete mobile preset confirm-save flow and add platforms.
- `feat`: load presets from server with local cache fallback.
- `feat`: add timeout, retry, and typed errors to vendor preset setup API client (mobile).
- `test`: add HTTP roundtrip tests for payee preferences save and dedupe (integration-service).
- `refactor`: introduce preferences repository boundary toward user-service (integration-service) — abstraction now named `PreferencesRepository` (was `PreferencesGateway` to avoid edge-gateway terminology clash).
- `feat`: derive user_id from auth headers on preferences endpoints (integration-service).
- `feat`: send payee identity via auth headers from mobile app.
- `docs`: add `testing/` folder with `MANUAL_TESTING_GUIDE.md` for shipped modules.
- `docs`: clean up unused `prompting/` folders, retire `development/PROMPTS.md`, and refocus README + CALL_FOR_CONTRIBUTORS on AGENT_HANDOFF as the live coordination doc.
- `feat`: bootstrap `sharingbridge-user-service` skeleton with demo-token auth endpoint, donor-presets GET/PUT APIs, file-backed payee model/preset storage, and green roundtrip tests for token + presets + 401/403 auth paths.
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
- `feat` (mobile): Saved presets screen + navigation from Vendor preset setup; copy/open order URLs for manual deep-link checks; docs/test counts updated (`MANUAL_TESTING_GUIDE.md`).
- `fix` (mobile): Vendor preset setup suggestion tiles show full menu list + app name; manual guide notes mock suggest-vendors ignores `query_text`.
- `fix` (mobile): After **Confirm and Save Presets**, keep the full mock suggestion list and clear only checkboxes; avoid stale `_loadInitialPresets` overwriting search results; snackbar on save.
- `feat`: integration-service **`DELETE` donor-setup preferences** + `POST …/delete-item`; mobile **Clear all** + per-row **Remove**; user-service **`POST …/donor-presets/delete-item`** (single HTTP delete); OpenAPI: `donor_setup_preferences.openapi.yaml`, `user_service_donor_presets.openapi.yaml`.
- `feat` (mobile): Vendor preset setup **Copy link**, **Open vendor page**, **Suggest again**; integration README + manual guide + migration doc aligned to current counts and flows.
- `feat` (mobile): Home hub + payee–seeker **Offer food help** flow (consent, safety gate, beneficiary notes, local draft persistence); `flutter test` count **30**.
- `feat` (mobile): **Offer food help** redesign — dignity + photo-consent guidance; stub delivery instructions + copy; vendor deep links after copy; remove field draft persistence; `flutter test` **32**.
- `feat` (mobile): **Offer food help** — 3-step flow, optional `image_picker` reference photo, async `requestStubDeliveryInstructions` AI placeholder, `Card.filled` instruction area; `flutter test` **34**.
- `docs`: **AI interactions — payee–seeker field slice** in `IMPLEMENTATION_APPROACH.md` (safety, deep links, instruction-pack template, photo match); photo-service / location-safety notes (latter deferred).
- `docs`: **AI platform integration** — `AI_PLATFORM_INTEGRATION.md` (LangChain orchestration, hosting, mobile/backend bridges).
- `docs`: BRD + Technical Architecture aligned — **Location Safety Module** / `sharingbridge-location-safety` (rule-based geo; not LLM); photo/face in `sharingbridge-photo-service`.
