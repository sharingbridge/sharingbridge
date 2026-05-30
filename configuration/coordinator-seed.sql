-- Grant coordinator role in PostgreSQL (run after the user row exists).
-- Typical flow: sign in once on mobile (donor) or web so `users` has a row, then run this in psql/pgAdmin/Supabase SQL Editor.
-- Replace the email with the coordinator's Gmail (same account used for web dashboard Google Sign-In).

INSERT INTO user_roles (user_id, role)
SELECT id, 'coordinator'
FROM users
WHERE lower(email) = lower('your-coordinator@gmail.com')
ON CONFLICT DO NOTHING;
