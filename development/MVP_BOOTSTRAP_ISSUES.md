# ShareBridge MVP Bootstrap Issues Checklist

This document provides copy-ready MVP bootstrap issue definitions for the core repos:

- `sharingbridge-api-gateway`
- `sharingbridge-user-service`
- `sharingbridge-order-service`
- `sharingbridge-integration-service`
- `sharingbridge-notification-service`
- `sharingbridge-mobile-app`
- `sharingbridge-web-app`

Source-of-truth alignment:

- BRD: `requirements/ShareBridge_Business_Requirement.md` -> `Core Workflow` + `Operating Constraints & Assumptions`
- Technical architecture and implementation approach must follow BRD assumptions

Locked constraints reflected in all issues:

- Provider/vendor-hosted payment links only (no platform-owned checkout flow)
- No authoritative ShareBridge financial ledger or settlement ownership
- Delivery data access via technical controls only (no NDA dependency)
- Secure instruction/photo link active until delivery completion + 30-minute look-back, then expiry
- Queue strategy: Redis Streams/PubSub for MVP; AWS SQS/SNS as scale path
- Mobile and web client repos are explicit MVP tracks

---

## Shared MVP Acceptance Baseline (Apply to Every Repo)

Each issue below should be closed only when all relevant items are demonstrably true:

- Supports BRD workflow ordering from donor setup to delivery confirmation/history
- Enforces facilitator-only payment model with vendor/provider redirect handling
- Avoids authoritative financial-ledger responsibilities
- Uses technical access controls for delivery artifacts and instruction references
- Works with Redis-based async flow for MVP and keeps SQS/SNS migration path clean
- Produces observable logs/metrics for key success and failure states

---

## 1) `sharingbridge-api-gateway`

**Issue title:** `MVP Bootstrap: API Gateway routing, auth edge, and workflow orchestration endpoints`

**Scope checklist:**

- [ ] Define and expose v1 route map for donor setup, order intent, integration actions, status/history
- [ ] Add OAuth start/callback pass-through endpoints for vendor auth flow
- [ ] Implement JWT validation, request-id propagation, and role guard stubs
- [ ] Add rate limits and basic abuse protection on public/externalized endpoints
- [ ] Add health/readiness endpoints and OpenAPI baseline docs
- [ ] Add integration contract tests against user/order/integration/notification service stubs

**Acceptance criteria:**

- [ ] API contracts support BRD flow steps 1, 5, 8, 11, 12 without reordering assumptions
- [ ] Payment endpoints only redirect/relay to provider/vendor links; no in-gateway payment processing
- [ ] Gateway does not expose any ledger-style endpoints for settlement or balances
- [ ] OAuth callback handling is idempotent and traceable via correlation IDs
- [ ] Failure responses are standardized for mobile/web consumption

---

## 2) `sharingbridge-user-service`

**Issue title:** `MVP Bootstrap: donor auth/profile and pre-field setup preferences`

**Scope checklist:**

- [ ] Bootstrap auth module (OTP/email or configured MVP auth mechanism) and token lifecycle
- [ ] Define donor profile model with vendor deep-link preferences and menu templates
- [ ] Add donor setup preference schema support for AI-suggested local vendors/menu templates with explicit donor-confirmed values
- [ ] Add APIs for donor setup CRUD (pre-field preferences)
- [ ] Add secure storage rules for profile-linked configuration data
- [ ] Add audit events for auth and setup updates
- [ ] Add unit/integration tests for auth and setup API contracts

**Acceptance criteria:**

- [ ] BRD step 1 (Donor Setup) is fully supported through API + persistence
- [ ] Beneficiary is not treated as a registered login user in service design
- [ ] User service stores only required non-financial profile/config data
- [ ] Auth/session behavior is consumable by both `sharingbridge-mobile-app` and `sharingbridge-web-app`
- [ ] Core setup APIs are documented and versioned
- [ ] Setup model cleanly stores AI suggestion provenance (confidence/source type) separately from donor-confirmed preferences

---

## 3) `sharingbridge-order-service`

**Issue title:** `MVP Bootstrap: order intent lifecycle, safety gate, and delivery-status timeline`

**Scope checklist:**

- [ ] Define order intent entity and status state machine for MVP path
- [ ] Add early safety-check gate integration point before order placement progression
- [ ] Persist beneficiary interaction-context metadata needed for coordination and delivery
- [ ] Publish/consume order domain events over Redis Streams/PubSub
- [ ] Expose APIs for order create/read/status/history
- [ ] Add retry/idempotency controls for event-driven transitions

**Acceptance criteria:**

- [ ] BRD steps 4-5, 8, 10-12 are represented in explicit order states/transitions
- [ ] Data model excludes authoritative money ledger responsibilities
- [ ] Event contracts are compatible with Redis MVP and transport-abstraction for SQS/SNS migration
- [ ] History endpoints provide donor/admin view of nearby/past outcomes
- [ ] Timeouts and dead-letter/retry behavior are documented for operational handling

---

## 4) `sharingbridge-integration-service`

**Issue title:** `MVP Bootstrap: vendor integration, instruction-pack assembly, secure artifact references`

