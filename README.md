Worldgate Server Connector
==========================

A Luanti/Minetest mod that generates ancient worldgate structures throughout your world and enables server-to-server player transfers. Worldgates are synchronized across multiple servers via Supabase, allowing players to travel between different game servers through the gate network.

## Features

- **Automatic Gate Generation**: Worldgates spawn throughout the world with various architectural styles
- **Server Network**: Connect multiple Luanti/Minetest servers through a shared database
- **Cross-Server Transfers**: Players can transfer between servers by using linked worldgates
- **Transfer Logging**: All transfers are logged for debugging and analytics
- **Configurable Spawning**: Control where and how gates generate in your world

## How It Works

1. Each server runs the worldgate mod and connects to a shared Supabase database
2. When gates generate, they are automatically registered in the database
3. Server admins can link gates between different servers
4. Players right-click a beacon to transfer to another server
5. Transfer cooldowns prevent spam (5 seconds by default)

## Setup

### 1. Supabase Database

You need a Supabase project to synchronize gates between servers. The mod will automatically create the required tables on first run.

1. Create a free account at [supabase.com](https://supabase.com)
2. Create a new project
3. Get your project URL and anon key from the API settings

### 2. Server Configuration

Add these settings to your `minetest.conf` (see `minetest.conf.example` for full options):

```
# Server identification
worldgate.server_name = My Server Name

# Supabase connection
worldgate.supabase_url = https://your-project.supabase.co
worldgate.supabase_anon_key = your-anon-key-here

# Enable HTTP API access
secure.http_mods = worldgate
```

### 3. Linking Gates

Gates can be linked using the Lua API:

```lua
worldgate.link_gates_manual(source_beacon_pos, destination_gate_id, destination_server_id)
```

Where:
- `source_beacon_pos` is the position of the beacon node
- `destination_gate_id` is the UUID of the destination gate from the database
- `destination_server_id` is the UUID of the destination server

## Configuration Options

- `worldgate.mapgen` - Enable/disable worldgate generation (default: true)
- `worldgate.native` - Enable native gate generation (default: true)
- `worldgate.native.link` - Auto-link gates locally (default: false for server connector)
- `worldgate.native.spread` - Distance between gates in nodes (default: 1000)
- `worldgate.ymin` - Minimum Y coordinate for gates (default: -29900)
- `worldgate.ymax` - Maximum Y coordinate for gates (default: 29900)
- `worldgate.beaconglow` - Make beacons emit light (default: true)

## Notes

- Worldgates only generate in unexplored areas
- By default, gates generate roughly every 1000 nodes
- Transfer cooldown is 5 seconds to prevent spam
- Gates register in the database 2 seconds after generation

## Technical Details

The mod creates three database tables:
- `servers` - Registered servers in the network
- `worldgates` - All gates and their linking information
- `transfer_logs` - History of player transfers

Each server maintains a heartbeat every 60 seconds to indicate it's active.