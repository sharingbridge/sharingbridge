# Field handoff configuration (Help a seeker)

**Doc map:** [README.md § Documentation guide](../README.md#documentation-guide) · Planned merge with seeker demand → [Configurator_Role_and_Unified_Initiation.md](../design/Configurator_Role_and_Unified_Initiation.md).

Mobile: **Help a seeker** (`sharingbridge-mobile-app`; home hub label).

## BRD step 4 — guidance (not a safety score)

Handover suitability is **fixed in-app guidance**, not a backend geo score.

- Implemented in mobile step 1: **Quick guidance** (consent, surroundings, visibility, photos, initiator judgment).
- `sharingbridge-location-safety` is **archived**; do not deploy a scoring service for MVP.

## Mobile steps (shipped)

| Step | What happens |
|------|----------------|
| 1 | Quick guidance → Continue |
| 2 | **Capture handover location** → confirm label + coordinates → optional reference photo + verbal notes → instruction-pack (integration → ai-orchestration) |
| 3 | Review instructions → **Copy instructions to clipboard and register order intent** → vendor preset links unlock |

Handover location fields (`location_label`, `location_lat`, `location_lng`) and how they differ from vendor-app delivery address: [mobile-client.md § Handover location](./mobile-client.md#handover-location--map-picker-address-pickup-note). Vendor strategy (one map/geocode vendor, adapter seams): [Location_Services_Vendor_Abstraction.md](../design/Location_Services_Vendor_Abstraction.md).

## Order intent (shipped on integration-service)

When the initiator taps the step 3 button, the app:

1. Copies `delivery_instructions` to the clipboard.
2. Calls `POST /v1/donor-seeker/order-intents` on **integration-service** (Bearer JWT).

When `AUTH_TOKEN` is set, the mobile client does **not** send `user_id` in the body — integration uses the JWT subject. See [mobile-client.md](./mobile-client.md) and [authentication.md](./authentication.md).

Repeated taps for the **same instruction pack** (`pack_id`) update the existing intent (same `order_intent_id`, new `updated_at`) instead of creating duplicates. The mobile client also sends `order_intent_id` when it already has one from an earlier tap in the session.

Stored fields include `pack_id`, preset snapshot, reference-photo flag, and verbal notes. Persisted in Postgres `order_intents` (integration-service requires `DATABASE_URL`).

**Verify (local or Render):** after the first copy, the app shows **Order intent registered** with a reference id (mobile copy). The web dashboard will label the same timestamp **Order intent taken** (`created_at`) — see [PRODUCT_MODEL.md](../development/PRODUCT_MODEL.md). A second tap on the same pack updates that intent (SnackBar **Order intent updated**, same reference id). On API failure, clipboard copy still succeeds and an error SnackBar is shown.

## Order intent dashboard

| Surface | Status |
|---------|--------|
| `GET /v1/donor-seeker/order-intents` | **Shipped** (integration-service, Bearer auth, newest first) |
| Mobile **Order initiation history** (home hub, after Help a seeker) | **Shipped** — list + detail |
| Web **Order initiation history** | **Shipped** (`sharingbridge-web-app`) — [web-client.md](./web-client.md) |

**Coordinator web wiring:** same initiator `user_id` on sign-in as on mobile, and the same integration base URL (`VITE_API_BASE_URL` = mobile `API_BASE_URL`). Local vs Render stores are separate.

## Backend services

| Capability | Service |
|------------|---------|
| Instruction pack | integration → ai-orchestration |
| Order intent register | integration (`POST …/order-intents`) |
| Presets | integration → user-service (`USER_SERVICE_BASE_URL`) → Postgres `donor_presets` |

## AI instruction text

`SHARINGBRIDGE_WEBSITE_URL=pending` on ai-orchestration → courier copy states the public program website is not published yet.

## Reference photos (shipped)

| Piece | Service |
|-------|---------|
| Upload `POST /v1/photos/upload` | `sharingbridge-photo-service` (Python, Cloudinary) |
| Mobile `PHOTO_SERVICE_BASE_URL` | `--dart-define` (default `http://localhost:8092`) |
| Coordinator thumbnail + link | Web dashboard reads `reference_photo_view_url` / `reference_photo_thumbnail_url` on order intents |

Flow: initiator picks camera or gallery → upload on **Get AI delivery instructions** → `reference_photo_artifact_id` + Cloudinary URLs stored on order intent.

Local: configure `CLOUDINARY_*` (or `CLOUDINARY_URL`) in photo-service `.env`. Run `photo_artifacts` DDL from [schema.sql](./schema.sql) (or let photo-service create the table on startup).

## Planned (Track B+)

- Delivery acknowledgement upload and initiator reference↔delivery photo match
- Local image processing hooks in photo-service
- Live LLM (`AI_LLM_MODE=openai`)

See [ENGINEERING_PLAN.md](../development/ENGINEERING_PLAN.md).

---

## Seeker demand — Record seeker demand (Phase C.1, shipped)

Separate from **Help a seeker** (direct order / `order_intents`). **For pledging** records a need for the web **Actions** tab (legacy API `seeker_demands`).

| Piece | Detail |
|-------|--------|
| Mobile hub | **Start initiation** → **For pledging** → `RecordSeekerDemandPage` |
| API | `POST /v1/seeker-demands` on **integration-service** (Bearer JWT) |
| Who can record | **Initiator** or **coordinator** (`requireReporterRole`) |
| Stored as | Postgres `seeker_demands` — [database-setup-sequence.md](./database-setup-sequence.md) |
| Response field | `seeker_demand.seeker_demand_id` (`sd-…` prefix); reporter = `reported_by_user_id` |
| Web | `GET /v1/demand/board` — **Actions** tab (pledges, kitchen commitments) |

**Not** a vendor order. **Pledges** and **kitchen commitments** (legacy `vendor_bids`) persist after marketplace SQL (M1–M2). Auto-allocation and eco **connection** handoff: [Eco_Kitchen_Initiation_Flow.md](../design/Eco_Kitchen_Initiation_Flow.md).
