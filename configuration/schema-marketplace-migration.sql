-- Phase F–G marketplace tables (pledges, vendor bids, standard offers, demand windows).
-- Run order: configuration/database-setup-sequence.md (step M1, after schema.sql / seeker_demands).

CREATE TABLE IF NOT EXISTS standard_offers (
  standard_offer_id  TEXT PRIMARY KEY,
  locality_key       TEXT NOT NULL,
  menu_label         TEXT NOT NULL,
  price_inr          INTEGER,
  created_at         TIMESTAMPTZ NOT NULL,
  updated_at         TIMESTAMPTZ NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_standard_offers_locality
  ON standard_offers (locality_key);

CREATE TABLE IF NOT EXISTS demand_windows (
  demand_window_id   TEXT PRIMARY KEY,
  locality_key       TEXT NOT NULL,
  starts_at          TIMESTAMPTZ NOT NULL,
  ends_at            TIMESTAMPTZ NOT NULL,
  status             TEXT NOT NULL DEFAULT 'open'
    CHECK (status IN ('open', 'closed', 'allocated')),
  created_at         TIMESTAMPTZ NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_demand_windows_locality_starts
  ON demand_windows (locality_key, starts_at DESC);

CREATE TABLE IF NOT EXISTS meal_pledges (
  pledge_id            TEXT PRIMARY KEY,
  pledged_by_user_id   TEXT NOT NULL REFERENCES users(id),
  demand_window_id     TEXT REFERENCES demand_windows(demand_window_id),
  locality_key         TEXT NOT NULL,
  standard_offer_id    TEXT REFERENCES standard_offers(standard_offer_id),
  meal_units           INTEGER NOT NULL CHECK (meal_units >= 1 AND meal_units <= 50),
  status               TEXT NOT NULL DEFAULT 'pledged'
    CHECK (status IN ('pledged', 'assigned', 'paid', 'cancelled')),
  created_at           TIMESTAMPTZ NOT NULL,
  updated_at           TIMESTAMPTZ NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_meal_pledges_locality
  ON meal_pledges (locality_key, updated_at DESC);

CREATE TABLE IF NOT EXISTS vendor_bids (
  vendor_bid_id          TEXT PRIMARY KEY,
  submitted_by_user_id   TEXT NOT NULL REFERENCES users(id),
  demand_window_id       TEXT REFERENCES demand_windows(demand_window_id),
  locality_key           TEXT NOT NULL,
  standard_offer_id      TEXT REFERENCES standard_offers(standard_offer_id),
  vendor_name            TEXT NOT NULL,
  portions               INTEGER NOT NULL CHECK (portions >= 1 AND portions <= 500),
  notes                  TEXT,
  status                 TEXT NOT NULL DEFAULT 'submitted'
    CHECK (status IN ('submitted', 'accepted', 'rejected', 'withdrawn')),
  created_at             TIMESTAMPTZ NOT NULL,
  updated_at             TIMESTAMPTZ NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_vendor_bids_locality
  ON vendor_bids (locality_key, updated_at DESC);
