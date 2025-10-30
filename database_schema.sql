-- Worldgate Server Connector - PostgreSQL Schema
-- Run this on your PostgreSQL server to create the required tables

-- Note: Run these commands after connecting to your PostgreSQL database:
-- psql -U postgres -d worldgate
-- Or if the database doesn't exist yet:
-- createdb -U postgres worldgate
-- psql -U postgres -d worldgate < database_schema.sql

-- Servers table
CREATE TABLE IF NOT EXISTS servers (
  id CHAR(36) PRIMARY KEY,
  name VARCHAR(255) NOT NULL UNIQUE,
  url VARCHAR(512) NOT NULL,
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_active ON servers(is_active);
CREATE INDEX IF NOT EXISTS idx_name ON servers(name);

-- Worldgates table
CREATE TABLE IF NOT EXISTS worldgates (
  id CHAR(36) PRIMARY KEY,
  server_id CHAR(36) NOT NULL,
  position TEXT NOT NULL,
  base_schematic VARCHAR(255) NOT NULL,
  decor_schematic VARCHAR(255) NOT NULL,
  quality INT NOT NULL DEFAULT 0,
  destination_gate_id CHAR(36) DEFAULT NULL,
  destination_server_id CHAR(36) DEFAULT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (server_id) REFERENCES servers(id) ON DELETE CASCADE,
  FOREIGN KEY (destination_gate_id) REFERENCES worldgates(id) ON DELETE SET NULL,
  FOREIGN KEY (destination_server_id) REFERENCES servers(id) ON DELETE SET NULL
);

CREATE INDEX IF NOT EXISTS idx_server ON worldgates(server_id);
CREATE INDEX IF NOT EXISTS idx_destination ON worldgates(destination_gate_id, destination_server_id);

-- Transfer logs table
CREATE TABLE IF NOT EXISTS transfer_logs (
  id CHAR(36) PRIMARY KEY,
  player_name VARCHAR(255) NOT NULL,
  source_gate_id CHAR(36) DEFAULT NULL,
  destination_gate_id CHAR(36) DEFAULT NULL,
  source_server_id CHAR(36) DEFAULT NULL,
  destination_server_id CHAR(36) DEFAULT NULL,
  transfer_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  success BOOLEAN DEFAULT FALSE,
  FOREIGN KEY (source_gate_id) REFERENCES worldgates(id) ON DELETE SET NULL,
  FOREIGN KEY (destination_gate_id) REFERENCES worldgates(id) ON DELETE SET NULL,
  FOREIGN KEY (source_server_id) REFERENCES servers(id) ON DELETE SET NULL,
  FOREIGN KEY (destination_server_id) REFERENCES servers(id) ON DELETE SET NULL
);

CREATE INDEX IF NOT EXISTS idx_player ON transfer_logs(player_name);
CREATE INDEX IF NOT EXISTS idx_time ON transfer_logs(transfer_time);
CREATE INDEX IF NOT EXISTS idx_source_server ON transfer_logs(source_server_id);
CREATE INDEX IF NOT EXISTS idx_dest_server ON transfer_logs(destination_server_id);

-- Create a trigger to update the updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = CURRENT_TIMESTAMP;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_servers_updated_at
  BEFORE UPDATE ON servers
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_worldgates_updated_at
  BEFORE UPDATE ON worldgates
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- Create a dedicated user for the worldgate mod
-- Change the password to something secure!
-- Note: Run this as the postgres superuser
CREATE USER worldgate WITH PASSWORD 'change_this_password';
GRANT CONNECT ON DATABASE worldgate TO worldgate;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO worldgate;
GRANT USAGE ON SCHEMA public TO worldgate;

-- Show the tables
\dt
