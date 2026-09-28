-- Add ISO 4217 currency on standard_offers (amount stays in price_inr column).
-- Currency values come from seed / inserts only — no locality→currency mapping here.
-- Run order: M3a (this file) then re-run M3 seed-standard-offers.sql.

ALTER TABLE standard_offers
  ADD COLUMN IF NOT EXISTS currency TEXT;

ALTER TABLE standard_offers
  ALTER COLUMN currency DROP DEFAULT;
