Worldgate Server Connector
==========================

A Luanti/Minetest mod that generates ancient worldgate structures throughout your world and enables server-to-server player transfers. Worldgates are synchronized across multiple servers via MariaDB/MySQL, allowing players to travel between different game servers through the gate network.

## Features

- **Automatic Gate Generation**: Worldgates spawn throughout the world with various architectural styles
- **Server Network**: Connect multiple Luanti/Minetest servers through a shared database
- **Cross-Server Transfers**: Players can transfer between servers by using linked servergates
- **Visual Transfer Screen**: Fullscreen portal animation when transferring servers
- **Transfer Logging**: All transfers are logged for debugging and analytics
- **Configurable Spawning**: Control where and how gates generate in your world
- **Distinct Beacons**: Servergate beacons (red) are visually distinct from worldgate/telemosaic beacons (blue) to avoid conflicts

## How It Works

1. Each server runs the worldgate mod and connects to a shared MariaDB/MySQL database
2. When gates generate, they spawn with red servergate beacons in their centers
3. Server admins can link servergate beacons between different servers
4. Players right-click a servergate beacon to see a fullscreen transfer screen with destination info
5. Players disconnect and reconnect using the provided server address
6. Transfer cooldowns prevent spam (5 seconds by default)

**📖 Want to understand the architecture?** See [ARCHITECTURE.md](ARCHITECTURE.md) for diagrams and detailed explanations.

## Setup

### Quick Start Guides

Choose the guide that matches your experience level:

- **✅ SETUP CHECKLIST** → [SETUP_CHECKLIST.md](SETUP_CHECKLIST.md)
  - Complete step-by-step checklist
  - Verify each component works
  - Troubleshooting for each step

- **🌟 NEW TO DATABASES?** → [MySQL Setup for Complete Beginners](MYSQL_SETUP_FOR_BEGINNERS.md)
  - Step-by-step instructions with explanations
  - Covers installation, security, and testing
  - Troubleshooting for common issues

- **💪 EXPERIENCED USER?** → [MariaDB Advanced Setup](MARIADB_SETUP.md)
  - Network configuration
  - Performance tuning
  - Production deployment

### 1. Database Setup

Set up a MySQL/MariaDB database that all your servers can access:

1. Follow the [MySQL Setup for Complete Beginners](MYSQL_SETUP_FOR_BEGINNERS.md) guide
2. Run the provided `database_schema.sql` to create tables
3. Register each server with `/worldgate_register_server`

**Quick install:**
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

### 4. Transfer Screen Image (Optional)

For the best player experience, add a custom transfer screen background:

1. Place an image named `worldgate_transfer.png` in the `textures/` directory
2. Recommended size: 1920x1080 or larger
3. Theme: Portal, tunnel, or dimensional transfer imagery

See [TRANSFER_SCREEN.md](TRANSFER_SCREEN.md) for detailed setup and customization.

### 5. Linking Gates

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

## 📚 Documentation

- **[QUICK_REFERENCE.md](QUICK_REFERENCE.md)** - Commands and queries cheat sheet
- **[SETUP_CHECKLIST.md](SETUP_CHECKLIST.md)** - Complete setup verification
- **[MYSQL_SETUP_FOR_BEGINNERS.md](MYSQL_SETUP_FOR_BEGINNERS.md)** - Database setup guide
- **[ARCHITECTURE.md](ARCHITECTURE.md)** - System architecture and diagrams
- **[TRANSFER_SCREEN.md](TRANSFER_SCREEN.md)** - Customize transfer interface
- **[API.md](API.md)** - Full API reference
- **[DATABASE_QUERIES.md](DATABASE_QUERIES.md)** - Advanced database queries
- **[MARIADB_SETUP.md](MARIADB_SETUP.md)** - Advanced database setup

## Technical Details

The mod creates three database tables:
- `servers` - Registered servers in the network
- `worldgates` - All gates and their linking information
- `transfer_logs` - History of player transfers

Each server maintains a heartbeat every 60 seconds to indicate it's active.
