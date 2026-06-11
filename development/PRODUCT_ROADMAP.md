# SharingBridge — Product roadmap

**Purpose:** **Authoritative product vocabulary**, actors, marketplace model, and neighbourhood dashboard spec (June 2026).

**Doc map:** [README.md § Documentation guide](../README.md#documentation-guide) — reading order and which file wins when docs disagree.

| Also read | For |
|-----------|-----|
| [AGENT_HANDOFF.md](./AGENT_HANDOFF.md) | What is shipped **today** |
| [IMPLEMENTATION_APPROACH.md](./IMPLEMENTATION_APPROACH.md) | Engineering phases, repos, timelines (marketplace **E–I**) |
| [Configurator_Role_and_Unified_Initiation.md](../design/Configurator_Role_and_Unified_Initiation.md) | Configurator, payee, unified initiation |
| [Future_Extensions.md](../design/Future_Extensions.md) | Order-ops supplement only (payment-done, delivery proof) |

**Do not** spin up parallel roadmap docs — extend **this file** for product themes.

**Transcripts (local Whisper — not quoted verbatim in docs; summaries below are corrected):**

| Batch | Folder |
|-------|--------|
| June 3 | `C:\Users\Hp\Downloads\drive-download-20260603T052656Z-3-001` |
| June 4 | `C:\Users\Hp\Downloads\drive-download-20260604T033037Z-3-001` |

Re-run: `$env:TEMP\asrvenv\Scripts\python.exe` `..\..\scripts\transcribe_audio.py` `<folder>` → `transcripts.json`

---

## Documentation verbiage (product language)

SharingBridge serves **anyone who needs affordable meals**—people on the street, seniors, parents, families, or someone a passer-by wants to help. Docs use **inclusive meal-support language**, not charity-only framing.

| Prefer in docs | Avoid in docs | Legacy in code/API (unchanged until rename) |
|----------------|---------------|---------------------------------------------|
| **Community meal coordination platform** | Digital alms platform | — |
| **Initiator** (registers order intent or demand) | Donor (legacy docs) | JWT `donor` still accepted; DB `user_roles.donor` |
| **Payee / payer** (who pays the vendor) | Donor as generic helper | — |
| **API routes** | `/v1/donor-*` only | Prefer `/v1/initiator-setup/*`, `/v1/order-intents`, `/v1/instruction-pack` |
| **JSON fields** | `donor_email` only | Prefer `initiator_email` (both returned for coordinators) |
| **Env** | `DONOR_NEIGHBOURHOOD_*` only | Prefer `INITIATOR_NEIGHBOURHOOD_*` (legacy still read) |
| **Beneficiary / person who needs a meal** | Person who needs a meal | — |
| **Meal arrangement / order intent** | Donation, order intent | — |
| **Intent to help with food / meal support** | Intent to help with food, meal support | — |
| **Vendor preset setup** | Vendor preset setup (prose only) | `/v1/donor-setup/*`, table `donor_presets` |
| **Neighbourhood feed radius** | Payee neighbourhood (prose) | env `DONOR_NEIGHBOURHOOD_*` |

When documenting APIs or SQL, show the **legacy identifier** in backticks. Use **initiator** for who registered an intent/demand; use **payee** only for who pays the vendor.

---

## Glossary (avoid ambiguity)

| Term | Meaning |
|------|---------|
| **Order intent** | Payee- or initiator-registered handover signal after copying instructions (`instructions_copied`). **Not** a placed or paid order in a vendor app. |
| **Order intent taken** | Dashboard label for **`created_at`** — when the payee or initiator registered the intent. Do not use “order taken” or “order placed.” |
| **Delivered at** | **`delivered_at`** — handover/delivery completion time when set. Often empty until delivery-partner flow (Phase B) populates it. |
| **Elapsed (freshness)** | `now − created_at`. Shown near **Order intent taken**; **do not** derive elapsed from `delivered_at`. |
| **Distance (m)** | **`distance_m`** — metres from viewer `near_lat` / `near_lng` to intent location (API-computed). |
| **Radius** | Server filter: **`DONOR_NEIGHBOURHOOD_RADIUS_M`** (metres; default 5000). |
| **Seeker demand** | Logged meal need for aggregation (`seeker_demands`). **Not** an order intent and **not** a paid vendor order. Distinct from **pledge** (future funding commitment). **Planned merge** into prepaid **order intent** — see [Configurator_Role_and_Unified_Initiation.md](../design/Configurator_Role_and_Unified_Initiation.md). |
| **Beneficiary / seeker** | Person who receives food. **No app login** — linked on records (address, notes, optional photo) with consent captured by an initiator. |
| **Demand initiator** | Signed-in user who arranges meals **for** a beneficiary (e.g. adult child for a parent, or anyone they meet). May be one-off or **recurring**. Today overlaps payee role and **Record seeker demand**. Target: single **meal initiation** flow. |
| **Configurator** | **One-time** geographic actor: menus, `locality_key` tiers, optional zone setup. **Not** full-time ops — renames local **coordinator** for config-only work. Runtime ops → payees, fulfillers, automation. See [Configurator_Role_and_Unified_Initiation.md](../design/Configurator_Role_and_Unified_Initiation.md). |
| **Payee / payer** | User who pays the meal vendor directly (relative, neighbour, self, initiator). **Preferred product term.** API role `payee` is legacy; alias `payee` planned. |
| **Prepaid order intent** | Planned unified record: standard menu + location + payee commitment; merges **Help a seeker** and **seeker demand** paths. Fulfillment: **bidder board** or **direct vendor** per initiation. |
| **Demand fulfiller** | Signed-in kitchen/vendor who **commits prep capacity** (portions per window). Future role. |
| **Transport bidder** | Signed-in courier who **commits delivery capacity** between prep points and beneficiary locations. Paid by **meal vendor**, not payee. Future role. |

### App actors (who signs in)

| Actor | Signs in | Notes |
|-------|----------|--------|
| **Payee / supporter** | Yes (mobile) | Field handover or remote arrangement; pays vendor directly. API role `payee` today. |
| **Demand initiator** | Yes | Plans meals for a beneficiary; sets pickup vs delivery. |
| **Coordinator** | Yes (web) | **Transitioning:** runtime ops UI (demand board, manual vendor bid MVP). Long-term **configurator** = menu/zone setup only; see design doc above. |
| **Configurator** | Yes (web, future) | One-time menus and geography per `locality_key`; not daily operations. |
| **Demand fulfiller** | Yes | Prep bids; may self-deliver or hire transport. |
| **Transport bidder** | Yes | Route bids; paid by fulfiller. |
| **Beneficiary** | **No** | Data only — never a `user_roles` row. |

### Product lanes (keep separate)

| Lane | Status | Initiator | Payment |
|------|--------|-----------|---------|
| **A — Field handover** | Shipped | Payee / initiator in person | Payee → vendor app (one-time) |
| **B — Seeker demand log** | Shipped (C.1) | Payee / initiator / coordinator | None yet — aggregation only |
| **C — Meal arrangement** | Future | Demand initiator | Family / self-funded plans; recurring |
| **D — Marketplace window** | Future | Pledges + aggregated demand | Payee → vendor (food); bulk prep + transport |

---

## Marketplace — fulfillment paths & payments (future, authoritative)

**Bulk default:** Prep and transport are **aggregated per window/locality** to reduce cost. **Payee funding** stays **direct one-time** payment to the meal vendor (no platform wallet — per BRD).

### Fulfillment path (per beneficiary / plan)

Chosen by **demand initiator** (or coordinator on their behalf); beneficiary has no login.

| Path | Who moves food | Proof of handover |
|------|----------------|-------------------|
| **Self pickup** | Beneficiary or family collects at prep vendor | **Meal prep vendor** captures proof |
| **Vendor delivers** | Fulfiller’s own delivery | Fulfiller |
| **Vendor + transport bidder** | Transporter: vendor location → beneficiaries | Transporter (with vendor handoff event) |

If not self-pickup, the **meal vendor owns delivery** — own fleet **or** selects a **transport bidder** for that area. **Transport is paid by the meal vendor**, not the payee.

### Payment rhythms

| Flow | Who pays whom | When |
|------|---------------|------|
| **Payee / pledge → meal vendor** | Payee | Direct, one-time, per funded meals |
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

### List columns (web payee + coordinator when neighbourhood applies)

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

### Neighbourhood reference photos

- Payees see **beneficiary reference photo thumbnails** in the **neighbourhood** feed for intents inside `DONOR_NEIGHBOURHOOD_WINDOW_HOURS` (same window as photo URL redaction; env name legacy).
- **Coordinator-only:** payee email (`donor_email` in API) and unrestricted history — not “all photos coordinator-only.”

### Mobile → web

- Link to open the **payee web dashboard** in the browser; native in-app dashboard deferred.

### Voice memo themes (June 4, cleaned)

1. Return **distance in metres**; show on dashboard; sort nearest first; payees see neighbourhood **photos**.
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
| Web roles | Payee dashboard access; **emails** coordinator-only. |
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
5. Payee neighbourhood photos (confirm web + mobile within window).

**Later:**

- Delivery-partner flow **populates** `delivered_at` ([Future_Extensions.md](../design/Future_Extensions.md) § B).
- Marketplace roles, allocation, pickup proof ([IMPLEMENTATION_APPROACH.md](./IMPLEMENTATION_APPROACH.md) § Marketplace phases).

---

## Related docs

- [README.md § Documentation guide](../README.md#documentation-guide) — master index
- [IMPLEMENTATION_APPROACH.md](./IMPLEMENTATION_APPROACH.md) — phased delivery, repos
- [AGENT_HANDOFF.md](./AGENT_HANDOFF.md) — shipped snapshot
- [database-setup-sequence.md](../configuration/database-setup-sequence.md) — SQL order for marketplace
- [web-client.md](../configuration/web-client.md)
- [environment-variables.md](../configuration/environment-variables.md)
- [Future_Extensions.md](../design/Future_Extensions.md) — order-ops phases A–B supplement
