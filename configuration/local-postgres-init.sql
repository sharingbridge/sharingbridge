-- Step 1 of 2 — local bootstrap (database.md Option A Step A5).
-- pgAdmin: Query Tool on database "postgres" → open this file → Execute.
-- Then run local-postgres-create-database.sql (Step 2; see that file for pgAdmin note).

DO $$
BEGIN
  IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'sharingbridge') THEN
    CREATE ROLE sharingbridge WITH LOGIN PASSWORD 'sharingbridge';
  END IF;
END
$$;
