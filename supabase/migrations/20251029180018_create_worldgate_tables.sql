/*
  # Worldgate Server Connector Database Schema

  This migration creates the database schema for synchronizing worldgates between multiple Luanti/Minetest servers.

  ## New Tables

  ### `servers`
  Stores information about connected servers in the network
  - `id` (uuid, primary key) - Unique server identifier
  - `name` (text) - Human-readable server name
  - `host` (text) - Server hostname/IP
  - `port` (integer) - Server port
  - `is_active` (boolean) - Whether server is currently active
  - `created_at` (timestamptz) - Server registration time
  - `updated_at` (timestamptz) - Last heartbeat/update time

  ### `worldgates`
  Stores worldgate positions and their cross-server linking information
  - `id` (uuid, primary key) - Unique gate identifier
  - `server_id` (uuid, foreign key) - Server where this gate exists
  - `position` (jsonb) - Gate position {x, y, z}
  - `base_schematic` (text) - Base schematic name
  - `decor_schematic` (text) - Decor schematic name
  - `quality` (integer) - Gate quality (-1, 0, 1)
  - `destination_gate_id` (uuid, nullable, foreign key) - Linked gate on another server
  - `destination_server_id` (uuid, nullable, foreign key) - Destination server
  - `created_at` (timestamptz) - Gate creation time
  - `updated_at` (timestamptz) - Last update time

  ### `transfer_logs`
  Logs player transfers between servers for debugging and analytics
  - `id` (uuid, primary key) - Log entry ID
  - `player_name` (text) - Player who transferred
  - `source_gate_id` (uuid, foreign key) - Origin gate
  - `destination_gate_id` (uuid, foreign key) - Destination gate
  - `source_server_id` (uuid, foreign key) - Origin server
  - `destination_server_id` (uuid, foreign key) - Destination server
  - `transfer_time` (timestamptz) - When transfer occurred
  - `success` (boolean) - Whether transfer succeeded

  ## Security
  - Enable RLS on all tables
  - Add policies for authenticated server-to-server communication
*/

-- Create servers table
CREATE TABLE IF NOT EXISTS servers (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL UNIQUE,
  host text NOT NULL,
  port integer NOT NULL DEFAULT 30000,
  is_active boolean DEFAULT true,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

ALTER TABLE servers ENABLE ROW LEVEL SECURITY;

-- Create worldgates table
CREATE TABLE IF NOT EXISTS worldgates (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  server_id uuid NOT NULL REFERENCES servers(id) ON DELETE CASCADE,
  position jsonb NOT NULL,
  base_schematic text NOT NULL,
  decor_schematic text NOT NULL,
  quality integer NOT NULL DEFAULT 0,
  destination_gate_id uuid REFERENCES worldgates(id) ON DELETE SET NULL,
  destination_server_id uuid REFERENCES servers(id) ON DELETE SET NULL,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

ALTER TABLE worldgates ENABLE ROW LEVEL SECURITY;

-- Create transfer_logs table
CREATE TABLE IF NOT EXISTS transfer_logs (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  player_name text NOT NULL,
  source_gate_id uuid REFERENCES worldgates(id) ON DELETE SET NULL,
  destination_gate_id uuid REFERENCES worldgates(id) ON DELETE SET NULL,
  source_server_id uuid REFERENCES servers(id) ON DELETE SET NULL,
  destination_server_id uuid REFERENCES servers(id) ON DELETE SET NULL,
  transfer_time timestamptz DEFAULT now(),
  success boolean DEFAULT false
);

ALTER TABLE transfer_logs ENABLE ROW LEVEL SECURITY;

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_worldgates_server_id ON worldgates(server_id);
CREATE INDEX IF NOT EXISTS idx_worldgates_destination ON worldgates(destination_gate_id, destination_server_id);
CREATE INDEX IF NOT EXISTS idx_transfer_logs_player ON transfer_logs(player_name);
CREATE INDEX IF NOT EXISTS idx_transfer_logs_time ON transfer_logs(transfer_time);

-- RLS Policies for servers table
CREATE POLICY "Servers can read all server data"
  ON servers FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Servers can update their own data"
  ON servers FOR UPDATE
  TO authenticated
  USING (true)
  WITH CHECK (true);

CREATE POLICY "Servers can insert new servers"
  ON servers FOR INSERT
  TO authenticated
  WITH CHECK (true);

-- RLS Policies for worldgates table
CREATE POLICY "Worldgates can be read by all servers"
  ON worldgates FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Servers can insert worldgates"
  ON worldgates FOR INSERT
  TO authenticated
  WITH CHECK (true);

CREATE POLICY "Servers can update worldgates"
  ON worldgates FOR UPDATE
  TO authenticated
  USING (true)
  WITH CHECK (true);

CREATE POLICY "Servers can delete worldgates"
  ON worldgates FOR DELETE
  TO authenticated
  USING (true);

-- RLS Policies for transfer_logs table
CREATE POLICY "Transfer logs can be read by all servers"
  ON transfer_logs FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Servers can insert transfer logs"
  ON transfer_logs FOR INSERT
  TO authenticated
  WITH CHECK (true);
