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
| 3 | Copy instructions + open saved vendor preset URLs |

## Backend

| Capability | Service |
|------------|---------|
| Instruction pack | integration → ai-orchestration |
| Order intent (on copy) | integration (file-backed MVP) |
| Presets | integration → user-service when `PREFERENCES_BACKEND=user_service` |

## AI instruction text

`SHARINGBRIDGE_WEBSITE_URL=pending` on ai-orchestration → courier copy states the public program website is not published yet. Set a real `https://…` URL when available.

## Planned (Track B+)

- Reference photo upload (`sharingbridge-photo-service`)
- Delivery acknowledgement and photo match
- Live LLM (`AI_LLM_MODE=openai`)

See [IMPLEMENTATION_APPROACH.md](../development/IMPLEMENTATION_APPROACH.md).
