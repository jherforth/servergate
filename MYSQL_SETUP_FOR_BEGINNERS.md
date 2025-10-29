# MySQL/MariaDB Setup for Complete Beginners

This guide assumes you've **never set up a database before**. We'll walk through every step with explanations.

---

## 🎯 What You're Building

You want multiple Minetest servers to share worldgate data so players can transfer between them.

```
┌──────────────┐         ┌──────────────┐         ┌──────────────┐
│  Server 1    │         │  Server 2    │         │  Server 3    │
│  Fantasy     │         │  Desert      │         │  Space       │
│  :30000      │         │  :30001      │         │  :30002      │
└──────┬───────┘         └──────┬───────┘         └──────┬───────┘
       │                        │                        │
       └────────────────────────┼────────────────────────┘
                                │
                    All connect to one database
                                │
                        ┌───────▼───────┐
                        │  MySQL/MariaDB│
                        │   Database    │
                        └───────────────┘
```

**⚠️ IMPORTANT LIMITATION:** Player inventories do NOT transfer between servers! Players will lose all items when transferring through worldgates. This is because different servers may run different games/mods with incompatible items.

---

## ⚠️ Important: Where to Host the Database

### Option A: Same Machine (Easiest)
- Database runs on the same computer as your Minetest servers
- Use `localhost` or `127.0.0.1` for connections
- **Best for**: Testing, local server networks

### Option B: Separate Database Server (Advanced)
- Database runs on a different computer
- Requires network configuration
- **Best for**: Production, multiple physical servers

**This guide covers Option A (same machine).** For Option B, see `MARIADB_SETUP.md`.

---

## 📋 Step-by-Step Installation

### Step 1: Install MySQL/MariaDB

Choose your operating system:

#### 🐧 Ubuntu/Debian Linux

```bash
# Update package list
sudo apt-get update

# Install MariaDB
sudo apt-get install mariadb-server mariadb-client

# Start the service
sudo systemctl start mariadb
sudo systemctl enable mariadb
```

#### 🎩 CentOS/RHEL/Fedora Linux

```bash
# Install MariaDB
sudo yum install mariadb-server mariadb

# Start the service
sudo systemctl start mariadb
sudo systemctl enable mariadb
```

#### 🪟 Windows

1. Download **MariaDB** from: https://mariadb.org/download/
2. Run the installer
3. During installation:
   - Set a **root password** (write it down!)
   - Enable "Install as a service"
   - Use default port (3306)

#### 🍎 macOS

```bash
# Install Homebrew if you don't have it
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install MariaDB
brew install mariadb

# Start MariaDB
brew services start mariadb
```

---

### Step 2: Secure Your Database

This step sets a root password and removes insecure defaults.

```bash
sudo mysql_secure_installation
```

**Answer the prompts:**

1. **Enter current password for root**: Press Enter (no password yet)
2. **Set root password?**: `Y` (yes)
   - Enter a strong password
   - **WRITE THIS PASSWORD DOWN!**
3. **Remove anonymous users?**: `Y`
4. **Disallow root login remotely?**: `Y`
5. **Remove test database?**: `Y`
6. **Reload privilege tables?**: `Y`

---

### Step 3: Create the Worldgate Database

#### Method A: Automatic (Recommended)

Navigate to your worldgate mod directory:

```bash
cd /path/to/minetest/mods/worldgate/
mysql -u root -p < database_schema.sql
```

Enter your root password when prompted. Done! ✅

#### Method B: Manual

If the automatic method doesn't work:

```bash
# Log into MySQL
mysql -u root -p
```

Enter your root password. You'll see:

```
MariaDB [(none)]>
```

Now copy and paste these commands **one at a time**:

```sql
-- Create the database
CREATE DATABASE worldgate CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- Use it
USE worldgate;

-- Create servers table
CREATE TABLE servers (
  id VARCHAR(36) PRIMARY KEY,
  name VARCHAR(255) NOT NULL,
  url VARCHAR(255) NOT NULL,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- Create worldgates table
CREATE TABLE worldgates (
  id VARCHAR(36) PRIMARY KEY,
  server_id VARCHAR(36) NOT NULL,
  position JSON NOT NULL,
  base_schematic VARCHAR(50),
  decor_schematic VARCHAR(50),
  quality INT DEFAULT 0,
  destination_gate_id VARCHAR(36),
  destination_server_id VARCHAR(36),
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (server_id) REFERENCES servers(id)
);

-- Create transfer logs table
CREATE TABLE transfer_logs (
  id VARCHAR(36) PRIMARY KEY,
  player_name VARCHAR(255) NOT NULL,
  source_gate_id VARCHAR(36),
  destination_gate_id VARCHAR(36),
  source_server_id VARCHAR(36),
  destination_server_id VARCHAR(36),
  transfer_time DATETIME DEFAULT CURRENT_TIMESTAMP,
  success BOOLEAN DEFAULT FALSE
);

-- Create indexes
CREATE INDEX idx_worldgates_server ON worldgates(server_id);
CREATE INDEX idx_worldgates_destination ON worldgates(destination_gate_id, destination_server_id);
CREATE INDEX idx_transfer_logs_player ON transfer_logs(player_name);
CREATE INDEX idx_transfer_logs_time ON transfer_logs(transfer_time);
```

