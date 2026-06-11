-- Wire standard_offer_id on pledges and vendor bids.
-- Run order: configuration/database-setup-sequence.md (step M2, after schema-marketplace-migration.sql).
-- Seeker demand stores standard_offer_id in payload JSONB — no seeker_demands column change.

ALTER TABLE meal_pledges
  ADD COLUMN IF NOT EXISTS standard_offer_id TEXT REFERENCES standard_offers(standard_offer_id);

ALTER TABLE vendor_bids
  ADD COLUMN IF NOT EXISTS standard_offer_id TEXT REFERENCES standard_offers(standard_offer_id);

CREATE INDEX IF NOT EXISTS idx_meal_pledges_offer
  ON meal_pledges (locality_key, standard_offer_id, updated_at DESC);

CREATE INDEX IF NOT EXISTS idx_vendor_bids_offer
  ON vendor_bids (locality_key, standard_offer_id, updated_at DESC);
