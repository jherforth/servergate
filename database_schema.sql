-- Worldgate Server Connector - MariaDB/MySQL Schema
-- Run this on your MariaDB server to create the required tables

CREATE DATABASE IF NOT EXISTS worldgate CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE worldgate;

-- Servers table
CREATE TABLE IF NOT EXISTS servers (
  id CHAR(36) PRIMARY KEY,
  name VARCHAR(255) NOT NULL UNIQUE,
  url VARCHAR(512) NOT NULL,
  is_active BOOLEAN DEFAULT TRUE,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX idx_active (is_active),
  INDEX idx_name (name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

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
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (server_id) REFERENCES servers(id) ON DELETE CASCADE,
  FOREIGN KEY (destination_gate_id) REFERENCES worldgates(id) ON DELETE SET NULL,
  FOREIGN KEY (destination_server_id) REFERENCES servers(id) ON DELETE SET NULL,
  INDEX idx_server (server_id),
  INDEX idx_destination (destination_gate_id, destination_server_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Transfer logs table
CREATE TABLE IF NOT EXISTS transfer_logs (
  id CHAR(36) PRIMARY KEY,
  player_name VARCHAR(255) NOT NULL,
  source_gate_id CHAR(36) DEFAULT NULL,
  destination_gate_id CHAR(36) DEFAULT NULL,
  source_server_id CHAR(36) DEFAULT NULL,
  destination_server_id CHAR(36) DEFAULT NULL,
  transfer_time DATETIME DEFAULT CURRENT_TIMESTAMP,
  success BOOLEAN DEFAULT FALSE,
  FOREIGN KEY (source_gate_id) REFERENCES worldgates(id) ON DELETE SET NULL,
  FOREIGN KEY (destination_gate_id) REFERENCES worldgates(id) ON DELETE SET NULL,
  FOREIGN KEY (source_server_id) REFERENCES servers(id) ON DELETE SET NULL,
  FOREIGN KEY (destination_server_id) REFERENCES servers(id) ON DELETE SET NULL,
  INDEX idx_player (player_name),
  INDEX idx_time (transfer_time),
  INDEX idx_source_server (source_server_id),
  INDEX idx_dest_server (destination_server_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Create a dedicated user for the worldgate mod
-- Change the password to something secure!
CREATE USER IF NOT EXISTS 'worldgate'@'%' IDENTIFIED BY 'change_this_password';
GRANT SELECT, INSERT, UPDATE, DELETE ON worldgate.* TO 'worldgate'@'%';
FLUSH PRIVILEGES;

-- Show the tables
SHOW TABLES;
