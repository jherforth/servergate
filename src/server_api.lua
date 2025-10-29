--
-- Worldgate Server Transfer API
-- Handles communication with MariaDB/MySQL and server-to-server transfers
--

local modpath = worldgate.modpath
local server_id = nil
local server_name = minetest.settings:get("worldgate.server_name") or "Unknown Server"
local server_url = minetest.settings:get("worldgate.server_url") or "minetest://localhost:30000"

-- Database configuration
local db_host = minetest.settings:get("worldgate.db_host") or "localhost"
local db_port = tonumber(minetest.settings:get("worldgate.db_port") or 3306)
local db_name = minetest.settings:get("worldgate.db_name") or "worldgate"
local db_user = minetest.settings:get("worldgate.db_user") or "worldgate"
local db_password = minetest.settings:get("worldgate.db_password") or ""

worldgate.server_api = {}

-- Get MySQL connection settings
local function get_mysql_settings()
  return {
    host = db_host,
    port = db_port,
    database = db_name,
    user = db_user,
    password = db_password,
  }
end

-- Execute MySQL query using minetest.get_mod_storage()
-- Since Minetest doesn't have native MySQL support, we'll use mod storage as fallback
-- For production, you'd need to use an external mod like mysql_base
local storage = minetest.get_mod_storage()

-- Try to load MySQL mod if available
local mysql_available = false
if minetest.get_modpath("mysql_base") then
  mysql_available = true
  minetest.log("action", "Worldgate: MySQL mod detected, using database backend")
else
  minetest.log("warning", "Worldgate: MySQL mod not found, using mod_storage as fallback")
  minetest.log("warning", "Worldgate: Install 'mysql_base' mod for multi-server support")
end

-- Helper: Generate UUID
local function generate_uuid()
  local random = math.random
  local template = 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'
  return string.gsub(template, '[xy]', function(c)
    local v = (c == 'x') and random(0, 0xf) or random(8, 0xb)
    return string.format('%x', v)
  end)
end

-- Helper: Execute MySQL query via mysql_base mod
local function mysql_query(query, callback)
  if not mysql_available then
    -- Fallback to mod_storage for single-server testing
    if callback then
      callback(false, "MySQL not available")
    end
    return
  end

  local mysql = minetest.get_mod_storage("mysql_base")
  if mysql and mysql.query then
    mysql.query(get_mysql_settings(), query, function(result, error)
      if error then
        minetest.log("error", "Worldgate MySQL error: " .. tostring(error))
        if callback then callback(false, error) end
      else
        if callback then callback(true, result) end
      end
    end)
  end
end

-- Register this server in the database
function worldgate.server_api.register_server(callback)
  if not mysql_available then
    -- Use mod_storage fallback
    server_id = storage:get_string("server_id")
    if not server_id or server_id == "" then
      server_id = generate_uuid()
      storage:set_string("server_id", server_id)
      storage:set_string("server_name", server_name)
      storage:set_string("server_url", server_url)
    end
    minetest.log("action", "Worldgate: Server ID (mod_storage): " .. server_id)
    if callback then callback(true, server_id) end
    return
  end

  -- Check if server already exists
  local check_query = string.format(
    "SELECT id FROM servers WHERE name = '%s' LIMIT 1",
    server_name:gsub("'", "''")
  )

  mysql_query(check_query, function(success, result)
    if success and result and #result > 0 then
      server_id = result[1].id
      -- Update existing server
      local update_query = string.format(
        "UPDATE servers SET url = '%s', is_active = 1, updated_at = NOW() WHERE id = '%s'",
        server_url:gsub("'", "''"),
        server_id:gsub("'", "''")
      )
      mysql_query(update_query, function()
        minetest.log("action", "Worldgate: Server updated with ID: " .. server_id)
        if callback then callback(true, server_id) end
      end)
    else
      -- Insert new server
      server_id = generate_uuid()
      local insert_query = string.format(
        "INSERT INTO servers (id, name, url, is_active, created_at, updated_at) VALUES ('%s', '%s', '%s', 1, NOW(), NOW())",
        server_id:gsub("'", "''"),
        server_name:gsub("'", "''"),
        server_url:gsub("'", "''")
      )
      mysql_query(insert_query, function(success2)
        if success2 then
          minetest.log("action", "Worldgate: Server registered with ID: " .. server_id)
          if callback then callback(true, server_id) end
        else
          minetest.log("error", "Worldgate: Failed to register server")
          if callback then callback(false, "Insert failed") end
        end
      end)
    end
  end)
