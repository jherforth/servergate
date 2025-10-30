# Worldgate Quick Reference

Essential commands and queries for daily management of your worldgate network.

---

## 🎮 Player Actions (No Admin Required!)

### Link Gates Between Servers
1. **Crouch-punch or right-click** an unlinked beacon (dark red)
2. Select a destination from the list
3. Click "Link to Selected Gate"
4. Done! Beacon lights up (glowing red)

### Travel to Another Server
1. **Right-click or crouch-punch** a linked beacon (glowing red)
2. Click the **GO!** button in the dialog
3. You're automatically transferred!

---

## 🔧 Admin Commands (Optional)

### Get Gate Information
```
/worldgate_info
```
Look at a beacon and run this to see its Gate ID, destination, and server info.

### Link Gates by UUID
```
/worldgate_link <destination_gate_id>
```
Look at a beacon and run this to link it to another gate by UUID.
The system automatically finds which server the destination is on.

### List All Gates
```
/worldgate_list
```
Shows all gates registered on this server from the database.

### Advanced Lua Functions
```lua
-- Get gate info from metadata
local meta = minetest.get_meta({x=100, y=50, z=200})
print(meta:get_string("servergate:gate_id"))

-- Link gates programmatically (for automation)
servergate.db.link_gates(
  "source-gate-uuid",
  "dest-gate-uuid",
  "dest-server-uuid",
  callback_function
)
```

---

## 🗄️ Database Quick Queries

### View All Servers
```sql
SELECT id, name, url FROM servers;
```

### View All Gates
```sql
SELECT id, server_id, position, destination_gate_id
FROM worldgates
ORDER BY server_id;
```

### View Linked Gates Only
```sql
SELECT w1.id as gate1, s1.name as server1,
       w1.destination_gate_id as gate2, s2.name as server2
FROM worldgates w1
JOIN servers s1 ON w1.server_id = s1.id
LEFT JOIN servers s2 ON w1.destination_server_id = s2.id
WHERE w1.destination_gate_id IS NOT NULL;
```

### Recent Transfers (Last 10)
```sql
SELECT player_name, source_gate_id, destination_gate_id,
       transfer_time, success
FROM transfer_logs
ORDER BY transfer_time DESC
LIMIT 10;
```

### Transfer Count by Player
```sql
SELECT player_name, COUNT(*) as transfers
FROM transfer_logs
WHERE success = TRUE
GROUP BY player_name
ORDER BY transfers DESC;
```

### Unlinked Gates
```sql
SELECT id, server_id, position
FROM worldgates
WHERE destination_gate_id IS NULL;
```

---

## 🔍 Troubleshooting Commands

### Test Database Connection
```bash
psql -U worldgate -d worldgate -c "SELECT 1;"
```

### Check Server Registration
```sql
SELECT * FROM servers WHERE name = 'Your Server Name';
```

### Verify Gate Exists
```sql
SELECT * FROM worldgates WHERE id = 'your-gate-uuid';
```

### Check PostgreSQL Service
```bash
sudo systemctl status postgresql
```

### Restart PostgreSQL
```bash
sudo systemctl restart postgresql
```

### View Recent PostgreSQL Errors
```bash
sudo tail -n 50 /var/log/postgresql/postgresql-*.log
```

---

## 📁 Important File Locations

### Configuration
```
/path/to/minetest/worlds/worldname/world.mt
```

### Debug Log
```
/path/to/minetest/debug.txt
```

### Mod Directory
```
/path/to/minetest/mods/worldgate/
```

### Transfer Image
```
/path/to/minetest/mods/worldgate/textures/worldgate_transfer.png
```

---

## ⚙️ Common Configuration

### Minimal world.mt
```ini
servergate.server_name = Fantasy Server
servergate.server_url = minetest://game.example.com:30000
servergate.db_host = localhost
servergate.db_port = 5432
servergate.db_name = worldgate
servergate.db_user = worldgate
servergate.db_password = your_secure_password
```

### Disable Gate Generation
```ini
servergate.mapgen = false
```

### Adjust Gate Spacing
```ini
servergate.native.spread = 2000
```

### Change Height Limits
```ini
servergate.ymin = -5000
servergate.ymax = 5000
```

---

## 🛠️ Maintenance Tasks

### Backup Database
```bash
pg_dump -U worldgate worldgate > worldgate_backup_$(date +%Y%m%d).sql
```

