# Field handoff configuration (Offer food help)

Mobile: **Offer food help** (`sharingbridge-mobile-app`).

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
2. Calls `POST /v1/donor-seeker/order-intents` on **integration-service** (authenticated).

Stored fields include `pack_id`, preset snapshot, reference-photo flag, and verbal notes. Data is file-backed on integration (`data/order-intents.json`) for MVP.

**Verify (local or Render):** after copy, the app shows **Order intent registered** with a reference id, or an error SnackBar if the API fails (clipboard copy still succeeds).

## Donation intent dashboard (planned)

A **list/history UI** on mobile and web is **not shipped**. Planned work:

- `GET /v1/donor-seeker/order-intents` (or order-service timeline) for the signed-in donor
- Mobile screen and web ops view to browse past intents and status

Until then, intents are persisted on the server for API inspection and future dashboards only.

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
- Donation intent history UI (mobile + web)

See [IMPLEMENTATION_APPROACH.md](../development/IMPLEMENTATION_APPROACH.md).
