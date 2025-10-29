# Worldgate Server Connector - Quick Start Guide

## Overview

This guide will help you set up a network of Luanti/Minetest servers connected via Worldgates.

## Prerequisites

- Two or more Luanti/Minetest servers
- A Supabase account (free tier works)
- Server admin access with `server` privilege

## Step 1: Set Up Supabase

1. Go to [supabase.com](https://supabase.com) and create a free account
2. Create a new project
3. Wait for the project to finish provisioning
4. Go to Project Settings > API
5. Copy your:
   - Project URL (looks like `https://xxxxx.supabase.co`)
   - Anon/Public key (starts with `eyJ...`)

## Step 2: Install the Mod

1. Install this mod on all servers in your network
2. Make sure all servers use the same Supabase project

## Step 3: Configure Each Server

Add to `minetest.conf` on each server:

```
# Unique name for this server
worldgate.server_name = Server Alpha

# Your Supabase credentials (same for all servers)
worldgate.supabase_url = https://your-project.supabase.co
worldgate.supabase_anon_key = eyJ...your-key-here

# Enable HTTP access for the mod
secure.http_mods = worldgate

# Disable auto-linking (we'll link manually)
worldgate.native.link = false
```

## Step 4: Start Servers and Explore

1. Start all servers
2. Explore the world on each server to generate worldgates
3. Check the server logs to see gates being registered

## Step 5: Link Gates Between Servers

### Find Gate IDs

On Server A:
1. Find a worldgate beacon
2. Look at it and run: `/worldgate_info`
3. Note the `Gate ID` (a UUID)

On Server B:
1. Find another worldgate beacon
2. Look at it and run: `/worldgate_info`
3. Note the `Gate ID`

### Get Server IDs

Check your Supabase dashboard:
1. Go to Table Editor
2. Open the `servers` table
3. Note the `id` for each server

### Link the Gates

On Server A, while looking at a beacon:
```
/worldgate_link <gate_id_from_server_b> <server_id_of_server_b>
```

On Server B, link back to Server A:
```
/worldgate_link <gate_id_from_server_a> <server_id_of_server_a>
```

## Step 6: Test the Transfer

1. On Server A, right-click the linked beacon
2. You should see a message: "Transferring to: Server B (address:port)"
3. The player will see the destination server information

## Admin Commands

- `/worldgate_info` - Get info about the gate you're looking at
- `/worldgate_link <dest_gate_id> <dest_server_id>` - Link a gate
- `/worldgate_list` - List all gates on this server

## Troubleshooting

### "HTTP API not available"
Add `secure.http_mods = worldgate` to minetest.conf

### "Supabase not configured"
Check that you've set both `worldgate.supabase_url` and `worldgate.supabase_anon_key`

### "Gate destination not found"
Make sure you've linked the gates correctly using the UUIDs from the database

### Check the Database

Go to Supabase > Table Editor to view:
- `servers` - All registered servers
- `worldgates` - All gates and their links
- `transfer_logs` - Transfer history

## Notes

- Gates only generate in unexplored chunks
- There's a 5-second cooldown between transfers
- Each server sends a heartbeat every 60 seconds
- Gates auto-register 2 seconds after generation

## Support

For issues and questions, check the mod's documentation and logs.
