--
-- Spawn gate generation for new players
--

-- Track players who have spawned to avoid duplicate gate generation
local spawned_players = {}

-- Register callback for when a player first spawns
minetest.register_on_newplayer(function(player)
	local player_name = player:get_player_name()

	-- Mark player as having spawned
	spawned_players[player_name] = true

	-- Get player spawn position
	local spawn_pos = player:get_pos()

	if not spawn_pos then
		minetest.log("warning", "Could not get spawn position for player " .. player_name)
		return
	end

	-- Generate a random position within 100 nodes of spawn
	local pcgr = PcgRandom(minetest.hash_node_position(spawn_pos) + os.time())

	-- Random offset within 100 nodes (sphere-ish distribution)
	local offset_x = pcgr:next(-100, 100)
	local offset_y = pcgr:next(-50, 50)
	local offset_z = pcgr:next(-100, 100)

	local gate_pos = vector.new(
		spawn_pos.x + offset_x,
		spawn_pos.y + offset_y,
		spawn_pos.z + offset_z
	)

	-- Ensure gate is within valid y bounds
	local ymin = math.max(-29900, worldgate.settings.ymin)
	local ymax = math.min(29900, worldgate.settings.ymax)

	if gate_pos.y < ymin then
		gate_pos.y = ymin + 50
	elseif gate_pos.y > ymax then
		gate_pos.y = ymax - 50
	end

	-- Add the spawn gate
	worldgate.add_gate({
		position = gate_pos,
		base = worldgate.get_random_base(),
		decor = worldgate.get_random_decor(),
		quality = 0, -- Average quality for spawn gates
		exact = false,
	})

	minetest.log("action", "Spawn worldgate queued near " .. minetest.pos_to_string(spawn_pos) ..
	             " for new player " .. player_name .. " at " .. minetest.pos_to_string(gate_pos))
end)
