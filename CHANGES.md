# Worldgate to Server Connector - Changes Summary

## Overview

This mod has been transformed from a local teleportation system (based on Telemosaic) into a cross-server player transfer system using Supabase for synchronization.

## What's Been Kept

### ✅ Core Functionality Preserved
- **Gate Generation**: All worldgate generation code remains intact
  - Native gate generation with configurable spread
  - Multiple base and decor schematics
  - Quality system for gate variety
  - Heightmap-based placement
  - All mapgen logic and placement strategies

- **Visual Structure**: Gates still look the same
  - All schematic files unchanged
  - Platform and airspace generation
  - Quality-based degradation
  - Structure nodes for decoration

- **Configuration**: Most settings remain
  - `worldgate.mapgen` - Enable/disable generation
  - `worldgate.native` - Native gate generation
  - `worldgate.native.spread` - Distance between gates
  - `worldgate.ymin/ymax` - Y coordinate limits
  - `worldgate.underwaterspawn` - Underwater spawning
  - `worldgate.midairspawn` - Midair spawning
  - `worldgate.breakage` - Structure damage percentage
  - `worldgate.beaconglow` - Beacon lighting

## What's Been Changed

### 🔄 Major Changes

1. **Removed Telemosaic Dependency**
   - No longer requires the Telemosaic mod
   - Created new servergate beacon nodes: `worldgate:servergate_beacon` and `worldgate:servergate_beacon_off`
   - Beacons now trigger server transfers instead of local teleportation
   - Servergate beacons are red to distinguish from worldgate/telemosaic beacons (blue)
   - Both mods can now coexist in the same world without conflicts

2. **Added Database Synchronization**
   - MariaDB/MySQL integration for cross-server coordination
   - Self-hosted database on your private network
   - Three database tables:
     - `servers` - Server registry with configurable URLs
     - `worldgates` - Gate positions and links
     - `transfer_logs` - Transfer history

3. **Server Transfer System**
   - New `server_api.lua` module for MariaDB/MySQL communication
   - Automatic server registration and heartbeat
   - Configurable server URLs for player transfers
   - Gate registration in database on generation
   - Cross-server gate linking capability

4. **Updated Link System**
   - `link.lua` completely rewritten
   - Removed force-loading system (no longer needed)
   - Added transfer cooldown (5 seconds)
   - Simplified beacon management with ABM

### 📝 Configuration Changes

**New Settings:**
- `worldgate.server_name` - Server identification
- `worldgate.supabase_url` - Database URL
- `worldgate.supabase_anon_key` - Database access key

**Changed Defaults:**
- `worldgate.native.link` - Now defaults to `false` (manual linking via database)

**Removed Settings:**
- `worldgate.superextenders` - No longer applicable
- `worldgate.destroykeys` - No longer applicable

### 📦 New Files

- `src/server_api.lua` - Supabase integration and transfer logic
- `admin_commands.lua` - Admin commands for gate management
- `minetest.conf.example` - Configuration template
- `QUICKSTART.md` - Setup guide
- `CHANGES.md` - This file

### 📋 Modified Files

- `init.lua` - Load server_api module, updated settings
- `mod.conf` - Removed telemosaic dependency
- `src/nodes.lua` - New beacon nodes
- `src/link.lua` - Complete rewrite for server transfers
- `src/mapgen.lua` - Database registration on gate generation
- `README.md` - Updated documentation
- `API.md` - Added server transfer API documentation
- `settingtypes.txt` - New settings, removed obsolete ones

## Migration Notes

### If Upgrading from Original Worldgate

1. **Backup Your World**: This is a breaking change
2. **Install Requirements**: You'll need:
   - A Supabase account
   - HTTP API access configured
3. **Existing Gates**: Will not work automatically
   - Old gates will remain as structures
   - New beacon nodes must be placed or gates regenerated
4. **No Automatic Conversion**: This is essentially a new mod

### For New Installations

Simply follow the QUICKSTART.md guide - no migration needed!

## Technical Architecture

### Database Schema

```
servers
├─ id (uuid)
├─ name (text)
├─ host (text)
├─ port (integer)
└─ is_active (boolean)

worldgates
├─ id (uuid)
├─ server_id (uuid) → servers
├─ position (jsonb)
├─ destination_gate_id (uuid) → worldgates
└─ destination_server_id (uuid) → servers

transfer_logs
├─ player_name (text)
├─ source_gate_id (uuid)
├─ destination_gate_id (uuid)
└─ transfer_time (timestamp)
```

### API Flow

1. Server starts → Registers in database
2. Gate generates → Registers in database
3. Admin links gates → Updates database
4. Player clicks beacon → Queries database → Shows destination
5. Transfer occurs → Logs in database

## Future Enhancements

Possible future additions:
- Actual player data transfer between servers
- Automatic gate linking algorithms
- Web-based admin panel for gate management
- Player transfer statistics and analytics
- Multi-destination gates (network routing)
- Gate discovery system for players

## Credits

Original Worldgate mod by EmptyStar
Server Connector transformation preserves the excellent gate generation system while adding multi-server capabilities.
