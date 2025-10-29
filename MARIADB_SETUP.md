# MariaDB Setup Guide for Worldgate Server Connector

This guide explains how to set up MariaDB for the Worldgate Server Connector on your private network.

## Why MariaDB?

- **Self-hosted**: You control the database on your own infrastructure
- **Private**: Database stays on your private network
- **Configurable**: Full control over URLs, ports, and access
- **Secure**: No external dependencies or third-party services
- **Performance**: Direct database access without HTTP overhead

## Architecture Overview

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│  Server A   │     │  Server B   │     │  Server C   │
│  (Alpha)    │     │  (Beta)     │     │  (Gamma)    │
└──────┬──────┘     └──────┬──────┘     └──────┬──────┘
       │                   │                   │
       │   MySQL/MariaDB Connection (3306)     │
       └───────────────────┼───────────────────┘
                           │
                    ┌──────▼──────┐
                    │   MariaDB   │
                    │   Database  │
                    │  (Private   │
                    │   Network)  │
                    └─────────────┘
```

## Installation Steps

### 1. Install MariaDB Server

On your database server (Ubuntu/Debian):

```bash
sudo apt-get update
sudo apt-get install mariadb-server
```

On CentOS/RHEL:

```bash
sudo yum install mariadb-server
sudo systemctl start mariadb
sudo systemctl enable mariadb
```

### 2. Secure MariaDB Installation

```bash
sudo mysql_secure_installation
```

Follow the prompts:
- Set root password
- Remove anonymous users
- Disallow root login remotely
- Remove test database
- Reload privilege tables

### 3. Create Worldgate Database

Run the provided SQL schema:

```bash
mysql -u root -p < database_schema.sql
```

Or manually:

```sql
mysql -u root -p

CREATE DATABASE worldgate CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE worldgate;

-- Run the contents of database_schema.sql
```

### 4. Create Database User

The schema file creates a user, but you should change the password:

```sql
ALTER USER 'worldgate'@'%' IDENTIFIED BY 'your_super_secure_password_here';
FLUSH PRIVILEGES;
```

### 5. Configure Network Access

Edit MariaDB configuration to allow network connections:

```bash
sudo nano /etc/mysql/mariadb.conf.d/50-server.cnf
```

Change:
```
bind-address = 127.0.0.1
```

To:
```
bind-address = 0.0.0.0
```

Or bind to your private network interface:
```
bind-address = 192.168.1.100
```

Restart MariaDB:
```bash
sudo systemctl restart mariadb
```

### 6. Configure Firewall

Allow connections from your game servers only:

```bash
# UFW (Ubuntu)
sudo ufw allow from 192.168.1.10 to any port 3306
sudo ufw allow from 192.168.1.11 to any port 3306

# Or allow entire private subnet
sudo ufw allow from 192.168.1.0/24 to any port 3306
```

```bash
# firewalld (CentOS)
sudo firewall-cmd --permanent --add-rich-rule='rule family="ipv4" source address="192.168.1.0/24" port protocol="tcp" port="3306" accept'
sudo firewall-cmd --reload
```

### 7. Verify Connection

From each game server, test the connection:

```bash
mysql -h 192.168.1.100 -u worldgate -p worldgate
```

You should be able to connect and see the tables:
```sql
SHOW TABLES;
```

## Minetest/Luanti MySQL Integration

### Option 1: Using mysql_base Mod (Recommended)

1. Download/install the `mysql_base` mod
2. Place it in your mods directory
3. The worldgate mod will automatically detect and use it

### Option 2: Fallback Mode (Single Server)

Without `mysql_base`, the mod uses local mod_storage:
- Gates are stored locally only
- No cross-server functionality
- Useful for development/testing

## Server Configuration

On each Minetest/Luanti server, add to `minetest.conf`:

```ini
# Unique per server
worldgate.server_name = My Server Alpha
worldgate.server_url = minetest://alpha.example.com:30000

# Same for all servers
worldgate.db_host = 192.168.1.100
worldgate.db_port = 3306
worldgate.db_name = worldgate
worldgate.db_user = worldgate
worldgate.db_password = your_super_secure_password_here

# Recommended settings
worldgate.native.link = false
```

## Security Best Practices

### 1. Use Strong Passwords

```sql
-- Generate a secure password for the database user
-- Use a password manager or: openssl rand -base64 32
ALTER USER 'worldgate'@'%' IDENTIFIED BY 'Ax9Kp2Mn8Qr5Wt7Yv3Zb6Cd1Ef4Gh0';
```

### 2. Restrict Network Access

Only allow your game servers:

```sql
-- Drop the wildcard user
DROP USER 'worldgate'@'%';

