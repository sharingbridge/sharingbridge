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

## Current Implementation Status
- `sharebridge-integration-service`:
  - `POST /v1/donor-setup/suggest-vendors` implemented (mock top-5 suggestions).
  - `POST /v1/donor-setup/preferences` implemented (save presets by `user_id`).
  - `GET /v1/donor-setup/preferences?user_id=...` implemented.
  - File-backed preferences store: `src/preferencesStore.js`.
  - Tests passing via `npm test`.
- `sharebridge-mobile-app`:
  - Donor setup search wired to backend API.
  - Confirm-and-save wired to preferences endpoint.
  - Startup load from backend by `user_id` with local `shared_preferences` fallback cache.
  - Tests passing via `flutter test`.

## Quick Runbook
- Integration service:
  - `cd sharebridge-integration-service`
  - `npm install`
  - `npm test`
  - `npm start`
  - Health: `http://localhost:8080/health`
- Mobile app:
  - `cd sharebridge-mobile-app`
  - `flutter pub get`
  - `flutter test`
  - Windows desktop: `flutter run --dart-define=API_BASE_URL=http://localhost:8080`
  - Android emulator: `flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8080`

## Next Recommended Tasks
1. Add timeout/retry and typed error mapping in mobile API client.
2. Add integration tests for preferences save+fetch roundtrip and dedupe behavior.
3. Move preference ownership from integration-service mock path toward user-service boundary (when user-service API baseline is ready).
4. Add minimal auth context (`user_id` from token/headers) instead of static demo user.
