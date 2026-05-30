-- Step 2 of 2 — run AFTER local-postgres-init.sql
--
-- pgAdmin: CREATE DATABASE cannot run inside a transaction.
--   • Open a NEW Query Tool (still connected as postgres), OR
--   • Toolbar: enable "Auto-commit" (commit icon), then Execute this file only.
-- GUI alternative: Servers → your server → Databases → right-click → Create →
--   Database: sharingbridge, Owner: sharingbridge
--
-- psql: this file alone is fine (psql auto-commits DDL).

CREATE DATABASE sharingbridge OWNER sharingbridge;
