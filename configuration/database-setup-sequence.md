# Database setup — SQL run sequence

**Purpose:** Run migrations in the **correct order** when setting up Supabase or local Postgres from scratch, or when upgrading an older database.

**Deep dive (connection strings, local install):** [database.md](./database.md)  
**Deploy context:** [e2e-deployment-sequence.md](./e2e-deployment-sequence.md)  
**Doc map:** [README.md § Documentation guide](../README.md#documentation-guide)

---

## SQL files at a glance

| Category | File(s) | Run when |
|----------|---------|----------|
| **Core** | [schema.sql](./schema.sql) | **Once** on every new database (users, order intents, seeker_demands, PostGIS, `delivered_at`) |
| **Marketplace M1–M5** | See [§ Marketplace add-on](#marketplace-add-on-after-core-schema) | After `schema.sql` if you use **Actions** tab, eco kitchen routes, or FCM push |
| **Coordinator data** | [coordinator-seed.sql](./coordinator-seed.sql) | After your Gmail exists in `users` |
| **Brownfield legacy** | [§ Brownfield](#brownfield-upgrades-legacy-databases-only) | **Only** if your DB predates features now in `schema.sql` |
| **Dev reset** | [reset-marketplace-data.sql](./reset-marketplace-data.sql) | Dev/staging only — wipes marketplace rows |
| **Local Postgres** | `local-postgres-*.sql` | Laptop install only — not Supabase |

**Keep all `.sql` files in the repo.** Brownfield migrations are not redundant — they upgrade databases created months ago. New projects skip them because [schema.sql](./schema.sql) already includes PostGIS, `delivered_at`, and `seeker_demands`.

---

## Where you are (quick pick-up)

| Last file you ran | Run next (in order) | Skip |
|-------------------|----------------------|------|
| `schema.sql` only | **M1** → **M2** → **M3** | Brownfield § below |
| **M1** marketplace | **M2** → **M3** | M1 again |
| **M2** standard-offers wire | **M3** → **M4** → **M5** (M5 only for FCM) | M1–M2 |
| **M3** seed | **M4** → **M5** (optional) | M1–M3 |
| **M4** eco kitchen phase 3 | **M5** if using push; else **done** | M1–M4 |
| **M5** device_tokens | **Done** for SQL | — |

After SQL: redeploy integration-service (+ notification-service if M5). See [MANUAL_TESTING_GUIDE.md](../testing/MANUAL_TESTING_GUIDE.md).

---

## Choose your path

| Situation | Follow |
|-----------|--------|
| **New project** (empty Supabase / new local DB) | [§ Greenfield](#greenfield-new-database) → [§ Marketplace](#marketplace-add-on-after-core-schema) |
| **Existing DB** from an older SharingBridge deploy | [§ Brownfield](#brownfield-upgrades-legacy-databases-only) — run **only** rows you have not applied |
| **Marketplace + eco kitchen + push** | M1–M5 in [§ Marketplace](#marketplace-add-on-after-core-schema) |

Run each file **once** in Supabase **SQL Editor** (or `psql -f`). Migrations use `IF NOT EXISTS` where possible — safe to re-run most steps.

---

## Greenfield (new database)

### A — Local Postgres only (optional prep)

Skip entirely for **Supabase**.

| Step | File | Notes |
|------|------|--------|
| A1 | [local-postgres-init.sql](./local-postgres-init.sql) | Create role `sharingbridge` |
| A2 | [local-postgres-create-database.sql](./local-postgres-create-database.sql) | **Separate** query / auto-commit — not in same transaction as A1 |
| A3 | [schema.sql](./schema.sql) | Core tables |
| A4 | [local-postgres-grants.sql](./local-postgres-grants.sql) | Only if A3 was run as `postgres` but app uses `sharingbridge` |

### B — Supabase or Docker or local (required)

| Step | File | Creates |
|------|------|---------|
| **1** | [schema.sql](./schema.sql) | `users`, `user_roles`, `donor_presets`, `order_intents` (+ PostGIS, `delivered_at`), `photo_artifacts`, `seeker_demands` |

**Verify:** Table Editor shows the tables above. PostGIS extension enabled.

### C — Auth role (after first Google sign-in)

| Step | File | When |
|------|------|------|
| **2** | [coordinator-seed.sql](./coordinator-seed.sql) | After your Gmail exists in `users` — edit email in file first |

### D — Marketplace + eco kitchen + push

Continue to [§ Marketplace add-on](#marketplace-add-on-after-core-schema) (**M1–M5**).

---

## Brownfield upgrades (legacy databases only)

**Skip this entire section** if you:

- Created the database from **current** [schema.sql](./schema.sql), **or**
- Already applied the matching migration when it shipped.

Run **only** rows for features **missing** from your DB (check Table Editor / `\dt` / column list).

| If missing… | Run | Notes |
|-------------|-----|--------|
| PostGIS / `order_intents.location` | [schema-postgis-migration.sql](./schema-postgis-migration.sql) | Then `npm run db:backfill-order-intent-geo` in integration-service |
| `order_intents.delivered_at` | [schema-delivered-at-migration.sql](./schema-delivered-at-migration.sql) | Already in current `schema.sql` |
| `seeker_demands` table | [schema-seeker-demands-migration.sql](./schema-seeker-demands-migration.sql) | Already in current `schema.sql` |
| `meal_pledges`, `vendor_bids`, `standard_offers` | [schema-marketplace-migration.sql](./schema-marketplace-migration.sql) | Same as **M1** |
| `standard_offer_id` on pledges/bids | [schema-standard-offers-wire-migration.sql](./schema-standard-offers-wire-migration.sql) | Same as **M2** |
| `initiator` role in `user_roles` | [schema-initiator-role-migration.sql](./schema-initiator-role-migration.sql) | Optional — legacy `donor` rows still work |
| Eco Kitchen (`order_code`, `initiation_route`, consent) | [schema-eco-kitchen-phase3-migration.sql](./schema-eco-kitchen-phase3-migration.sql) | Same as **M4** |
| FCM `device_tokens` | [schema-device-tokens-migration.sql](./schema-device-tokens-migration.sql) | Same as **M5** |

**Catalog data:** [seed-standard-offers.sql](./seed-standard-offers.sql) after `standard_offers` exists (= **M3**).

---

## Marketplace add-on (after core schema)

Run **in this order** on greenfield or brownfield DBs that have `schema.sql` but not yet marketplace/eco/push:

| Step | File | Purpose |
|------|------|---------|
| **M1** | [schema-marketplace-migration.sql](./schema-marketplace-migration.sql) | `standard_offers`, `demand_windows`, `meal_pledges`, `vendor_bids` |
| **M2** | [schema-standard-offers-wire-migration.sql](./schema-standard-offers-wire-migration.sql) | `standard_offer_id` on pledges and vendor bids |
| **M3** | [seed-standard-offers.sql](./seed-standard-offers.sql) | Postal catalog (`IN:TN:600115`); test mirror in `sharingbridge-integration-service/test/fixtures/standardOffersCatalog.js` |
| **M4** | [schema-eco-kitchen-phase3-migration.sql](./schema-eco-kitchen-phase3-migration.sql) | Order codes (`SB-…`), `initiation_route`, email-share consent |
| **M5** | [schema-device-tokens-migration.sql](./schema-device-tokens-migration.sql) | FCM `device_tokens` — **only if** using notification-service push |

**App env (integration-service on Render):**

- `DATABASE_URL` — same Supabase URI as user-service
- `NOMINATIM_USER_AGENT` — GPS → postal `locality_key` (integration-service; separate from ai-orchestration’s copy)

**Verify:**

1. Restart integration-service.
2. Web **Actions** tab loads without `schema_pending`.
3. Mobile **Start initiation** → eco kitchen route → standard menu picker returns offers (after M3 + GPS in seeded postal area).
4. After M4: new seeker demands get `SB-…` order codes; **Connection** panel works when kitchen commits.
5. After M5 + notification deploy: FCM push on kitchen commit (optional — in-app Connection works without M5).

---

## Full sequence diagram

```text
GREENFIELD
==========
[local: init → create-db]  (optional)
        ↓
   schema.sql
        ↓
coordinator-seed.sql (after sign-in)
        ↓
   M1 → M2 → M3 → M4 → M5 (optional push)
        ↓
   DONE

BROWFIELD (legacy DBs only — skip if schema.sql is current)
============================================================
postgis / delivered_at / seeker_demands  →  only if missing
        ↓
M1 → M2 → (M3 seed) → M4 → M5
```

---

## SQL file index

| File | Type | Depends on |
|------|------|------------|
| [schema.sql](./schema.sql) | Core | — |
| [local-postgres-init.sql](./local-postgres-init.sql) | Local only | — |
| [local-postgres-create-database.sql](./local-postgres-create-database.sql) | Local only | init |
| [local-postgres-grants.sql](./local-postgres-grants.sql) | Local only | schema |
| [schema-marketplace-migration.sql](./schema-marketplace-migration.sql) | **M1** | `users` |
| [schema-standard-offers-wire-migration.sql](./schema-standard-offers-wire-migration.sql) | **M2** | M1 + `standard_offers` |
| [seed-standard-offers.sql](./seed-standard-offers.sql) | **M3** data | `standard_offers` |
| [schema-eco-kitchen-phase3-migration.sql](./schema-eco-kitchen-phase3-migration.sql) | **M4** | M1–M2, `seeker_demands` |
| [schema-device-tokens-migration.sql](./schema-device-tokens-migration.sql) | **M5** | `users` |
| [coordinator-seed.sql](./coordinator-seed.sql) | Data | `users` row |
| [reset-marketplace-data.sql](./reset-marketplace-data.sql) | Dev reset | marketplace tables |
| [schema-postgis-migration.sql](./schema-postgis-migration.sql) | Brownfield | `order_intents` |
| [schema-delivered-at-migration.sql](./schema-delivered-at-migration.sql) | Brownfield | `order_intents` |
| [schema-seeker-demands-migration.sql](./schema-seeker-demands-migration.sql) | Brownfield | `users` |
| [schema-initiator-role-migration.sql](./schema-initiator-role-migration.sql) | Brownfield optional | `user_roles` |

---

## Common mistakes

| Symptom | Fix |
|---------|-----|
| `permission denied for table users` (local) | Run [local-postgres-grants.sql](./local-postgres-grants.sql) |
| `CREATE DATABASE` inside transaction | Run create-database file alone with auto-commit |
| Actions tab `schema_pending` | Run M1 or use current `schema.sql` + seeker_demands |
| Empty pledges / 503 marketplace | Run **M1** |
| `column p.standard_offer_id does not exist` | Run **M2** (after M1) |
| No menu picker items | Run **M3** for your postal key; or [reset-marketplace-data.sql](./reset-marketplace-data.sql) then M3 |
| No `SB-…` order codes | Run **M4** |
| Push never registers tokens | Run **M5**; rebuild mobile APK with `google-services.json` |
| Integration won't start (geo) | PostGIS in `schema.sql` or brownfield postgis migration + backfill |

---

**Last updated:** 2026-06 — M1–M5 active path; brownfield files retained for legacy upgrades only.