-- Create specific users for each server
CREATE USER 'worldgate'@'192.168.1.10' IDENTIFIED BY 'password';
CREATE USER 'worldgate'@'192.168.1.11' IDENTIFIED BY 'password';

GRANT SELECT, INSERT, UPDATE, DELETE ON worldgate.* TO 'worldgate'@'192.168.1.10';
GRANT SELECT, INSERT, UPDATE, DELETE ON worldgate.* TO 'worldgate'@'192.168.1.11';
```

### 3. Enable SSL/TLS (Optional)

For encrypted database connections:

```bash
sudo mysql_ssl_rsa_setup
```

Configure MariaDB to require SSL and update client connections accordingly.

### 4. Regular Backups

Backup your database regularly:

```bash
# Daily backup
mysqldump -u root -p worldgate > worldgate_backup_$(date +%Y%m%d).sql

# Automated with cron
0 2 * * * mysqldump -u root -p'password' worldgate > /backups/worldgate_$(date +\%Y\%m\%d).sql
```

### 5. Monitor Access

Check who's connecting:

```sql
SELECT user, host, db FROM mysql.db WHERE db = 'worldgate';
SHOW PROCESSLIST;
```

### 6. Audit Logging

Enable MariaDB audit plugin for security monitoring:

```sql
INSTALL SONAME 'server_audit';
SET GLOBAL server_audit_logging = ON;
```

## Performance Tuning

### For Small Networks (2-5 servers)

Default settings are usually fine.

### For Larger Networks (10+ servers)

Edit `/etc/mysql/mariadb.conf.d/50-server.cnf`:

```ini
[mysqld]
# Connection settings
max_connections = 100

# Buffer pool (set to 70% of RAM for dedicated DB server)
innodb_buffer_pool_size = 2G

# Query cache
query_cache_size = 64M
query_cache_limit = 2M

# Logging
slow_query_log = 1
slow_query_log_file = /var/log/mysql/slow.log
long_query_time = 2
```

Restart MariaDB after changes:
```bash
sudo systemctl restart mariadb
```

## Troubleshooting

### Can't connect from game server

```bash
# Check if MariaDB is listening
sudo netstat -tlnp | grep 3306

# Check firewall
sudo ufw status
sudo iptables -L -n | grep 3306

# Test from game server
telnet 192.168.1.100 3306
```

### Access denied errors

```sql
-- Check user permissions
SELECT user, host FROM mysql.user WHERE user = 'worldgate';
SHOW GRANTS FOR 'worldgate'@'%';

-- Recreate user if needed
DROP USER 'worldgate'@'%';
-- Then recreate with database_schema.sql
```

### Slow queries

```sql
-- Check slow queries
SELECT * FROM mysql.slow_log;

-- Add indexes if needed
ALTER TABLE worldgates ADD INDEX idx_server_quality (server_id, quality);
ALTER TABLE transfer_logs ADD INDEX idx_player_time (player_name, transfer_time);
```

### Database corruption

```bash
# Check tables
sudo mysqlcheck worldgate

# Repair if needed
sudo mysqlcheck --repair worldgate
```

## Maintenance

### Weekly Tasks

```bash
# Optimize tables
mysqlcheck -o worldgate -u root -p

# Clean old transfer logs (keep 30 days)
mysql -u root -p worldgate -e "DELETE FROM transfer_logs WHERE transfer_time < NOW() - INTERVAL 30 DAY;"
```

### Monthly Tasks

```bash
# Analyze tables
mysqlcheck -a worldgate -u root -p

# Full backup
mysqldump -u root -p worldgate | gzip > worldgate_full_$(date +%Y%m%d).sql.gz
```

### Monitor Database Size

```sql
SELECT
    table_name,
    ROUND(((data_length + index_length) / 1024 / 1024), 2) AS size_mb
FROM information_schema.TABLES
WHERE table_schema = 'worldgate'
ORDER BY size_mb DESC;
```

## Support

For MariaDB-specific issues:
- MariaDB Documentation: https://mariadb.com/kb/
- MariaDB Community: https://mariadb.org/community/

For Worldgate mod issues:
- Check server logs in `debug.txt`
- Review database queries in MariaDB logs
- Test with `mysql_base` mod installed
