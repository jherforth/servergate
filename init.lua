--
-- Globals
--

worldgate = {
  modpath = minetest.get_modpath("worldgate"),
  gates = {},
  hash_index = {},
  forceload_index = {},
  settings = {
    mapgen = minetest.settings:get_bool("worldgate.mapgen",true),
    native = minetest.settings:get_bool("worldgate.native",true),
    native_link = minetest.settings:get_bool("worldgate.native.link",false),
    native_spread = tonumber(minetest.settings:get("worldgate.native.spread",1000) or 1000),
    native_xzjitter = tonumber(minetest.settings:get("worldgate.native.xzjitter",12.5) or 12.5),
    ymin = tonumber(minetest.settings:get("worldgate.ymin",-29900) or -29900),
    ymax = tonumber(minetest.settings:get("worldgate.ymax",29900) or 29900),
    underwaterspawn = minetest.settings:get_bool("worldgate.underwaterspawn",false),
    midairspawn = minetest.settings:get_bool("worldgate.midairspawn",false),
    breakage = tonumber(minetest.settings:get("worldgate.breakage",8) or 8),
    beaconglow = minetest.settings:get_bool("worldgate.beaconglow",true),
  },
}

--
-- Modules
--

local function load(file)
  dofile(worldgate.modpath .. "/src/" .. file .. ".lua")
end

load("nodes")
load("functions")
load("gates")
load("server_api")
load("mapgen")
load("logging")
load("settings_overrides")
load("link")

-- Load admin commands
dofile(worldgate.modpath .. "/admin_commands.lua")