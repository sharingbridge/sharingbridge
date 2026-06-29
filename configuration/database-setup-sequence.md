# Database setup — progressive sequence

**Purpose:** Run SQL and related deploy steps **in order** for the current build (eco kitchen, Actions, Connection, FCM push).

**Deep dive (connection strings, local install):** [database.md](./database.md)  
**Deploy context:** [e2e-deployment-sequence.md](./e2e-deployment-sequence.md)  
**After SQL:** [notification-service-local.md](./notification-service-local.md) (M5 + Firebase + webhook)

---

## Progressive setup

Run each SQL file **once** in Supabase **SQL Editor** (or `psql -f`). Steps use `IF NOT EXISTS` where possible.

| Step | File | What it enables |
|------|------|-----------------|
| **1a** | [schema-spatial-bootstrap.sql](./schema-spatial-bootstrap.sql) | `extensions` schema + spatial extension (one-time; vendor name only here) |
| **1** | [schema.sql](./schema.sql) | Core tables: `users`, `order_intents`, `seeker_demands`, geo columns, `delivered_at` |
| **2** | [coordinator-seed.sql](./coordinator-seed.sql) | `coordinator` role for web dashboard (after your Gmail is in `users`) |
| **M1** | [schema-marketplace-migration.sql](./schema-marketplace-migration.sql) | `standard_offers`, `meal_pledges`, `vendor_bids`, `demand_windows` |
| **M2** | [schema-standard-offers-wire-migration.sql](./schema-standard-offers-wire-migration.sql) | `standard_offer_id` on pledges and vendor bids |
| **M3** | [seed-standard-offers.sql](./seed-standard-offers.sql) | Postal catalog (`IN:TN:600115`); test mirror in integration `test/fixtures/standardOffersCatalog.js` |
| **M4** | [schema-eco-kitchen-phase3-migration.sql](./schema-eco-kitchen-phase3-migration.sql) | Order codes (`SB-…`), `initiation_route`, email-share consent |
| **M5** | [schema-device-tokens-migration.sql](./schema-device-tokens-migration.sql) | `device_tokens` for FCM registration |
| **Deploy** | notification-service + `CONNECTION_NOTIFY_WEBHOOK_*` + Firebase | Mobile **connection-ready** push after kitchen commit — [notification-service-local.md](./notification-service-local.md) |

**Local Postgres prep** (skip for Supabase): [local-postgres-init.sql](./local-postgres-init.sql) → [local-postgres-create-database.sql](./local-postgres-create-database.sql) → **1a** + **1** → [local-postgres-grants.sql](./local-postgres-grants.sql).

**App env (integration-service):** `DATABASE_URL` (same as user-service); **`GIS_SCHEMA=extensions`** (required); `NOMINATIM_USER_AGENT` for GPS → postal `locality_key`. **`GET /v1/geocode/reverse`** is code-only — no extra SQL beyond **1a + 1** geo columns.

