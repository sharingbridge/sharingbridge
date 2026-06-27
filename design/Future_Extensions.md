# SharingBridge — Future extensions (order operations only)

**Purpose:** Technical supplement for **order operations** — payer marks payment done (Phase A), delivery proof (Phase B). **Not** the marketplace roadmap.

**Read first:** [README.md § Documentation guide](../README.md#documentation-guide) — doc hierarchy and reading order.

| Topic | Authoritative doc |
|-------|-------------------|
| Glossary, actors, marketplace, dashboard UX | [PRODUCT_MODEL.md](../development/PRODUCT_MODEL.md) |
| Configurator, payer, unified initiation | [Configurator_Role_and_Unified_Initiation.md](./Configurator_Role_and_Unified_Initiation.md) |
| Engineering phases E–I, repos, AI timeline | [ENGINEERING_PLAN.md](../development/ENGINEERING_PLAN.md) § Marketplace phases |
| SQL run order | [database-setup-sequence.md](../configuration/database-setup-sequence.md) |

**Related:** [SharingBridge_End_to_End_Workflow.md](./SharingBridge_End_to_End_Workflow.md) · [database.md](../configuration/database.md) · [authentication.md](../configuration/authentication.md)

---

## What exists today (baseline)

| Capability | Status |
|------------|--------|
| Initiator registers **order initiation** after copying delivery instructions | Shipped |
| Fields: pack id, notes, preset snapshot, `instructions_copied` status | Shipped |
| Initiator lists **own** initiations (mobile); coordinator lists **all** (web) | Shipped |
| Geo on order intent (`location_lat/lng`, `locality_key`); initiator neighbourhood feed; PostGIS `ST_DWithin` list queries | Shipped — [database.md](../configuration/database.md) |
| Mobile handover map picker + server reverse geocode | Shipped — [Handover_Location_Map_Picker.md](./Handover_Location_Map_Picker.md); vendor strategy [Location_Services_Vendor_Abstraction.md](./Location_Services_Vendor_Abstraction.md) |
| Payment / delivery lifecycle, coordinator **map** UI (bbox / clustering) | **Not shipped** |
| Delivery photo proof, delivery-partner role | **Planned** |
| Locality demand + eco kitchen commitments | [Eco_Kitchen_Initiation_Flow.md](./Eco_Kitchen_Initiation_Flow.md); engineering phases E–I in [ENGINEERING_PLAN.md](../development/ENGINEERING_PLAN.md) |

Payments for food still happen in **vendor apps** (Swiggy, Zomato, etc.). SharingBridge tracks **intent and status**, not card charges, unless a later scope explicitly adds audited payment references.

---

## Design principles (all phases)

1. **Facilitator, not merchant of record** — **Payers** pay **vendors or delivery partners directly** (vendors are the **payees** of those funds); the platform orchestrates visibility, assignment, and status—not a pooled escrow account unless a future legal scope says otherwise (see BRD *Operating Constraints*).
2. **Server-side authorization** — Initiators on the limited dashboard see only their rows; coordinators see operational fields; **admins** see PII (e.g. email) when needed. APIs on Render; Postgres on Supabase with **no client DB keys** ([authentication.md](../configuration/authentication.md)).
3. **Single persistence** — Postgres only after cutover; no parallel JSON file reads in production ([database.md](../configuration/database.md)).
4. **Explicit status enums** — Human-readable states initiators, payers, and coordinators can understand and audit.

---

## Phase A — Order operations (near-term)

**Goal:** Turn **order initiation** into a trackable **order** for coordinators and initiators/payers, without vendor API integration.

### A.1 Payer marks payment done

After the **payer** places and pays in the **vendor app**, they open **order history** (mobile; web limited dashboard), select the record, and set:

| Field | Example values |
|-------|------------------|
| `payment_status` | `pending` → `paid_externally` (initiator/payer action) |

- **Who can update:** Initiator/payer (own record only); coordinator/admin may correct in disputes (audit log later).
- **UX:** Single action — “Mark payment done” on the selected row; optional confirmation dialog.
- **No** automatic payment verification in this phase (no Swiggy/Zomato webhooks).

### A.2 Coordinator / initiator dashboards (next slice)

**Goal:** Initiators see **neighbourhood activity** (default window from `DONOR_NEIGHBOURHOOD_WINDOW_HOURS`) on mobile and web; coordinators retain full ops view. **Dashboard list columns** (planned — [PRODUCT_MODEL.md](../development/PRODUCT_MODEL.md)): **Order intent taken** (`created_at`), **Delivered at** (`delivered_at`, often empty), **Distance (m)** (`distance_m`); list sorted by **`distance_m` ascending** when viewer sends `near_lat` / `near_lng`; elapsed freshness from **`created_at`** only.

| Viewer | List | PII / photos |
|--------|------|----------------|
| **Initiator** (mobile + web limited) | Own intents + **neighbourhood** feed (`since`, `near_lat`/`near_lng`); web groups **By day** / **By area** (area includes **No location on record**) | **No email**; opaque `user_id`; **reference thumbnails in neighbourhood feed** within the server time window |
| **Coordinator** | All intents; filter by day, `user_id`, optional `since`, `near_lat/lng`, `locality_key` (PostGIS; map UI later) | Full ops fields; **initiator email**; photos per policy |
| **Admin** | Same as coordinator + user lookup | May include email for support |

Initiator limited web dashboard ([environment-variables.md](../configuration/environment-variables.md) § Web dashboard roles). **`since=Nh`** and **`near_lat` / `near_lng`** apply radius **`DONOR_NEIGHBOURHOOD_RADIUS_M`** (metres) server-side; API returns **`distance_m`** per row and **`feed.radius_m`**. Without viewer location, initiators see only their own rows in the time window. Location is stored on `POST` when `location_lat` / `location_lng` are sent (mobile **Help a seeker** captures GPS on copy/register). Named locality labels (`chennai-adyar`) remain future work.

**Neighbourhood API:**

- `GET /v1/donor-seeker/order-intents?since=2h&near_lat=…&near_lng=…` — server applies radius; response rows include `distance_m`, `created_at`, `delivered_at` (when column exists).
- `GET /v1/donor-seeker/order-intents?locality_key=…&since=2h`

### A.3 Data fields (additive)

Extend stored order / order_intent records:

- `payment_status`, `delivery_status`
- `location_lat`, `location_lng`, `location_label`, `locality_key` (optional at registration; PostGIS `location` **shipped**)
- `delivered_at` (nullable; dashboard column before Phase B routinely fills it — [schema-delivered-at-migration.sql](../configuration/schema-delivered-at-migration.sql))
- `updated_at` for filters; list sort by **`distance_m`** when neighbourhood coords present (not `updated_at` for initiator neighbourhood view)

JWT: keep active `role` per session; add `roles[]` and optional **`admin`** in `user_roles` ([database.md](../configuration/database.md)).

### A.4 API sketch (illustrative)

- `PATCH /v1/order-intents/:id` — initiator/payer updates `payment_status` on own row.
- `GET /v1/order-intents?since=2h&locality_key=…` — neighbourhood + coordinator filters (§ A.2).
- Integration-service: strip **email** from initiator-role responses; omit or redact `reference_photo_*` URLs when intent age > 2h for initiator JWT.
- Response grouping by day + `user_id` / locality: client-side today; server-side optional.

**Feasibility:** High. Builds on existing routes and auth; needs Postgres + UI work.

### A.5 Coordinator map UI (PostGIS list queries shipped)

**Shipped:** `order_intents.location` + `listForDashboard` SQL (`ST_DWithin`, `locality_key`). Run [schema-postgis-migration.sql](../configuration/schema-postgis-migration.sql) on older DBs; `npm run db:backfill-order-intent-geo` in integration-service.

**Next:** Coordinator web map (pins, bbox pan) using the same `near_lat` / `near_lng` / `since` params; optional `ST_MakeEnvelope` for viewport queries.

---

## Phase B — Delivery proof (next after A)

**Goal:** Close the loop in BRD steps 10–11 with evidence, without claiming legal certification.

### B.1 Delivery partner captures proof

1. Authorized **delivery partner** (new role or vendor-scoped account) opens an assigned order.
2. Takes a **photo at handover** to the seeker (in-app camera).
3. Upload goes to **photo-service** (or integration-stored object URL); linked on the same order record.
4. Sets `delivery_status` → `delivered` (or `completed`).

| Field | Notes |
|-------|--------|
| `delivery_photo_url` | Time-limited or access-controlled URL |
| `delivered_at` | Timestamp (nullable on intent row until partner marks delivery; shown on dashboard even when empty) |
| `delivery_status` | `out_for_delivery` → `delivered` |

### B.2 Initiator / payer visibility

Initiator/payer sees status progression and optionally a thumbnail of delivery proof (policy: blur faces if required by safety module later).

**Feasibility:** Medium. Depends on `sharingbridge-photo-service`, delivery-role auth, and mobile capture UX. Aligns with [Technical Architecture](./SharingBridge_Technical_Architecture.md) delivery verification themes.

```mermaid
sequenceDiagram
  participant DP as Delivery partner
  participant M as Mobile app
  participant I as Integration service
  participant P as Photo service
  participant D as Initiator

  DP->>M: Open assigned order
  DP->>M: Capture handover photo
  M->>P: Upload image
  P-->>M: delivery_photo_url
  M->>I: PATCH order delivered + photo ref
  I-->>D: Status notification planned
```

---

## Marketplace (moved — do not extend this file)

Eco kitchen pledging, kitchen commitments, allocation, and configurator model:

- [Eco_Kitchen_Initiation_Flow.md](./Eco_Kitchen_Initiation_Flow.md) — **authoritative** initiation routes and connection
- [PRODUCT_MODEL.md](../development/PRODUCT_MODEL.md) — glossary, actors
- [Configurator_Role_and_Unified_Initiation.md](./Configurator_Role_and_Unified_Initiation.md) — configurator vs automation
- [ENGINEERING_PLAN.md](../development/ENGINEERING_PLAN.md) — marketplace phases **E–I**
- [database-setup-sequence.md](../configuration/database-setup-sequence.md) — SQL for marketplace tables

---

## Summary table (order operations only)

| Phase | Payer / initiator | Ops viewer | Vendor (payee of funds) | Delivery |
|-------|---------------|------------|--------|----------|
| **Today** | Register initiation, own list | Web list (coordinator role) | External app only | External |
| **A** | Mark payment done on record | Filters, neighbourhood columns | — | Status fields only |
| **B** | See delivery proof | Monitor | — | Photo + complete |
| **Marketplace** | See PRODUCT_MODEL | Configurator (setup only) | Self-service bids | See ENGINEERING_PLAN E–I |

---

## Document maintenance

When Phase A ships, update:

- [SharingBridge_End_to_End_Workflow.md](./SharingBridge_End_to_End_Workflow.md) status table (steps 8–11).
- [database.md](../configuration/database.md) schema section.
- [MANUAL_TESTING_GUIDE.md](../testing/MANUAL_TESTING_GUIDE.md) new flows.
- [AGENT_SESSION.md](../development/AGENT_SESSION.md) “Next Recommended Tasks”.

**Last updated:** 2026-06 — marketplace content removed (see README § Documentation guide).
