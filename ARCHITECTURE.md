# Worldgate Server Connector Architecture

## Simple Explanation

Think of it like a train network:
- **Worldgates** = Train stations (they spawn in your world)
- **Servergates** = Platforms (the red beacons you click)
- **Database** = The central schedule board (knows where all stations connect)
- **Multiple Servers** = Different cities with their own train stations

Players can travel between "cities" (servers) by using the "train stations" (worldgates).

---

## Technical Architecture

### Single Machine, Multiple Servers

This is the most common setup for testing or small networks:

```
┌─────────────────────────────────────────────────────────────┐
│                    YOUR COMPUTER / VPS                       │
│                                                              │
│  ┌──────────────┐   ┌──────────────┐   ┌──────────────┐    │
│  │ Minetest     │   │ Minetest     │   │ Minetest     │    │
│  │ Server 1     │   │ Server 2     │   │ Server 3     │    │
│  │              │   │              │   │              │    │
│  │ Port: 30000  │   │ Port: 30001  │   │ Port: 30002  │    │
│  │ World: Alpha │   │ World: Beta  │   │ World: Gamma │    │
│  └──────┬───────┘   └──────┬───────┘   └──────┬───────┘    │
│         │                  │                  │             │
│         └──────────────────┼──────────────────┘             │
│                            ▼                                │
│                   ┌─────────────────┐                       │
│                   │   PostgreSQL    │                       │
│                   │    Database     │                       │
│                   │  (localhost)    │                       │
│                   └─────────────────┘                       │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

**Key Points:**
- All servers run on the same machine
- Different ports for each world (30000, 30001, 30002)
- Database connection: `localhost` or `127.0.0.1`
- Players connect to: `yourdomain.com:30000`, `yourdomain.com:30001`, etc.

---

### Multiple Machines

For larger networks or distributed hosting:

```
┌─────────────────────────┐
│   Database Server       │
│   192.168.1.10          │
│                         │
│  ┌──────────────────┐   │
│  │   PostgreSQL     │   │
│  │  Port: 5432      │   │
│  └──────────────────┘   │
└────────────┬────────────┘
             │
    ┌────────┼────────┐
    │        │        │
    ▼        ▼        ▼
┌───────┐ ┌───────┐ ┌───────┐
│Server │ │Server │ │Server │
│   A   │ │   B   │ │   C   │
│       │ │       │ │       │
│:30000 │ │:30000 │ │:30000 │
└───────┘ └───────┘ └───────┘
  Alpha     Beta     Gamma
```

**Key Points:**
- Separate database server
- Each game server connects via network IP
- Firewall rules needed for port 5432
- Better performance for large networks

---

## Data Flow: Player Transfer

### Step 1: Player Clicks Servergate
```
┌─────────┐
│ Player  │ Right-clicks red beacon
└────┬────┘
     │
     ▼
┌──────────────────┐
│ Worldgate Mod    │ "What gate is this?"
│ (Server A)       │
└────┬─────────────┘
     │
     ▼
┌──────────────────┐
│ PostgreSQL DB    │ "Gate ABC123 → Server B, Gate XYZ789"
└────┬─────────────┘
     │
     ▼
┌──────────────────┐
│ Worldgate Mod    │ "Get info for Server B"
│ (Server A)       │
└────┬─────────────┘
     │
     ▼
┌──────────────────┐
│ MySQL Database   │ "Server B is at minetest://play.server.com:30001"
└────┬─────────────┘
     │
     ▼
┌──────────────────┐
│ Transfer Screen  │ Shows portal image + connection info
│ (Player sees)    │
└──────────────────┘
```

### Step 2: Player Transfers
```
┌─────────┐
│ Player  │ Disconnects from Server A
└────┬────┘
     │
     │ Manual step: Player reconnects to new address
     │
     ▼
┌──────────────────┐
│ Server B         │ Player joins at destination gate
└──────────────────┘
     │
     ▼
