--
-- Beacon interaction system for linking gates
--

-- Store player context for formspec callbacks
local player_context = {}

-- Show travel confirmation dialog
local function show_travel_dialog(player_name, pos, dest_server_name, dest_url)
  local formspec = "formspec_version[4]" ..
    "size[10,7]" ..
    "label[0.5,0.5;Worldgate Destination]" ..
    "textarea[0.5,1;9,2.5;;;" ..
    "This gate is linked to:\n" ..
    dest_server_name .. "\n" ..
    dest_url .. "\n\n" ..
    "Click GO to travel to this server!]" ..
    "button[0.5,4.5;4,1;go;GO!]" ..
    "button[5,4.5;4,1;close;Cancel]" ..
    "label[0.5,6;Note: Your inventory will not transfer between servers]"

  player_context[player_name] = {
    pos = pos,
    dest_url = dest_url,
    mode = "travel"
  }

  minetest.show_formspec(player_name, "servergate:travel", formspec)
end

-- Show gate linking dialog
local function show_linking_dialog(player_name, pos, source_gate_id, available_gates)
  local gates_list = ""

  if #available_gates == 0 then
    local formspec = "formspec_version[4]" ..
      "size[10,6]" ..
      "label[0.5,0.5;No Unlinked Gates Available]" ..
      "textarea[0.5,1;9,3.5;;;" ..
      "There are no unlinked gates from other servers in the database.\n\n" ..
      "Make sure:\n" ..
      "1. Other servers are running and connected to the database\n" ..
      "2. Those servers have generated worldgates\n" ..
      "3. The gates are not already linked]" ..
      "button[3,5;4,1;close;Close]"

    minetest.show_formspec(player_name, "servergate:link", formspec)
    return
  end

  -- Build gate list
  for i, gate in ipairs(available_gates) do
    local short_id = gate.id:sub(1, 8)
    gates_list = gates_list .. i .. ". " .. gate.server_name .. " - " .. gate.position .. " (ID: " .. short_id .. "...)"
    if i < #available_gates then
      gates_list = gates_list .. ","
    end
  end

  local formspec = "formspec_version[4]" ..
    "size[12,9]" ..
    "label[0.5,0.5;Link This Gate to Another Server]" ..
    "label[0.5,1;Select a destination gate from the list below:]" ..
    "textlist[0.5,1.5;11,5.5;gate_list;" .. gates_list .. ";1]" ..
    "button[0.5,7.5;5,1;link;Link to Selected Gate]" ..
    "button[6.5,7.5;5,1;close;Cancel]"

  player_context[player_name] = {
    pos = pos,
    source_gate_id = source_gate_id,
    available_gates = available_gates,
    mode = "link"
  }

  minetest.show_formspec(player_name, "servergate:link", formspec)
end

-- Handle beacon interaction (right-click or stand on beacon)
local function on_beacon_interact(pos, node, player, itemstack, pointed_thing)
  if not player or not player:is_player() then
    return
  end

  local player_name = player:get_player_name()

  if not servergate.db or not servergate.db.available then
    minetest.chat_send_player(player_name, "Database not available. Configure PostgreSQL to use gate linking.")
    return
  end

  local meta = minetest.get_meta(pos)
  local gate_id = meta:get_string("servergate:gate_id")

  if not gate_id or gate_id == "" then
    minetest.chat_send_player(player_name, "This gate has no UUID. It may not be registered.")
    return
  end

  -- Check if this gate is already linked
  local dest_gate_id = meta:get_string("servergate:destination_gate_id")

  if dest_gate_id and dest_gate_id ~= "" then
    -- Gate is linked - show travel dialog
    servergate.db.get_gate_info(gate_id, function(success, result)
      if success and result and #result > 0 then
        local gate_info = result[1]
        local dest_name = gate_info.dest_server_name or "Unknown Server"
        local dest_url = gate_info.dest_server_url or meta:get_string("servergate:destination_url") or "unknown"

        show_travel_dialog(player_name, pos, dest_name, dest_url)
      else
        minetest.chat_send_player(player_name, "Error: Could not retrieve gate information")
      end
    end)
  else
    -- Gate is not linked - show linking dialog
    -- Query for unlinked gates from other servers
    local sql = string.format([[
      SELECT g.id, g.position, g.quality, s.name as server_name, s.url as server_url
      FROM worldgates g
      JOIN servers s ON g.server_id = s.id
      WHERE g.destination_gate_id IS NULL
        AND g.server_id != '%s'
        AND s.is_active = TRUE
      ORDER BY s.name, g.created_at
      LIMIT 50;
    ]], servergate.server_id or "")

    servergate.db.query(sql, function(success, result)
      if success and result then
        show_linking_dialog(player_name, pos, gate_id, result)
      else
        minetest.chat_send_player(player_name, "Error querying database: " .. tostring(result))
      end
    end)
  end