**After pulling map-picker / geocode code:** redeploy **integration-service** on Render; set `GIS_SCHEMA` if missing. Mobile: `GOOGLE_MAPS_API_KEY` in `android/local.properties` only — [mobile-client.md § Handover](../configuration/mobile-client.md#handover-location--map-picker-address-pickup-note).

---

## If a step was skipped

| Skipped | What breaks or is missing |
|---------|---------------------------|
| **1a** + **1** `schema-spatial-bootstrap.sql` then `schema.sql` | Node services fail at startup; missing core tables |
| **2** `coordinator-seed.sql` | Web dashboard `403` / no coordinator Actions tab |
| **M1** | Actions tab `schema_pending`; marketplace APIs 503 |
| **M2** | SQL errors on pledges (`standard_offer_id` missing) |
| **M3** | Mobile menu picker empty for seeded postal areas |
| **M4** | No `SB-…` order codes; Connection API / panel unavailable |
| **M5** | `PUT /v1/device-tokens` fails; FCM tokens not stored |
| **Deploy** (notification + webhook + Firebase) | Kitchen commit and **web Connection** still work (**M4**); mobile gets **no system notification** when connection is ready |
| **Firebase / `google-services.json` on APK** | Push registration silent no-op; rebuild APK after adding file + SHA fingerprints |

---

## Where you are (pick-up)

| Last file you ran | Run next |
|-------------------|----------|
| **1a** + **1** only | **M1** → **M2** → **M3** → **M4** → **M5** |
| **M1** | **M2** → **M3** → **M4** → **M5** |
| **M2** standard-offers wire | **M3** → **M4** → **M5** |
| **M3** seed | **M4** → **M5** |
| **M4** eco kitchen | **M5** → notification deploy |
| **M5** device_tokens | Notification deploy + integration webhook — then **done** for SQL |

After SQL: redeploy integration-service; deploy notification-service; set `CONNECTION_NOTIFY_WEBHOOK_*`. Manual checks: [MANUAL_TESTING_GUIDE.md](../testing/MANUAL_TESTING_GUIDE.md) **§4d–4g**.

---

## Verify after each stage

| After | Check |
|-------|--------|
| **1a** + **1** | Table Editor shows `users`, `order_intents`, `seeker_demands`; spatial extension in `extensions` |
| **M1–M3** | Web **Actions** loads; mobile eco kitchen route shows standard menu in seeded postal area |
| **M4** | New seeker demands get `SB-…`; kitchen commit + **Connection** panel on web |
| **M5** + deploy | Mobile sign-in creates `device_tokens` row; kitchen commit sends FCM push |

**Dev reset:** [reset-marketplace-data.sql](./reset-marketplace-data.sql) then re-run **M3** only.

---

## Sequence diagram

```text
schema-spatial-bootstrap.sql
    ↓
schema.sql
    ↓
coordinator-seed.sql (after sign-in)
    ↓
M1 → M2 → M3 → M4 → M5
    ↓
notification-service + CONNECTION_NOTIFY_WEBHOOK_* + Firebase + APK rebuild
    ↓
DONE
```

---

## SQL file index

| File | Step |
|------|------|
| [schema-spatial-bootstrap.sql](./schema-spatial-bootstrap.sql) | **1a** |
| [schema.sql](./schema.sql) | **1** |
| [local-postgres-init.sql](./local-postgres-init.sql) | Local only |
| [local-postgres-create-database.sql](./local-postgres-create-database.sql) | Local only |
| [local-postgres-grants.sql](./local-postgres-grants.sql) | Local only |
| [schema-marketplace-migration.sql](./schema-marketplace-migration.sql) | **M1** |
| [schema-standard-offers-wire-migration.sql](./schema-standard-offers-wire-migration.sql) | **M2** |
| [seed-standard-offers.sql](./seed-standard-offers.sql) | **M3** |
| [schema-eco-kitchen-phase3-migration.sql](./schema-eco-kitchen-phase3-migration.sql) | **M4** |
| [schema-device-tokens-migration.sql](./schema-device-tokens-migration.sql) | **M5** |
| [coordinator-seed.sql](./coordinator-seed.sql) | **2** |
| [schema-postgis-move-to-extensions.sql](./schema-postgis-move-to-extensions.sql) | Legacy (existing Supabase with extension in `public`) |
| [schema-postgis-migration.sql](./schema-postgis-migration.sql) | Legacy (geo columns) |
| [reset-marketplace-data.sql](./reset-marketplace-data.sql) | Dev reset |

**Legacy upgrade files** (databases created before current **1a + 1** — do not run on greenfield): `schema-postgis-migration.sql`, `schema-postgis-move-to-extensions.sql`, `schema-delivered-at-migration.sql`, `schema-seeker-demands-migration.sql`, `schema-initiator-role-migration.sql`. Same end state as **1a + 1** + **M1–M5** when applied as needed.

---

## Common mistakes

| Symptom | Fix |
|---------|-----|
| `permission denied for table users` (local) | [local-postgres-grants.sql](./local-postgres-grants.sql) |
| `CREATE DATABASE` inside transaction | Run create-database file alone |
| Actions tab `schema_pending` | **M1** |
| `column p.standard_offer_id does not exist` | **M2** |
| Empty menu picker | **M3** |
| No `SB-…` order codes | **M4** |
| No `device_tokens` row after sign-in | **M5** + APK with `google-services.json` |
| No push after commit | notification-service deploy + `CONNECTION_NOTIFY_WEBHOOK_*` + Firebase Admin JSON |
| Integration won't start (geo) | Run **1a** then **1**; existing Supabase: [schema-postgis-move-to-extensions.sql](./schema-postgis-move-to-extensions.sql); redeploy integration-service |

---

**Last updated:** 2026-06 — progressive **1a → 1 → 2 → M1–M5 → notification deploy**.
