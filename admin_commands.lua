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

        if minetest.get_item_group(node.name, "worldgate_beacon") > 0 then
          local meta = minetest.get_meta(node_pos)
          local gate_id = meta:get_string("worldgate:gate_id")
          local source = meta:get_string("worldgate:source")

          if gate_id and gate_id ~= "" then
            return true, "Gate ID: " .. gate_id .. "\nSource: " .. source .. "\nPosition: " .. minetest.pos_to_string(node_pos)
          else
            return false, "This beacon is not registered in the database"
          end
        end
      end
    end

    return false, "No worldgate beacon found"
  end,
})

-- Command to link gates
minetest.register_chatcommand("worldgate_link", {
  params = "<destination_gate_id> <destination_server_id>",
  description = "Link the worldgate you're looking at to another gate",
  privs = {server = true},
  func = function(name, param)
    local player = minetest.get_player_by_name(name)
    if not player then
      return false, "Player not found"
    end

    local dest_gate_id, dest_server_id = param:match("^(%S+)%s+(%S+)$")
    if not dest_gate_id or not dest_server_id then
      return false, "Usage: /worldgate_link <destination_gate_id> <destination_server_id>"
    end

    local pos = player:get_pos()
    local dir = player:get_look_dir()
    local end_pos = vector.add(pos, vector.multiply(dir, 10))
    local ray = minetest.raycast(pos, end_pos, false, false)

    for pointed_thing in ray do
      if pointed_thing.type == "node" then
        local node_pos = pointed_thing.under
        local node = minetest.get_node(node_pos)

        if minetest.get_item_group(node.name, "worldgate_beacon") > 0 then
          local success, err = worldgate.link_gates_manual(node_pos, dest_gate_id, dest_server_id)
          if success then
            return true, "Gate linking initiated. Check server log for confirmation."
          else
            return false, err or "Failed to link gates"
          end
        end
      end
    end

    return false, "No worldgate beacon found"
  end,
})

-- Command to list all gates on this server
minetest.register_chatcommand("worldgate_list", {
  params = "",
  description = "List all worldgates registered on this server",
  privs = {server = true},
  func = function(name, param)
    local count = 0
    local output = "Registered worldgates:\n"

    for _, gate in ipairs(worldgate.gates) do
      count = count + 1
      output = output .. count .. ". Position: " .. minetest.pos_to_string(gate.position) .. "\n"
    end

    if count == 0 then
      return false, "No worldgates registered yet"
    end

    return true, output
  end,
})
