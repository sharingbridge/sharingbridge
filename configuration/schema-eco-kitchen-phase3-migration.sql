-- Eco Kitchen Phase 3 — order codes, initiation routes, consent timestamps.
-- Run after marketplace M1–M3: configuration/database-setup-sequence.md

ALTER TABLE order_intents
  ADD COLUMN IF NOT EXISTS order_code TEXT,
  ADD COLUMN IF NOT EXISTS initiation_route TEXT NOT NULL DEFAULT 'direct_order'
    CHECK (initiation_route IN (
      'direct_order',
      'eco_kitchen_self_pay',
      'eco_kitchen_pledge'
    ));

CREATE UNIQUE INDEX IF NOT EXISTS idx_order_intents_order_code
  ON order_intents (order_code)
  WHERE order_code IS NOT NULL AND order_code <> '';

ALTER TABLE seeker_demands
  ADD COLUMN IF NOT EXISTS order_code TEXT,
  ADD COLUMN IF NOT EXISTS initiation_route TEXT NOT NULL DEFAULT 'eco_kitchen_pledge'
    CHECK (initiation_route IN (
      'direct_order',
      'eco_kitchen_self_pay',
      'eco_kitchen_pledge'
    )),
  ADD COLUMN IF NOT EXISTS initiator_email_share_consent_at TIMESTAMPTZ;

CREATE UNIQUE INDEX IF NOT EXISTS idx_seeker_demands_order_code
  ON seeker_demands (order_code)
  WHERE order_code IS NOT NULL AND order_code <> '';

ALTER TABLE meal_pledges
  ADD COLUMN IF NOT EXISTS email_share_consent_at TIMESTAMPTZ;

ALTER TABLE vendor_bids
  ADD COLUMN IF NOT EXISTS email_share_consent_at TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS seeker_demand_id TEXT REFERENCES seeker_demands(seeker_demand_id),
  ADD COLUMN IF NOT EXISTS order_code TEXT,
  ADD COLUMN IF NOT EXISTS commitment_status TEXT NOT NULL DEFAULT 'submitted'
    CHECK (commitment_status IN ('submitted', 'committed', 'withdrawn'));

CREATE INDEX IF NOT EXISTS idx_vendor_bids_order_code
  ON vendor_bids (order_code)
  WHERE order_code IS NOT NULL AND order_code <> '';
