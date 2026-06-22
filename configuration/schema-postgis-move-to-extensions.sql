-- PostGIS out of public → extensions (Supabase lint 0014).
-- Run once when postgis is installed in public.
--
-- PostGIS 2.3+ does NOT support:  ALTER EXTENSION postgis SET SCHEMA extensions;
-- (error 0A000: extension "postgis" does not support SET SCHEMA)
--
-- This script: drop geo columns → drop extension → recreate in extensions →
-- re-add columns → backfill from payload JSONB (lat/lng preserved there).
-- Safe for build-phase / test data. For production with heavy geo-only data,
-- take a backup first (Supabase dashboard or pg_dump).
--
-- App: integration-service GIS_SCHEMA=extensions (default). Redeploy after this runs.
-- Alternative: Supabase Dashboard → Database → Extensions → disable postgis →
-- enable again and choose "Create a new schema" → extensions, then run only
-- the "Re-add columns" + backfill section below if columns were dropped.

CREATE SCHEMA IF NOT EXISTS extensions;

-- ---------------------------------------------------------------------------
-- 1. Drop app geo columns (payload JSONB still has location_lat / location_lng)
-- ---------------------------------------------------------------------------
DROP INDEX IF EXISTS idx_order_intents_location;
DROP INDEX IF EXISTS idx_seeker_demands_location;

ALTER TABLE order_intents
  DROP COLUMN IF EXISTS location;

ALTER TABLE seeker_demands
  DROP COLUMN IF EXISTS location;

-- ---------------------------------------------------------------------------
-- 2. Drop postgis from public and install into extensions
-- ---------------------------------------------------------------------------
DROP EXTENSION IF EXISTS postgis CASCADE;

CREATE EXTENSION postgis WITH SCHEMA extensions;

-- ---------------------------------------------------------------------------
-- 3. Re-add columns (extensions.geography — matches schema.sql)
-- ---------------------------------------------------------------------------
ALTER TABLE order_intents
  ADD COLUMN IF NOT EXISTS locality_key TEXT,
  ADD COLUMN IF NOT EXISTS location extensions.geography(POINT, 4326);

ALTER TABLE seeker_demands
  ADD COLUMN IF NOT EXISTS locality_key TEXT,
  ADD COLUMN IF NOT EXISTS location extensions.geography(POINT, 4326);

-- ---------------------------------------------------------------------------
-- 4. Backfill from payload
-- ---------------------------------------------------------------------------
UPDATE order_intents
SET
  locality_key = COALESCE(
    NULLIF(TRIM(locality_key), ''),
    NULLIF(TRIM(payload->>'locality_key'), '')
  ),
  location = CASE
    WHEN (payload->>'location_lat') ~ '^-?[0-9]+(\.[0-9]+)?$'
     AND (payload->>'location_lng') ~ '^-?[0-9]+(\.[0-9]+)?$'
    THEN extensions.ST_SetSRID(
      extensions.ST_MakePoint(
        (payload->>'location_lng')::double precision,
        (payload->>'location_lat')::double precision
      ),
      4326
    )::extensions.geography
    ELSE NULL
  END
WHERE location IS NULL
  AND payload ? 'location_lat'
  AND payload ? 'location_lng';

UPDATE seeker_demands
SET
  locality_key = COALESCE(
    NULLIF(TRIM(locality_key), ''),
    NULLIF(TRIM(payload->>'locality_key'), '')
  ),
  location = CASE
    WHEN (payload->>'location_lat') ~ '^-?[0-9]+(\.[0-9]+)?$'
     AND (payload->>'location_lng') ~ '^-?[0-9]+(\.[0-9]+)?$'
    THEN extensions.ST_SetSRID(
      extensions.ST_MakePoint(
        (payload->>'location_lng')::double precision,
        (payload->>'location_lat')::double precision
      ),
      4326
    )::extensions.geography
    ELSE NULL
  END
WHERE location IS NULL
  AND payload ? 'location_lat'
  AND payload ? 'location_lng';

CREATE INDEX IF NOT EXISTS idx_order_intents_location
  ON order_intents USING GIST (location);

CREATE INDEX IF NOT EXISTS idx_order_intents_locality_key
  ON order_intents (locality_key)
  WHERE locality_key IS NOT NULL AND locality_key <> '';

CREATE INDEX IF NOT EXISTS idx_seeker_demands_location
  ON seeker_demands USING GIST (location);

CREATE INDEX IF NOT EXISTS idx_seeker_demands_locality_key
  ON seeker_demands (locality_key)
  WHERE locality_key IS NOT NULL AND locality_key <> '';

-- ---------------------------------------------------------------------------
-- 5. Keep extension objects off Supabase REST API
-- ---------------------------------------------------------------------------
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
