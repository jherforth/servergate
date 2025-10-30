Worldgate Server Connector
==========================

A Luanti/Minetest mod that generates ancient worldgate structures throughout your world and enables server-to-server player transfers. Worldgates are synchronized across multiple servers via PostgreSQL, allowing players to travel between different game servers through the gate network.

**Built upon [EmptyStar's worldgate mod](https://github.com/mt-empty/worldgate)** - This mod extends the excellent foundation provided by EmptyStar's worldgate with multi-server connectivity, database synchronization, and cross-server transfer capabilities.

## Features

- **Automatic Gate Generation**: Worldgates spawn throughout the world with various architectural styles
- **Server Network**: Connect multiple Luanti/Minetest servers through a shared database
- **Cross-Server Transfers**: Players can transfer between servers by using linked servergates
- **Visual Transfer Screen**: Fullscreen portal animation when transferring servers
- **Transfer Logging**: All transfers are logged for debugging and analytics
- **Configurable Spawning**: Control where and how gates generate in your world
- **Distinct Beacons**: Servergate beacons (red) are visually distinct from worldgate/telemosaic beacons (blue) to avoid conflicts

## How It Works

1. Each server runs the worldgate mod and connects to a shared PostgreSQL database
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

- **🌟 NEW TO DATABASES?** → [PostgreSQL Setup Guide](POSTGRESQL_SETUP.md)
  - Step-by-step instructions with explanations
  - Covers installation, security, and testing
  - Troubleshooting for common issues
  - Migration from MySQL/MariaDB

### 1. Database Setup

Set up a PostgreSQL database that all your servers can access:

1. Follow the [PostgreSQL Setup Guide](POSTGRESQL_SETUP.md)
2. Run the provided `database_schema.sql` to create tables
3. Register each server with `/worldgate_register_server`

**Quick install:**
```bash
sudo -u postgres psql -d worldgate < database_schema.sql
```

### 2. Configure Minetest PostgreSQL Backend

PostgreSQL is natively supported by Minetest - no additional mods required! Just configure your `world.mt` file with the PostgreSQL connection string.

### 3. Server Configuration

Add these settings to your `minetest.conf` on each server (see `minetest.conf.example` for full options):

```
# Server identification
servergate.server_name = My Server Alpha

# URL players should connect to
servergate.server_url = minetest://play.example.com:30000

# PostgreSQL backend (in world.mt)
backend = postgresql
pgsql_connection = host=192.168.1.100 port=5432 user=worldgate password=xxx dbname=worldgate

# Database connection (for mod queries)
servergate.db_host = 192.168.1.100
servergate.db_port = 5432
servergate.db_name = worldgate
servergate.db_user = worldgate
servergate.db_password = your_secure_password
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
servergate.link_gates_manual(source_beacon_pos, destination_gate_id, destination_server_id)
```

Where:
- `source_beacon_pos` is the position of the beacon node
- `destination_gate_id` is the UUID of the destination gate from the database
- `destination_server_id` is the UUID of the destination server

## Configuration Options

- `servergate.mapgen` - Enable/disable worldgate generation (default: true)
- `servergate.native` - Enable native gate generation (default: true)
- `servergate.native.link` - Auto-link gates locally (default: false for server connector)
- `servergate.native.spread` - Distance between gates in nodes (default: 1000)
- `servergate.ymin` - Minimum Y coordinate for gates (default: -29900)
- `servergate.ymax` - Maximum Y coordinate for gates (default: 29900)
- `servergate.beaconglow` - Make beacons emit light (default: true)

## Important Limitations

**⚠️ Inventory Does Not Transfer**

Player inventories do **not** transfer between servers. When players transfer through a servergate:
- **Player keeps:** Their username, authentication
- **Player loses:** All inventory items, armor, wielded items

This is a technical limitation because:
- Servers may run different games (Minetest Game, MineClone2, etc.)
- Item names and properties differ between games
- No standardized inventory transfer protocol exists
- Security concerns with cross-server item validation

**Recommendation:** Use worldgates as "starting fresh" portals or configure your servers to run identical games/mods if you need consistent gameplay.

## Notes

- Worldgates only generate in unexplored areas
- By default, gates generate roughly every 1000 nodes
- Transfer cooldown is 5 seconds to prevent spam
- Gates register in the database 2 seconds after generation

## 📚 Documentation

- **[QUICK_REFERENCE.md](QUICK_REFERENCE.md)** - Commands and queries cheat sheet
- **[SETUP_CHECKLIST.md](SETUP_CHECKLIST.md)** - Complete setup verification
- **[POSTGRESQL_SETUP.md](POSTGRESQL_SETUP.md)** - PostgreSQL database setup guide
- **[ARCHITECTURE.md](ARCHITECTURE.md)** - System architecture and diagrams
- **[COMPATIBILITY.md](COMPATIBILITY.md)** - Inventory limitations and compatibility notes
- **[TRANSFER_SCREEN.md](TRANSFER_SCREEN.md)** - Customize transfer interface
- **[API.md](API.md)** - Full API reference
- **[DATABASE_QUERIES.md](DATABASE_QUERIES.md)** - Advanced database queries

## Technical Details

The mod creates three database tables:
- `servers` - Registered servers in the network
- `worldgates` - All gates and their linking information
- `transfer_logs` - History of player transfers

Each server maintains a heartbeat every 60 seconds to indicate it's active.

---

## Credits & Acknowledgements

**Original Mod:** [EmptyStar's worldgate](https://github.com/mt-empty/worldgate)
This server connector variant was built upon EmptyStar's excellent worldgate mod, which provides the beautiful gate structures, mapgen integration, and core worldgate functionality. All credit for the original concept, schematics, and single-server worldgate implementation goes to EmptyStar.

**Development Platform:** This mod was developed using [Bolt.new](https://bolt.new), an AI-powered coding platform that accelerates development through intelligent code assistance. Don't hate on me for it, but we do live in an age when someone has an idea, they can finally bring it to life. I hope you enjoy this mod all the same!

**License:** See LICENSE file for details.
