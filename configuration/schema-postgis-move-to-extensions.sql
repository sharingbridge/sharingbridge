-- PostGIS out of public — Supabase lint 0014 (build-phase hardening).
-- Run once in Supabase SQL Editor when postgis is still in public.
--
-- Uses schema extensions (Supabase convention for installed extensions).
-- Does NOT move your tables — only PostGIS extension objects.
-- App SQL qualifies extensions.* in integration-service (GIS_SCHEMA, no search_path).
-- Your DATABASE_URL path stays .../postgres (Supabase default database name).

CREATE SCHEMA IF NOT EXISTS extensions;

-- If postgis is already installed in public:
ALTER EXTENSION postgis SET SCHEMA extensions;

-- If ALTER fails (some PostGIS versions), use Supabase guide: drop extension,
-- then: CREATE EXTENSION postgis WITH SCHEMA extensions;

-- Keep PostGIS internals off the Supabase REST API (anon / authenticated).
REVOKE ALL ON SCHEMA extensions FROM PUBLIC;

DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'anon') THEN
    EXECUTE 'REVOKE ALL ON SCHEMA extensions FROM anon';
  END IF;
  IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'authenticated') THEN
    EXECUTE 'REVOKE ALL ON SCHEMA extensions FROM authenticated';
  END IF;
END
$$;

-- Smoke test (should return t)
SELECT extensions.ST_DWithin(
  extensions.ST_SetSRID(extensions.ST_MakePoint(0, 0), 4326)::extensions.geography,
  extensions.ST_SetSRID(extensions.ST_MakePoint(0, 0), 4326)::extensions.geography,
  1
) AS postgis_ok;