end

-- Update server heartbeat
function worldgate.server_api.update_heartbeat()
  if not server_id then return end

  if not mysql_available then
    storage:set_string("last_heartbeat", os.time())
    return
  end

  local query = string.format(
    "UPDATE servers SET updated_at = NOW(), is_active = 1 WHERE id = '%s'",
    server_id:gsub("'", "''")
  )
  mysql_query(query)
end

-- Register a worldgate in the database
function worldgate.server_api.register_gate(position, base, decor, quality, callback)
  if not server_id then
    minetest.log("error", "Worldgate: Server not registered, cannot register gate")
    if callback then callback(false, "Server not registered") end
    return
  end

  local gate_id = generate_uuid()
  local pos_json = minetest.write_json({x = position.x, y = position.y, z = position.z})

  if not mysql_available then
    -- Store in mod_storage as fallback
    local gate_key = "gate_" .. gate_id
    storage:set_string(gate_key, minetest.write_json({
      id = gate_id,
      server_id = server_id,
      position = position,
      base_schematic = base,
      decor_schematic = decor,
      quality = quality,
    }))
    if callback then callback(true, {{id = gate_id}}) end
    return
  end

  local query = string.format(
    "INSERT INTO worldgates (id, server_id, position, base_schematic, decor_schematic, quality, created_at, updated_at) VALUES ('%s', '%s', '%s', '%s', '%s', %d, NOW(), NOW())",
    gate_id:gsub("'", "''"),
    server_id:gsub("'", "''"),
    pos_json:gsub("'", "''"),
    base:gsub("'", "''"),
    decor:gsub("'", "''"),
    quality
  )

  mysql_query(query, function(success)
    if success then
      if callback then callback(true, {{id = gate_id}}) end
    else
      if callback then callback(false, "Insert failed") end
    end
  end)
end

-- Link a worldgate to another gate
function worldgate.server_api.link_gates(source_gate_id, destination_gate_id, destination_server_id, callback)
  if not mysql_available then
    local gate_key = "gate_" .. source_gate_id
    local gate_data_str = storage:get_string(gate_key)
    if gate_data_str and gate_data_str ~= "" then
      local gate_data = minetest.parse_json(gate_data_str)
      gate_data.destination_gate_id = destination_gate_id
      gate_data.destination_server_id = destination_server_id
      storage:set_string(gate_key, minetest.write_json(gate_data))
      if callback then callback(true) end
    else
      if callback then callback(false, "Gate not found") end
    end
    return
  end

  local query = string.format(
    "UPDATE worldgates SET destination_gate_id = '%s', destination_server_id = '%s', updated_at = NOW() WHERE id = '%s'",
    destination_gate_id:gsub("'", "''"),
    destination_server_id:gsub("'", "''"),
    source_gate_id:gsub("'", "''")
  )

  mysql_query(query, callback)
end

-- Get destination info for a gate
function worldgate.server_api.get_gate_destination(gate_id, callback)
  if not mysql_available then
    local gate_key = "gate_" .. gate_id
    local gate_data_str = storage:get_string(gate_key)
    if gate_data_str and gate_data_str ~= "" then
      local gate_data = minetest.parse_json(gate_data_str)
      if callback then callback(true, {{
        destination_gate_id = gate_data.destination_gate_id,
        destination_server_id = gate_data.destination_server_id
      }}) end
    else
      if callback then callback(false, "Gate not found") end
    end
    return
  end

  local query = string.format(
    "SELECT destination_gate_id, destination_server_id FROM worldgates WHERE id = '%s'",
    gate_id:gsub("'", "''")
  )

  mysql_query(query, callback)
