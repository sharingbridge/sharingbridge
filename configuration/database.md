# Database configuration (PostgreSQL)

SharingBridge is moving **users, roles, donor presets, and order intents** from JSON files on disk to **PostgreSQL**. There is **no** runtime fallback to files after cutover — import JSON once, then the database is the only source of truth.

**Related:** [authentication.md](./authentication.md) (JWT + roles), [backend-render.md](./backend-render.md) (Render services), [e2e-deployment-sequence.md](./e2e-deployment-sequence.md).

---

## Status

| Data | Today (file) | Target (Postgres) |
|------|----------------|-------------------|
| Users, Google mapping | `user-service/data/user-service-store.json` | `users` |
| Coordinator allowlist | `data/coordinators.json` + `COORDINATOR_EMAILS` | `user_roles` |
| Donor presets | same JSON store | `donor_presets` |
| Order intents | `integration-service/data/order-intents.json` | `order_intents` |
| Integration preferences (local mode) | `data/preferences.json` | unchanged until migrated separately |

Services require **`DATABASE_URL`** once the DB migration is deployed. Until then, keep using file-backed stores and the older env vars.

---

## Architecture

- **One PostgreSQL database** for MVP (local Docker or Render Postgres).
- **user-service** and **integration-service** each get the same **`DATABASE_URL`** (same DB, different tables).
- **ai-orchestration** does not use this database for MVP.
- **Indexes:** `PRIMARY KEY` and `UNIQUE` constraints create indexes automatically. Extra `CREATE INDEX` statements below speed up list/sort queries (see § Indexes).

---

## Local PostgreSQL (development)

### Option A — Docker (recommended)

```powershell
docker run -d --name sharingbridge-pg `
  -e POSTGRES_USER=sharingbridge `
  -e POSTGRES_PASSWORD=sharingbridge `
  -e POSTGRES_DB=sharingbridge `
  -p 5432:5432 `
  postgres:16-alpine
