-- FCM device tokens for connection-ready push (Phase 4 notify path).
-- Run after core schema.sql / users table exists.

CREATE TABLE IF NOT EXISTS device_tokens (
  user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  fcm_token TEXT NOT NULL,
  platform TEXT NOT NULL DEFAULT 'android',
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY (user_id, fcm_token)
);

CREATE INDEX IF NOT EXISTS idx_device_tokens_user_id
  ON device_tokens (user_id);
