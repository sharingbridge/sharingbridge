-- Dev reset: clear marketplace + seeker demand data (keeps users and order_intents).
-- Run in Supabase before re-seeding with postal locality_key catalog.

DELETE FROM vendor_bids;
DELETE FROM meal_pledges;
DELETE FROM seeker_demands;
DELETE FROM standard_offers;

-- Optional: wipe order intent geo keys from legacy GPS-bucket era (uncomment if desired)
-- UPDATE order_intents SET locality_key = NULL, location = NULL;
