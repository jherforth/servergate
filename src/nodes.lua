--
-- Servergate structure nodes
-- These get replaced with "real" nodes defined by games/mods/mapgen

for name,def in pairs({
  Extender1 = {
    color = "#00FF00",
    group = "servergate_extender",
    group_value = 1,
  },
  Extender2 = {
    color = "#0000FF",
    group = "servergate_extender",
    group_value = 2,
  },
  Extender3 = {
    color = "#FF00FF",
    group = "servergate_extender",
    group_value = 3,
  },
}) do
  minetest.register_node("servergate:structure_" .. name:lower(),{
    description = "Servergate Structure Node: " .. name,
    groups = {
      not_in_creative_inventory = 1,
      oddly_breakable_by_hand = 1,
      [def.group] = def.group_value,
    },
    color = def.color,
  })
end

--
-- Servergate beacon nodes for cross-server transfers
-- These are distinct from telemosaic beacons to avoid conflicts
--

minetest.register_node("servergate:servergate_beacon", {
  description = "Servergate Beacon",
  tiles = {
    "default_stone_brick.png^[colorize:#FF0000:120",
  },
  groups = {
    cracky = 3,
    servergate_beacon = 1,
  },
  light_source = servergate.settings.beaconglow and 14 or 0,
  paramtype = "light",
  drawtype = "glasslike",
  sunlight_propagates = true,
})

minetest.register_node("servergate:servergate_beacon_off", {
  description = "Inactive Servergate Beacon",
  tiles = {
    "default_stone_brick.png^[colorize:#330000:120",
  },
  groups = {
    cracky = 3,
    servergate_beacon = 1,
  },
  paramtype = "light",
  drawtype = "glasslike",
  sunlight_propagates = true,
})

-- Alias old names for backwards compatibility
minetest.register_alias("worldgate:beacon", "servergate:servergate_beacon")
minetest.register_alias("worldgate:beacon_off", "servergate:servergate_beacon_off")
minetest.register_alias("worldgate:servergate_beacon", "servergate:servergate_beacon")
minetest.register_alias("worldgate:servergate_beacon_off", "servergate:servergate_beacon_off")
minetest.register_alias("worldgate:structure_extender1", "servergate:structure_extender1")
minetest.register_alias("worldgate:structure_extender2", "servergate:structure_extender2")
minetest.register_alias("worldgate:structure_extender3", "servergate:structure_extender3")
