--
-- Worldgate structure nodes
-- These get replaced with "real" nodes defined by games/mods/mapgen

for name,def in pairs({
  Extender1 = {
    color = "#00FF00",
    group = "worldgate_extender",
    group_value = 1,
  },
  Extender2 = {
    color = "#0000FF",
    group = "worldgate_extender",
    group_value = 2,
  },
  Extender3 = {
    color = "#FF00FF",
    group = "worldgate_extender",
    group_value = 3,
  },
}) do
  minetest.register_node("worldgate:structure_" .. name:lower(),{
    description = "Worldgate Structure Node: " .. name,
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

minetest.register_node("worldgate:servergate_beacon", {
  description = "Servergate Beacon",
  tiles = {
    "default_stone_brick.png^[colorize:#FF0000:120",
  },
  groups = {
    cracky = 3,
    servergate_beacon = 1,
  },
  light_source = worldgate.settings.beaconglow and 14 or 0,
  paramtype = "light",
  drawtype = "glasslike",
  sunlight_propagates = true,
  on_rightclick = function(pos, node, clicker, itemstack, pointed_thing)
    if not clicker or not clicker:is_player() then
      return
    end

    worldgate.initiate_transfer(pos, clicker)
  end,
})

minetest.register_node("worldgate:servergate_beacon_off", {
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
minetest.register_alias("worldgate:beacon", "worldgate:servergate_beacon")
minetest.register_alias("worldgate:beacon_off", "worldgate:servergate_beacon_off")