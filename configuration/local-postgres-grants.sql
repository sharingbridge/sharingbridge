-- Run as superuser (postgres) on database "sharingbridge" after schema.sql.
-- Fixes: permission denied for table users (SQL state 42501) when using
-- DATABASE_URL as user "sharingbridge".

GRANT USAGE ON SCHEMA public TO sharingbridge;

GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO sharingbridge;

GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO sharingbridge;

ALTER DEFAULT PRIVILEGES IN SCHEMA public
  GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO sharingbridge;

ALTER DEFAULT PRIVILEGES IN SCHEMA public
  GRANT USAGE, SELECT ON SEQUENCES TO sharingbridge;
