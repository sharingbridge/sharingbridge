-- SharingBridge MVP schema — canonical DDL (Supabase SQL Editor, local Postgres, Docker).
-- Documented in database.md § Tables.

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
  role         TEXT NOT NULL CHECK (role IN ('donor', 'coordinator')),
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
-- Included in MVP schema; no extra Supabase charge beyond normal Postgres usage.
CREATE EXTENSION IF NOT EXISTS postgis;

ALTER TABLE order_intents
  ADD COLUMN IF NOT EXISTS locality_key TEXT,
  ADD COLUMN IF NOT EXISTS location geography(POINT, 4326),
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
