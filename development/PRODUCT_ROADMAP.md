# SharingBridge — Product roadmap

**Purpose:** Founder voice memos (June 2026), **authoritative product vocabulary**, and near-term neighbourhood dashboard spec. Use with [AGENT_HANDOFF.md](./AGENT_HANDOFF.md) for what is shipped; use [IMPLEMENTATION_APPROACH.md](./IMPLEMENTATION_APPROACH.md) for phased delivery (repos, timelines). **Do not** spin up parallel roadmap docs — extend this file for new product themes.

**Transcripts (local Whisper — not quoted verbatim in docs; summaries below are corrected):**

| Batch | Folder |
|-------|--------|
| June 3 | `C:\Users\Hp\Downloads\drive-download-20260603T052656Z-3-001` |
| June 4 | `C:\Users\Hp\Downloads\drive-download-20260604T033037Z-3-001` |

Re-run: `$env:TEMP\asrvenv\Scripts\python.exe` `..\..\scripts\transcribe_audio.py` `<folder>` → `transcripts.json`

---

## Glossary (avoid ambiguity)

| Term | Meaning |
|------|---------|
| **Order intent** | Donor-registered handover signal after copying instructions (`instructions_copied`). **Not** a placed or paid order in a vendor app. |
| **Order intent taken** | Dashboard label for **`created_at`** — when the donor registered the intent. Do not use “order taken” or “order placed.” |
| **Delivered at** | **`delivered_at`** — handover/delivery completion time when set. Often empty until delivery-partner flow (Phase B) populates it. |
| **Elapsed (freshness)** | `now − created_at`. Shown near **Order intent taken**; **do not** derive elapsed from `delivered_at`. |
| **Distance (m)** | **`distance_m`** — metres from viewer `near_lat` / `near_lng` to intent location (API-computed). |
| **Radius** | Server filter: **`DONOR_NEIGHBOURHOOD_RADIUS_M`** (metres; default 5000). |
| **Seeker demand** | Logged meal need for aggregation (`seeker_demands`). **Not** an order intent and **not** a paid vendor order. Distinct from **pledge** (future funding commitment). |
| **Beneficiary / seeker** | Person who receives food. **No app login** — linked on records (address, notes, optional photo) with consent captured by an initiator. |
| **Demand initiator** | Signed-in user who arranges meals **for** a known beneficiary (e.g. adult child for a parent). May be one-off or **recurring** (e.g. one month). Future role; today overlaps donor/coordinator **Record seeker demand**. |
| **Demand fulfiller** | Signed-in kitchen/vendor who **commits prep capacity** (portions per window). Future role. |
| **Transport bidder** | Signed-in courier who **commits delivery capacity** between prep points and beneficiary locations. Paid by **meal vendor**, not donor. Future role. |

### App actors (who signs in)

| Actor | Signs in | Notes |
|-------|----------|--------|
| **Donor** | Yes (mobile) | Field handover; pays vendor directly for one-off meals. |
| **Demand initiator** | Yes | Plans meals for a beneficiary; sets pickup vs delivery. |
| **Coordinator** | Yes (web) | Ops, demand board, reconciliation. |
| **Demand fulfiller** | Yes | Prep bids; may self-deliver or hire transport. |
| **Transport bidder** | Yes | Route bids; paid by fulfiller. |
| **Beneficiary** | **No** | Data only — never a `user_roles` row. |

### Product lanes (keep separate)

| Lane | Status | Initiator | Payment |
|------|--------|-----------|---------|
| **A — Field handover** | Shipped | Donor in person | Donor → vendor app (one-time) |
| **B — Seeker demand log** | Shipped (C.1) | Donor / coordinator | None yet — aggregation only |
| **C — Meal arrangement** | Future | Demand initiator | Family / self / donor-funded plans; recurring |
| **D — Marketplace window** | Future | Pledges + aggregated demand | Donor → vendor (food); bulk prep + transport |

---

## Marketplace — fulfillment paths & payments (future, authoritative)

**Bulk default:** Prep and transport are **aggregated per window/locality** to reduce cost. **Donor funding** stays **direct one-time** payment to the meal vendor (no platform wallet — per BRD).

### Fulfillment path (per beneficiary / plan)

Chosen by **demand initiator** (or coordinator on their behalf); beneficiary has no login.

| Path | Who moves food | Proof of handover |
|------|----------------|-------------------|
| **Self pickup** | Beneficiary or family collects at prep vendor | **Meal prep vendor** captures proof |
| **Vendor delivers** | Fulfiller’s own delivery | Fulfiller |
| **Vendor + transport bidder** | Transporter: vendor location → beneficiaries | Transporter (with vendor handoff event) |

If not self-pickup, the **meal vendor owns delivery** — own fleet **or** selects a **transport bidder** for that area. **Transport is paid by the meal vendor**, not the donor.

### Payment rhythms

| Flow | Who pays whom | When |
|------|---------------|------|
| **Donor / pledge → meal vendor** | Donor | Direct, one-time, per funded meals |
| **Meal vendor → transport bidder** | Fulfiller | Bulk settlement for assigned routes/windows |
| **Initiator / family → vendor** | Demand initiator or beneficiary (via initiator) | Recurring plans — same direct-payment principle |

### Matching (location-driven)

