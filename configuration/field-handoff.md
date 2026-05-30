# Field handoff configuration (Help a seeker)

Mobile: **Help a seeker** (`sharingbridge-mobile-app`; home hub label).

## BRD step 4 — guidance (not a safety score)

Handover suitability is **fixed in-app guidance**, not a backend geo score.

- Implemented in mobile step 1: **Quick guidance** (consent, surroundings, visibility, photos, donor judgment).
- `sharingbridge-location-safety` is **archived**; do not deploy a scoring service for MVP.

## Mobile steps (shipped)

| Step | What happens |
|------|----------------|
| 1 | Quick guidance → Continue |
| 2 | Optional reference photo + verbal notes → instruction-pack (integration → ai-orchestration) |
| 3 | Review instructions → **Copy instructions to clipboard and register donation intent** → vendor preset links unlock |

## Donation intent (shipped on integration-service)

When the donor taps the step 3 button, the app:

1. Copies `delivery_instructions` to the clipboard.
2. Calls `POST /v1/donor-seeker/order-intents` on **integration-service** (Bearer JWT).

When `AUTH_TOKEN` is set, the mobile client does **not** send `user_id` in the body — integration uses the JWT subject. See [mobile-client.md](./mobile-client.md) and [authentication.md](./authentication.md).

Repeated taps for the **same instruction pack** (`pack_id`) update the existing intent (same `order_intent_id`, new `updated_at`) instead of creating duplicates. The mobile client also sends `order_intent_id` when it already has one from an earlier tap in the session.

Stored fields include `pack_id`, preset snapshot, reference-photo flag, and verbal notes. Persisted in Postgres `order_intents` (integration-service requires `DATABASE_URL`).

**Verify (local or Render):** after the first copy, the app shows **Order intent registered** with a reference id. A second tap on the same pack updates that intent (SnackBar **Donation intent updated**, same reference id). On API failure, clipboard copy still succeeds and an error SnackBar is shown.

## Donation intent dashboard

| Surface | Status |
|---------|--------|
| `GET /v1/donor-seeker/order-intents` | **Shipped** (integration-service, Bearer auth, newest first) |
| Mobile **Order initiation history** (home hub, after Help a seeker) | **Shipped** — list + detail |
| Web **Order initiation history** | **Shipped** (`sharingbridge-web-app`) — [web-client.md](./web-client.md) |

**Coordinator web wiring:** same donor `user_id` on sign-in as on mobile, and the same integration base URL (`VITE_API_BASE_URL` = mobile `API_BASE_URL`). Local vs Render stores are separate.

## Backend services

| Capability | Service |
|------------|---------|
| Instruction pack | integration → ai-orchestration |
| Donation intent register | integration (`POST …/order-intents`) |
| Presets | integration → user-service when `PREFERENCES_BACKEND=user_service` |

## AI instruction text

`SHARINGBRIDGE_WEBSITE_URL=pending` on ai-orchestration → courier copy states the public program website is not published yet.

## Planned (Track B+)

- Reference photo upload (`sharingbridge-photo-service`)
- Delivery acknowledgement and photo match
- Live LLM (`AI_LLM_MODE=openai`)

See [IMPLEMENTATION_APPROACH.md](../development/IMPLEMENTATION_APPROACH.md).
