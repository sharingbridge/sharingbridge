-- One-time pilot catalog for Chennai GPS buckets used in field testing.
-- Run order: configuration/database-setup-sequence.md (step M3, after wire migration).
-- Future: chef advisors maintain offers via admin UI; this seed is for MVP only.

INSERT INTO standard_offers (
  standard_offer_id, locality_key, menu_label, price_inr, created_at, updated_at
) VALUES
  (
    'so-breakfast-light',
    '12.936,80.236',
    'Light breakfast (idli / pongal)',
    45,
    NOW(),
    NOW()
  ),
  (
    'so-breakfast-full',
    '12.936,80.236',
    'Full breakfast (combo meal)',
    80,
    NOW(),
    NOW()
  ),
  (
    'so-lunch-full',
    '12.936,80.236',
    'Full course lunch (veg meals)',
    120,
    NOW(),
    NOW()
  ),
  (
    'so-dinner-light',
    '12.936,80.236',
    'Light dinner (chapati / rice portion)',
    55,
    NOW(),
    NOW()
  ),
  (
    'so-breakfast-light-legacy-grid',
    '12.94,80.24',
    'Light breakfast (idli / pongal)',
    45,
    NOW(),
    NOW()
  ),
  (
    'so-lunch-full-legacy-grid',
    '12.94,80.24',
    'Full course lunch (veg meals)',
    120,
    NOW(),
    NOW()
  ),
  (
    'so-dinner-light-legacy-grid',
    '12.94,80.24',
    'Light dinner (chapati / rice portion)',
    55,
    NOW(),
    NOW()
  )
ON CONFLICT (standard_offer_id) DO UPDATE SET
  locality_key = EXCLUDED.locality_key,
  menu_label = EXCLUDED.menu_label,
  price_inr = EXCLUDED.price_inr,
  updated_at = EXCLUDED.updated_at;
