# SharingBridge — Product roadmap

**Purpose:** Founder voice memos (June 2026) and the **authoritative** spec for near-term neighbourhood dashboard work. Use with [AGENT_HANDOFF.md](./AGENT_HANDOFF.md) for what is already shipped.

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
| Photos / AI | Embeddings, descriptions, drone narrative; optional store embeddings not raw photos. |
| GIS | Neighbourhood feeds; PostGIS lists **shipped**; map UI later. |
| Cloudinary | Short-lived distribution window (1–2 h). |

Details: [Future_Extensions.md](../design/Future_Extensions.md), [IMPLEMENTATION_APPROACH.md](./IMPLEMENTATION_APPROACH.md).

---

## Implementation order (June 4)

1. **Schema:** `delivered_at` — [schema.sql](../configuration/schema.sql); older DBs: [schema-delivered-at-migration.sql](../configuration/schema-delivered-at-migration.sql).
2. **integration-service:** `distance_m`, `ORDER BY distance_m ASC`, `ORDER_INTENT_LIST_MAX_ROWS`, expose `created_at` / `delivered_at`.
3. **web-app:** Columns **Order intent taken**, **Delivered at**, **Distance (m)**; elapsed from `created_at`.
4. **mobile-app:** “Open web dashboard” URL from config.
5. Donor neighbourhood photos (confirm web + mobile within window).

**Later:** Delivery-partner flow **populates** `delivered_at` reliably ([Future_Extensions.md](../design/Future_Extensions.md) § B).

---

## Related docs

- [web-client.md](../configuration/web-client.md)
- [environment-variables.md](../configuration/environment-variables.md)
- [database.md](../configuration/database.md)
- [Future_Extensions.md](../design/Future_Extensions.md)
