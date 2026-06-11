-- Standard menu catalog keyed by hierarchical locality_key: {country}:{region}:{postal}
-- Example: IN:TN:600115 (Chennai Sholinganallur pilot near 12.9427, 80.2379)
-- Run order: configuration/database-setup-sequence.md (step M3, after wire migration).
-- Clear old GPS-bucket rows first: reset-marketplace-data.sql

DELETE FROM standard_offers
WHERE locality_key LIKE '%,%'
   OR standard_offer_id LIKE '%legacy-grid%';

INSERT INTO standard_offers (
  standard_offer_id, locality_key, menu_label, price_inr, created_at, updated_at
) VALUES
  (
    'so-breakfast-light',
    'IN:TN:600115',
    'Light breakfast (idli / pongal)',
    45,
    NOW(),
    NOW()
  ),
  (
    'so-breakfast-full',
    'IN:TN:600115',
    'Full breakfast (combo meal)',
    80,
    NOW(),
    NOW()
  ),
  (
    'so-lunch-full',
    'IN:TN:600115',
    'Full course lunch (veg meals)',
    120,
    NOW(),
    NOW()
  ),
  (
    'so-dinner-light',
    'IN:TN:600115',
    'Light dinner (chapati / rice portion)',
    55,
    NOW(),
    NOW()
  ),
  (
    'so-lunch-full-state',
    'IN:TN',
    'Full course lunch (state default)',
    110,
    NOW(),
    NOW()
  )
ON CONFLICT (standard_offer_id) DO UPDATE SET
  locality_key = EXCLUDED.locality_key,
  menu_label = EXCLUDED.menu_label,
  price_inr = EXCLUDED.price_inr,
  updated_at = EXCLUDED.updated_at;
