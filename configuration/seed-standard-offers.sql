-- Standard menu catalog keyed by hierarchical locality_key: {country}:{region}:{postal}
-- Examples:
--   IN:TN:600115 (Chennai Sholinganallur near 12.9427, 80.2379)
--   US:CA:95630  (Folsom, California — Lembi Park / 95630)
-- Run order: configuration/database-setup-sequence.md
--   M3 seed (this file) after M2; run M3a currency migration before or with this seed.
-- Clear old GPS-bucket rows first: reset-marketplace-data.sql
-- price_inr = catalog amount; currency = ISO 4217 for that row (source of truth for UI).
-- After upsert, enforce NOT NULL so every offer has an explicit currency.

DELETE FROM standard_offers
WHERE locality_key LIKE '%,%'
   OR standard_offer_id LIKE '%legacy-grid%';

INSERT INTO standard_offers (
  standard_offer_id, locality_key, menu_label, price_inr, currency, created_at, updated_at
) VALUES
  (
    'so-breakfast-light',
    'IN:TN:600115',
    'Light breakfast (idli / pongal)',
    45,
    'INR',
    NOW(),
    NOW()
  ),
  (
    'so-breakfast-full',
    'IN:TN:600115',
    'Full breakfast (combo meal)',
    80,
    'INR',
    NOW(),
    NOW()
  ),
  (
    'so-lunch-full',
    'IN:TN:600115',
    'Full course lunch (veg meals)',
    120,
    'INR',
    NOW(),
    NOW()
  ),
  (
    'so-dinner-light',
    'IN:TN:600115',
    'Light dinner (chapati / rice portion)',
    55,
    'INR',
    NOW(),
    NOW()
  ),
  (
    'so-lunch-full-state',
    'IN:TN',
    'Full course lunch (state default)',
    110,
    'INR',
    NOW(),
    NOW()
  ),
  (
    'so-us-ca-95630-lunch',
    'US:CA:95630',
    'Standard lunch (sandwich / bowl)',
    12,
    'USD',
    NOW(),
    NOW()
  ),
  (
    'so-us-ca-95630-dinner',
    'US:CA:95630',
    'Standard dinner (hot meal)',
    15,
    'USD',
    NOW(),
    NOW()
  ),
  (
    'so-us-ca-lunch-default',
    'US:CA',
    'California default lunch',
    12,
    'USD',
    NOW(),
    NOW()
  )
ON CONFLICT (standard_offer_id) DO UPDATE SET
  locality_key = EXCLUDED.locality_key,
  menu_label = EXCLUDED.menu_label,
  price_inr = EXCLUDED.price_inr,
  currency = EXCLUDED.currency,
  updated_at = EXCLUDED.updated_at;

ALTER TABLE standard_offers
  ALTER COLUMN currency SET NOT NULL;