1. Aggregate meal units + beneficiary drop points for a **demand window**.
2. Match **fulfilment bids** (prep location, portions, ready time).
3. For non–self-pickup rows: require fulfiller delivery capacity **or** matched **transport bid** (vendor lat → beneficiary cluster).
4. Self-pickup rows skip transport; vendor runs pickup proof workflow.

**Implementation phases:** see [IMPLEMENTATION_APPROACH.md](./IMPLEMENTATION_APPROACH.md) § Marketplace phases. Order-ops detail (payment-done, delivery photo): [Future_Extensions.md](../design/Future_Extensions.md) Phase A–B (legacy pointer).

---

## June 4 — Neighbourhood dashboard (authoritative)

### List columns (web donor + coordinator when neighbourhood applies)

| Column | Source | Notes |
|--------|--------|--------|
| **Order intent taken** | `created_at` | Absolute time; optional sub-line: elapsed since intent created (e.g. `45m ago`). |
| **Delivered at** | `delivered_at` | Column always visible; **—** when null. |
| **Distance (m)** | `distance_m` | Metres; **—** without viewer location or intent geo. |

### Sort and filter

| Item | Rule |
|------|------|
| List order | **`distance_m` ASC** (nearest first) when `near_lat` / `near_lng` sent. No separate sort-by-time mode. |
| Radius filter | `DONOR_NEIGHBOURHOOD_RADIUS_M` on server (`ST_DWithin`; metres). |
| Row cap | **`ORDER_INTENT_LIST_MAX_ROWS`** (default **100**) on integration-service. |

### Donor photos

- Donors see **seeker reference photo thumbnails** in the **neighbourhood** feed for intents inside `DONOR_NEIGHBOURHOOD_WINDOW_HOURS` (same window as photo URL redaction).
- **Coordinator-only:** `donor_email` and unrestricted history — not “all photos coordinator-only.”

### Mobile → web

- Link to open the **donor web dashboard** in the browser; native in-app dashboard deferred.

### Voice memo themes (June 4, cleaned)

1. Return **distance in metres**; show on dashboard; sort nearest first; donors see neighbourhood **photos**.
2. Configurable **list limit** (~100 rows).
3. Show **order intent taken**, **delivered at**, and **distance** on dashboard; freshness from **intent created** time.
4. Max rows env for gateway payload size.
5. Mobile link to web dashboard.

### Shipped (code)

- **integration-service:** `distance_m`, `delivered_at` in list SQL; sort by `distance_m` asc when `near_lat` / `near_lng`; `ORDER_INTENT_LIST_MAX_ROWS`.
- **web-app:** list + detail columns; preserves distance sort when grouping.
- **mobile-app:** `WEB_DASHBOARD_URL` dart-define opens neighbourhood dashboard in browser.

**DB:** run [schema-delivered-at-migration.sql](../configuration/schema-delivered-at-migration.sql) on existing Supabase/local DB before restarting integration-service.

---

## June 3 — Longer-term (summary)

| Theme | Notes |
|-------|--------|
| Web roles | Donor dashboard access; **emails** coordinator-only. |
| Pledges | Order intents → pledge / crowdsourcing extension. |
| Marketplace | Demand initiator, fulfiller, transport bidder; self-pickup vs delivery; bulk prep/transport — see **Marketplace** section above. |
| Photos / AI | Embeddings, descriptions, drone narrative; optional store embeddings not raw photos. |
| GIS | Neighbourhood feeds; PostGIS lists **shipped**; map UI **shipped** on web. |
| Cloudinary | Short-lived distribution window (1–2 h). |

Delivery detail: [IMPLEMENTATION_APPROACH.md](./IMPLEMENTATION_APPROACH.md). Order-ops phases A–B: [Future_Extensions.md](../design/Future_Extensions.md).

---

## Implementation order (June 4)

1. **Schema:** `delivered_at` — [schema.sql](../configuration/schema.sql); older DBs: [schema-delivered-at-migration.sql](../configuration/schema-delivered-at-migration.sql).
2. **integration-service:** `distance_m`, `ORDER BY distance_m ASC`, `ORDER_INTENT_LIST_MAX_ROWS`, expose `created_at` / `delivered_at`.
3. **web-app:** Columns **Order intent taken**, **Delivered at**, **Distance (m)**; elapsed from `created_at`.
4. **mobile-app:** “Open web dashboard” URL from config.
5. Donor neighbourhood photos (confirm web + mobile within window).

**Later:**

- Delivery-partner flow **populates** `delivered_at` ([Future_Extensions.md](../design/Future_Extensions.md) § B).
- Marketplace roles, allocation, pickup proof ([IMPLEMENTATION_APPROACH.md](./IMPLEMENTATION_APPROACH.md) § Marketplace phases).

---

## Related docs

- [IMPLEMENTATION_APPROACH.md](./IMPLEMENTATION_APPROACH.md) — phased delivery, repos
- [AGENT_HANDOFF.md](./AGENT_HANDOFF.md) — shipped snapshot
- [web-client.md](../configuration/web-client.md)
- [environment-variables.md](../configuration/environment-variables.md)
- [database.md](../configuration/database.md)
- [Future_Extensions.md](../design/Future_Extensions.md) — order-ops phases A–B only (legacy detail)
