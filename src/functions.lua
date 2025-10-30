--
-- Servergate functions
--

-- Simple UUID v4 generator
function servergate.generate_uuid()
  local template = 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'
  return string.gsub(template, '[xy]', function(c)
    local v = (c == 'x') and math.random(0, 0xf) or math.random(8, 0xb)
    return string.format('%x', v)
  end)
end

-- Function for selecting a random base schematic
local base_schematics = (function()
  local schems = {}
  for _,schematic in ipairs(minetest.get_dir_list(servergate.modpath .. "/schematics/base/",false)) do
    table.insert(schems,servergate.modpath .. "/schematics/base/" .. schematic)
  end
  return schems
end)()
local base_count = #base_schematics
servergate.schematics = {}
servergate.schematics.base = base_schematics

function servergate.get_random_base(pcgr)
  return base_schematics[pcgr and pcgr:next(1,base_count) or math.random(1,base_count)]
end

-- Function for selecting a random decor schematic
local decor_schematics = (function()
  local schems = {}
  for _,schematic in ipairs(minetest.get_dir_list(servergate.modpath .. "/schematics/decor/",false)) do
    table.insert(schems,servergate.modpath .. "/schematics/decor/" .. schematic)
  end
  return schems
end)()
local decor_count = #decor_schematics
servergate.schematics.decor = decor_schematics

function servergate.get_random_decor(pcgr)
  return decor_schematics[pcgr and pcgr:next(1,decor_count) or math.random(1,decor_count)]
end

-- Function for selecting a random quality value
function servergate.get_random_quality(pcgr)
  return pcgr and pcgr:next(-1,1) or math.random(-1,1)
end

-- Function for adding new servergates without data checks
function servergate.add_gate_unsafe(def)
  -- Add gate to list of gates
  local ngates = #servergate.gates
  servergate.gates[ngates + 1] = def

  -- Index the gate via mapblock hashing
  local hash = minetest.hash_node_position(def.position:divide(16):floor())
  local gates = servergate.hash_index[hash] or {}
  gates[#gates + 1] = ngates + 1
  servergate.hash_index[hash] = gates
end

-- Function for adding new servergates
local ymin = math.max(-29900,servergate.settings.ymin)
local ymax = math.min(29900,servergate.settings.ymax)
function servergate.add_gate(def)
  -- Position must be a valid vector
  if not def.position then
    error("Attempted to add a servergate without a position")
  elseif not vector.check(def.position) then
    error("Servergate position must be a vector created with vector.new")
  elseif def.position.y > ymax or def.position.y < ymin then
    error("Servergate position " .. minetest.pos_to_string(def.position) .. " is beyond ymin/ymax values")
  end

  if not def.base then
    def.base = servergate.get_random_base()
  elseif type(def.base) ~= "string" then
    error("Servergate base must be a string that identifies a schematic")
  end

  if not def.decor then
    def.decor = servergate.get_random_decor()
  elseif type(def.decor) ~= "string" then
    error("Servergate decor must be a string that identifies a schematic")
  end

  if not def.quality then
    def.quality = servergate.get_random_quality()
  elseif not (def.quality == -1 or def.quality == 0 or def.quality == 1) then
    error("Servergate quality must be an integer between -1 and 1 inclusive")
  end

  if def.exact == nil then
    def.exact = false
  else
    def.exact = not not def.exact -- boolean cast
  end

  -- Add gate via unsafe function
  servergate.add_gate_unsafe(def)
end

-- Function for checking a mapblock against the gate hash index
function servergate.get_gates_for_mapblock(pos)
  local gates = servergate.hash_index[minetest.hash_node_position(pos:divide(16):floor())] or {}
  for i = 0, #gates do
    gates[i] = servergate.gates[gates[i]]
  end
  return gates
end

-- Function for finding a suitable placement for a servergate within a given area
function servergate.find_servergate_location_in_area(minp,maxp)
end

-- Function for spawning a servergate
function servergate.generate_gate(pos)
end

-- Function for gate generation callbacks
servergate.servergate_generated_callbacks = {}
function servergate.reigster_on_servergate_generated(fn)
  table.insert(servergate.servergate_generated_callbacks,fn)
end

-- Function for failed gate generation callbacks
servergate.servergate_failed_callbacks = {}
function servergate.reigster_on_servergate_failed(fn)
  table.insert(servergate.servergate_failed_callbacks,fn)
end
