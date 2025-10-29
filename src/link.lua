--
-- Worldgate linking and gate management functions
--

-- Transfer cooldown management
local transfer_cooldowns = {}
local COOLDOWN_TIME = 5

-- Check if player can transfer (cooldown check)
local function can_transfer(player_name)
  local now = os.time()
  local last_transfer = transfer_cooldowns[player_name]

  if not last_transfer or (now - last_transfer) >= COOLDOWN_TIME then
    return true
  end

  return false, COOLDOWN_TIME - (now - last_transfer)
end

-- Set transfer cooldown for player
local function set_transfer_cooldown(player_name)
  transfer_cooldowns[player_name] = os.time()
end

-- Enhanced transfer initiation with cooldown
local original_initiate = worldgate.initiate_transfer
worldgate.initiate_transfer = function(beacon_pos, player)
  local player_name = player:get_player_name()
  local can, remaining = can_transfer(player_name)

  if not can then
    minetest.chat_send_player(player_name,
      "Transfer cooldown active. Please wait " .. math.ceil(remaining) .. " seconds.")
    return
  end

  set_transfer_cooldown(player_name)
  original_initiate(beacon_pos, player)
end

-- ABM to keep beacons active and manage their state
minetest.register_abm({
  label = "Worldgate beacon management",
  nodenames = {"worldgate:beacon", "worldgate:beacon_off"},
  interval = 5,
  chance = 1,
  catch_up = false,
  action = function(pos, node)
    local meta = minetest.get_meta(pos)
    local gate_id = meta:get_string("worldgate:gate_id")

    -- If beacon has no gate_id, deactivate it
    if not gate_id or gate_id == "" then
      if node.name == "worldgate:beacon" then
        minetest.swap_node(pos, {name = "worldgate:beacon_off", param2 = 0})
      end
    else
      -- If beacon has gate_id, ensure it's active
      if node.name == "worldgate:beacon_off" then
        minetest.swap_node(pos, {name = "worldgate:beacon", param2 = 0})
      end
    end
  end,
})

-- Function to manually link two gates
function worldgate.link_gates_manual(source_pos, dest_gate_id, dest_server_id)
  local meta = minetest.get_meta(source_pos)
  local source_gate_id = meta:get_string("worldgate:gate_id")

  if not source_gate_id or source_gate_id == "" then
    return false, "Source gate not registered"
  end

  worldgate.server_api.link_gates(source_gate_id, dest_gate_id, dest_server_id, function(success, data)
    if success then
      minetest.log("action", "Worldgate: Linked gate " .. source_gate_id .. " to " .. dest_gate_id)
      minetest.swap_node(source_pos, {name = "worldgate:beacon", param2 = 0})
    else
      minetest.log("error", "Worldgate: Failed to link gates")
    end
  end)

  return true
end