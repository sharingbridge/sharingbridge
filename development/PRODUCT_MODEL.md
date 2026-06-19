# SharingBridge — product model

**Purpose:** **Authoritative product vocabulary**, actors, marketplace model, and neighbourhood dashboard spec (June 2026).

**Doc map:** [README.md § Documentation guide](../README.md#documentation-guide) — reading order and which file wins when docs disagree.

| Also read | For |
|-----------|-----|
| [STATUS.md](./STATUS.md) | **Progress vs plan** — update when milestones ship |
| [AGENT_SESSION.md](./AGENT_SESSION.md) | Agent session: next tasks, runbook |
| [ENGINEERING_PLAN.md](./ENGINEERING_PLAN.md) | Engineering plan (phases **E–I**) |
| [Configurator_Role_and_Unified_Initiation.md](../design/Configurator_Role_and_Unified_Initiation.md) | Configurator vs daily ops |
| [Eco_Kitchen_Initiation_Flow.md](../design/Eco_Kitchen_Initiation_Flow.md) | Three routes, connection, payment boundaries |
| [Future_Extensions.md](../design/Future_Extensions.md) | Order-ops supplement only (payment-done, delivery proof) |

**Do not** spin up parallel product-model docs — extend **this file** for vocabulary and actors.

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
| **Initiator** (registers order intent or demand) | Donor (legacy docs) | JWT `initiator` (legacy `donor` accepted); DB `user_roles.donor` |
| **Payer** (who pays the vendor) | **Payee** for the paying person (wrong — payee = payment recipient) | — |
| **Payee** (accounting only) | Using payee for mobile user or payer | Vendor/kitchen **receives** payment |
| **API routes** | `/v1/donor-*` only | Prefer `/v1/initiator-setup/*`, `/v1/order-intents`, `/v1/instruction-pack` |
| **JSON fields** | `donor_email` only | Prefer `initiator_email` (both returned for coordinators) |
| **Env** | `DONOR_NEIGHBOURHOOD_*` only | Prefer `INITIATOR_NEIGHBOURHOOD_*` (legacy still read) |
| **Beneficiary / person who needs a meal** | Person who needs a meal | — |
| **Meal arrangement / order intent** | Donation, order intent | — |
| **Intent to help with food / meal support** | Intent to help with food, meal support | — |
| **Vendor preset setup** | Vendor preset setup (prose only) | `/v1/donor-setup/*`, table `donor_presets` |
| **Neighbourhood feed radius** | Initiator neighbourhood (prose) | env `DONOR_NEIGHBOURHOOD_*` |

When documenting APIs or SQL, show the **legacy identifier** in backticks.

**Three-way rule (do not conflate):**

| Term | Use for |
|------|---------|
| **Initiator** | Who registered an order intent or seeker demand (signed-in mobile user in MVP) |
| **Payer** | Who pays the meal vendor off-platform (often the same person as initiator today) |
| **Payee** | Who **receives** payment — vendor, eco kitchen, transport bidder settlement — not the helper |

Never use **payee** for the mobile app user, JWT role, or “person who pays Swiggy.”

---

## Glossary (avoid ambiguity)

| Term | Meaning |
|------|---------|
| **Order intent** | Initiator-registered handover signal after copying instructions (`instructions_copied`). **Not** a placed or paid order in a vendor app. |
| **Order intent taken** | Dashboard label for **`created_at`** — when the initiator registered the intent. Do not use “order taken” or “order placed.” |
| **Delivered at** | **`delivered_at`** — handover/delivery completion time when set. Often empty until delivery-partner flow (Phase B) populates it. |
| **Elapsed (freshness)** | `now − created_at`. Shown near **Order intent taken**; **do not** derive elapsed from `delivered_at`. |
| **Distance (m)** | **`distance_m`** — metres from viewer `near_lat` / `near_lng` to intent location (API-computed). |
| **Radius** | Server filter: **`DONOR_NEIGHBOURHOOD_RADIUS_M`** (metres; default 5000). |
| **Seeker demand** | Logged need for pledging (`seeker_demands`). Maps to initiation route **Eco kitchen · open for pledging** until unified `initiation.route` ships. **Not** a placed vendor order. Distinct from **pledge** (funding commitment on dashboard). See [Eco_Kitchen_Initiation_Flow.md](../design/Eco_Kitchen_Initiation_Flow.md). |
| **Eco kitchen** | Crowd-sourced kitchen on the network: standard menu, eco-friendly packaging, economical volume prep. Commits to fulfil; payment off-platform after SB **connection**. |
| **Initiation route** | One of: **Direct order** \| **Eco kitchen · I pay** \| **Eco kitchen · open for pledging**. API target: `direct_order` \| `eco_kitchen_self_pay` \| `eco_kitchen_pledge`. |
| **Order code** | Scoped id (e.g. `SB-7K2M-9F3`) visible only to parties on that order; trust anchor for off-platform payment. |
| **Email share consent** | Explicit opt-in before pledging or opening eco-kitchen routes; login email revealed in-app after kitchen commit — [Eco_Kitchen_Initiation_Flow.md](../design/Eco_Kitchen_Initiation_Flow.md) §7.5. |
| **Kitchen commitment** | Eco kitchen accepts a line (portions, price, ETA). Product term; legacy table `vendor_bids` during migration. |
| **Beneficiary / seeker** | Person who receives food. **No app login** — linked on records (address, notes, optional photo) with consent captured by an initiator. |
| **Demand initiator** | Signed-in user who arranges meals **for** a beneficiary (e.g. adult child for a parent, or anyone they meet). May be one-off or **recurring**. Today overlaps **initiator** mobile flows and **Record seeker demand**. Target: single **meal initiation** flow. |
| **Configurator** | **One-time** geographic actor: menus, `locality_key` tiers, optional zone setup. **Not** full-time ops — renames local **coordinator** for config-only work. Runtime ops → payers, fulfillers, automation. See [Configurator_Role_and_Unified_Initiation.md](../design/Configurator_Role_and_Unified_Initiation.md). |
| **Payer** | User who pays the meal vendor directly (relative, neighbour, self, or initiator on their behalf). **Preferred term** for the paying side. Future: payer may differ from initiator. |
| **Payee** | Party who **receives** payment (meal vendor, eco kitchen, transport bidder). **Not** the initiator or payer. |
| **Prepaid order intent** | Planned unified record: standard menu + location + payer commitment; merges **Help a seeker** and **seeker demand** paths. Fulfillment: **bidder board** or **direct vendor** per initiation. |
| **Demand fulfiller** | Signed-in kitchen/vendor who **commits prep capacity** (portions per window). Future role. |
| **Transport bidder** | Signed-in courier who **commits delivery capacity** between prep points and beneficiary locations. Paid by **meal vendor**, not the payer. Future role. |

### App actors (who signs in)

| Actor | Signs in | Notes |
|-------|----------|--------|
| **Initiator** | Yes (mobile) | Registers intents/demands; captures beneficiary context. In shipped flows usually also the **payer**. JWT `initiator` (legacy `donor` in DB). |
| **Coordinator** | Yes (web) | **Transitioning:** **Actions** tab (pledges, kitchen commitments). Long-term **configurator** = menu/zone setup only. |
| **Configurator** | Yes (web, future) | One-time menus and geography per `locality_key`; not daily operations. |
| **Demand fulfiller** | Yes | Prep bids; may self-deliver or hire transport. |
| **Transport bidder** | Yes | Route bids; paid by fulfiller. |
| **Beneficiary** | **No** | Data only — never a `user_roles` row. |

### Product lanes (keep separate)

| Lane | Status | Initiator | Payment |
|------|--------|-----------|---------|
| **A — Direct order** | Shipped | Initiator | Initiator → vendor app (external) |
| **B — Eco kitchen · open for pledging** | Partial | Initiator opens; pledgers fund | Pledgers → eco kitchen off-platform after **connection** |
| **C — Eco kitchen · I pay** | Planned | Initiator | Initiator → eco kitchen off-platform after **connection** |
| **D — Meal arrangement / recurring** | Future | Demand initiator | Family / self-funded plans |

Authoritative step-by-step flows: [Eco_Kitchen_Initiation_Flow.md](../design/Eco_Kitchen_Initiation_Flow.md).

---

## Initiation routes (authoritative summary)

| Route | Label | Shipped? |
|-------|-------|----------|
| 1 | **Direct order** | Yes (`order_intents`, Help a seeker) |
| 2 | **Eco kitchen · I pay** | Design + mobile teaser only |
| 3 | **Eco kitchen · open for pledging** | Partial (`seeker_demands` + Actions pledges) |

**SharingBridge never** processes payments, publishes phone numbers in listings, or sends QR/payment links by email. See [Eco_Kitchen_Initiation_Flow.md](../design/Eco_Kitchen_Initiation_Flow.md) §7–8.

---

## Marketplace — fulfillment paths & payments (future, authoritative)

**Bulk default:** Prep and transport are **aggregated per window/locality** to reduce cost. **Payer funding** stays **direct one-time** payment to the meal vendor (no platform wallet — per BRD).

### Fulfillment path (per beneficiary / plan)

Chosen by **demand initiator** (or coordinator on their behalf); beneficiary has no login.

| Path | Who moves food | Proof of handover |
|------|----------------|-------------------|
| **Self pickup** | Beneficiary or family collects at prep vendor | **Meal prep vendor** captures proof |
| **Vendor delivers** | Fulfiller’s own delivery | Fulfiller |
| **Vendor + transport bidder** | Transporter: vendor location → beneficiaries | Transporter (with vendor handoff event) |

If not self-pickup, the **meal vendor owns delivery** — own fleet **or** selects a **transport bidder** for that area. **Transport is paid by the meal vendor**, not the payer.

### Payment rhythms

| Flow | Who pays whom | When |
|------|---------------|------|
| **Payer / pledge → meal vendor** | Payer or pledger | Direct, one-time, per funded meals |
| **Meal vendor → transport bidder** | Fulfiller (vendor is payee of payer funds) | Bulk settlement for assigned routes/windows |
| **Initiator / family → vendor** | Demand initiator or beneficiary (via initiator) | Recurring plans — same direct-payment principle |

### Matching (location-driven)

1. Aggregate meal units + beneficiary drop points for a **demand window**.
2. Match **fulfilment bids** (prep location, portions, ready time).
3. For non–self-pickup rows: require fulfiller delivery capacity **or** matched **transport bid** (vendor lat → beneficiary cluster).
4. Self-pickup rows skip transport; vendor runs pickup proof workflow.

**Implementation phases:** see [ENGINEERING_PLAN.md](./ENGINEERING_PLAN.md) § Marketplace phases. Order-ops detail (payment-done, delivery photo): [Future_Extensions.md](../design/Future_Extensions.md) Phase A–B (legacy pointer).

---

## June 4 — Neighbourhood dashboard (authoritative)

### List columns (web initiator limited view + coordinator when neighbourhood applies)

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

- Initiators on the **limited** dashboard see **beneficiary reference photo thumbnails** in the **neighbourhood** feed for intents inside `DONOR_NEIGHBOURHOOD_WINDOW_HOURS` (same window as photo URL redaction; env name legacy).
- **Coordinator-only:** initiator email (`initiator_email` / legacy `donor_email` in API) and unrestricted history — not “all photos coordinator-only.”

### Mobile → web

- Link to open the **web dashboard** in the browser; native in-app dashboard deferred.

### Voice memo themes (June 4, cleaned)

1. Return **distance in metres**; show on dashboard; sort nearest first; initiators see neighbourhood **photos**.
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
| Web roles | Initiator limited dashboard + coordinator full view; **emails** coordinator-only. |
| Pledges | Order intents → pledge / crowdsourcing extension. |
| Marketplace | Demand initiator, fulfiller, transport bidder; self-pickup vs delivery; bulk prep/transport — see **Marketplace** section above. |
| Photos / AI | Embeddings, descriptions, drone narrative; optional store embeddings not raw photos. |
| GIS | Neighbourhood feeds; PostGIS lists **shipped**; map UI **shipped** on web. |
| Cloudinary | Short-lived distribution window (1–2 h). |

Delivery detail: [ENGINEERING_PLAN.md](./ENGINEERING_PLAN.md). Order-ops phases A–B: [Future_Extensions.md](../design/Future_Extensions.md).

---

## Implementation order (June 4)

1. **Schema:** `delivered_at` — [schema.sql](../configuration/schema.sql); older DBs: [schema-delivered-at-migration.sql](../configuration/schema-delivered-at-migration.sql).
2. **integration-service:** `distance_m`, `ORDER BY distance_m ASC`, `ORDER_INTENT_LIST_MAX_ROWS`, expose `created_at` / `delivered_at`.
3. **web-app:** Columns **Order intent taken**, **Delivered at**, **Distance (m)**; elapsed from `created_at`.
4. **mobile-app:** “Open web dashboard” URL from config.
5. Initiator neighbourhood photos (confirm web + mobile within window).

**Later:**

- Delivery-partner flow **populates** `delivered_at` ([Future_Extensions.md](../design/Future_Extensions.md) § B).
- Marketplace roles, allocation, pickup proof ([ENGINEERING_PLAN.md](./ENGINEERING_PLAN.md) § Marketplace phases).

---

## Related docs

- [README.md § Documentation guide](../README.md#documentation-guide) — master index
- [ENGINEERING_PLAN.md](./ENGINEERING_PLAN.md) — phased delivery, repos
- [STATUS.md](./STATUS.md) — progress snapshot
- [database-setup-sequence.md](../configuration/database-setup-sequence.md) — SQL order for marketplace
- [web-client.md](../configuration/web-client.md)
- [environment-variables.md](../configuration/environment-variables.md)
- [Future_Extensions.md](../design/Future_Extensions.md) — order-ops phases A–B supplement
