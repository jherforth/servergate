# Worldgate Server Connector - Quick Start Guide

## Overview

This guide will help you set up a network of Luanti/Minetest servers connected via Worldgates using your own MariaDB database.

## Prerequisites

- Two or more Luanti/Minetest servers
- MariaDB or MySQL server on your private network
- Server admin access with `server` privilege
- (Optional) `mysql_base` mod for Minetest/Luanti

## Step 1: Set Up MariaDB Database

On your database server:

1. Install MariaDB:
```bash
sudo apt-get install mariadb-server
```

2. Create the database and tables:
```bash
mysql -u root -p < database_schema.sql
```

3. Make sure the database is accessible from your game servers

4. Note your database connection details:
   - Host (e.g., `192.168.1.100`)
   - Port (default: `3306`)
   - Database name (`worldgate`)
   - Username (`worldgate`)
   - Password (you set this in the SQL file)

## Step 2: Install the Mod

1. Install this mod on all servers in your network
2. (Optional) Install `mysql_base` mod for MySQL connectivity
   - Without this, mod will work in single-server fallback mode
3. Make sure all servers can reach your database

## Step 3: Configure Each Server

Add to `minetest.conf` on each server (use different names and URLs):

**Server Alpha:**
```
worldgate.server_name = Server Alpha
worldgate.server_url = minetest://alpha.example.com:30000

worldgate.db_host = 192.168.1.100
worldgate.db_port = 3306
worldgate.db_name = worldgate
worldgate.db_user = worldgate
worldgate.db_password = your_secure_password

worldgate.native.link = false
```

**Server Beta:**
```
worldgate.server_name = Server Beta
worldgate.server_url = minetest://beta.example.com:30001

worldgate.db_host = 192.168.1.100
worldgate.db_port = 3306
worldgate.db_name = worldgate
worldgate.db_user = worldgate
worldgate.db_password = your_secure_password

worldgate.native.link = false
```

## Step 4: Start Servers and Explore

1. Start all servers
2. Explore the world on each server to generate worldgates
3. Check the server logs to see gates being registered
4. Look for messages like: `Worldgate: Server registered with ID: ...`

## Step 5: Link Gates Between Servers

### Find Gate IDs

On Server Alpha:
1. Find a worldgate beacon (glowing blue block)
2. Look at it and run: `/worldgate_info`
3. Note the `Gate ID` (a UUID like `12345678-abcd-...`)

On Server Beta:
1. Find another worldgate beacon
2. Look at it and run: `/worldgate_info`
3. Note the `Gate ID`

### Get Server IDs

Query your database directly:
```sql
SELECT id, name, url FROM servers;
```

Or check the server logs when they start - they print their server ID.

### Link the Gates

On Server Alpha, while looking at a beacon:
```
/worldgate_link <gate_id_from_beta> <server_id_of_beta>
```

On Server Beta, link back to Alpha:
```
/worldgate_link <gate_id_from_alpha> <server_id_of_alpha>
```

## Step 6: Test the Connection

1. On Server Alpha, right-click the linked beacon
2. You should see:
   ```
   Connect to destination: Server Beta at minetest://beta.example.com:30001
   Copy this command: /connect minetest://beta.example.com:30001
   ```
3. Players can copy/paste that command to switch servers

## Admin Commands

- `/worldgate_info` - Get info about the gate you're looking at
- `/worldgate_link <dest_gate_id> <dest_server_id>` - Link a gate
- `/worldgate_list` - List all gates on this server

## Troubleshooting

### "MySQL mod not found, using mod_storage as fallback"
- Install the `mysql_base` mod for multi-server support
- In fallback mode, gates only work locally

### "Failed to register server"
- Check database credentials in minetest.conf
- Verify network connectivity to database server
- Check MariaDB logs for connection errors

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
2. **Firewall**: Only allow your game servers to access port 3306
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
