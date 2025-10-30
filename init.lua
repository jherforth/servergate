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
    superextenders = minetest.settings:get_bool("servergate.superextenders",false),
    destroykeys = minetest.settings:get_bool("servergate.destroykeys",false),
    server_name = minetest.settings:get("servergate.server_name") or "My Server",
    server_url = minetest.settings:get("servergate.server_url") or "minetest://localhost:30000",
    db_host = minetest.settings:get("servergate.db_host") or "localhost",
    db_port = tonumber(minetest.settings:get("servergate.db_port") or 5432),
    db_name = minetest.settings:get("servergate.db_name") or "worldgate",
    db_user = minetest.settings:get("servergate.db_user") or "worldgate",
    db_password = minetest.settings:get("servergate.db_password") or "",
  },
  server_id = nil,
}

--
-- Modules
--

local function load(file)
  dofile(servergate.modpath .. "/src/" .. file .. ".lua")
end

load("nodes")
load("functions")
load("database")
load("gates")
load("server_api")
load("transfer_screen")
load("mapgen")
load("beacon_interaction")
load("logging")
load("settings_overrides")
load("link")
load("spawn_gate")

-- Load admin commands
dofile(servergate.modpath .. "/admin_commands.lua")