-- Add delivered_at for dashboard column (nullable until delivery-partner flow sets it).
-- Run once on DBs created from schema.sql before this column was added.
-- See development/PRODUCT_ROADMAP.md and database.md.

ALTER TABLE order_intents
  ADD COLUMN IF NOT EXISTS delivered_at TIMESTAMPTZ;
