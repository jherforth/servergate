# Worldgate User Guide

A simple guide for players and admins on how to use worldgates for server-to-server travel.

---

## What Are Worldgates?

Worldgates are ancient portal structures that spawn naturally throughout your world. Each worldgate has a beacon block at its center that allows you to travel between different game servers.

**Beacon Types:**
- **Dark Red Beacon** = Unlinked (not connected to any server)
- **Glowing Red Beacon** = Linked (ready for travel)

---

## For Players: How to Travel

### Finding Worldgates

Worldgates generate randomly as you explore. Look for large stone structures with a red glowing block (beacon) at the center.

### Traveling to Another Server

1. **Approach a linked worldgate** (beacon is glowing red)
2. **Right-click the beacon** or **crouch and punch it**
3. A dialog appears showing:
   - The destination server name
   - The connection URL
   - A big **GO!** button
4. **Click the GO! button**
5. You'll automatically connect to the destination server!

**⚠️ Important:** Your inventory does NOT transfer between servers. You'll lose all items when traveling!

---

## For Admins: How to Link Gates

### Automatic Linking (Recommended)

The easiest way to link gates is through the interactive beacon system:

#### Step 1: Link from Server A to Server B

1. Find an unlinked beacon on Server A (dark red)
2. **Crouch and punch** the beacon (or right-click it)
3. A dialog appears showing all available gates from other servers
4. The list shows:
   - Server name
   - Gate position
   - Gate ID (short version)
5. **Click on a gate** from Server B to select it
6. **Click "Link to Selected Gate"**
7. Done! The beacon lights up (glowing red)

#### Step 2: Link from Server B back to Server A

1. Find a beacon on Server B
2. Repeat the same process
3. Select the gate from Server A
4. Link complete!

Now players can travel both directions!

### Using Commands (Advanced)

If you prefer using commands:

#### Get Gate Information
```
/worldgate_info
```
Look at any beacon and run this command to see:
- Gate UUID
- Destination (if linked)
- Server information

#### Link by Gate UUID
```
/worldgate_link <destination_gate_uuid>
```
Look at the source beacon and run this command with the destination gate's UUID.

The system automatically:
- Finds which server the destination gate is on
- Updates the database
- Lights up the beacon

#### List All Gates
```
/worldgate_list
```
Shows all gates registered on your current server from the database.

---

## How the Database Works

### Automatic Registration

When a worldgate generates:
1. A unique UUID is created for the gate
2. 2 seconds later, it registers in the shared PostgreSQL database
3. All information is stored: position, server, style, quality

### Server Heartbeat

Each server sends a "heartbeat" every 60 seconds to show it's active. This ensures the gate list only shows gates from running servers.

### Gate Information Stored

For each gate, the database stores:
- Unique ID (UUID)
- Server ID
- Position coordinates
- Base schematic style
- Decoration style
- Quality level
- Destination (if linked)
- Creation timestamp

---

## Tips and Best Practices

### For Players

1. **Explore First**: Travel with an empty inventory to scout new servers
2. **Mark Your Gates**: Use signs or landmarks to remember gate locations
3. **Check Destination**: Read the destination info before clicking GO!
4. **Coordinate**: Plan with friends which server to meet on

### For Admins

1. **Link Strategically**: Connect servers that complement each other
2. **Balance Network**: Don't link every gate - create interesting routes
3. **Document Links**: Keep a map or list of gate connections
4. **Monitor Usage**: Check transfer logs to see popular routes
5. **Regular Backups**: Backup your database regularly
6. **Test Links**: After linking, test both directions

---

## Troubleshooting

### "Database not available"

**Cause:** PostgreSQL is not configured or not accessible

**Fix:**
1. Check database settings in `world.mt`
2. Verify PostgreSQL is running
3. Test connection with: `psql -U worldgate -d worldgate -c "SELECT 1;"`

### "No unlinked gates available"

**Cause:** No other servers have unlinked gates

**Solutions:**
1. Make sure other servers are running
2. Check that gates have generated on other servers
3. Verify servers can connect to the database
4. Wait for gates to generate (they only spawn in unexplored areas)

### "Gate has no UUID"

**Cause:** Gate didn't register in database (rare)

**Fix:**
1. Note the gate position
2. Check server logs for errors
3. Restart the server
4. If still failing, check database connectivity

