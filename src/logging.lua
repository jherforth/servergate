-- Logging for successfully generated servergates
servergate.reigster_on_servergate_generated(function(pos,gate,strategy)
  minetest.log("action","Servergate generated at " .. minetest.pos_to_string(pos) .. " using the " .. strategy .. " strategy")
end)

-- Logging for servergates that failed to generate
servergate.reigster_on_servergate_failed(function(gate)
  minetest.log("warning","Servergate failed to generate" .. (gate.exact and " at " or " near ") .. minetest.pos_to_string(gate.position))
end)
