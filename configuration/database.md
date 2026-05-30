# Database configuration (Supabase PostgreSQL)

SharingBridge stores **users, roles, donor presets, and order intents** in **PostgreSQL**. For production we use **[Supabase](https://supabase.com)** (hosted Postgres). **Render** hosts only the **APIs** (user-service, integration-service); they connect to Supabase via **`DATABASE_URL`**.

There is **no** runtime fallback to JSON files after cutover — import once, then the database is the only source of truth.

**Related:** [authentication.md](./authentication.md) · [backend-render.md](./backend-render.md) (APIs on Render) · [e2e-deployment-sequence.md](./e2e-deployment-sequence.md) · [IMPLEMENTATION_APPROACH.md](../development/IMPLEMENTATION_APPROACH.md) (long-term stack).

---

## Status

| Data | Today (file) | Target (Supabase table) |
|------|----------------|-------------------------|
| Users, Google mapping | `user-service/data/user-service-store.json` | `users` |
| Coordinator allowlist | `data/coordinators.json` + `COORDINATOR_EMAILS` | `user_roles` |
| Donor presets | same JSON store | `donor_presets` |
| Order intents | `integration-service/data/order-intents.json` | `order_intents` |

**Code note:** Node services use **`DATABASE_URL`** only after the DB migration is deployed. Until then, keep file-backed stores. This doc is the reference for **creating Supabase tables now** so you are ready when that code ships.

---

## Architecture (read this once)

```text
  Mobile / Web  ──HTTPS──►  Render (user-service, integration-service)
                                    │
                                    │  DATABASE_URL (Postgres wire protocol)
                                    ▼
                            Supabase (PostgreSQL)
                            tables: users, user_roles, donor_presets, order_intents
```

- **Supabase** = database + SQL Editor + connection strings. **Do not** put Supabase in the mobile or web app.
- **Render** = Node APIs. Set **`DATABASE_URL`** on **both** `sharingbridge-user-service` and `sharingbridge-integration-service` to the **same** Supabase connection string.
- **Do not** use the Supabase **anon** or **service_role** API keys as `DATABASE_URL`. Use the **database connection URI** (see below).

---

## Step 1 — Create a Supabase project

1. Sign in at [supabase.com](https://supabase.com) → **New project**.
2. Pick an organization (personal is fine), name e.g. `sharingbridge`, choose a **region** (prefer one close to your Render services).
3. Set a strong **database password** and save it (password manager). You need it for `DATABASE_URL`.
4. Wait until the project dashboard shows the project as **ready**.

PostGIS is **not** required for the MVP schema below (add later for geo features per [IMPLEMENTATION_APPROACH.md](../development/IMPLEMENTATION_APPROACH.md) if needed).

---

## Step 2 — Create tables in Supabase (SQL Editor)

1. In the Supabase dashboard, open **SQL Editor** (left sidebar).
2. Click **New query**.
3. Open [schema.sql](./schema.sql) from this repo, copy all contents, paste into the query, and **Run** (or Ctrl+Enter).
4. Confirm success — you should see four tables under **Table Editor** (see [§ Tables](#tables)).

**Verify:** **Table Editor** → each table exists with no rows until sign-in / migration.

**Coordinator access (after first web sign-in):** use [§ Coordinator seeding](#coordinator-seeding-replaces-file-allowlist) to insert into `user_roles`, or rely on app code + migration script when DB mode ships.

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
| [local-postgres-init.sql](./local-postgres-init.sql) | **Local Postgres only** (Option A Step A5): creates role + database |
| [schema.sql](./schema.sql) | **Everywhere** (Supabase, local, Docker): creates tables |

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

Open **pgAdmin** (or **SQL Shell / psql** as user `postgres`).

Run [local-postgres-init.sql](./local-postgres-init.sql) (pgAdmin: **Query Tool** → open file → **Execute**, connected as `postgres`). Re-run is safe for the role (`DO` block); if `CREATE DATABASE` errors because the database already exists, continue to Step A6.

**Not used for Supabase or Docker** — those paths only need [schema.sql](./schema.sql) (Docker creates the user/database via container env vars).

#### Step A6 — Create tables

In pgAdmin, connect to database **sharingbridge** → **Query Tool** → open [schema.sql](./schema.sql) → **Execute**.

Or from a terminal (set `PORT` and path to your clone):

```text
set PGPASSWORD=sharingbridge
psql -U sharingbridge -h localhost -p PORT -d sharingbridge -f path/to/sharingbridge/configuration/schema.sql
```

Verify: `\dt` should list `users`, `user_roles`, `donor_presets`, `order_intents`.

#### Step A7 — Configure Node services

In **both** `sharingbridge-user-service/.env` and `sharingbridge-integration-service/.env`:

```env
DATABASE_URL=postgresql://sharingbridge:sharingbridge@localhost:PORT/sharingbridge
```

Example for port **5433**:

```env
DATABASE_URL=postgresql://sharingbridge:sharingbridge@localhost:5433/sharingbridge
```

**Code note:** Services use `DATABASE_URL` only after the DB migration ships; until then JSON file storage still applies at runtime.

---

### Option B — Supabase dev project (no local Postgres)

1. Create a project at [supabase.com](https://supabase.com) (e.g. `sharingbridge-dev`).
2. **SQL Editor** → run [schema.sql](./schema.sql).
3. **Settings → Database** → copy the **connection URI** into both services’ `DATABASE_URL`.

---

### Option C — Docker (only if Docker Desktop is installed)

```text
docker run -d --name sharingbridge-pg -e POSTGRES_USER=sharingbridge -e POSTGRES_PASSWORD=sharingbridge -e POSTGRES_DB=sharingbridge -p 5432:5432 postgres:16-alpine
```

Load schema from your repo clone:

```text
docker exec -i sharingbridge-pg psql -U sharingbridge -d sharingbridge < path/to/sharingbridge/configuration/schema.sql
```

Same `DATABASE_URL` shape as Option A (`localhost` and the published port).

---

## Optional: Render PostgreSQL instead of Supabase

Only if you **do not** want Supabase: Render → **New +** → **PostgreSQL**, copy **Internal Database URL**, set as `DATABASE_URL` on both Node services. Apply [schema.sql](./schema.sql) via SQL or Render’s psql.

**Recommended default for this project:** **Supabase** (aligned with [IMPLEMENTATION_APPROACH.md](../development/IMPLEMENTATION_APPROACH.md)). Render Postgres is optional.

---

## Environment variables (DB mode)

### `sharingbridge-user-service` and `sharingbridge-integration-service`

| Key | Required | Purpose |
|-----|----------|---------|
| `DATABASE_URL` | Yes | Supabase (or local) Postgres URI — **same on both services** |
| `AUTH_TOKEN_*` | Yes | Unchanged |
| `GOOGLE_CLIENT_ID_WEB` | Yes (user-service) | Unchanged |
| `WEB_CORS_ORIGINS` | Yes | Unchanged — browser origin, not Supabase |

**Deprecated after DB cutover:** `COORDINATOR_EMAILS` / runtime `coordinators.json` — use `user_roles` in Supabase instead.

---

## Tables

**Canonical DDL:** [schema.sql](./schema.sql) — run once in Supabase **SQL Editor** (Step 2), local pgAdmin/psql (Option A Step A6), or Docker (Option C). Do not maintain a second copy of the SQL in this doc.

| Table | Replaces (file mode) |
|-------|----------------------|
| `users` | `user-service-store.json` users |
| `user_roles` | `coordinators.json` / `COORDINATOR_EMAILS` |
| `donor_presets` | donor presets in user-service store |
| `order_intents` | `order-intents.json` |

`order_intents.payload` (JSONB) holds `verbal_handover_notes`, `presets_snapshot`, `has_reference_photo`, etc.

Primary keys and `UNIQUE` constraints create indexes automatically; [schema.sql](./schema.sql) adds two indexes on `order_intents` for list queries.

---

## Indexes explained

| Index | Type | Why |
|-------|------|-----|
| `PRIMARY KEY` / `UNIQUE` | Automatic | Upsert by `order_intent_id`; one row per `(user_id, pack_id)` |
| `idx_order_intents_user_updated` | Manual | Donor list: `WHERE user_id` + `ORDER BY updated_at DESC` |
| `idx_order_intents_updated` | Manual | Coordinator list: `ORDER BY updated_at DESC` |

---

## Coordinator seeding (replaces file allowlist)

Run in Supabase **SQL Editor** after the coordinator has signed in once (so `users` has a row), or after migration inserts users:

```sql
INSERT INTO user_roles (user_id, role)
SELECT id, 'coordinator' FROM users WHERE email = 'your-coordinator@gmail.com'
ON CONFLICT DO NOTHING;
```

---

## JWT claims (when DB mode ships)

user-service reads **`user_roles`** and mints `role` (active) + `roles` (array). See [authentication.md](./authentication.md).

---

## Cutover checklist

- [ ] Supabase project created
- [ ] [schema.sql](./schema.sql) run in **SQL Editor** (four tables visible in Table Editor)
- [ ] `DATABASE_URL` set on **both** Render Node services (Supabase URI, not anon key)
- [ ] Both services redeployed
- [ ] One-time JSON import (when migration script exists)
- [ ] Coordinator row in `user_roles`
- [ ] Smoke: Google sign-in, order intent, web **Refresh**

---

## Troubleshooting

| Symptom | Likely cause | Fix |
|---------|----------------|-----|
| `%5C` or broken file link | Windows `d:\...` paths in chat | Open from repo: **Ctrl+P** → `database.md` or `schema.sql` |
| Local install stuck / messy | Old Postgres on 5432, partial install | Uninstall from Apps; pick a free port (e.g. 5433); one Postgres version; see Option A Step A3 |
| `connection refused` (local) | Wrong port in `DATABASE_URL` | Match installer port (`5432` vs `5433`) |
| `connection refused` | Wrong `DATABASE_URL` or password | Re-copy URI from Supabase **Database** settings; redeploy Render |
| `relation does not exist` | Schema not run | Re-run [schema.sql](./schema.sql) in SQL Editor |
| App still uses JSON | DB migration not deployed yet | Expected until code uses `DATABASE_URL` |
| Used anon key as `DATABASE_URL` | Wrong credential type | Use **database URI**, not Project API keys |
| `403 wrong_client_role` | No `coordinator` in `user_roles` | Run coordinator seed SQL |

---

## Future order fields

See [Future_Extensions.md](../design/Future_Extensions.md).

---

## See also

- [backend-render.md](./backend-render.md) — deploy APIs on Render (not the database)
- [authentication.md](./authentication.md) — JWT, roles, secrets
- [google-auth-setup.md](./google-auth-setup.md) — Google OAuth