### "Transfer failed"

**Cause:** Destination server URL is incorrect or server is offline

**Fix:**
1. Verify destination server is running
2. Check server URL in database: `SELECT url FROM servers;`
3. Test manual connection: `/connect <server_url>`
4. Update server URL if needed

### Beacon won't interact

**Cause:** Permissions or broken node

**Try:**
1. Make sure you're close enough (within reach)
2. Check you have permission to use worldgates
3. Verify it's actually a beacon (not a decoration block)
4. Try both right-click and crouch-punch

---

## Advanced: Database Queries

### View All Servers
```sql
SELECT id, name, url, is_active FROM servers;
```

### View All Gates
```sql
SELECT id, server_id, position, destination_gate_id
FROM worldgates
ORDER BY created_at;
```

### View Gate Links
```sql
SELECT
  w1.id as source_gate,
  s1.name as source_server,
  w2.id as dest_gate,
  s2.name as dest_server
FROM worldgates w1
JOIN servers s1 ON w1.server_id = s1.id
LEFT JOIN worldgates w2 ON w1.destination_gate_id = w2.id
LEFT JOIN servers s2 ON w1.destination_server_id = s2.id
WHERE w1.destination_gate_id IS NOT NULL;
```

### Find Unlinked Gates
```sql
SELECT g.id, s.name as server, g.position
FROM worldgates g
JOIN servers s ON g.server_id = s.id
WHERE g.destination_gate_id IS NULL
ORDER BY s.name;
```

---

## Configuration Reference

### Essential Settings (world.mt)

```ini
# Server identification
servergate.server_name = Fantasy Realm
servergate.server_url = minetest://game.example.com:30000

# Database connection
servergate.db_host = localhost
servergate.db_port = 5432
servergate.db_name = worldgate
servergate.db_user = worldgate
servergate.db_password = your_secure_password

# Optional: Disable auto-linking (for server network)
servergate.native.link = false
```

### Optional Settings

```ini
# Gate generation
servergate.mapgen = true              # Enable/disable generation
servergate.native.spread = 1000       # Distance between gates
servergate.ymin = -29900              # Minimum height
servergate.ymax = 29900               # Maximum height

# Appearance
servergate.beaconglow = true          # Glowing beacons
servergate.breakage = 8               # Structure damage %

# Spawning behavior
servergate.underwaterspawn = false    # Spawn underwater
servergate.midairspawn = true         # Spawn in air
```

---

## FAQ

**Q: Can I transfer items between servers?**
A: No, inventories do not transfer. This is a technical limitation.

**Q: Do I need admin privileges to travel?**
A: No, any player can use linked gates. Only linking requires admin privileges.

**Q: Can I link one gate to multiple destinations?**
A: No, each gate links to exactly one destination.

**Q: How many gates can I have?**
A: Unlimited! Gates spawn naturally as you explore.

**Q: Can I manually place gates?**
A: Currently no, gates only generate naturally. Future versions may add this.

**Q: Do gates work in single-player?**
A: Yes, but they won't connect to other servers without database setup.

**Q: Can I delete a gate?**
A: Yes, gates are made of breakable blocks. Or unlink with SQL: `UPDATE worldgates SET destination_gate_id = NULL WHERE id = 'gate-uuid';`

**Q: What happens if the destination server is offline?**
A: The transfer will fail. Players can see the error and try again later.

**Q: Can I rename a server?**
A: Yes, update both `servergate.server_name` in config and the database: `UPDATE servers SET name = 'New Name' WHERE id = 'server-uuid';`

---

## Support

For issues and questions:
1. Check server logs: `debug.txt`
2. Review database connectivity
3. Consult [SETUP_CHECKLIST.md](SETUP_CHECKLIST.md)
4. Check [TROUBLESHOOTING](QUICKSTART.md#troubleshooting) section

---

## Quick Command Reference

```
/worldgate_info              # Get gate details
/worldgate_link <gate_uuid>  # Link to specific gate
/worldgate_list              # List all gates on server
```

**Interactive Actions:**
- **Crouch + Punch beacon** or **Right-click beacon** → Link/Travel dialog
- **Select destination** → Link gates
- **Click GO!** → Travel instantly

---

Enjoy exploring the worldgate network!