Exit MySQL:

```sql
exit;
```

---

### Step 4: Create Database User for Worldgate

**Why?** Don't use the root account for your mod - it's a security risk!

```bash
mysql -u root -p
```

Then run:

```sql
-- Create user (change 'your_password' to something secure!)
CREATE USER 'worldgate'@'localhost' IDENTIFIED BY 'your_password';

-- Grant permissions
GRANT ALL PRIVILEGES ON worldgate.* TO 'worldgate'@'localhost';

-- Apply changes
FLUSH PRIVILEGES;

-- Exit
exit;
```

**⚠️ WRITE DOWN YOUR PASSWORD!** You'll need it in the next step.

---

### Step 5: Test the Connection

Let's verify everything works:

```bash
mysql -u worldgate -p worldgate
```

Enter the password you created. If you see:

```
MariaDB [worldgate]>
```

Success! ✅ Type `exit;` to quit.

If you get an error:
- Double-check username: `worldgate`
- Double-check password
- Make sure you're using the database name: `worldgate`

---

### Step 6: Configure Each Minetest Server

On **every** Minetest server that will share the worldgate network:

1. Navigate to your world's directory:
   ```
   /path/to/minetest/worlds/your_world_name/
   ```

2. Edit `world.mt` file (or create it):
   ```bash
   nano world.mt
   ```

3. Add these lines at the bottom:
   ```ini
   worldgate.db_host = localhost
   worldgate.db_port = 3306
   worldgate.db_name = worldgate
   worldgate.db_user = worldgate
   worldgate.db_password = your_password
   ```

4. **Customize for this server:**
   ```ini
   worldgate.server_name = Fantasy World
   worldgate.server_url = minetest://your.server.ip:30000
   ```

5. Save and close (Ctrl+X, then Y, then Enter)

---

### Step 7: Register Each Server

Each Minetest server needs a unique ID in the database.

#### First Server

1. Start your first Minetest server
2. Join as admin
3. Run this command in chat:
   ```
   /worldgate_register_server
   ```

4. **SAVE THE SERVER ID!** It will show something like:
   ```
   Server registered with ID: a1b2c3d4-e5f6-7890-abcd-ef1234567890
   ```

5. Write this down! You need it for linking gates.

#### Additional Servers

Repeat the same process for each server:
1. Update the `world.mt` with **different** server name/URL
2. Start the server
3. Join as admin
4. Run `/worldgate_register_server`
5. Save the server ID

---

## ✅ Verification Checklist

Before linking gates, verify:

- [ ] MySQL/MariaDB is running
- [ ] Database `worldgate` exists
- [ ] User `worldgate` can connect
- [ ] All servers have `world.mt` configured
- [ ] Each server has been registered (has a server ID)
- [ ] Each server has a unique name and URL

---

## 🔗 Next Steps

Now that your database is set up:

1. **Link Gates**: See `API.md` for linking commands
2. **Test Transfers**: Right-click a linked servergate beacon
3. **Monitor Logs**: Check `transfer_logs` table

```sql
-- View recent transfers
mysql -u worldgate -p worldgate -e "SELECT * FROM transfer_logs ORDER BY transfer_time DESC LIMIT 10;"
```

---

## 🐛 Common Issues & Fixes

### "Can't connect to MySQL server"

**Problem**: MySQL isn't running

**Fix**:
```bash
sudo systemctl status mariadb
sudo systemctl start mariadb
```

---

### "Access denied for user 'worldgate'"

**Problem**: Wrong password or user doesn't exist

**Fix**: Re-create the user (Step 4)

---

### "Unknown database 'worldgate'"

**Problem**: Database wasn't created

**Fix**: Re-run Step 3

---

### "Server already registered"

**Problem**: You ran `/worldgate_register_server` twice

**Fix**: This is OK! It just means your server is already in the database.

---

### Servers can't find each other's gates

**Problem**: Each server has its own separate database

**Fix**: All servers must use the **same** database. Check:
- Same `worldgate.db_host`
- Same `worldgate.db_name`
- Same `worldgate.db_user`
- Same `worldgate.db_password`

---

## 🔒 Security Tips

### For Testing (Local Only)
- Using `localhost` is fine
- Password can be simple

### For Production (Public Servers)
- Use a **strong** password (16+ characters, mixed symbols)
- Consider a firewall to block port 3306 from internet
- Use `localhost` connection when possible
- Regular database backups:
  ```bash
  mysqldump -u worldgate -p worldgate > worldgate_backup_$(date +%Y%m%d).sql
  ```

---

## 📚 Additional Resources

- **Detailed Setup**: `MARIADB_SETUP.md` (advanced configuration)
- **API Reference**: `API.md` (linking gates, commands)
- **Database Schema**: `database_schema.sql` (table structure)
- **Troubleshooting**: Check Minetest `debug.txt` for errors

---

## ❓ Still Stuck?

If you're still having trouble:

1. Check Minetest's `debug.txt` for error messages
2. Verify MySQL is running: `sudo systemctl status mariadb`
3. Test connection: `mysql -u worldgate -p worldgate`
4. Make sure all servers use **identical** database settings

Remember: The most common issue is typos in `world.mt` - double-check everything!
