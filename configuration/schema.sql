-- SharingBridge MVP schema — canonical DDL (Supabase SQL Editor, local Postgres, Docker).
-- Run order: configuration/database-setup-sequence.md (greenfield: step 1a then 1).
-- Deep dive: database.md § Tables. Marketplace: M1–M3 in setup sequence.

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

CREATE TABLE user_roles (
  user_id      TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  role         TEXT NOT NULL CHECK (role IN ('donor', 'initiator', 'coordinator')),
  PRIMARY KEY (user_id, role)
);

CREATE TABLE donor_presets (
  user_id       TEXT PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
  presets_json  JSONB NOT NULL DEFAULT '[]'::jsonb,
  updated_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);

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

CREATE INDEX idx_order_intents_user_updated
  ON order_intents (user_id, updated_at DESC);

CREATE INDEX idx_order_intents_updated
  ON order_intents (updated_at DESC);

-- Geospatial list filters (donor neighbourhood + coordinator map queries).
-- Spatial types live in extensions — run schema-spatial-bootstrap.sql first.
-- GIS_SCHEMA env on integration-service is required (e.g. extensions).

ALTER TABLE order_intents
  ADD COLUMN IF NOT EXISTS locality_key TEXT,
  ADD COLUMN IF NOT EXISTS location extensions.geography(POINT, 4326),
  ADD COLUMN IF NOT EXISTS delivered_at TIMESTAMPTZ;

CREATE INDEX IF NOT EXISTS idx_order_intents_location
  ON order_intents USING GIST (location);

CREATE INDEX IF NOT EXISTS idx_order_intents_locality_key
  ON order_intents (locality_key)
  WHERE locality_key IS NOT NULL AND locality_key <> '';

CREATE TABLE photo_artifacts (
  artifact_id           TEXT PRIMARY KEY,
  user_id               TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  photo_type            TEXT NOT NULL CHECK (photo_type IN ('seeker_reference', 'delivery_acknowledgement')),
  cloudinary_public_id  TEXT NOT NULL,
  view_url              TEXT NOT NULL,
  thumbnail_url         TEXT NOT NULL,
  mime_type             TEXT,
  file_size             INTEGER,
  created_at            TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_photo_artifacts_user ON photo_artifacts (user_id);

-- Phase C.1 — seeker demand recorded in the field (aggregated on web Demand tab).
CREATE TABLE seeker_demands (
  seeker_demand_id     TEXT PRIMARY KEY,
  reported_by_user_id  TEXT NOT NULL REFERENCES users(id),
  status               TEXT NOT NULL DEFAULT 'recorded'
    CHECK (status IN ('recorded', 'aggregated', 'fulfilled', 'cancelled')),
  meal_units           INTEGER NOT NULL DEFAULT 1 CHECK (meal_units >= 1 AND meal_units <= 50),
  payload              JSONB NOT NULL,
  locality_key         TEXT,
  location             extensions.geography(POINT, 4326),
  created_at           TIMESTAMPTZ NOT NULL,
  updated_at           TIMESTAMPTZ NOT NULL
);

CREATE INDEX idx_seeker_demands_reporter_updated
  ON seeker_demands (reported_by_user_id, updated_at DESC);

CREATE INDEX idx_seeker_demands_updated
  ON seeker_demands (updated_at DESC);

CREATE INDEX idx_seeker_demands_locality_key
  ON seeker_demands (locality_key)
  WHERE locality_key IS NOT NULL AND locality_key <> '';

CREATE INDEX idx_seeker_demands_location
  ON seeker_demands USING GIST (location);

-- Keep spatial extension internals off Supabase REST roles (see schema-spatial-bootstrap.sql).
