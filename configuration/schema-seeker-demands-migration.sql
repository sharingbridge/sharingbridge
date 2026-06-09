-- Phase C.1 — seeker_demands (rename from demand_signals if present, else create fresh).
-- Run in Supabase SQL editor on existing databases.

-- Upgrade path from earlier demand_signals table
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.tables
    WHERE table_schema = 'public' AND table_name = 'demand_signals'
  ) AND NOT EXISTS (
    SELECT 1 FROM information_schema.tables
    WHERE table_schema = 'public' AND table_name = 'seeker_demands'
  ) THEN
    ALTER TABLE demand_signals RENAME TO seeker_demands;
    ALTER TABLE seeker_demands RENAME COLUMN demand_signal_id TO seeker_demand_id;
    ALTER TABLE seeker_demands RENAME COLUMN user_id TO reported_by_user_id;

    IF EXISTS (
      SELECT 1 FROM pg_indexes WHERE indexname = 'idx_demand_signals_user_updated'
    ) THEN
      ALTER INDEX idx_demand_signals_user_updated
        RENAME TO idx_seeker_demands_reporter_updated;
    END IF;
    IF EXISTS (
      SELECT 1 FROM pg_indexes WHERE indexname = 'idx_demand_signals_updated'
    ) THEN
      ALTER INDEX idx_demand_signals_updated RENAME TO idx_seeker_demands_updated;
    END IF;
    IF EXISTS (
      SELECT 1 FROM pg_indexes WHERE indexname = 'idx_demand_signals_locality_key'
    ) THEN
      ALTER INDEX idx_demand_signals_locality_key
        RENAME TO idx_seeker_demands_locality_key;
    END IF;
    IF EXISTS (
      SELECT 1 FROM pg_indexes WHERE indexname = 'idx_demand_signals_location'
    ) THEN
      ALTER INDEX idx_demand_signals_location RENAME TO idx_seeker_demands_location;
    END IF;

    UPDATE seeker_demands SET status = 'recorded' WHERE status = 'captured';
  END IF;
END $$;

CREATE TABLE IF NOT EXISTS seeker_demands (
  seeker_demand_id     TEXT PRIMARY KEY,
  reported_by_user_id  TEXT NOT NULL REFERENCES users(id),
  status               TEXT NOT NULL DEFAULT 'recorded'
    CHECK (status IN ('recorded', 'aggregated', 'fulfilled', 'cancelled')),
  meal_units           INTEGER NOT NULL DEFAULT 1 CHECK (meal_units >= 1 AND meal_units <= 50),
  payload              JSONB NOT NULL,
  locality_key         TEXT,
  location             geography(POINT, 4326),
  created_at           TIMESTAMPTZ NOT NULL,
  updated_at           TIMESTAMPTZ NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_seeker_demands_reporter_updated
  ON seeker_demands (reported_by_user_id, updated_at DESC);

CREATE INDEX IF NOT EXISTS idx_seeker_demands_updated
  ON seeker_demands (updated_at DESC);

CREATE INDEX IF NOT EXISTS idx_seeker_demands_locality_key
  ON seeker_demands (locality_key)
  WHERE locality_key IS NOT NULL AND locality_key <> '';

CREATE INDEX IF NOT EXISTS idx_seeker_demands_location
  ON seeker_demands USING GIST (location);
