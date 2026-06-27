# Database configuration (Supabase PostgreSQL)

SharingBridge stores **users, roles, initiator vendor presets, and order intents** in **PostgreSQL**. For production we use **[Supabase](https://supabase.com)** (hosted Postgres). **Render** hosts only the **APIs** (user-service, integration-service); they connect to Supabase via **`DATABASE_URL`**.

There is **no** runtime fallback to JSON files after cutover — import once, then the database is the only source of truth.

> **SQL run order (start here):** [database-setup-sequence.md](./database-setup-sequence.md) — progressive **1 → M5** + notification deploy.

**Related:** [authentication.md](./authentication.md) · [backend-render.md](./backend-render.md) · [e2e-deployment-sequence.md](./e2e-deployment-sequence.md) · [README.md § Documentation guide](../README.md#documentation-guide)

---

## Status

| Data | Supabase table | Notes |
|------|----------------|--------|
| Users, Google mapping | `users` | user-service |
| Roles | `user_roles` | [coordinator-seed.sql](./coordinator-seed.sql) |
| Initiator vendor presets | `donor_presets` | integration → user-service |
| Order intents | `order_intents` | integration-service |
| Seeker demands | `seeker_demands` | mobile eco kitchen / pledging routes |
| Marketplace | `standard_offers`, `meal_pledges`, `vendor_bids` | SQL **M1–M3** |
| Eco kitchen phase 3 | `order_code`, `initiation_route` columns | SQL **M4** |
| FCM device tokens | `device_tokens` | SQL **M5** — [notification-service-local.md](./notification-service-local.md) |

Full order: [database-setup-sequence.md](./database-setup-sequence.md).

**Code note:** Both Node services **require** **`DATABASE_URL`** at startup and read/write the database only (no JSON file fallback). Run [schema-spatial-bootstrap.sql](./schema-spatial-bootstrap.sql) then [schema.sql](./schema.sql) before starting services.

---

## Architecture (read this once)

```text
  Mobile / Web  ──HTTPS──►  Render (user-service, integration-service)
                                    │
                                    │  DATABASE_URL (Postgres wire protocol)
                                    ▼
                            Supabase (PostgreSQL)
                            public: users, order_intents, seeker_demands, …
                            extensions: PostGIS extension only (not app tables)
```

- **Supabase** = database + SQL Editor + connection strings. **Do not** put Supabase in the mobile or web app.
- **Render** = Node APIs. Set **`DATABASE_URL`** on **both** `sharingbridge-user-service` and `sharingbridge-integration-service` to the **same** Supabase connection string.
- **Do not** use the Supabase **anon** or **service_role** API keys as `DATABASE_URL`. Use the **database connection URI** (see below).
- **Schemas:** App tables live in **`public`** (unqualified SQL in Node services). Spatial functions/types live in **`extensions`** (`GIS_SCHEMA` env). See [§ What `public` means](#what-public-means-not-public-on-the-internet) below.

---

## Step 1 — Create a Supabase project

1. Sign in at [supabase.com](https://supabase.com) → **New project**.
2. Pick an organization (personal is fine), name e.g. `sharingbridge`, choose a **region** (prefer one close to your Render services).
3. Set a strong **database password** and save it (password manager). You need it for `DATABASE_URL`.
4. Wait until the project dashboard shows the project as **ready**.

**Spatial extension:** greenfield runs [schema-spatial-bootstrap.sql](./schema-spatial-bootstrap.sql) then [schema.sql](./schema.sql) (see [database-setup-sequence.md](./database-setup-sequence.md)). Older databases: [schema-postgis-migration.sql](./schema-postgis-migration.sql) or [schema-postgis-move-to-extensions.sql](./schema-postgis-move-to-extensions.sql); optional `npm run db:backfill-order-intent-geo` in integration-service.

---

## Step 2 — Create tables in Supabase (SQL Editor)

Follow **[database-setup-sequence.md](./database-setup-sequence.md)**:

1. Run [schema-spatial-bootstrap.sql](./schema-spatial-bootstrap.sql), then [schema.sql](./schema.sql).
2. Run **M1 → M5** and [coordinator-seed.sql](./coordinator-seed.sql) after sign-in.

Skipped-step symptoms: [database-setup-sequence.md](./database-setup-sequence.md) § **If a step was skipped**.

**Verify:** **Table Editor** → tables listed in [§ Tables](#tables).

---

## Step 3 — Get `DATABASE_URL` from Supabase

1. **Project Settings** (gear) → **Database**.
2. Under **Connection string**, choose **URI**.
3. For Node on **Render**, prefer **Connection pooling** → **Transaction** mode (port often `6543`) if Supabase shows it — better for serverless/long-lived web services. **Session** mode (port `5432`) is fine for local dev.
4. Copy the URI. Replace `[YOUR-PASSWORD]` with your database password.
5. Example shape (yours will differ):

   ```text
   postgresql://postgres.[project-ref]:YOUR_PASSWORD@aws-0-[region].pooler.supabase.com:6543/postgres
   ```

6. If the URI contains `?pgbouncer=true`, keep that query string for pooler URLs.

**Security:** This string is a **secret**. Store it only in:

- Render → **Environment** (user-service + integration-service)
- Local `.env` files (gitignored — never commit)

---

## Step 4 — Connect Render APIs to Supabase

APIs stay on Render; only the database moves to Supabase.

1. [Render Dashboard](https://dashboard.render.com/) → **sharingbridge-user-service** → **Environment**.
2. Add or update:

   | Key | Value |
   |-----|--------|
   | `DATABASE_URL` | Supabase URI from Step 3 |

3. Repeat the **same** `DATABASE_URL` on **sharingbridge-integration-service**.
4. **Save** and **redeploy both** Node services.

Do **not** create a separate Render PostgreSQL instance unless you intentionally want Postgres on Render instead of Supabase ([optional alternative](#optional-render-postgresql-instead-of-supabase) below).

**Still required on Render (unchanged):** `AUTH_TOKEN_SECRET`, `GOOGLE_CLIENT_ID_WEB`, `WEB_CORS_ORIGINS`, etc. — [backend-render.md](./backend-render.md).

---

## Local development (PostgreSQL on your machine)

Optional. Production uses **Supabase** (steps above). For local dev you can install Postgres on your PC, use a **Supabase dev project**, or Docker.

SQL files (canonical — do not duplicate SQL in this doc):

| File | When to use |
|------|-------------|
| [local-postgres-init.sql](./local-postgres-init.sql) | **Local only** Step A5a: app role |
| [local-postgres-create-database.sql](./local-postgres-create-database.sql) | **Local only** Step A5b: database (run separately in pgAdmin) |
| [local-postgres-grants.sql](./local-postgres-grants.sql) | **Local only** Step A6b: table permissions for `sharingbridge` user |
| [schema-spatial-bootstrap.sql](./schema-spatial-bootstrap.sql) | **Everywhere** Step **1a**: spatial extension in `extensions` |
| [schema.sql](./schema.sql) | **Everywhere** Step **1**: app tables |

Replace `PORT` below with the port you chose in the installer (often **5432** or **5433** if 5432 is already in use).

---

### Option A — Install PostgreSQL (manual, step by step)

#### Step A1 — Download

1. Open https://www.postgresql.org/download/windows/
2. Download **PostgreSQL 16** (64-bit, EDB installer).

#### Step A2 — Components (installer screen)

| Component | Install? |
|-----------|----------|
| **PostgreSQL Server** | Yes |
| **pgAdmin 4** | Yes (run SQL in a GUI) |
| **Command Line Tools** | Yes (`psql`) |
| **Stack Builder** | No (skip at end) |
| **EDB / PEM agent registration** | No — do not register with PEM |

#### Step A3 — Install location and port

Use any directories you prefer (installer defaults under `Program Files` are fine). Note the paths and port for later.

| Setting | Typical choice |
|---------|----------------|
| Port | **5432** if free; otherwise **5433** (or whatever the installer suggests) |
| Superuser (`postgres`) password | Choose one and remember it |
| Locale | Default |

If install hangs or fails, uninstall Postgres from **Settings → Apps**, remove leftover data folders only if you know they are unused, then retry with a single version (avoid two Postgres services fighting for the same port).

**Check what uses port 5432 (Windows):**

```text
netstat -ano | findstr :5432
```

#### Step A4 — Start the service

**Services** (`services.msc`) → **postgresql-x64-…** → **Running**. Start it if stopped.

#### Step A5 — Create app user and database

Connect as **`postgres`** (pgAdmin or psql). Run **two** SQL files in order — not one combined script in pgAdmin.

**Step A5a — role**

1. **Query Tool** on database `postgres` → open [local-postgres-init.sql](./local-postgres-init.sql) → **Execute**.

**Step A5b — database**

PostgreSQL does not allow `CREATE DATABASE` inside a transaction. pgAdmin runs a whole script in one transaction, so you will see `SQL state: 25001` if you run both files together.

Pick **one**:

| Method | Action |
|--------|--------|
| **pgAdmin SQL** | New **Query Tool** → enable **Auto-commit** on the toolbar → open [local-postgres-create-database.sql](./local-postgres-create-database.sql) → **Execute** only that file |
| **pgAdmin GUI** | **Databases** → right-click → **Create** → Database `sharingbridge`, Owner `sharingbridge` |
| **psql** | `psql -U postgres -f .../local-postgres-create-database.sql` |

If the database already exists, skip to Step A6.

**Not used for Supabase or Docker** — those paths need **1a + 1** ([schema-spatial-bootstrap.sql](./schema-spatial-bootstrap.sql), then [schema.sql](./schema.sql)).

#### Step A6 — Create tables

In pgAdmin, connect to database **sharingbridge** → **Query Tool** → run [schema-spatial-bootstrap.sql](./schema-spatial-bootstrap.sql), then [schema.sql](./schema.sql) → **Execute** each file.

Or from a terminal (set `PORT` and path to your clone):

```text
set PGPASSWORD=sharingbridge
psql -U sharingbridge -h localhost -p PORT -d sharingbridge -f path/to/sharingbridge/configuration/schema-spatial-bootstrap.sql
psql -U sharingbridge -h localhost -p PORT -d sharingbridge -f path/to/sharingbridge/configuration/schema.sql
```

Verify: `\dt` should list `users`, `user_roles`, `donor_presets`, `order_intents`.

#### Step A6b — Grant table access to `sharingbridge` (if you ran schema as `postgres`)

If `DATABASE_URL` uses user **`sharingbridge`** but tables were created in pgAdmin as **`postgres`**, imports and the app fail with `permission denied for table users` (SQL `42501`).

As **`postgres`**, on database **`sharingbridge`**, run [local-postgres-grants.sql](./local-postgres-grants.sql) (Query Tool → Execute).

#### Step A7 — Configure Node services

In **both** `sharingbridge-user-service/.env` and `sharingbridge-integration-service/.env`:

```env
DATABASE_URL=postgresql://sharingbridge:sharingbridge@localhost:PORT/sharingbridge
```

Example for port **5433**:

```env
DATABASE_URL=postgresql://sharingbridge:sharingbridge@localhost:5433/sharingbridge
```

Restart both Node services after setting `DATABASE_URL`.

#### Coordinator seed

Sign in once (creates a `users` row), then run:

```sql
INSERT INTO user_roles (user_id, role)
SELECT id, 'coordinator' FROM users WHERE email = 'your-coordinator@gmail.com'
ON CONFLICT DO NOTHING;
```

Coordinator access is **not** configured in `.env`. Grant `coordinator` with [coordinator-seed.sql](./coordinator-seed.sql) after the user exists in `users`.

---

### Option B — Supabase dev project (no local Postgres)

1. Create a project at [supabase.com](https://supabase.com) (e.g. `sharingbridge-dev`).
2. **SQL Editor** → run [schema-spatial-bootstrap.sql](./schema-spatial-bootstrap.sql), then [schema.sql](./schema.sql).
3. **Settings → Database** → copy the **connection URI** into both services’ `DATABASE_URL`.

---

### Option C — Docker (only if Docker Desktop is installed)

```text
docker run -d --name sharingbridge-pg -e POSTGRES_USER=sharingbridge -e POSTGRES_PASSWORD=sharingbridge -e POSTGRES_DB=sharingbridge -p 5432:5432 postgres:16-alpine
```

Load schema from your repo clone:

```text
docker exec -i sharingbridge-pg psql -U sharingbridge -d sharingbridge < path/to/sharingbridge/configuration/schema-spatial-bootstrap.sql
docker exec -i sharingbridge-pg psql -U sharingbridge -d sharingbridge < path/to/sharingbridge/configuration/schema.sql
```

Same `DATABASE_URL` shape as Option A (`localhost` and the published port).

---

## Optional: Render PostgreSQL instead of Supabase

Only if you **do not** want Supabase: Render → **New +** → **PostgreSQL**, copy **Internal Database URL**, set as `DATABASE_URL` on both Node services. Apply **1a + 1** via SQL or Render’s psql.

**Recommended default for this project:** **Supabase** (aligned with [ENGINEERING_PLAN.md](../development/ENGINEERING_PLAN.md)). Render Postgres is optional.

---

## Environment variables (DB mode)

Set **`DATABASE_URL`** on user-service, integration-service, and photo-service (same URI). All other keys: [environment-variables.md](./environment-variables.md).

---

## Tables

**Canonical DDL:** [schema-spatial-bootstrap.sql](./schema-spatial-bootstrap.sql) + [schema.sql](./schema.sql) — run in Supabase **SQL Editor** (Step 2), local pgAdmin/psql (Option A Step A6), or Docker (Option C). Do not maintain a second copy of the SQL in this doc.

| Table | Replaces (file mode) |
|-------|----------------------|
| `users` | `user-service-store.json` users |
| `user_roles` | `donor` / `initiator` / `coordinator` (SQL seed) |
| `donor_presets` | initiator vendor presets in user-service store |
| `order_intents` | `order-intents.json` |

`order_intents.payload` (JSONB) holds `verbal_handover_notes`, `presets_snapshot`, `has_reference_photo`, and optional **`location_lat`**, **`location_lng`**, **`location_label`**, **`locality_key`** (set on `POST` when the client sends coordinates).

| Column | Purpose |
|--------|---------|
| `created_at` | **Order intent taken** time (initiator registered intent — not a vendor order). |
| `delivered_at` | Nullable; **Delivered at** on dashboard ([schema-delivered-at-migration.sql](./schema-delivered-at-migration.sql) on older DBs). Populated when delivery-partner flow exists. |
| `location` / `locality_key` | PostGIS neighbourhood filters; list may return computed **`distance_m`** (metres, not stored). `locality_key` is derived server-side (v1: Nominatim) — vendor-agnostic on clients; see [Location_Services_Vendor_Abstraction.md](../design/Location_Services_Vendor_Abstraction.md). |

Dashboard spec: [PRODUCT_MODEL.md](../development/PRODUCT_MODEL.md).

Primary keys and `UNIQUE` constraints create indexes automatically; [schema.sql](./schema.sql) adds two indexes on `order_intents` for list queries (time-ordered lists, not geo).

---

## Indexes explained

| Index | Type | Why |
|-------|------|-----|
| `PRIMARY KEY` / `UNIQUE` | Automatic | Upsert by `order_intent_id`; one row per `(user_id, pack_id)` |
| `idx_order_intents_user_updated` | Manual | Initiator list: `WHERE user_id` + `ORDER BY updated_at DESC` |
| `idx_order_intents_updated` | Manual | Time-ordered lists |
| `idx_order_intents_location` | GiST | `ST_DWithin` neighbourhood / map queries |
| `idx_order_intents_locality_key` | Partial btree | `locality_key = $key` filters |

---

## Coordinator seeding

1. Ensure a row exists in `users` (e.g. one Google sign-in on mobile as initiator).
2. Run [coordinator-seed.sql](./coordinator-seed.sql) in psql, pgAdmin, or Supabase **SQL Editor** (edit the email in that file first).
3. Sign in on the **web dashboard** with that Gmail — JWT will include `role: coordinator`.

---

## JWT claims (when DB mode ships)

user-service reads **`user_roles`** and mints `role` (active) + `roles` (array). See [authentication.md](./authentication.md).

---

## Cutover checklist

- [ ] Supabase project created
- [ ] [schema-spatial-bootstrap.sql](./schema-spatial-bootstrap.sql) + [schema.sql](./schema.sql) run in **SQL Editor**
- [ ] `DATABASE_URL` set on **both** Render Node services (Supabase URI, not anon key)
- [ ] Both services redeployed
- [ ] Coordinator row in `user_roles`
- [ ] Smoke: Google sign-in, order intent, web **Refresh**

---

## Troubleshooting

| Symptom | Likely cause | Fix |
|---------|----------------|-----|
| `%5C` or broken file link | Windows `d:\...` paths in chat | Open from repo: **Ctrl+P** → `database.md` or `schema.sql` |
| `CREATE DATABASE cannot run inside a transaction block` (25001) | Ran init + create DB in one pgAdmin Execute | Run [local-postgres-create-database.sql](./local-postgres-create-database.sql) alone with **Auto-commit**, or create DB via pgAdmin GUI — Step A5b |
| Local install stuck / messy | Old Postgres on 5432, partial install | Uninstall from Apps; pick a free port (e.g. 5433); one Postgres version; see Option A Step A3 |
| `connection refused` (local) | Wrong port in `DATABASE_URL` | Match installer port (`5432` vs `5433`) |
| `connection refused` | Wrong `DATABASE_URL` or password | Re-copy URI from Supabase **Database** settings; redeploy Render |
| `relation does not exist` | Schema not run | Re-run **1a + 1** in SQL Editor |
| `permission denied for table users` (42501) | Tables owned by `postgres`, app uses `sharingbridge` | Run [local-postgres-grants.sql](./local-postgres-grants.sql) as `postgres` — Step A6b |
| Used anon key as `DATABASE_URL` | Wrong credential type | Use **database URI**, not Project API keys |
| `extension "postgis" does not support SET SCHEMA` (0A000) | PostGIS 2.3+ on Supabase | Use [schema-postgis-move-to-extensions.sql](./schema-postgis-move-to-extensions.sql) (drop/recreate — not `ALTER EXTENSION`) |

---

## Geospatial data and PostGIS

### What runs today (PostGIS on Postgres)

| Layer | Behaviour |
|-------|-----------|
| **Storage** | JSONB `payload` (client fields) **plus** denormalized `locality_key` and `location` (`extensions.geography`) on upsert. |
| **List query** | `SqlOrderIntentStore.listForDashboard()` — SQL `WHERE` with `updated_at`, `extensions.ST_DWithin`, or `locality_key`. Service **fails at startup** if `location` column or spatial extension is missing. |
| **Tests** | File `OrderIntentStore` mirrors list rules in memory (no database); not used in production. |
| **Initiator** (limited dashboard) | Default time window from `DONOR_NEIGHBOURHOOD_WINDOW_HOURS`; without browser location → own rows only in that window. |
| **Coordinator** | Full history by default; optional `?since=…`, `?near_lat=&near_lng=`, `?locality_key=` hit the same SQL predicates. |

### Existing databases (created before spatial columns in schema.sql)

Run [schema-postgis-migration.sql](./schema-postgis-migration.sql) or [schema-postgis-move-to-extensions.sql](./schema-postgis-move-to-extensions.sql) in Supabase SQL Editor, or `npm run db:backfill-order-intent-geo` from `sharingbridge-integration-service` with `DATABASE_URL` set. Integration-service will not start until `order_intents.location` exists, spatial queries work, and **`GIS_SCHEMA`** is set (e.g. `extensions`).

### How the app sees the database (security model)

| Client | DB access? | Enforcement |
|--------|------------|-------------|
| Web / mobile | **No** — HTTPS to user-service / integration-service only | JWT + route handlers in Node |
| integration-service / user-service | **Yes** — `pg` pool via `DATABASE_URL` | Server-side SQL; coordinator vs initiator filters in application code |
| Supabase REST (anon / authenticated) | **Not used** by SharingBridge apps today | N/A |

**RLS is not the current security layer.** Row-level security on `public` tables only matters if you expose those tables through Supabase’s auto-generated API (PostgREST) with anon/authenticated keys. We do not: clients never hold database credentials or Supabase API keys for data access.

**What fixes Supabase lint 0014:** move the PostGIS **extension** out of `public` into **`extensions`**, then `REVOKE` that schema from `anon` and `authenticated`. That removes PostGIS functions from the REST API surface. It is **not** RLS — it is schema isolation for extension objects.

**If you later add Supabase client reads** on `public.order_intents`, enable RLS there separately. Until then, protecting app data means keeping `DATABASE_URL` server-only and not publishing anon keys against those tables.

### What `public` means (not “public on the internet”)

In PostgreSQL, **`public` is a schema name** — a namespace for tables, like a folder. It is the default place new tables go if you do not specify another schema. It does **not** mean “anyone on the internet can read your data.”

```text
  End user (browser / app)
        │  HTTPS + JWT only
        ▼
  user-service / integration-service
        │  DATABASE_URL (server secret)
        │  SQL:  SELECT … FROM order_intents     ──► resolves to public.order_intents
        │        SELECT … extensions.ST_DWithin(…)   ──► spatial functions in extensions
        ▼
  PostgreSQL
        ├── public          ← users, order_intents, seeker_demands, …
        └── extensions          ← spatial extension objects only (not your rows)
```

**How table names resolve in app code**

| SQL in Node | Actual object |
|-------------|----------------|
| `FROM order_intents` | `public.order_intents` |
| `FROM users` | `public.users` |
| `extensions.ST_DWithin(…)` | function in `extensions` (via `GIS_SCHEMA` / `geoSql.js`) |
| `location` column type | `extensions.geography` (defined in DDL) |

No `search_path` trick — table schema is implicit Postgres default; spatial schema is explicit in code.

**Who can reach `public` tables**

| Actor | Can query `public.order_intents`? | Today |
|-------|-----------------------------------|--------|
| Mobile / web client | **No** | No DB credentials; calls APIs only |
| integration-service / user-service | **Yes** | Holds `DATABASE_URL`; runs all SQL |
| Supabase REST (`anon` / `authenticated` keys) | **Could**, if you used those keys | **We do not** — apps never ship anon key for data |
| Random internet user | **No** | No route to Postgres without `DATABASE_URL` |

**Why “public” can still feel worrying on Supabase**

Supabase’s hosted product **can** auto-expose tables in the `public` schema through its REST API when someone uses the anon key. That is a **Supabase product behaviour**, not Postgres making your data world-readable.

SharingBridge’s model avoids that path: clients talk to Render APIs; only the server has `DATABASE_URL`. Row filtering (initiator sees own rows + neighbourhood; coordinator sees scoped lists) happens in **application SQL**, not RLS.

**Optional hardening later** (not required for current architecture):

- Move app tables from `public` to e.g. `sb_app` and qualify SQL — cosmetic + slightly clearer separation
- `REVOKE ALL ON ALL TABLES IN SCHEMA public FROM anon, authenticated` on Supabase
- Enable **RLS** on `public` tables if you ever add Supabase client reads

For build phase, the practical boundary is: **server-only `DATABASE_URL` + JWT APIs**. The `public` schema name is normal Postgres convention, not an exposure decision by itself.

**Explicit schema in env:** integration-service **requires** **`GIS_SCHEMA`** (e.g. `extensions` on Supabase) — no code default; startup fails if unset. See [environment-variables.md](./environment-variables.md).

### Supabase lint: PostGIS in `public` (recommended during build)

Supabase lint **0014** warns when `postgis` is installed in `public`, exposing PostGIS functions on the auto-generated REST API. **Fix properly now** (build phase), not by ignoring the lint:

| Name | What it is | Can you rename? |
|------|------------|-----------------|
| **`extensions`** | Supabase convention for installed extensions (PostGIS, etc.) | **Yes** — set `GIS_SCHEMA=extensions` in integration-service env |
| **`postgres`** in `DATABASE_URL` (`…/postgres`) | Default **database name** on every Supabase project | **No** on hosted Supabase — platform default |
| **`postgres.[ref]`** in the username | Supabase **role** prefix, not your DB name | No — part of the connection URI |
| **Project name** (e.g. `sharingbridge`) | Identifies your project in the dashboard | Yes — set when creating the project |
| **Local dev DB** | [local-postgres-create-database.sql](./local-postgres-create-database.sql) | Already **`sharingbridge`** — good |

**Greenfield:** [schema-spatial-bootstrap.sql](./schema-spatial-bootstrap.sql) installs the spatial extension into **`extensions`** and revokes `anon` / `authenticated` access; [schema.sql](./schema.sql) creates app tables with geo columns.

**Existing Supabase project** (postgis already in `public`): run [schema-postgis-move-to-extensions.sql](./schema-postgis-move-to-extensions.sql) once, redeploy integration-service. PostGIS 2.3+ cannot use `ALTER EXTENSION … SET SCHEMA`; that script drops/recreates the extension in `extensions` and backfills from `payload` JSONB.

**Exposure model:** Web/mobile talk to **integration-service** with JWT; only the server holds `DATABASE_URL`. Moving PostGIS to `extensions` + revoking REST roles from that schema keeps PostGIS off the Supabase API surface. App tables remain in **`public`** — enable RLS on those only if you query them from the Supabase client.

### Coordinator map UI (later)

List filtering is already in SQL. A coordinator **map** (pins, bbox) is a web-client slice on the same query params — see [Future_Extensions.md](../design/Future_Extensions.md) § A.5.

---

## Future order fields

See [Future_Extensions.md](../design/Future_Extensions.md).

---

## See also

- [backend-render.md](./backend-render.md) — deploy APIs on Render (not the database)
- [authentication.md](./authentication.md) — JWT, roles, secrets
- [google-auth-setup.md](./google-auth-setup.md) — Google OAuth
