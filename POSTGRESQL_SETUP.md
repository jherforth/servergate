# PostgreSQL Setup Guide for Worldgate Server Connector

This guide explains how to set up PostgreSQL for the Worldgate Server Connector on your private network.

## Why PostgreSQL?

- **Self-hosted**: You control the database on your own infrastructure
- **Private**: Database stays on your private network
- **Native Support**: Minetest/Luanti has built-in PostgreSQL support
- **No Extra Mods**: Unlike MySQL/MariaDB, no additional mods required
- **Performance**: Excellent performance for multi-server setups
- **Reliability**: Battle-tested, ACID-compliant database

## Architecture Overview

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│  Server A   │     │  Server B   │     │  Server C   │
│  (Alpha)    │     │  (Beta)     │     │  (Gamma)    │
└──────┬──────┘     └──────┬──────┘     └──────┬──────┘
       │                   │                   │
       │   PostgreSQL Connection (5432)        │
       └───────────────────┼───────────────────┘
                           │
                    ┌──────▼──────┐
                    │ PostgreSQL  │
                    │   Database  │
                    │  (Private   │
                    │   Network)  │
                    └─────────────┘
```

## Installation Steps

### 1. Install PostgreSQL Server

#### Ubuntu/Debian:
```bash
sudo apt-get update
sudo apt-get install postgresql postgresql-contrib
```

#### CentOS/RHEL:
```bash
sudo yum install postgresql-server postgresql-contrib
sudo postgresql-setup initdb
sudo systemctl start postgresql
sudo systemctl enable postgresql
```

#### Fedora:
```bash
sudo dnf install postgresql-server postgresql-contrib
sudo postgresql-setup --initdb
sudo systemctl start postgresql
sudo systemctl enable postgresql
```

### 2. Configure PostgreSQL Authentication

Edit the PostgreSQL configuration to allow network connections from your game servers.

```bash
sudo nano /etc/postgresql/*/main/pg_hba.conf
```

Add these lines (adjust IP addresses for your network):

```conf
# Allow worldgate user from local network
host    worldgate    worldgate    192.168.1.0/24    md5
```

Edit the main configuration:

```bash
sudo nano /etc/postgresql/*/main/postgresql.conf
```

Change the listen address:

```conf
listen_addresses = '*'  # or specify your private network interface
```

Restart PostgreSQL:

```bash
sudo systemctl restart postgresql
```

### 3. Create the Worldgate Database

Switch to the postgres user and create the database:

```bash
sudo -u postgres psql
```

In the PostgreSQL prompt:

```sql
CREATE DATABASE worldgate;
\q
```

### 4. Run the Schema Script

Apply the worldgate schema:

```bash
cd /path/to/minetest/mods/worldgate/
sudo -u postgres psql -d worldgate < database_schema.sql
```

Or manually:

```bash
sudo -u postgres psql worldgate
```

Then paste the contents of `database_schema.sql` into the PostgreSQL prompt.

### 5. Verify the Setup

Check that the tables were created:

```bash
sudo -u postgres psql worldgate -c "\dt"
```

You should see:
- servers
- worldgates
- transfer_logs

### 6. Test the Connection

From each game server, test the PostgreSQL connection:

```bash
psql -h 192.168.1.100 -U worldgate -d worldgate
```

Enter the password when prompted. If you can connect, you're all set!

### 7. Configure Firewall

Allow connections from your game servers only:

#### UFW (Ubuntu):
```bash
sudo ufw allow from 192.168.1.10 to any port 5432
sudo ufw allow from 192.168.1.11 to any port 5432

# Or allow entire private subnet
sudo ufw allow from 192.168.1.0/24 to any port 5432
```

#### firewalld (CentOS/RHEL):
```bash
sudo firewall-cmd --permanent --add-rich-rule='rule family="ipv4" source address="192.168.1.0/24" port protocol="tcp" port="5432" accept'
sudo firewall-cmd --reload
```

## Minetest Configuration

### Option 1: Using Native PostgreSQL Backend (Recommended)

Configure each Minetest server to use PostgreSQL natively.

Edit `world.mt` in your world directory:

```ini
# Use PostgreSQL as the world database backend
backend = postgresql
pgsql_connection = host=192.168.1.100 port=5432 user=worldgate password=your_password dbname=worldgate

# Server identification (unique per server)
worldgate.server_name = My Server Alpha
worldgate.server_url = minetest://alpha.example.com:30000

# Database configuration (for mod queries)
worldgate.db_host = 192.168.1.100
worldgate.db_port = 5432
worldgate.db_name = worldgate
worldgate.db_user = worldgate
worldgate.db_password = your_password

# Recommended settings
worldgate.native.link = false
```

### Option 2: Using Mod Storage (Single Server)

If you don't need multi-server support, you can use local storage:

```ini
# Just set the server identification
worldgate.server_name = My Server
worldgate.server_url = minetest://localhost:30000
```

## Security Best Practices

### 1. Use Strong Passwords

```sql
-- Generate a secure password for the database user
-- Use a password manager or: openssl rand -base64 32
ALTER USER worldgate WITH PASSWORD 'Ax9Kp2Mn8Qr5Wt7Yv3Zb6Cd1Ef4Gh0';
```

### 2. Restrict Network Access

Edit `pg_hba.conf` to allow only specific servers:

```conf
# Specific servers only
host    worldgate    worldgate    192.168.1.10/32    md5
host    worldgate    worldgate    192.168.1.11/32    md5
```

### 3. Enable SSL/TLS (Recommended)

Generate SSL certificates:

```bash
sudo -u postgres openssl req -new -x509 -days 365 -nodes -text -out /var/lib/postgresql/*/main/server.crt -keyout /var/lib/postgresql/*/main/server.key
sudo chmod 600 /var/lib/postgresql/*/main/server.key
sudo chown postgres:postgres /var/lib/postgresql/*/main/server.*
```

Enable SSL in `postgresql.conf`:

```conf
ssl = on
ssl_cert_file = 'server.crt'
ssl_key_file = 'server.key'
```

Update `pg_hba.conf` to require SSL:

```conf
hostssl    worldgate    worldgate    192.168.1.0/24    md5
```

### 4. Regular Backups

Backup your database regularly:

```bash
# Daily backup
pg_dump -U worldgate worldgate > worldgate_backup_$(date +%Y%m%d).sql