end

-- Log a transfer
function worldgate.server_api.log_transfer(player_name, source_gate_id, dest_gate_id, dest_server_id, success, callback)
  if not mysql_available then
    -- Just log to file for fallback mode
    minetest.log("action", string.format(
      "Worldgate transfer: %s from gate %s to gate %s on server %s (success: %s)",
      player_name, source_gate_id or "unknown", dest_gate_id or "unknown",
      dest_server_id or "unknown", tostring(success)
    ))
    if callback then callback(true) end
    return
  end

  local log_id = generate_uuid()
  local query = string.format(
    "INSERT INTO transfer_logs (id, player_name, source_gate_id, destination_gate_id, source_server_id, destination_server_id, transfer_time, success) VALUES ('%s', '%s', %s, %s, %s, %s, NOW(), %d)",
    log_id:gsub("'", "''"),
    player_name:gsub("'", "''"),
    source_gate_id and "'" .. source_gate_id:gsub("'", "''") .. "'" or "NULL",
    dest_gate_id and "'" .. dest_gate_id:gsub("'", "''") .. "'" or "NULL",
    server_id and "'" .. server_id:gsub("'", "''") .. "'" or "NULL",
    dest_server_id and "'" .. dest_server_id:gsub("'", "''") .. "'" or "NULL",
    success and 1 or 0
  )

  mysql_query(query, callback)
end

-- Get server info by ID
function worldgate.server_api.get_server_info(target_server_id, callback)
  if not mysql_available then
    -- Return dummy data for fallback
    if callback then callback(true, {{
      name = storage:get_string("server_name") or "Unknown",
      url = storage:get_string("server_url") or "minetest://localhost:30000"
    }}) end
    return
  end

  local query = string.format(
    "SELECT name, url FROM servers WHERE id = '%s'",
    target_server_id:gsub("'", "''")
  )

  mysql_query(query, callback)
end

-- Initiate server transfer for a player
function worldgate.initiate_transfer(beacon_pos, player)
  local meta = minetest.get_meta(beacon_pos)
  local gate_id = meta:get_string("worldgate:gate_id")

  if not gate_id or gate_id == "" then
    minetest.chat_send_player(player:get_player_name(), "This gate is not configured for transfer.")
    return
  end

  worldgate.server_api.get_gate_destination(gate_id, function(success, data)
    if not success or not data or #data == 0 then
      minetest.chat_send_player(player:get_player_name(), "Gate destination not found.")
      return
    end

    local dest_gate_id = data[1].destination_gate_id
    local dest_server_id = data[1].destination_server_id

    if not dest_gate_id or not dest_server_id then
      minetest.chat_send_player(player:get_player_name(), "This gate has no destination.")
      return
    end

    worldgate.server_api.get_server_info(dest_server_id, function(success2, server_data)
      if not success2 or not server_data or #server_data == 0 then
        minetest.chat_send_player(player:get_player_name(), "Destination server not found.")
        return
      end

      local dest_server = server_data[1]
      local player_name = player:get_player_name()

      -- Show the transfer screen with the portal image
      worldgate.transfer_screen.show(
        player,
        dest_server.name,
        dest_server.url,
        "Gate " .. gate_id:sub(1, 8)
      )

      worldgate.server_api.log_transfer(player_name, gate_id, dest_gate_id, dest_server_id, true)
    end)
  end)
end

-- Initialize server registration on startup
minetest.after(2, function()
  worldgate.server_api.register_server()
end)

-- Heartbeat every 60 seconds
local heartbeat_timer = 0
minetest.register_globalstep(function(dtime)
  heartbeat_timer = heartbeat_timer + dtime
  if heartbeat_timer >= 60 then
    worldgate.server_api.update_heartbeat()
    heartbeat_timer = 0
  end
end)
