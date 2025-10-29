# Worldgate Setup Checklist

Use this checklist to ensure your multi-server worldgate network is configured correctly.

---

## 📋 Pre-Installation

- [ ] I have 2 or more Minetest/Luanti servers ready
- [ ] I have admin privileges on all servers
- [ ] I understand I need MySQL/MariaDB for multi-server setup
- [ ] I've read [MYSQL_SETUP_FOR_BEGINNERS.md](MYSQL_SETUP_FOR_BEGINNERS.md) (if new to databases)

---

## 🗄️ Database Setup

- [ ] MySQL/MariaDB is installed
- [ ] Database is secured with `mysql_secure_installation`
- [ ] Database `worldgate` exists
- [ ] Database user `worldgate` exists with a strong password
- [ ] User has permissions on the `worldgate` database
- [ ] Tables created successfully from `database_schema.sql`
- [ ] I can connect manually: `mysql -u worldgate -p worldgate`

**Test Command:**
```bash
mysql -u worldgate -p worldgate -e "SHOW TABLES;"
```

**Expected Output:**
```
+--------------------+
| Tables_in_worldgate|
+--------------------+
| servers            |
| transfer_logs      |
| worldgates         |
+--------------------+
```

---

## 🎮 Server 1 Configuration

- [ ] Worldgate mod installed in mods folder
- [ ] (Optional) `mysql_base` mod installed
- [ ] `world.mt` or `minetest.conf` configured with:
  - [ ] `worldgate.server_name` = Unique name
  - [ ] `worldgate.server_url` = Full connection URL
  - [ ] `worldgate.db_host` = Database IP/hostname
  - [ ] `worldgate.db_port` = 3306 (or custom port)
  - [ ] `worldgate.db_name` = worldgate
  - [ ] `worldgate.db_user` = worldgate
  - [ ] `worldgate.db_password` = Your password
- [ ] Server starts without errors
- [ ] Checked `debug.txt` for worldgate errors
- [ ] Server registered with `/worldgate_register_server`
- [ ] Server ID saved (looks like: `abc123-def456-...`)

**Test Command (in-game as admin):**
```
/worldgate_register_server
```

**Expected Output:**
```
Server registered with ID: xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
```

---

## 🎮 Server 2 Configuration

- [ ] Worldgate mod installed in mods folder
- [ ] (Optional) `mysql_base` mod installed
- [ ] `world.mt` or `minetest.conf` configured with:
  - [ ] `worldgate.server_name` = **Different** unique name
  - [ ] `worldgate.server_url` = **Different** connection URL
  - [ ] `worldgate.db_host` = **Same** database IP as Server 1
  - [ ] `worldgate.db_port` = **Same** database port
  - [ ] `worldgate.db_name` = **Same** database name
  - [ ] `worldgate.db_user` = **Same** database user
  - [ ] `worldgate.db_password` = **Same** database password
- [ ] Server starts without errors
- [ ] Checked `debug.txt` for worldgate errors
- [ ] Server registered with `/worldgate_register_server`
- [ ] Server ID saved (should be **different** from Server 1)

---

## 🎮 Server 3+ Configuration

Repeat Server 2 checklist for each additional server:
- [ ] Unique `server_name`
- [ ] Unique `server_url`
- [ ] Same database credentials as other servers
- [ ] Registered successfully
- [ ] Unique server ID

---

## 🔗 Gate Linking

- [ ] Located a worldgate beacon on Server 1 (red glowing block)
- [ ] Noted its position coordinates (x, y, z)
- [ ] Located a worldgate beacon on Server 2
- [ ] Noted its gate ID from database or in-game
- [ ] Used admin command to link gates
- [ ] Verified link in database

**Example Link Command:**
```lua
-- From Server 1's console or chat (if admin)
worldgate.link_gates_manual(
  {x=100, y=50, z=200},  -- Server 1 beacon position
  "destination-gate-id",  -- Server 2 gate ID
  "destination-server-id" -- Server 2 server ID
)
```

**Verify in Database:**
```sql
mysql -u worldgate -p worldgate -e "SELECT id, destination_gate_id, destination_server_id FROM worldgates WHERE destination_gate_id IS NOT NULL;"
```

---

## 🧪 Testing

- [ ] Right-clicked a linked servergate beacon
- [ ] Transfer screen appeared with portal image
- [ ] Destination server name displayed correctly
- [ ] Destination server URL shown
- [ ] Chat messages received with transfer instructions
- [ ] Successfully disconnected from Server 1
- [ ] Successfully reconnected to Server 2 using provided URL
- [ ] Transfer logged in `transfer_logs` table

**Verify Transfer Log:**
```sql
mysql -u worldgate -p worldgate -e "SELECT * FROM transfer_logs ORDER BY transfer_time DESC LIMIT 5;"
```