# Automated with cron
0 2 * * * pg_dump -U worldgate worldgate > /backups/worldgate_$(date +\%Y\%m\%d).sql
```

### 5. Monitor Connections

Check who's connected:

```sql
SELECT datname, usename, client_addr, state FROM pg_stat_activity WHERE datname = 'worldgate';
```

## Performance Tuning

### For Small Networks (2-5 servers)

Default PostgreSQL settings are usually sufficient.

### For Larger Networks (10+ servers)

Edit `/etc/postgresql/*/main/postgresql.conf`:

```conf
# Connection settings
max_connections = 100

# Memory settings (adjust based on available RAM)
shared_buffers = 256MB
effective_cache_size = 1GB
work_mem = 16MB
maintenance_work_mem = 64MB

# Query planning
random_page_cost = 1.1  # For SSD storage
effective_io_concurrency = 200

# Logging
log_min_duration_statement = 1000  # Log slow queries (1 second)
```

Restart PostgreSQL after changes:

```bash
sudo systemctl restart postgresql
```

## Troubleshooting

### Can't connect from game server

```bash
# Check if PostgreSQL is listening
sudo netstat -tlnp | grep 5432

# Check firewall
sudo ufw status
sudo iptables -L -n | grep 5432

# Test from game server
telnet 192.168.1.100 5432
```

### Authentication failed

```sql
-- Check user exists
sudo -u postgres psql -c "\du"

-- Recreate user if needed
DROP USER IF EXISTS worldgate;
CREATE USER worldgate WITH PASSWORD 'your_password';
GRANT CONNECT ON DATABASE worldgate TO worldgate;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO worldgate;
GRANT USAGE ON SCHEMA public TO worldgate;
```

### Permission denied errors

```sql
-- Grant necessary permissions
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO worldgate;
GRANT USAGE ON SCHEMA public TO worldgate;
```

### Slow queries

```sql
-- Check for missing indexes
SELECT schemaname, tablename, attname, n_distinct, correlation
FROM pg_stats
WHERE schemaname = 'public' AND tablename IN ('servers', 'worldgates', 'transfer_logs');

-- Analyze tables
ANALYZE servers;
ANALYZE worldgates;
ANALYZE transfer_logs;
```

### Database corruption

```bash
# Check database integrity
sudo -u postgres pg_dump worldgate > /dev/null

# Vacuum and analyze
sudo -u postgres psql worldgate -c "VACUUM FULL ANALYZE;"
```

## Maintenance

### Weekly Tasks

```bash
# Vacuum and analyze
sudo -u postgres psql worldgate -c "VACUUM ANALYZE;"

# Clean old transfer logs (keep 30 days)
sudo -u postgres psql worldgate -c "DELETE FROM transfer_logs WHERE transfer_time < NOW() - INTERVAL '30 days';"
```

### Monthly Tasks

```bash
# Full vacuum
sudo -u postgres psql worldgate -c "VACUUM FULL;"

# Full backup
pg_dump -U worldgate worldgate | gzip > worldgate_full_$(date +%Y%m%d).sql.gz

# Check database size
sudo -u postgres psql worldgate -c "SELECT pg_size_pretty(pg_database_size('worldgate'));"
```

### Monitor Database Size

```sql
SELECT
    schemaname,
    tablename,
    pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) AS size
FROM pg_tables
WHERE schemaname = 'public'
ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC;
```

## Migration from MySQL/MariaDB

If you're migrating from MySQL/MariaDB to PostgreSQL:

### 1. Export Data from MySQL

```bash
mysqldump -u worldgate -p worldgate > mysql_export.sql
```

### 2. Convert Schema

The SQL syntax differences are minimal. Key changes:
- `DATETIME` → `TIMESTAMP`
- `NOW()` → `CURRENT_TIMESTAMP`
- `BOOLEAN` values: `1`/`0` → `TRUE`/`FALSE`
- Auto-increment triggers are different

### 3. Import to PostgreSQL

```bash
# Create the schema first
sudo -u postgres psql -d worldgate < database_schema.sql

# Then import data (may need manual conversion)
sudo -u postgres psql -d worldgate < converted_data.sql
```

### 4. Update Minetest Configuration

Update `world.mt` to use PostgreSQL settings as described above.

## Comparison: PostgreSQL vs MySQL/MariaDB

| Feature | PostgreSQL | MySQL/MariaDB |
|---------|-----------|---------------|
| Minetest Support | Native (built-in) | Requires external mod |
| Setup Complexity | Moderate | Moderate + mod install |
| Performance | Excellent | Excellent |
| Standards Compliance | Excellent | Good |
| Advanced Features | More extensive | Less extensive |
| Community Support | Very strong | Very strong |

## Support

For PostgreSQL-specific issues:
- PostgreSQL Documentation: https://www.postgresql.org/docs/
- PostgreSQL Community: https://www.postgresql.org/community/

For Worldgate mod issues:
- Check server logs in `debug.txt`
- Review database connection settings
- Verify PostgreSQL is running and accessible

For Minetest PostgreSQL backend:
- Minetest Forum: https://forum.minetest.net/
- Minetest Documentation: https://github.com/minetest/minetest/blob/master/doc/world_format.txt
