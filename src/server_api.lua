--
-- Worldgate Server Transfer API
-- Handles communication with Supabase and server-to-server transfers
--

local http = minetest.request_http_api()
if not http then
  minetest.log("error", "Worldgate: HTTP API not available. Add worldgate to secure.http_mods in minetest.conf")
  return
end

local modpath = worldgate.modpath
local server_id = nil
local server_name = minetest.settings:get("worldgate.server_name") or "Unknown Server"
local supabase_url = minetest.settings:get("worldgate.supabase_url")
local supabase_key = minetest.settings:get("worldgate.supabase_anon_key")

if not supabase_url or not supabase_key then
  minetest.log("warning", "Worldgate: Supabase credentials not configured. Set worldgate.supabase_url and worldgate.supabase_anon_key")
end

worldgate.server_api = {}

-- Helper function to make HTTP requests to Supabase
local function supabase_request(endpoint, method, data, callback)
  if not supabase_url or not supabase_key then
    minetest.log("error", "Worldgate: Supabase not configured")
    if callback then callback(false, "Supabase not configured") end
    return
  end

  local url = supabase_url .. "/rest/v1/" .. endpoint
  local headers = {
    "Content-Type: application/json",
    "apikey: " .. supabase_key,
    "Authorization: Bearer " .. supabase_key,
  }

  local post_data = data and minetest.write_json(data) or nil

  http.fetch({
    url = url,
    method = method or "GET",
    extra_headers = headers,
    data = post_data,
  }, function(result)
    if result.succeeded and result.code >= 200 and result.code < 300 then
      local response_data = result.data and minetest.parse_json(result.data)
      if callback then callback(true, response_data) end
    else
      minetest.log("error", "Worldgate: HTTP request failed: " .. (result.data or "Unknown error"))
      if callback then callback(false, result.data) end
    end
  end)
end

-- Register this server in the database
function worldgate.server_api.register_server(callback)
  local host = minetest.settings:get("bind_address") or "localhost"
  local port = tonumber(minetest.settings:get("port") or 30000)

  supabase_request("servers", "POST", {
    name = server_name,
    host = host,
    port = port,
    is_active = true,
  }, function(success, data)
    if success and data and data[1] then
      server_id = data[1].id
      minetest.log("action", "Worldgate: Server registered with ID: " .. server_id)
      if callback then callback(true, server_id) end
    else
      minetest.log("error", "Worldgate: Failed to register server")
      if callback then callback(false, data) end
    end
  end)
end

-- Update server heartbeat
function worldgate.server_api.update_heartbeat()
  if not server_id then return end

  supabase_request("servers?id=eq." .. server_id, "PATCH", {
    updated_at = os.date("!%Y-%m-%dT%H:%M:%SZ"),
    is_active = true,
  })
end

-- Register a worldgate in the database
function worldgate.server_api.register_gate(position, base, decor, quality, callback)
  if not server_id then
    minetest.log("error", "Worldgate: Server not registered, cannot register gate")
    if callback then callback(false, "Server not registered") end
    return
  end

  supabase_request("worldgates", "POST", {
    server_id = server_id,
    position = {x = position.x, y = position.y, z = position.z},
    base_schematic = base,
    decor_schematic = decor,
    quality = quality,
  }, callback)
end

-- Link a worldgate to another gate
function worldgate.server_api.link_gates(source_gate_id, destination_gate_id, destination_server_id, callback)
  supabase_request("worldgates?id=eq." .. source_gate_id, "PATCH", {
    destination_gate_id = destination_gate_id,
    destination_server_id = destination_server_id,
  }, callback)
end

-- Get destination info for a gate
function worldgate.server_api.get_gate_destination(gate_id, callback)
  supabase_request("worldgates?id=eq." .. gate_id .. "&select=destination_gate_id,destination_server_id", "GET", nil, callback)
end

-- Log a transfer
function worldgate.server_api.log_transfer(player_name, source_gate_id, dest_gate_id, dest_server_id, success, callback)
  supabase_request("transfer_logs", "POST", {
    player_name = player_name,
    source_gate_id = source_gate_id,
    destination_gate_id = dest_gate_id,
    source_server_id = server_id,
    destination_server_id = dest_server_id,
    success = success,
  }, callback)
end

-- Get server info by ID
function worldgate.server_api.get_server_info(target_server_id, callback)
  supabase_request("servers?id=eq." .. target_server_id, "GET", nil, callback)
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
    if not success or not data or not data[1] then
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
      if not success2 or not server_data or not server_data[1] then
        minetest.chat_send_player(player:get_player_name(), "Destination server not found.")
        return
      end

      local dest_server = server_data[1]
      minetest.chat_send_player(player:get_player_name(),
        "Transferring to: " .. dest_server.name .. " (" .. dest_server.host .. ":" .. dest_server.port .. ")")

      worldgate.server_api.log_transfer(player:get_player_name(), gate_id, dest_gate_id, dest_server_id, true)
    end)
  end)
end

-- Initialize server registration on startup
if supabase_url and supabase_key then
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
end
