-- Idempotent geo migration for databases created before PostGIS was added to schema.sql.
-- New projects: geo DDL is already in schema.sql — run this only to backfill existing rows.
-- See database.md § Geospatial data and PostGIS.

CREATE EXTENSION IF NOT EXISTS postgis;

ALTER TABLE order_intents
  ADD COLUMN IF NOT EXISTS locality_key TEXT,
  ADD COLUMN IF NOT EXISTS location geography(POINT, 4326);

-- Backfill from JSONB payload (lat/lng stored at registration).
UPDATE order_intents
SET
  locality_key = COALESCE(NULLIF(TRIM(payload->>'locality_key'), ''), locality_key),
  location = CASE
    WHEN (payload->>'location_lat') ~ '^-?[0-9]+(\.[0-9]+)?$'
     AND (payload->>'location_lng') ~ '^-?[0-9]+(\.[0-9]+)?$'
    THEN ST_SetSRID(
      ST_MakePoint(
        (payload->>'location_lng')::double precision,
        (payload->>'location_lat')::double precision
      ),
      4326
    )::geography
    ELSE location
  END
WHERE location IS NULL
  AND payload ? 'location_lat'
  AND payload ? 'location_lng';

CREATE INDEX IF NOT EXISTS idx_order_intents_location
  ON order_intents USING GIST (location);

CREATE INDEX IF NOT EXISTS idx_order_intents_locality_key
  ON order_intents (locality_key)
  WHERE locality_key IS NOT NULL AND locality_key <> '';
