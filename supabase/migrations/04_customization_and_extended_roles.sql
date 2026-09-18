-- Migration: 04_customization_and_extended_roles.sql
-- Description: Adds role preset naming, custom points, and extended 5-6 player support.

-- 1. Extend rooms table with player count and role customizations
ALTER TABLE rooms ADD COLUMN IF NOT EXISTS max_players INTEGER NOT NULL DEFAULT 4;
ALTER TABLE rooms ADD COLUMN IF NOT EXISTS role_preset TEXT NOT NULL DEFAULT 'classic';
ALTER TABLE rooms ADD COLUMN IF NOT EXISTS role_labels JSONB;
ALTER TABLE rooms ADD COLUMN IF NOT EXISTS role_points JSONB;

-- 2. Extend game_rounds table to track 5th and 6th player roles
ALTER TABLE game_rounds ADD COLUMN IF NOT EXISTS chintaykari_player_id TEXT;
ALTER TABLE game_rounds ADD COLUMN IF NOT EXISTS batpar_player_id TEXT;

-- 3. Comments for documentation
COMMENT ON COLUMN rooms.max_players IS 'Configurable room capacity: 4, 5, or 6 players';
COMMENT ON COLUMN rooms.role_preset IS 'Selected role naming preset (e.g. classic, chor_police_dakat_babu)';
COMMENT ON COLUMN rooms.role_labels IS 'JSON map of custom role labels: {"raja": "Babu", ...}';
COMMENT ON COLUMN rooms.role_points IS 'JSON map of custom point values: {"raja": 1000, ...}';
COMMENT ON COLUMN game_rounds.chintaykari_player_id IS 'Player ID assigned to Chintaykari role (5th player)';
COMMENT ON COLUMN game_rounds.batpar_player_id IS 'Player ID assigned to Batpar role (6th player)';
