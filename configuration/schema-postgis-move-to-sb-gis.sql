-- PostGIS out of public — Supabase lint 0014 (build-phase hardening).
-- Run once in Supabase SQL Editor when postgis is still in public.
--
-- Uses schema sb_gis (SharingBridge), not the generic name "extensions".
-- Does NOT move your tables — only PostGIS extension objects.
-- App SQL qualifies sb_gis.* in integration-service (no search_path change).
-- Your DATABASE_URL path stays .../postgres (Supabase default database name).

CREATE SCHEMA IF NOT EXISTS sb_gis;

-- If postgis is already installed in public:
ALTER EXTENSION postgis SET SCHEMA sb_gis;

-- If ALTER fails (some PostGIS versions), use Supabase guide: drop extension,
-- then: CREATE EXTENSION postgis WITH SCHEMA sb_gis;

-- Keep PostGIS internals off the Supabase REST API (anon / authenticated).
REVOKE ALL ON SCHEMA sb_gis FROM PUBLIC;

DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'anon') THEN
    EXECUTE 'REVOKE ALL ON SCHEMA sb_gis FROM anon';
  END IF;
  IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'authenticated') THEN
    EXECUTE 'REVOKE ALL ON SCHEMA sb_gis FROM authenticated';
  END IF;
END
$$;

-- Smoke test (should return t)
SELECT sb_gis.ST_DWithin(
  sb_gis.ST_SetSRID(sb_gis.ST_MakePoint(0, 0), 4326)::sb_gis.geography,
  sb_gis.ST_SetSRID(sb_gis.ST_MakePoint(0, 0), 4326)::sb_gis.geography,
  1
) AS postgis_ok;
