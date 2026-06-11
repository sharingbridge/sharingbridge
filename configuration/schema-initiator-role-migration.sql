-- Brownfield: allow initiator role alongside legacy donor (run after schema.sql).
-- See configuration/database-setup-sequence.md

ALTER TABLE user_roles DROP CONSTRAINT IF EXISTS user_roles_role_check;
ALTER TABLE user_roles
  ADD CONSTRAINT user_roles_role_check
  CHECK (role IN ('donor', 'initiator', 'coordinator'));

INSERT INTO user_roles (user_id, role)
SELECT user_id, 'initiator'
FROM user_roles
WHERE role = 'donor'
ON CONFLICT DO NOTHING;
