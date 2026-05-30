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
