-- Battle Castles Database Initialization Script
-- This script creates the necessary tables and indexes for the game

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Create players table
CREATE TABLE IF NOT EXISTS players (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    username VARCHAR(50) UNIQUE NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    display_name VARCHAR(100),
    skill_rating INTEGER DEFAULT 1000,
    total_games INTEGER DEFAULT 0,
    wins INTEGER DEFAULT 0,
    losses INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    last_login TIMESTAMP WITH TIME ZONE,
    is_active BOOLEAN DEFAULT TRUE,
    is_banned BOOLEAN DEFAULT FALSE
);

-- Create game_sessions table
CREATE TABLE IF NOT EXISTS game_sessions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    room_id VARCHAR(100) UNIQUE NOT NULL,
    player1_id UUID REFERENCES players(id) ON DELETE SET NULL,
    player2_id UUID REFERENCES players(id) ON DELETE SET NULL,
    winner_id UUID REFERENCES players(id) ON DELETE SET NULL,
    game_mode VARCHAR(50) DEFAULT 'ranked',
    status VARCHAR(20) DEFAULT 'pending',
    started_at TIMESTAMP WITH TIME ZONE,
    ended_at TIMESTAMP WITH TIME ZONE,
    duration_seconds INTEGER,
    player1_final_score INTEGER,
    player2_final_score INTEGER,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Create player_stats table
CREATE TABLE IF NOT EXISTS player_stats (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    player_id UUID REFERENCES players(id) ON DELETE CASCADE,
    total_damage_dealt INTEGER DEFAULT 0,
    total_units_deployed INTEGER DEFAULT 0,
    total_towers_destroyed INTEGER DEFAULT 0,
    highest_skill_rating INTEGER DEFAULT 1000,
    current_win_streak INTEGER DEFAULT 0,
    longest_win_streak INTEGER DEFAULT 0,
    total_playtime_seconds INTEGER DEFAULT 0,
    favorite_unit VARCHAR(50),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(player_id)
);

-- Create player_inventory table
CREATE TABLE IF NOT EXISTS player_inventory (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    player_id UUID REFERENCES players(id) ON DELETE CASCADE,
    unit_type VARCHAR(50) NOT NULL,
    level INTEGER DEFAULT 1,
    experience INTEGER DEFAULT 0,
    unlocked_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(player_id, unit_type)
);

-- Create matchmaking_queue table
CREATE TABLE IF NOT EXISTS matchmaking_queue (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    player_id UUID REFERENCES players(id) ON DELETE CASCADE,
    skill_rating INTEGER NOT NULL,
    game_mode VARCHAR(50) DEFAULT 'ranked',
    joined_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    status VARCHAR(20) DEFAULT 'queued'
);

-- Create game_events table (for analytics and replay)
CREATE TABLE IF NOT EXISTS game_events (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    session_id UUID REFERENCES game_sessions(id) ON DELETE CASCADE,
    event_type VARCHAR(50) NOT NULL,
    player_id UUID REFERENCES players(id) ON DELETE SET NULL,
    event_data JSONB,
    timestamp_ms BIGINT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes for better query performance
CREATE INDEX IF NOT EXISTS idx_players_username ON players(username);
CREATE INDEX IF NOT EXISTS idx_players_email ON players(email);
CREATE INDEX IF NOT EXISTS idx_players_skill_rating ON players(skill_rating DESC);
CREATE INDEX IF NOT EXISTS idx_players_created_at ON players(created_at DESC);

CREATE INDEX IF NOT EXISTS idx_game_sessions_room_id ON game_sessions(room_id);
CREATE INDEX IF NOT EXISTS idx_game_sessions_player1 ON game_sessions(player1_id);
CREATE INDEX IF NOT EXISTS idx_game_sessions_player2 ON game_sessions(player2_id);
CREATE INDEX IF NOT EXISTS idx_game_sessions_status ON game_sessions(status);
CREATE INDEX IF NOT EXISTS idx_game_sessions_started_at ON game_sessions(started_at DESC);

CREATE INDEX IF NOT EXISTS idx_player_stats_player_id ON player_stats(player_id);
CREATE INDEX IF NOT EXISTS idx_player_inventory_player_id ON player_inventory(player_id);

CREATE INDEX IF NOT EXISTS idx_matchmaking_queue_player_id ON matchmaking_queue(player_id);
CREATE INDEX IF NOT EXISTS idx_matchmaking_queue_status ON matchmaking_queue(status);
CREATE INDEX IF NOT EXISTS idx_matchmaking_queue_joined_at ON matchmaking_queue(joined_at);

CREATE INDEX IF NOT EXISTS idx_game_events_session_id ON game_events(session_id);
CREATE INDEX IF NOT EXISTS idx_game_events_event_type ON game_events(event_type);
CREATE INDEX IF NOT EXISTS idx_game_events_timestamp ON game_events(timestamp_ms);

-- Create function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Create triggers for updated_at
CREATE TRIGGER update_players_updated_at BEFORE UPDATE ON players
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_player_stats_updated_at BEFORE UPDATE ON player_stats
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Insert default units (starter deck)
INSERT INTO player_inventory (player_id, unit_type, level, experience)
SELECT p.id, 'knight', 1, 0
FROM players p
WHERE NOT EXISTS (
    SELECT 1 FROM player_inventory pi
    WHERE pi.player_id = p.id AND pi.unit_type = 'knight'
);

-- Create view for player leaderboard
CREATE OR REPLACE VIEW leaderboard AS
SELECT
    p.id,
    p.username,
    p.display_name,
    p.skill_rating,
    p.total_games,
    p.wins,
    p.losses,
    CASE
        WHEN p.total_games > 0 THEN ROUND((p.wins::DECIMAL / p.total_games::DECIMAL) * 100, 2)
        ELSE 0
    END as win_rate,
    ps.current_win_streak,
    ps.longest_win_streak,
    RANK() OVER (ORDER BY p.skill_rating DESC) as rank
FROM players p
LEFT JOIN player_stats ps ON p.id = ps.player_id
WHERE p.is_active = TRUE AND p.is_banned = FALSE
ORDER BY p.skill_rating DESC;

-- Grant permissions
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO battlecastles;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO battlecastles;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO battlecastles;
