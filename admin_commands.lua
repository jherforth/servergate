--
-- Admin commands for managing worldgates
--

-- Command to get gate info at a position
minetest.register_chatcommand("worldgate_info", {
  params = "",
  description = "Get information about the worldgate beacon you're looking at",
  privs = {server = true},
  func = function(name, param)
    local player = minetest.get_player_by_name(name)
    if not player then
      return false, "Player not found"
    end

    local pos = player:get_pos()
    local dir = player:get_look_dir()
    local end_pos = vector.add(pos, vector.multiply(dir, 10))
    local ray = minetest.raycast(pos, end_pos, false, false)

    for pointed_thing in ray do
      if pointed_thing.type == "node" then
        local node_pos = pointed_thing.under
        local node = minetest.get_node(node_pos)

        if minetest.get_item_group(node.name, "servergate_beacon") > 0 or minetest.get_item_group(node.name, "telemosaic") > 0 then
          local meta = minetest.get_meta(node_pos)
          local gate_id = meta:get_string("servergate:gate_id")
          local source = meta:get_string("servergate:source")
          local destination = meta:get_string("servergate:destination")

          if source and source ~= "" then
            local info = "Servergate Beacon"
            if gate_id and gate_id ~= "" then
              info = info .. "\nGate ID: " .. gate_id
            end
            info = info .. "\nSource: " .. source .. "\nPosition: " .. minetest.pos_to_string(node_pos)
            if destination and destination ~= "" then
              info = info .. "\nDestination: " .. destination
            else
              info = info .. "\nDestination: Not linked"
            end
            return true, info
          else
            return false, "This beacon is not a registered servergate"
          end
        end
      end
    end

    return false, "No servergate beacon found"
  end,
})

-- Command to link gates
minetest.register_chatcommand("worldgate_link", {
  params = "<destination_gate_id>",
  description = "Link the worldgate you're looking at to another gate by its UUID",
  privs = {server = true},
  func = function(name, param)
    local player = minetest.get_player_by_name(name)
    if not player then
      return false, "Player not found"
    end

    local dest_gate_id = param:match("^(%S+)$")
    if not dest_gate_id then
      return false, "Usage: /worldgate_link <destination_gate_id>\nExample: /worldgate_link 12345678-abcd-4xxx-yxxx-xxxxxxxxxxxx"
    end

    if not servergate.db or not servergate.db.available then
      return false, "Database not available. Configure PostgreSQL to use gate linking."
    end

    local pos = player:get_pos()
    local dir = player:get_look_dir()
    local end_pos = vector.add(pos, vector.multiply(dir, 10))
    local ray = minetest.raycast(pos, end_pos, false, false)

    for pointed_thing in ray do
      if pointed_thing.type == "node" then
        local node_pos = pointed_thing.under
        local node = minetest.get_node(node_pos)

        if minetest.get_item_group(node.name, "servergate_beacon") > 0 or minetest.get_item_group(node.name, "telemosaic") > 0 then
          local meta = minetest.get_meta(node_pos)
          local source_gate_id = meta:get_string("servergate:gate_id")

          if not source_gate_id or source_gate_id == "" then
            return false, "This gate has no UUID. It may not be registered in the database."
          end

          -- Get destination gate info from database to find its server
          servergate.db.get_gate_info(dest_gate_id, function(success, result)
            if not success or not result or #result == 0 then
              minetest.chat_send_player(name, "Error: Destination gate not found in database")
              return
            end

            local dest_gate = result[1]
            local dest_server_id = dest_gate.server_id

            -- Link the gates in the database
            servergate.db.link_gates(source_gate_id, dest_gate_id, dest_server_id, function(link_success, link_err)
              if link_success then
                -- Update local beacon metadata
                meta:set_string("servergate:destination_gate_id", dest_gate_id)
                meta:set_string("servergate:destination_server_id", dest_server_id)
                if dest_gate.dest_server_url then
                  meta:set_string("servergate:destination_url", dest_gate.dest_server_url)
                end

                -- Turn on the beacon
                local beacon_node = minetest.get_node(node_pos)
                if beacon_node.name:find("_off$") then
                  if beacon_node.name:find("^telemosaic:") then
                    minetest.swap_node(node_pos, { name = "telemosaic:beacon", param2 = 0 })
                  else
                    minetest.swap_node(node_pos, { name = "servergate:servergate_beacon", param2 = 0 })
                  end
                end

                minetest.chat_send_player(name, "Gate linked successfully to " .. (dest_gate.dest_server_name or "destination server"))
              else
                minetest.chat_send_player(name, "Error linking gates: " .. tostring(link_err))
              end
            end)
          end)

          return true, "Linking gate to " .. dest_gate_id .. "..."
        end
      end
    end

    return false, "No servergate beacon found"
  end,
})

-- Command to list all gates on this server
minetest.register_chatcommand("worldgate_list", {
  params = "",
  description = "List all worldgates registered on this server from the database",
  privs = {server = true},
  func = function(name, param)
    if not servergate.db or not servergate.db.available or not servergate.server_id then
      return false, "Database not available or server not registered"
    end

    local sql = string.format([[
      SELECT id, position, quality,
             destination_gate_id IS NOT NULL as is_linked
      FROM worldgates
      WHERE server_id = '%s'
      ORDER BY created_at;
    ]], servergate.server_id)

    servergate.db.query(sql, function(success, result)
      if not success then
        minetest.chat_send_player(name, "Error querying database: " .. tostring(result))
        return
      end

      if not result or #result == 0 then
        minetest.chat_send_player(name, "No worldgates registered yet")
        return
      end

      local output = "Registered worldgates on this server:\n"
      for i, gate in ipairs(result) do
        local linked_status = gate.is_linked == "t" and "linked" or "not linked"
        output = output .. i .. ". " .. gate.id:sub(1, 8) .. "... at " .. gate.position .. " (" .. linked_status .. ")\n"
      end

      minetest.chat_send_player(name, output)
    end)

    return true, "Fetching gate list from database..."
  end,
})
