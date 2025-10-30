--
-- Globals
--

servergate = {
  modpath = minetest.get_modpath("servergate"),
  gates = {},
  hash_index = {},
  forceload_index = {},
  settings = {
    mapgen = minetest.settings:get_bool("servergate.mapgen",true),
    native = minetest.settings:get_bool("servergate.native",true),
    native_link = minetest.settings:get_bool("servergate.native.link",false),
    native_spread = tonumber(minetest.settings:get("servergate.native.spread",1000) or 1000),
    native_xzjitter = tonumber(minetest.settings:get("servergate.native.xzjitter",12.5) or 12.5),
    ymin = tonumber(minetest.settings:get("servergate.ymin",-29900) or -29900),
    ymax = tonumber(minetest.settings:get("servergate.ymax",29900) or 29900),
    underwaterspawn = minetest.settings:get_bool("servergate.underwaterspawn",false),
    midairspawn = minetest.settings:get_bool("servergate.midairspawn",true),
    breakage = tonumber(minetest.settings:get("servergate.breakage",8) or 8),
    beaconglow = minetest.settings:get_bool("servergate.beaconglow",true),
  },
}

--
-- Modules
--

local function load(file)
  dofile(servergate.modpath .. "/src/" .. file .. ".lua")
end

load("nodes")
load("functions")
load("gates")
load("server_api")
load("transfer_screen")
load("mapgen")
load("logging")
load("settings_overrides")
load("link")
load("spawn_gate")

-- Load admin commands
dofile(servergate.modpath .. "/admin_commands.lua")