# Worldgate Server Connector - Quick Start Guide

## Overview

This guide will help you set up a network of Luanti/Minetest servers connected via Worldgates using your own PostgreSQL database.

## Prerequisites

- Two or more Luanti/Minetest servers
- PostgreSQL server on your private network
- Server admin access with `server` privilege

## 📚 Need Database Help?

**First time setting up PostgreSQL?** We have a complete guide for you:

👉 **[PostgreSQL Setup Guide](POSTGRESQL_SETUP.md)** 👈

It covers everything from installation to troubleshooting with step-by-step instructions.

---

## Step 1: Set Up PostgreSQL Database

### Quick Setup (Experienced Users)

On your database server:

1. Install PostgreSQL:
```bash
sudo apt-get install postgresql postgresql-contrib
```

2. Create the database and tables:
```bash
sudo -u postgres psql -c "CREATE DATABASE worldgate;"
sudo -u postgres psql -d worldgate < database_schema.sql
```

3. Database user is created automatically by the schema script.

4. Note your database connection details:
   - Host (e.g., `192.168.1.100` or `localhost`)
   - Port (default: `5432`)
   - Database name (`worldgate`)
   - Username (`worldgate`)
   - Password (what you just set)

## Step 2: Install the Mod

1. Install this mod on all servers in your network
2. Configure PostgreSQL backend in world.mt (PostgreSQL is natively supported by Minetest)
3. Make sure all servers can reach your database

## Step 3: Configure Each Server

Add to **either** `world.mt` (recommended) **or** `minetest.conf` on each server.

**Where to add:** Simply copy/paste these lines to the end of the file.

### Configuration Files:

- **`world.mt`**: `/path/to/minetest/worlds/<worldname>/world.mt` (per-world settings)
- **`minetest.conf`**: `/path/to/minetest/minetest.conf` (global for all worlds)

Use different names and URLs for each server:

**Server Alpha:**
```
servergate.server_name = Server Alpha
servergate.server_url = minetest://alpha.example.com:30000

servergate.db_host = 192.168.1.100
servergate.db_port = 5432
servergate.db_name = worldgate
servergate.db_user = worldgate
servergate.db_password = your_secure_password

servergate.native.link = false
```

**Server Beta:**
```
servergate.server_name = Server Beta
servergate.server_url = minetest://beta.example.com:30001

servergate.db_host = 192.168.1.100
servergate.db_port = 5432
servergate.db_name = worldgate
servergate.db_user = worldgate
servergate.db_password = your_secure_password

servergate.native.link = false
```

## Step 4: Start Servers and Explore

1. Start all servers
2. Explore the world on each server to generate worldgates
3. Check the server logs to see gates being registered
4. Look for messages like: `Worldgate: Server registered with ID: ...`

## Step 5: Link Gates Between Servers

**Easy Interactive Linking (No Commands!):**

### On Server Alpha:
1. Find a servergate beacon (dark red block in center of worldgate)
2. **Crouch and punch** (or right-click) the beacon
3. A dialog appears listing all available gates from other servers
4. Select a gate from Server Beta
5. Click "Link to Selected Gate"
6. Done! The beacon lights up (glowing red)

### On Server Beta:
1. Find another beacon
2. **Crouch and punch** (or right-click) it
3. Select the gate from Server Alpha
4. Click "Link to Selected Gate"
5. Gates are now linked both ways!

**Advanced: Using Commands (Optional)**

If you prefer commands:

1. Look at a beacon and run `/worldgate_info` to get its Gate ID
2. Run `/worldgate_link <destination_gate_id>` while looking at the source beacon
3. The system automatically finds the destination server from the database

## Step 6: Test the Connection

1. On Server Alpha, **right-click or crouch-punch** the linked beacon
2. A dialog appears showing:
   - Destination: Server Beta
   - Connection URL: minetest://beta.example.com:30001
   - **GO!** button
3. Click the **GO!** button
4. You're automatically transferred to Server Beta!

**⚠️ IMPORTANT:** Player inventories do NOT transfer between servers. Players will lose all items, armor, and wielded equipment when transferring. This is a technical limitation as servers may run different games/mods with incompatible items.

## Admin Commands (Optional)

Commands are no longer required for normal use, but available if needed:

- `/worldgate_info` - Get info about the gate you're looking at
- `/worldgate_link <dest_gate_id>` - Link a gate by UUID (system finds the server automatically)
- `/worldgate_list` - List all gates on this server from the database

**Note:** Most users prefer the interactive crouch-punch/right-click method!

## Troubleshooting

### "PostgreSQL not available"
- Configure PostgreSQL backend in world.mt
- Add pgsql_connection string to world.mt
- In fallback mode, gates only work locally

### "Failed to register server"
- Check database credentials in world.mt and minetest.conf
- Verify network connectivity to database server
- Check PostgreSQL logs for connection errors

### "Gate destination not found"
- Make sure you've linked the gates correctly using UUIDs
- Verify both gates are registered in the database
- Check the `worldgates` table in your database

### Check the Database

Query directly:
```sql
-- View all servers
SELECT * FROM servers;

-- View all gates
SELECT * FROM worldgates;

-- View gate links
SELECT
  w1.id as source_gate,
  s1.name as source_server,
  w2.id as dest_gate,
  s2.name as dest_server
FROM worldgates w1
LEFT JOIN servers s1 ON w1.server_id = s1.id
LEFT JOIN worldgates w2 ON w1.destination_gate_id = w2.id
LEFT JOIN servers s2 ON w1.destination_server_id = s2.id
WHERE w1.destination_gate_id IS NOT NULL;
```

## Network Setup Tips

1. **Private Network**: Keep your database on a private network
2. **Firewall**: Only allow your game servers to access port 5432
3. **SSL/TLS**: Consider enabling encrypted database connections
4. **Backups**: Regularly backup your `worldgate` database
5. **Monitoring**: Watch database logs for suspicious activity

## Notes

- Gates only generate in unexplored chunks
- There's a 5-second cooldown between transfers
- Each server sends a heartbeat every 60 seconds
- Gates auto-register 2 seconds after generation
- Server URLs can be customized per server
- Players must manually connect to the destination server

## Support

For issues and questions, check:
- Server logs in `debug.txt`
- Database logs
- The mod's documentation files
