-- One-time spatial extension bootstrap (greenfield step 1a).
-- Vendor-specific extension name appears here only — not in schema.sql.
-- Must run before schema.sql (tables reference sb_gis.geography).
-- Name must match integration-service GIS_SCHEMA (default sb_gis).

CREATE SCHEMA IF NOT EXISTS sb_gis;
CREATE EXTENSION IF NOT EXISTS postgis WITH SCHEMA sb_gis;

REVOKE ALL ON SCHEMA sb_gis FROM PUBLIC;

DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'anon') THEN
    EXECUTE 'REVOKE ALL ON SCHEMA sb_gis FROM anon';
  END IF;
  IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'authenticated') THEN
    EXECUTE 'REVOKE ALL ON SCHEMA sb_gis FROM authenticated';
  END IF;
  IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'sharingbridge') THEN
    EXECUTE 'GRANT USAGE ON SCHEMA sb_gis TO sharingbridge';
  END IF;
END
$$;
