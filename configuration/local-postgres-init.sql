-- Canonical local bootstrap (Option A Step A5 in database.md).
-- Run as superuser (postgres) in pgAdmin or psql. NOT for Supabase or Docker.
-- Next: run schema.sql on database "sharingbridge".
-- If role or database already exists, ignore the error and continue to schema.sql.

DO $$
BEGIN
  IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'sharingbridge') THEN
    CREATE ROLE sharingbridge WITH LOGIN PASSWORD 'sharingbridge';
  END IF;
END
$$;

CREATE DATABASE sharingbridge OWNER sharingbridge;
