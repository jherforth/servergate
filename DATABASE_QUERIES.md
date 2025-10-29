# Useful Database Queries

These SQL queries can be run directly on your MariaDB/MySQL server for managing your worldgate network.

Connect to your database:
```bash
mysql -u worldgate -p worldgate
```

## Server Management

### List All Active Servers
```sql
SELECT name, url, updated_at
FROM servers
WHERE is_active = 1
ORDER BY name;
```

### Find Inactive Servers
```sql
SELECT name, url, updated_at
FROM servers
WHERE is_active = 0
  OR updated_at < NOW() - INTERVAL 5 MINUTE
ORDER BY updated_at DESC;
```

### Deactivate a Server
```sql
UPDATE servers
SET is_active = 0
WHERE name = 'Server Name';
```

## Gate Management

### List All Gates
```sql
SELECT
  w.id,
  s.name as server_name,
  w.position,
  w.quality
FROM worldgates w
JOIN servers s ON w.server_id = s.id
ORDER BY s.name, w.position;
```

### Find Unlinked Gates
```sql
SELECT
  w.id,
  s.name as server_name,
  w.position
FROM worldgates w
JOIN servers s ON w.server_id = s.id
WHERE w.destination_gate_id IS NULL
ORDER BY s.name;
```

### Find Linked Gates
```sql
SELECT
  w.id as gate_id,
  s1.name as source_server,
  w.position as source_position,
  w2.id as dest_gate_id,
  s2.name as dest_server,
  w2.position as dest_position
FROM worldgates w
JOIN servers s1 ON w.server_id = s1.id
LEFT JOIN worldgates w2 ON w.destination_gate_id = w2.id
LEFT JOIN servers s2 ON w.destination_server_id = s2.id
WHERE w.destination_gate_id IS NOT NULL
ORDER BY s1.name;
```

### Count Gates Per Server
```sql
SELECT
  s.name,
  COUNT(w.id) as gate_count,
  COUNT(w.destination_gate_id) as linked_gates
FROM servers s
LEFT JOIN worldgates w ON s.id = w.server_id
GROUP BY s.name
ORDER BY gate_count DESC;
```

### Link Two Gates
```sql
-- Link gate A to gate B
UPDATE worldgates
SET
  destination_gate_id = 'uuid-of-gate-b',
  destination_server_id = 'uuid-of-server-b'
WHERE id = 'uuid-of-gate-a';

-- Link gate B to gate A (bidirectional)
UPDATE worldgates
SET
  destination_gate_id = 'uuid-of-gate-a',
  destination_server_id = 'uuid-of-server-a'
WHERE id = 'uuid-of-gate-b';
```

### Unlink a Gate
```sql
UPDATE worldgates
SET
  destination_gate_id = NULL,
  destination_server_id = NULL
WHERE id = 'gate-uuid';
```

## Transfer Analytics

### Recent Transfers
```sql
SELECT
  player_name,
  s1.name as from_server,
  s2.name as to_server,
  transfer_time,
  success
FROM transfer_logs t
LEFT JOIN servers s1 ON t.source_server_id = s1.id
LEFT JOIN servers s2 ON t.destination_server_id = s2.id
ORDER BY transfer_time DESC
LIMIT 50;
```

### Transfer Count by Player
```sql
SELECT
  player_name,
  COUNT(*) as transfer_count,
  COUNT(*) FILTER (WHERE success = true) as successful_transfers
FROM transfer_logs
GROUP BY player_name
ORDER BY transfer_count DESC;
```

### Transfer Count by Server Pair
```sql
SELECT
  s1.name as from_server,
  s2.name as to_server,
  COUNT(*) as transfer_count
FROM transfer_logs t
JOIN servers s1 ON t.source_server_id = s1.id
JOIN servers s2 ON t.destination_server_id = s2.id
GROUP BY s1.name, s2.name
ORDER BY transfer_count DESC;
```

### Failed Transfers
```sql
SELECT
  player_name,
  s1.name as from_server,
  s2.name as to_server,
  transfer_time
FROM transfer_logs t
LEFT JOIN servers s1 ON t.source_server_id = s1.id
LEFT JOIN servers s2 ON t.destination_server_id = s2.id
WHERE success = false
ORDER BY transfer_time DESC
LIMIT 50;
```

### Transfers in Last Hour
```sql
SELECT
  COUNT(*) as total_transfers,
  COUNT(*) FILTER (WHERE success = true) as successful,
  COUNT(DISTINCT player_name) as unique_players
FROM transfer_logs
WHERE transfer_time > NOW() - INTERVAL '1 hour';
```

## Maintenance

### Delete Old Transfer Logs (Older than 30 days)
```sql
DELETE FROM transfer_logs
WHERE transfer_time < NOW() - INTERVAL '30 days';
```

### Find Orphaned Gates (Server Deleted)
```sql
SELECT w.id, w.position
FROM worldgates w
LEFT JOIN servers s ON w.server_id = s.id
WHERE s.id IS NULL;
```

### Clean Up Orphaned Gates
```sql
DELETE FROM worldgates
WHERE server_id NOT IN (SELECT id FROM servers);
```

### Reset All Gate Links (USE WITH CAUTION)
```sql
UPDATE worldgates
SET
  destination_gate_id = NULL,
  destination_server_id = NULL;
```

## Network Topology

### Find Gate Pairs (Both Directions)
```sql
SELECT
  w1.id as gate_a,
  s1.name as server_a,
  w2.id as gate_b,
  s2.name as server_b
FROM worldgates w1
JOIN worldgates w2 ON w1.destination_gate_id = w2.id
JOIN servers s1 ON w1.server_id = s1.id
JOIN servers s2 ON w2.server_id = s2.id
WHERE w2.destination_gate_id = w1.id
ORDER BY s1.name, s2.name;
```

### Network Graph (Connection Matrix)
```sql
SELECT
  s1.name as from_server,
  s2.name as to_server,
  COUNT(*) as connection_count
FROM worldgates w
JOIN servers s1 ON w.server_id = s1.id
JOIN servers s2 ON w.destination_server_id = s2.id
WHERE w.destination_gate_id IS NOT NULL
GROUP BY s1.name, s2.name
ORDER BY s1.name, s2.name;
```

## Tips

1. **Always backup** before running UPDATE or DELETE queries
2. **Test queries** with SELECT before running modifications
3. **Use UUIDs** from the database, not manually typed
4. **Check constraints** - some deletes may cascade
5. **Monitor logs** table size and clean regularly

## Supabase Dashboard Shortcuts

- **Table Editor**: View and edit data visually
- **SQL Editor**: Run custom queries
- **Database > Roles**: Manage RLS policies
- **API Docs**: Auto-generated API documentation
- **Logs**: View database query logs