┌──────────────────┐
│ MySQL Database   │ Log: "Player traveled from A to B"
└──────────────────┘
```

---

## Database Tables

### `servers`
Stores information about each Minetest server in your network.

```
┌──────────────┬───────────────┬─────────────────────────────┐
│ id (UUID)    │ name          │ url                         │
├──────────────┼───────────────┼─────────────────────────────┤
│ abc-123      │ Fantasy World │ minetest://game.com:30000   │
│ def-456      │ Desert World  │ minetest://game.com:30001   │
│ ghi-789      │ Space World   │ minetest://game.com:30002   │
└──────────────┴───────────────┴─────────────────────────────┘
```

### `worldgates`
Stores each gate's location and where it links to.

```
┌──────────┬───────────┬──────────┬─────────────────┬─────────────────────┐
│ id       │ server_id │ position │ destination_id  │ destination_server  │
├──────────┼───────────┼──────────┼─────────────────┼─────────────────────┤
│ gate-001 │ abc-123   │ (x,y,z)  │ gate-205        │ def-456             │
│ gate-002 │ abc-123   │ (x,y,z)  │ NULL            │ NULL (unlinked)     │
│ gate-205 │ def-456   │ (x,y,z)  │ gate-001        │ abc-123             │
└──────────┴───────────┴──────────┴─────────────────┴─────────────────────┘
```

### `transfer_logs`
Records every player transfer for analytics and debugging.

```
┌─────────────┬──────────┬────────────┬─────────────┬─────────────────┐
│ player_name │ from_gat │ to_gate    │ to_server   │ timestamp       │
├─────────────┼──────────┼────────────┼─────────────┼─────────────────┤
│ Steve       │ gate-001 │ gate-205   │ def-456     │ 2024-01-15 14:30│
│ Alex        │ gate-205 │ gate-001   │ abc-123     │ 2024-01-15 14:35│
└─────────────┴──────────┴────────────┴─────────────┴─────────────────┘
```

---

## Component Breakdown

### Worldgate Mod (This Mod)
**What it does:**
- Generates worldgate structures in your world
- Places servergate beacons (red glowing blocks)
- Handles player right-clicks on beacons
- Queries database for gate destinations
- Shows transfer screen to players
- Logs transfers to database

**What it does NOT do:**
- Automatically teleport players (Minetest limitation)
- Host the database
- Configure network settings

### PostgreSQL Database
**What it stores:**
- List of all servers in your network
- Every worldgate's location and links
- Transfer history logs

**What it needs:**
- Accessible from all game servers
- Proper user permissions
- Network connectivity

### PostgreSQL Backend (Native Support)
**What it provides:**
- Native PostgreSQL connectivity in Minetest
- Built-in support, no external mods needed
- Configured via world.mt settings

**Fallback:**
- Without PostgreSQL configured, mod uses `mod_storage` (single-server only)
- Multi-server support requires proper PostgreSQL configuration

---

## Scaling Considerations

### Small Network (2-5 servers)
- ✅ Single database server is fine
- ✅ Same machine for database + game servers works
- ✅ Basic PostgreSQL configuration sufficient

### Medium Network (5-20 servers)
- ⚠️ Consider dedicated database server
- ⚠️ Enable PostgreSQL query caching
- ⚠️ Monitor database connections

### Large Network (20+ servers)
- ⚠️ Dedicated database server required
- ⚠️ Database replication for redundancy
- ⚠️ Connection pooling essential
- ⚠️ Consider read replicas
- ⚠️ Regular database optimization

---

## Security Layers

```
┌─────────────────────────────────────────────────────┐
│                  THE INTERNET                       │
└───────────────────────┬─────────────────────────────┘
                        │
                ┌───────▼────────┐
                │   Firewall     │  Block 5432 from internet
                └───────┬────────┘
                        │
        ┌───────────────┼───────────────┐
        │               │               │
   ┌────▼────┐    ┌────▼────┐    ┌────▼────┐
   │Server A │    │Server B │    │Server C │
   │ :30000  │    │ :30001  │    │ :30002  │  Public ports
   └────┬────┘    └────┬────┘    └────┬────┘
        │               │               │
        └───────────────┼───────────────┘
                        │
                   ┌────▼─────┐
                   │ Database │  Private port 5432
                   │ :5432    │  Only accessible internally
                   └──────────┘
```

**Security Best Practices:**
1. **Firewall**: Block port 5432 from internet
2. **Strong Passwords**: 16+ characters for database user
3. **Limited Permissions**: Database user only needs access to `worldgate` database
4. **No Superuser Access**: Never use postgres superuser in configs
5. **Backups**: Regular database backups

---

## Troubleshooting Flow

```
Problem: "Gates not linking"
    │
    ├─→ Check database connection
    │   └─→ Can you connect with psql command?
    │       ├─→ Yes: Database is fine
    │       └─→ No: Check credentials in world.mt
    │
    ├─→ Check if servers are registered
    │   └─→ Run /worldgate_register_server on each
    │
    └─→ Check if gates exist in database
        └─→ Query: SELECT * FROM worldgates;
```

---

## Next Steps

1. **Setup**: Follow [POSTGRESQL_SETUP.md](POSTGRESQL_SETUP.md)
2. **Configure**: Add database credentials to each server
3. **Register**: Run `/worldgate_register_server` on each server
4. **Link**: Use admin commands to link gates
5. **Test**: Right-click a linked servergate beacon

---

## Additional Resources

- **API Documentation**: `API.md`
- **Database Queries**: `DATABASE_QUERIES.md`
- **Quick Start**: `QUICKSTART.md`
- **Transfer Screen**: `TRANSFER_SCREEN.md`