---

## 🎨 Optional: Transfer Screen Image

- [ ] Downloaded or created portal/tunnel themed image
- [ ] Renamed image to `worldgate_transfer.png`
- [ ] Placed in `mods/worldgate/textures/` directory
- [ ] Restarted servers
- [ ] Transfer screen now shows custom background

**File Path Should Be:**
```
mods/worldgate/textures/worldgate_transfer.png
```

See [TRANSFER_SCREEN.md](TRANSFER_SCREEN.md) for details.

---

## 🔍 Troubleshooting

If something isn't working, check these common issues:

### Database Connection Failed

**Symptoms:**
- Errors in `debug.txt` about MySQL
- Gates not appearing in database
- Registration fails

**Solutions:**
- [ ] Verify MySQL is running: `sudo systemctl status mariadb`
- [ ] Test connection manually: `mysql -u worldgate -p worldgate`
- [ ] Check firewall isn't blocking port 3306
- [ ] Verify credentials in `world.mt` match database user
- [ ] Check `worldgate.db_host` is correct (use `localhost` if same machine)

### Server Registration Failed

**Symptoms:**
- `/worldgate_register_server` returns error
- Server doesn't appear in `servers` table

**Solutions:**
- [ ] Check database connection (see above)
- [ ] Verify `worldgate.server_name` and `worldgate.server_url` are set
- [ ] Check for errors in `debug.txt`
- [ ] Try restarting the server

### Gates Not Linking

**Symptoms:**
- Link command seems to work but nothing happens
- Right-clicking beacon shows no destination

**Solutions:**
- [ ] Verify both gates exist in database
- [ ] Verify both servers are registered
- [ ] Check gate IDs are correct (UUIDs, not positions)
- [ ] Verify destination server ID is correct
- [ ] Query database directly to see link status

### Transfer Screen Not Showing Image

**Symptoms:**
- Transfer screen appears but no background
- Black screen with text

**Solutions:**
- [ ] Check file exists: `mods/worldgate/textures/worldgate_transfer.png`
- [ ] Verify filename is exactly `worldgate_transfer.png`
- [ ] Check file permissions (must be readable)
- [ ] Restart server after adding image
- [ ] Check `debug.txt` for texture loading errors

---

## 📊 Verification Queries

Use these SQL queries to verify your setup:

### List All Registered Servers
```sql
SELECT id, name, url FROM servers;
```

### List All Worldgates
```sql
SELECT id, server_id, destination_gate_id, destination_server_id FROM worldgates;
```

### List Linked Gates Only
```sql
SELECT id, server_id, destination_gate_id, destination_server_id
FROM worldgates
WHERE destination_gate_id IS NOT NULL;
```

### Recent Transfers
```sql
SELECT player_name, source_gate_id, destination_gate_id, destination_server_id, transfer_time
FROM transfer_logs
ORDER BY transfer_time DESC
LIMIT 10;
```

### Count Gates Per Server
```sql
SELECT s.name, COUNT(w.id) as gate_count
FROM servers s
LEFT JOIN worldgates w ON s.id = w.server_id
GROUP BY s.name;
```

---

## ✅ Final Verification

Your setup is complete when:

- [ ] All servers connect to the same database
- [ ] Each server has a unique ID in the `servers` table
- [ ] Worldgates are spawning in each server's world
- [ ] At least one pair of gates is linked
- [ ] Players can see the transfer screen when clicking linked beacons
- [ ] Players can successfully transfer between servers
- [ ] Transfers are being logged in `transfer_logs` table

---

## 🎉 Success!

If all items are checked, your worldgate network is operational!

### Next Steps:
1. Link more gates to expand the network
2. Customize transfer screen image
3. Configure gate spawning settings
4. Set up automated backups
5. Monitor transfer logs for activity

### Resources:
- **API Reference**: [API.md](API.md)
- **Architecture**: [ARCHITECTURE.md](ARCHITECTURE.md)
- **Database Queries**: [DATABASE_QUERIES.md](DATABASE_QUERIES.md)
- **Transfer Screen**: [TRANSFER_SCREEN.md](TRANSFER_SCREEN.md)

---

## 📝 Notes

Use this space to record your setup details:

**Server 1:**
- Name: _________________
- URL: _________________
- ID: _________________

**Server 2:**
- Name: _________________
- URL: _________________
- ID: _________________

**Server 3:**
- Name: _________________
- URL: _________________
- ID: _________________

**Database:**
- Host: _________________
- Port: _________________
- Password: _________________ (keep secure!)

**Linked Gates:**
1. Server _____ Gate _____ → Server _____ Gate _____
2. Server _____ Gate _____ → Server _____ Gate _____
3. Server _____ Gate _____ → Server _____ Gate _____
