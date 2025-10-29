Worldgate Server Connector
==========================

A Luanti/Minetest mod that generates ancient worldgate structures throughout your world and enables server-to-server player transfers. Worldgates are synchronized across multiple servers via MariaDB/MySQL, allowing players to travel between different game servers through the gate network.

## Features

- **Automatic Gate Generation**: Worldgates spawn throughout the world with various architectural styles
- **Server Network**: Connect multiple Luanti/Minetest servers through a shared database
- **Cross-Server Transfers**: Players can transfer between servers by using linked servergates
- **Transfer Logging**: All transfers are logged for debugging and analytics
- **Configurable Spawning**: Control where and how gates generate in your world
- **Distinct Beacons**: Servergate beacons (red) are visually distinct from worldgate/telemosaic beacons (blue) to avoid conflicts

## How It Works

1. Each server runs the worldgate mod and connects to a shared MariaDB/MySQL database
2. When gates generate, they spawn with red servergate beacons in their centers
3. Server admins can link servergate beacons between different servers
4. Players right-click a servergate beacon to see connection information for the destination server
5. Transfer cooldowns prevent spam (5 seconds by default)

## Setup

### 1. MariaDB/MySQL Database

Set up a MariaDB or MySQL database that all your servers can access:

1. Install MariaDB on your private network
2. Run the provided `database_schema.sql` to create the tables
3. Create a user with access to the worldgate database
4. Make sure your servers can connect to the database

```bash
mysql -u root -p < database_schema.sql
```

### 2. Install mysql_base Mod (Optional but Recommended)

For multi-server support, install a MySQL connectivity mod like `mysql_base`. Without it, the mod will work in single-server mode using mod_storage as a fallback.

### 3. Server Configuration

Add these settings to your `minetest.conf` on each server (see `minetest.conf.example` for full options):

```
# Server identification
worldgate.server_name = My Server Alpha

# URL players should connect to
worldgate.server_url = minetest://play.example.com:30000

# Database connection
worldgate.db_host = 192.168.1.100
worldgate.db_port = 3306
worldgate.db_name = worldgate
worldgate.db_user = worldgate
worldgate.db_password = your_secure_password
```

### 4. Linking Gates

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