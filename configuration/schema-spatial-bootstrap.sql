-- One-time spatial extension bootstrap (greenfield step 1a).
-- Vendor-specific extension name appears here only — not in schema.sql.
-- Must run before schema.sql (tables reference extensions.geography).
-- Name must match integration-service GIS_SCHEMA (required env var, e.g. extensions).

CREATE SCHEMA IF NOT EXISTS extensions;
CREATE EXTENSION IF NOT EXISTS postgis WITH SCHEMA extensions;

REVOKE ALL ON SCHEMA extensions FROM PUBLIC;

DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'anon') THEN
    EXECUTE 'REVOKE ALL ON SCHEMA extensions FROM anon';
  END IF;
  IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'authenticated') THEN
    EXECUTE 'REVOKE ALL ON SCHEMA extensions FROM authenticated';
  END IF;
  IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'sharingbridge') THEN
    EXECUTE 'GRANT USAGE ON SCHEMA extensions TO sharingbridge';
  END IF;
END
$$;