### Restore Database
```bash
psql -U worldgate -d worldgate < worldgate_backup_20240115.sql
```

### Clean Old Transfer Logs (> 30 days)
```sql
DELETE FROM transfer_logs
WHERE transfer_time < NOW() - INTERVAL '30 days';
```

### Optimize Database
```sql
VACUUM ANALYZE servers;
VACUUM ANALYZE worldgates;
VACUUM ANALYZE transfer_logs;
```

---

## 📊 Statistics Queries

### Total Transfers
```sql
SELECT COUNT(*) FROM transfer_logs WHERE success = TRUE;
```

### Busiest Gates
```sql
SELECT source_gate_id, COUNT(*) as uses
FROM transfer_logs
GROUP BY source_gate_id
ORDER BY uses DESC
LIMIT 10;
```

### Busiest Routes
```sql
SELECT s1.name as from_server, s2.name as to_server, COUNT(*) as transfers
FROM transfer_logs t
JOIN servers s1 ON t.source_server_id = s1.id
JOIN servers s2 ON t.destination_server_id = s2.id
GROUP BY s1.name, s2.name
ORDER BY transfers DESC;
```

### Daily Transfer Activity
```sql
SELECT DATE(transfer_time) as date, COUNT(*) as transfers
FROM transfer_logs
WHERE transfer_time >= NOW() - INTERVAL '7 days'
GROUP BY DATE(transfer_time)
ORDER BY date;
```

---

## 🔐 Security Commands

### Create Database User
```sql
CREATE USER worldgate WITH PASSWORD 'strong_password';
GRANT ALL PRIVILEGES ON DATABASE worldgate TO worldgate;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO worldgate;
```

### Change Database Password
```sql
ALTER USER worldgate WITH PASSWORD 'new_password';
```

### Check User Permissions
```sql
\du worldgate
```

### List All Database Users
```sql
\du
```

---

## 🚨 Emergency Fixes

### Gate Stuck/Not Working
```lua
-- In server console, force re-register gate
local pos = {x=100, y=50, z=200}
local meta = minetest.get_meta(pos)
meta:set_string("servergate:gate_id", "")  -- Clear ID
-- Then restart server to regenerate
```

### Unlink a Gate
```sql
UPDATE worldgates
SET destination_gate_id = NULL, destination_server_id = NULL
WHERE id = 'problem-gate-uuid';
```

### Remove Failed Transfers
```sql
DELETE FROM transfer_logs WHERE success = FALSE;
```

### Reset Server Registration
```sql
DELETE FROM servers WHERE id = 'server-uuid-to-remove';
-- Then re-register with /worldgate_register_server
```

---

## 📖 Full Documentation

- [SETUP_CHECKLIST.md](SETUP_CHECKLIST.md) - Setup verification
- [POSTGRESQL_SETUP.md](POSTGRESQL_SETUP.md) - Database installation
- [ARCHITECTURE.md](ARCHITECTURE.md) - System architecture
- [API.md](API.md) - Full API reference
- [DATABASE_QUERIES.md](DATABASE_QUERIES.md) - Advanced queries
- [TRANSFER_SCREEN.md](TRANSFER_SCREEN.md) - Customize transfer UI

---

## 💡 Pro Tips

1. **Always backup before making changes:**
   ```bash
   pg_dump -U worldgate worldgate > backup.sql
   ```

2. **Test connections after config changes:**
   ```bash
   psql -U worldgate -d worldgate -c "SELECT 1;"
   ```

3. **Monitor debug.txt for errors:**
   ```bash
   tail -f /path/to/minetest/debug.txt | grep worldgate
   ```

4. **Keep server IDs documented:**
   - Create a text file mapping server names to IDs
   - Makes linking gates much easier

5. **Regular maintenance schedule:**
   - Weekly: Check transfer logs for errors
   - Monthly: Optimize database tables
   - Quarterly: Archive old transfer logs

6. **Use descriptive server names:**
   - Bad: "Server 1", "Test Server"
   - Good: "Fantasy World", "Desert Realm", "Space Station"

---

## 🆘 Getting Help

If you're stuck:

1. Check [SETUP_CHECKLIST.md](SETUP_CHECKLIST.md) troubleshooting section
2. Review `debug.txt` for error messages
3. Verify database connectivity
4. Check all servers use identical database config
5. Ensure all servers are registered

Most issues are typos in configuration files!