**Scope checklist:**

- [ ] Implement vendor OAuth/deep-link integration skeleton (start, callback, token handling hooks)
- [ ] Implement final instruction-pack assembly from donor/context inputs
- [ ] Implement AI-assisted local vendor/menu suggestion endpoint using fixed prompt + strict JSON schema validation
- [ ] Integrate secure photo + instruction storage reference generation
- [ ] Enforce secure link TTL policy: active until delivery completion + 30 minutes, then expire
- [ ] Add vendor order submission adapter interfaces and mock provider implementation
- [ ] Add webhook receiver skeleton for vendor status updates

**Acceptance criteria:**

- [ ] BRD steps 6-9 are supported with Integration Service as final instruction-pack owner
- [ ] Delivery artifact access is enforced through technical controls (no NDA dependency assumptions)
- [ ] Payment flow is provider-hosted redirect/deep-link only
- [ ] Secure link lifetime behavior is tested and auditable
- [ ] Vendor adapters are interface-driven to allow multi-vendor expansion
- [ ] AI suggestion endpoint rejects malformed model output and returns safe fallback/manual-entry guidance

---

## 5) `sharingbridge-notification-service`

**Issue title:** `MVP Bootstrap: event-driven donor notifications and completion confirmation`

**Scope checklist:**

- [ ] Subscribe to order/integration events over Redis Streams/PubSub
- [ ] Implement notification templates for key states (created, in-progress, completed, failed)
- [ ] Add push + in-app + email channels per MVP defaults
- [ ] Add deduplication/idempotency guard for repeated upstream events
- [ ] Persist notification delivery attempts and outcomes
- [ ] Add webhook or callback adapter hooks for future channel providers

**Acceptance criteria:**

- [ ] BRD step 11 completion communication is reliable across configured channels
- [ ] Notification timing reflects order timeline without exposing sensitive delivery artifacts directly
- [ ] Queue strategy is Redis for MVP with clear provider abstraction for SQS/SNS scale path
- [ ] Retries/backoff and failure observability are defined and tested
- [ ] Mobile/web clients can fetch notification history/status

---

## 6) `sharingbridge-mobile-app`

**Issue title:** `MVP Bootstrap: donor-seeker interaction flow mobile UX (setup -> safety -> instruction -> vendor redirect)`

**Scope checklist:**

- [ ] Bootstrap app shell, auth/session wiring, and API client base
- [ ] Build donor setup screens (AI-assisted local vendor/menu suggestions + manual edit + confirmation, then saved payment preferences)
- [ ] Build donor-seeker interaction flow screens (consent, quick safety check, beneficiary capture)
- [ ] Display generated instruction pack with one-tap copy + secure reference awareness
- [ ] Implement external vendor redirect/return handling with state recovery
- [ ] Add order status timeline and completion confirmation views

**Acceptance criteria:**

- [ ] Mobile UX supports BRD steps 1-11 in user-correct sequence
- [ ] Payment UX clearly exits ShareBridge into provider/vendor-hosted flow
- [ ] No UI implies platform-owned wallet/ledger behavior
- [ ] Error states cover safety check failure, vendor callback delay, and network interruption
- [ ] App stores only required local transient state and protects sensitive references
- [ ] AI onboarding never auto-commits suggestions; donor review/confirm is mandatory with low-confidence manual fallback

---

## 7) `sharingbridge-web-app`

**Issue title:** `MVP Bootstrap: web operations view for order monitoring, history, and exception handling`

**Scope checklist:**

- [ ] Bootstrap web app auth/session and role-aware route skeleton
- [ ] Build active order monitoring views and order detail timeline screens
- [ ] Build history/nearby outcomes views for donor/admin roles
- [ ] Add exception dashboards for failed callbacks, delayed webhooks, and retry actions
- [ ] Integrate notification status and secure-link access event visibility
- [ ] Add responsive + accessibility baseline for critical workflows

**Acceptance criteria:**

- [ ] Web app supports BRD step 12 with clear history/operations visibility
- [ ] Operational views surface workflow bottlenecks without exposing restricted artifact payloads
- [ ] No settlement/ledger UI concepts are introduced
- [ ] Supports parity with mobile flow state model for cross-channel consistency
- [ ] Production-readiness checklist includes security headers and session hardening

---

## Suggested Execution Order

1. `sharingbridge-user-service` + `sharingbridge-api-gateway` foundations
2. `sharingbridge-order-service` core state machine and events
3. `sharingbridge-integration-service` instruction-pack + vendor adapter skeleton
4. `sharingbridge-notification-service` event subscribers and delivery channels
5. `sharingbridge-mobile-app` donor-seeker interaction flow implementation
6. `sharingbridge-web-app` operations and history dashboards

Parallelization recommendation:

- Backend foundation (`api-gateway`, `user`, `order`) in parallel with frontend shell setup (`mobile`, `web`)
- Integration and notifications start once order events/contracts are stable

---

## Optional GitHub Labels for These Issues

- `mvp`
- `bootstrap`
- `core-workflow`
- `needs-contract-test`
- `assumption-locked`
- `redis-mvp`
- `sqs-sns-scale-path`