end

-- Track punch interactions on beacons (crouch-punch)
local player_punch_cooldown = {}

minetest.register_on_punchnode(function(pos, node, puncher, pointed_thing)
  if not puncher or not puncher:is_player() then
    return
  end

  -- Check if punching a beacon (telemosaic or servergate)
  local is_beacon = node.name:find("^telemosaic:beacon") or
                    node.name:find("^servergate:servergate_beacon") or
                    minetest.get_item_group(node.name, "telemosaic") > 0 or
                    minetest.get_item_group(node.name, "servergate_beacon") > 0

  if not is_beacon then
    return
  end

  local player_name = puncher:get_player_name()
  local player_control = puncher:get_player_control()

  -- Only trigger on crouch-punch
  if not player_control.sneak then
    return
  end

  -- Check cooldown (prevent spam)
  local cooldown_key = player_name .. minetest.pos_to_string(pos)
  local current_time = minetest.get_us_time() / 1000000

  if not player_punch_cooldown[cooldown_key] or
     (current_time - player_punch_cooldown[cooldown_key]) > 2 then
    player_punch_cooldown[cooldown_key] = current_time
    on_beacon_interact(pos, node, puncher, nil, nil)
  end
end)

-- Handle formspec submissions
minetest.register_on_player_receive_fields(function(player, formname, fields)
  if formname ~= "servergate:travel" and formname ~= "servergate:link" then
    return
  end

  local player_name = player:get_player_name()
  local context = player_context[player_name]

  if not context then
    return
  end

  if fields.close or fields.quit then
    player_context[player_name] = nil
    return true
  end

  if formname == "servergate:travel" then
    if fields.go then
      local player_obj = minetest.get_player_by_name(player_name)
      if player_obj then
        local dest_url = context.dest_url

        if not dest_url or dest_url == "" or dest_url == "unknown" then
          minetest.chat_send_player(player_name, "Error: Invalid destination URL")
          player_context[player_name] = nil
          return true
        end

        servergate.log("info", "Player " .. player_name .. " requested connection info for: " .. dest_url)
        minetest.chat_send_player(player_name, "To travel to this destination, use:")
        minetest.chat_send_player(player_name, "/connect " .. dest_url)
      end

      player_context[player_name] = nil
      return true
    end
  elseif formname == "servergate:link" then
    if fields.link and fields.gate_list then
      local event = minetest.explode_textlist_event(fields.gate_list)
      if event.type == "CHG" or event.type == "DCL" then
        local selected_index = event.index
        local dest_gate = context.available_gates[selected_index]

        if not dest_gate then
          minetest.chat_send_player(player_name, "Error: Invalid gate selection")
          return true
        end

        -- Link the gates
        servergate.db.link_gates(context.source_gate_id, dest_gate.id, dest_gate.server_id, function(success, err)
          if success then
            -- Update beacon metadata
            local meta = minetest.get_meta(context.pos)
            meta:set_string("servergate:destination_gate_id", dest_gate.id)
            meta:set_string("servergate:destination_server_id", dest_gate.server_id)
            meta:set_string("servergate:destination_url", dest_gate.server_url)

            -- Turn on the beacon
            local node = minetest.get_node(context.pos)
            if node.name:find("_off$") then
              minetest.swap_node(context.pos, { name = "servergate:servergate_beacon", param2 = 0 })
            end

            minetest.chat_send_player(player_name, "Gate linked successfully to " .. dest_gate.server_name)
            minetest.close_formspec(player_name, formname)
          else
            minetest.chat_send_player(player_name, "Error linking gates: " .. tostring(err))
          end
        end)

        player_context[player_name] = nil
        return true
      end
    end
  end

  return false
end)

-- Update beacon node definitions to handle right-click
-- Override both servergate and telemosaic beacons
local beacon_types = {
  "servergate:servergate_beacon",
  "servergate:servergate_beacon_off",
  "telemosaic:beacon",
  "telemosaic:beacon_off",
  "telemosaic:beacon_protected",
  "telemosaic:beacon_err",
  "telemosaic:beacon_err_protected",
  "telemosaic:beacon_disabled",
  "telemosaic:beacon_disabled_protected",
  "telemosaic:beacon_off_protected",
}

for _, beacon_name in ipairs(beacon_types) do
  -- Only override if the node exists
  if minetest.registered_nodes[beacon_name] then
    minetest.override_item(beacon_name, {
      on_rightclick = on_beacon_interact,
    })
  end
end
