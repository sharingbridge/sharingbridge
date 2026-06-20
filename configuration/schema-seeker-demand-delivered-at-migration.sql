-- Eco kitchen delivery completion — hide Connection updates after handover.
-- Run after M4 (eco kitchen phase 3): configuration/database-setup-sequence.md

ALTER TABLE seeker_demands
  ADD COLUMN IF NOT EXISTS delivered_at TIMESTAMPTZ;