```

Connection string (both Node services):

```env
DATABASE_URL=postgresql://sharingbridge:sharingbridge@localhost:5432/sharingbridge
```

### Option B — installed Postgres

Create a database and user, then set `DATABASE_URL` to match your host, port, user, password, and database name.

### Apply schema

Run the SQL in § Schema once against the empty database (migration tooling or `psql`):

```powershell
# Example if psql is on PATH:
psql "postgresql://sharingbridge:sharingbridge@localhost:5432/sharingbridge" -f path\to\schema.sql
```

Copy § Schema into `sharingbridge-user-service/scripts/schema.sql` when the migration PR lands; until then, keep this doc as the reference.

---

## Render PostgreSQL

1. [Render Dashboard](https://dashboard.render.com/) → **New +** → **PostgreSQL**.
2. Name e.g. `sharingbridge-db`, region aligned with your web services, plan per your needs.
3. After create, open the database → **Connections** → copy **Internal Database URL** (services on Render should use **internal** URL, not the external one).
4. On **sharingbridge-user-service** and **sharingbridge-integration-service** → **Environment** → add:

   | Key | Value |
   |-----|--------|
   | `DATABASE_URL` | Internal Database URL from step 3 |

5. Redeploy **both** services after setting `DATABASE_URL`.

**Do not** rely on `data/*.json` on Render web service disks for production persistence — ephemeral filesystems lose data on redeploy.

Optional: remove persistent disk mounts that only existed for JSON files after DB cutover.

---

## Environment variables

### `sharingbridge-user-service`

| Key | Required (DB mode) | Purpose |
|-----|-------------------|---------|
| `DATABASE_URL` | Yes | Postgres connection string |
| `AUTH_TOKEN_*` | Yes | JWT mint/verify (unchanged) |
| `GOOGLE_CLIENT_ID_WEB` | Yes | Google sign-in |
| `WEB_CORS_ORIGINS` | Yes | Browser CORS |
| `ALLOW_DEV_TOKEN_MINT` | Local only | `false` on Render |

**Deprecated after DB cutover (do not use for new deploys):**

- `COORDINATOR_EMAILS` — seed coordinators via SQL or one-time migration script instead.
- `data/coordinators.json` at runtime — import once, then remove from deploy artifact or stop reading it.

### `sharingbridge-integration-service`

| Key | Required (DB mode) | Purpose |
|-----|-------------------|---------|
| `DATABASE_URL` | Yes | Same database as user-service |
| `AUTH_TOKEN_*` | Yes | Must match user-service |
| `USER_SERVICE_BASE_URL` | Yes | Presets via user-service |
| `WEB_CORS_ORIGINS` | Yes | Browser CORS |
| `PREFERENCES_BACKEND` | Yes | `user_service` when both backends deployed |

`PREFERENCES_BACKEND=local` and `PREFERENCES_DB_PATH` remain for local-only preference JSON until that data is migrated.

---

## Schema

Primary keys and `UNIQUE` constraints create indexes automatically. Run the following once on an empty database.

```sql
-- Users (replaces user-service-store.json users)
CREATE TABLE users (
  id           TEXT PRIMARY KEY,
  google_sub   TEXT UNIQUE,
  email        TEXT UNIQUE,
  name         TEXT,
  picture      TEXT,
  phone        TEXT,
  created_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at   TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Roles (replaces coordinators.json / COORDINATOR_EMAILS + per-user role field)
CREATE TABLE user_roles (
  user_id      TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  role         TEXT NOT NULL CHECK (role IN ('donor', 'coordinator')),
  PRIMARY KEY (user_id, role)
);

-- Donor presets (replaces donorPresets in user-service-store.json)
CREATE TABLE donor_presets (
  user_id       TEXT PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
  presets_json  JSONB NOT NULL DEFAULT '[]'::jsonb,
  updated_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Order intents (replaces order-intents.json)
CREATE TABLE order_intents (
  order_intent_id TEXT PRIMARY KEY,
  user_id         TEXT NOT NULL REFERENCES users(id),
  pack_id         TEXT NOT NULL,
  status          TEXT NOT NULL,
  payload         JSONB NOT NULL,
  created_at      TIMESTAMPTZ NOT NULL,
  updated_at      TIMESTAMPTZ NOT NULL,
  UNIQUE (user_id, pack_id)
);

-- Secondary indexes (list + sort patterns in the API)
-- Donor: WHERE user_id = ? ORDER BY updated_at DESC
CREATE INDEX idx_order_intents_user_updated
  ON order_intents (user_id, updated_at DESC);

-- Coordinator: list all (optional filter by user_id), newest first
CREATE INDEX idx_order_intents_updated
  ON order_intents (updated_at DESC);
```

`payload` holds fields such as `verbal_handover_notes`, `presets_snapshot`, `has_reference_photo`, etc., so the HTTP API shape can stay stable.

---

## Indexes explained

| Index | Type | Why |
|-------|------|-----|
| `PRIMARY KEY` / `UNIQUE` | Automatic | Upsert by `order_intent_id`; one intent per `(user_id, pack_id)` |
| `idx_order_intents_user_updated` | `CREATE INDEX` | Donor history: filter by user, sort by `updated_at` |
| `idx_order_intents_updated` | `CREATE INDEX` | Coordinator dashboard: sort all intents newest first |

`updated_at` is **not** looked up with `WHERE updated_at = ?`; indexes support **sorting** (`ORDER BY updated_at DESC`), not direct fetch by timestamp.

---

## JWT claims (DB-backed roles)

At sign-in, user-service reads **`user_roles`** and mints a token with:

| Claim | Meaning |
|-------|---------|
| `sub` | Internal user id |
| `role` | **Active role for this session** (what integration-service enforces) |
| `roles` | All roles assigned in DB, e.g. `["donor","coordinator"]` |
| `iss`, `aud`, `iat`, `exp` | Unchanged |

**Client rules (unchanged):**

- `client_type: web` → active `role` must be `coordinator` and `coordinator` ∈ `roles`.
- `client_type: android|ios|mobile` → active `role` must be `donor` and `donor` ∈ `roles`.

integration-service continues to authorize using **`role`** (active). It may optionally verify `role` ∈ `roles` when `roles` is present.

---

## Coordinator seeding (replaces file allowlist)

After schema is applied, grant coordinator role by email (example):

```sql
-- After the user has signed in once (row exists in users), or pre-create by email:
INSERT INTO user_roles (user_id, role)
SELECT id, 'coordinator' FROM users WHERE email = 'coord@example.com'
ON CONFLICT DO NOTHING;

-- Ensure every Google user also has donor (typical on first sign-in in app code):
INSERT INTO user_roles (user_id, role)
SELECT id, 'donor' FROM users WHERE email = 'donor@example.com'
ON CONFLICT DO NOTHING;
```

**One-time migration** from existing JSON/env (run before disabling file reads):

1. Export / copy `data/coordinators.json`, `COORDINATOR_EMAILS`, `user-service-store.json`, `order-intents.json`.
2. Run migration script (to be added in service repos) against `DATABASE_URL`.
3. Deploy services that **only** read/write Postgres.
4. Archive JSON files in git as samples only — not loaded at runtime.

---

## Cutover checklist

- [ ] Postgres running (local Docker or Render).
- [ ] Schema applied (§ Schema).
- [ ] `DATABASE_URL` set on **user-service** and **integration-service** (same DB).
- [ ] One-time import from JSON completed.
- [ ] Coordinator emails present in `user_roles`.
- [ ] Smoke: Google sign-in (web + mobile), register order intent, coordinator **Refresh** lists intents.
- [ ] Render: `ALLOW_DEV_TOKEN_MINT=false`; no dependency on `data/` disk for users or order intents.

---

## Troubleshooting

| Symptom | Likely cause | Fix |
|---------|----------------|-----|
| `connection refused` on start | Postgres not running / wrong host | Check Docker or Render DB status; verify `DATABASE_URL` |
| `relation does not exist` | Schema not applied | Run § Schema SQL |
| Empty dashboard after cutover | Import not run or wrong DB | Re-run migration script; confirm both services use same `DATABASE_URL` |
| `403 wrong_client_role` | Missing `coordinator` in `user_roles` | Insert coordinator role for that user's email |
| Data lost on Render redeploy | Still using JSON files on disk | Complete DB migration; set `DATABASE_URL` |

---

## Future order fields (roadmap)

Payment status, delivery status, location, and delivery proof are **not** in the MVP JSON schema today. Planned shapes and phases are documented in [Future_Extensions.md](../design/Future_Extensions.md) (Phase A–B). Schema migrations should extend `order_intents` / `payload` when that work starts.

## See also

- [backend-render.md](./backend-render.md) — web services + Postgres on Render
- [Future_Extensions.md](../design/Future_Extensions.md) — order ops and marketplace roadmap
- [authentication.md](./authentication.md) — JWT and role rules
- [google-auth-setup.md](./google-auth-setup.md) — Google OAuth (coordinator emails → [§ Coordinator seeding](#coordinator-seeding-replaces-file-allowlist) after DB)
