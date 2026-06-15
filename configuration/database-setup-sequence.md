# Database setup — SQL run sequence

**Purpose:** Run migrations in the **correct order** when setting up Supabase or local Postgres from scratch, or when upgrading an older database.

**Deep dive (connection strings, local install):** [database.md](./database.md)  
**Deploy context:** [e2e-deployment-sequence.md](./e2e-deployment-sequence.md)  
**Doc map:** [README.md § Documentation guide](../README.md#documentation-guide)

---

## Choose your path

| Situation | Follow |
|-----------|--------|
| **New project** (empty Supabase / new local DB) | [§ Greenfield](#greenfield-new-database) |
| **Existing DB** created before a feature shipped | [§ Brownfield upgrades](#brownfield-upgrades-only-what-you-need) |
| **Marketplace + standard menus** (demand board, pledges) | [§ Marketplace add-on](#marketplace-add-on-after-core-schema) |

Run each file **once** in Supabase **SQL Editor** (or `psql -f`). All migration files use `IF NOT EXISTS` / idempotent patterns where possible — safe to re-run most steps.

---

## Greenfield (new database)

### A — Local Postgres only (optional prep)

Skip entirely for **Supabase** or **Docker**.

| Step | File | Notes |
|------|------|--------|
| A1 | [local-postgres-init.sql](./local-postgres-init.sql) | Create role `sharingbridge` |
| A2 | [local-postgres-create-database.sql](./local-postgres-create-database.sql) | **Separate** query / auto-commit — not in same transaction as A1 |
| A3 | [schema.sql](./schema.sql) | Core tables (see below) |
| A4 | [local-postgres-grants.sql](./local-postgres-grants.sql) | Only if A3 was run as `postgres` but app uses `sharingbridge` |

### B — Supabase or Docker or local (required)

| Step | File | Creates |
|------|------|---------|
| **1** | [schema.sql](./schema.sql) | `users`, `user_roles`, `donor_presets`, `order_intents` (+ PostGIS geo, `delivered_at`), `photo_artifacts`, `seeker_demands` |

**Verify:** Table Editor shows the tables above. PostGIS extension enabled.

### C — Auth role (after first Google sign-in)

| Step | File | When |
|------|------|------|
| **2** | [coordinator-seed.sql](./coordinator-seed.sql) | After your Gmail exists in `users` — edit email in file first |

### D — Marketplace (if using Demand tab, pledges, standard menus)

Continue to [§ Marketplace add-on](#marketplace-add-on-after-core-schema).

---

## Brownfield upgrades (only what you need)

Run **only** migrations for features missing from your DB. If unsure, check Table Editor / `\dt`.

| If missing… | Run | Then (optional) |
|-------------|-----|------------------|
| PostGIS / `order_intents.location` | [schema-postgis-migration.sql](./schema-postgis-migration.sql) | `npm run db:backfill-order-intent-geo` in integration-service |
| `order_intents.delivered_at` | [schema-delivered-at-migration.sql](./schema-delivered-at-migration.sql) | — |
| `seeker_demands` (or old `demand_signals`) | [schema-seeker-demands-migration.sql](./schema-seeker-demands-migration.sql) | — |
| `meal_pledges`, `vendor_bids`, `standard_offers` | [schema-marketplace-migration.sql](./schema-marketplace-migration.sql) | — |
| `standard_offer_id` on pledges/bids | [schema-standard-offers-wire-migration.sql](./schema-standard-offers-wire-migration.sql) | Requires marketplace tables |
| Sample menu catalog | [seed-standard-offers.sql](./seed-standard-offers.sql) | After `standard_offers` table exists |
| `initiator` role in `user_roles` | [schema-initiator-role-migration.sql](./schema-initiator-role-migration.sql) | Optional — legacy `donor` rows still work |
| Eco Kitchen Phase 3 (`order_code`, `initiation_route`, consent) | [schema-eco-kitchen-phase3-migration.sql](./schema-eco-kitchen-phase3-migration.sql) | After marketplace M1–M2; new initiations get `SB-…` codes when columns exist |

**Note:** Fresh installs from current [schema.sql](./schema.sql) already include PostGIS columns, `delivered_at`, and `seeker_demands`. Brownfield files exist for databases created **before** those were merged into `schema.sql`.

---

## Marketplace add-on (after core schema)

Run in this order on **greenfield or upgraded** DB:

| Step | File | Purpose |
|------|------|---------|
| **M1** | [schema-marketplace-migration.sql](./schema-marketplace-migration.sql) | `standard_offers`, `demand_windows`, `meal_pledges`, `vendor_bids` |
| **M2** | [schema-standard-offers-wire-migration.sql](./schema-standard-offers-wire-migration.sql) | `standard_offer_id` FK on pledges and vendor bids |
| **M3** | [seed-standard-offers.sql](./seed-standard-offers.sql) | Postal catalog (`IN:TN:600115`); test mirror in `sharingbridge-integration-service/test/fixtures/standardOffersCatalog.js` |
| **M4** | [schema-eco-kitchen-phase3-migration.sql](./schema-eco-kitchen-phase3-migration.sql) | Order codes (`SB-…`), `initiation_route`, email-share consent timestamps |
| **Reset** | [reset-marketplace-data.sql](./reset-marketplace-data.sql) | Clear old GPS-bucket data before re-seed (dev only) |

**App env (integration-service on Render):**

- `DATABASE_URL` — same Supabase URI as user-service
- `NOMINATIM_USER_AGENT` — required for GPS → postal `locality_key` (e.g. `IN:TN:600115`)

**Verify:**

1. Restart integration-service.
2. Web **Demand** tab loads without `schema_pending`.
3. Mobile **Record seeker demand** → standard item picker returns offers (after M3 + GPS in seeded postal area).

---

## Full sequence diagram

```text
GREENFIELD
==========
[local: init → create-db]  (optional)
        ↓
   schema.sql  ────────────────────────────────┐
        ↓                                      │
coordinator-seed.sql (after sign-in)           │
        ↓                                      │
   ┌──── MARKETPLACE (optional) ────┐         │
   │ M1 marketplace migration       │         │
   │ M2 standard-offers wire        │         │
   │ M3 seed-standard-offers        │         │
   │ M4 eco-kitchen phase3          │         │
   └────────────────────────────────┘         │
                                               │
BROWFIELD (pick rows you need)                 │
================================               │
postgis migration ──→ backfill geo             │
delivered_at migration                         │
seeker_demands migration                       │
        └──────────────────────────────────────┘
```

---

## SQL file index

| File | Type | Depends on |
|------|------|------------|
| [schema.sql](./schema.sql) | Core | — |
| [local-postgres-init.sql](./local-postgres-init.sql) | Local only | — |
| [local-postgres-create-database.sql](./local-postgres-create-database.sql) | Local only | init |
| [local-postgres-grants.sql](./local-postgres-grants.sql) | Local only | schema |
| [schema-postgis-migration.sql](./schema-postgis-migration.sql) | Upgrade | `order_intents` |
| [schema-delivered-at-migration.sql](./schema-delivered-at-migration.sql) | Upgrade | `order_intents` |
| [schema-seeker-demands-migration.sql](./schema-seeker-demands-migration.sql) | Upgrade | `users` |
| [schema-marketplace-migration.sql](./schema-marketplace-migration.sql) | Feature | `users` |
| [schema-standard-offers-wire-migration.sql](./schema-standard-offers-wire-migration.sql) | Feature | marketplace + `standard_offers` |
| [seed-standard-offers.sql](./seed-standard-offers.sql) | Data | `standard_offers` |
| [schema-eco-kitchen-phase3-migration.sql](./schema-eco-kitchen-phase3-migration.sql) | Feature | marketplace + `seeker_demands` |
| [coordinator-seed.sql](./coordinator-seed.sql) | Data | `users` row |

---

## Common mistakes

| Symptom | Fix |
|---------|-----|
| `permission denied for table users` (local) | Run [local-postgres-grants.sql](./local-postgres-grants.sql) |
| `CREATE DATABASE` inside transaction | Run create-database file alone with auto-commit |
| Demand tab `schema_pending` | Run seeker_demands migration or use current schema.sql |
| Empty pledges / 503 marketplace | Run M1 marketplace migration |
| Demand tab `column p.standard_offer_id does not exist` | Run **M2** [schema-standard-offers-wire-migration.sql](./schema-standard-offers-wire-migration.sql) (after M1) |
| Seeker demand requires `standard_offer_id` but no picker items | Run [reset-marketplace-data.sql](./reset-marketplace-data.sql) then M3 seed for your postal key (`IN:TN:PIN`) |
| Integration-service won't start (geo) | PostGIS migration + backfill |

---

**Last updated:** 2026-06 — postal locality keys; production catalog is SQL seed only (test fixtures live under integration-service `test/`).
