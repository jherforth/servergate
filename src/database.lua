--
-- PostgreSQL database integration for servergate
--

servergate.db = {}

-- Check if PostgreSQL connection is configured
local function check_pgsql_config()
  local s = servergate.settings
  if not s.db_host or s.db_host == "" or
     not s.db_name or s.db_name == "" or
     not s.db_user or s.db_user == "" then
    return false
  end
  return true
end

if not check_pgsql_config() then
  minetest.log("warning", "Servergate: PostgreSQL not configured. Database features disabled.")
  minetest.log("warning", "Servergate: Configure servergate.db_* settings in world.mt or minetest.conf")
  servergate.db.available = false
  return
end

-- Test if we can load the luasql.postgres library
local pgsql_status, luasql = pcall(require, "luasql.postgres")
if not pgsql_status then
  minetest.log("warning", "Servergate: PostgreSQL library not available: " .. tostring(luasql))
  minetest.log("warning", "Servergate: Install luasql-postgres package")
  servergate.db.available = false
  return
end

servergate.db.available = true
minetest.log("action", "Servergate: PostgreSQL connection configured")

-- Database connection parameters for LuaSQL
local function get_connection_params()
  local s = servergate.settings
  return s.db_name, s.db_user, s.db_password, s.db_host, s.db_port
end

-- Execute a database query
function servergate.db.query(sql, callback)
  if not servergate.db.available then
    if callback then
      callback(false, "PostgreSQL not available")
    end
    return
  end

  local db_name, db_user, db_password, db_host, db_port = get_connection_params()

  minetest.log("action", "Servergate DB query: " .. sql:sub(1, 100))

  -- Execute query asynchronously
  minetest.handle_async(
    function(dbname, user, pass, host, port)
      local luasql = require("luasql.postgres")
      local env = luasql.postgres()
      local conn, err = env:connect(dbname, user, pass, host, port)

      if not conn then
        env:close()
        return {success = false, error = "Failed to connect to database: " .. tostring(err)}
      end

      local cursor, err = conn:execute(sql)

      if not cursor then
        conn:close()
        env:close()
        return {success = false, error = tostring(err)}
      end

      local rows = {}
      if type(cursor) == "userdata" then
        local row = cursor:fetch({}, "a")
        while row do
          table.insert(rows, row)
          row = cursor:fetch({}, "a")
        end
        cursor:close()
      end

      local rowcount = #rows
      conn:close()
      env:close()
      return {success = true, rows = rows, rowcount = rowcount}
    end,
    function(result)
      if callback then
        callback(result.success, result.error or result.rows, result.rowcount)
      end
    end,
    db_name, db_user, db_password, db_host, db_port
  )
end

-- Register this server in the database
function servergate.db.register_server()
  if not servergate.db.available then
    minetest.log("warning", "Servergate: Cannot register server - PostgreSQL not available")
    return
  end

  local server_uuid = servergate.generate_uuid()
  local name = servergate.settings.server_name:gsub("'", "''") -- Escape quotes
  local url = servergate.settings.server_url:gsub("'", "''")

  local sql = string.format([[
    INSERT INTO servers (id, name, url, is_active)
    VALUES ('%s', '%s', '%s', TRUE)
    ON CONFLICT (name) DO UPDATE
    SET url = EXCLUDED.url,
        is_active = TRUE,
        updated_at = CURRENT_TIMESTAMP
    RETURNING id;
  ]], server_uuid, name, url)

  servergate.db.query(sql, function(success, result, rowcount)
    if success and result and #result > 0 then
      servergate.server_id = result[1].id
      minetest.log("action", "Servergate: Server registered with ID: " .. servergate.server_id)
    else
      minetest.log("error", "Servergate: Failed to register server: " .. tostring(result))
    end
  end)
end

-- Register a gate in the database
function servergate.db.register_gate(gate_id, position, base, decor, quality, callback)
  if not servergate.db.available or not servergate.server_id then
    if callback then
      callback(false, "Database not available or server not registered")
    end
    return
  end

  local pos_str = minetest.pos_to_string(position):gsub("'", "''")
  local base_str = base:gsub("'", "''")
  local decor_str = decor:gsub("'", "''")

  local sql = string.format([[
    INSERT INTO worldgates (id, server_id, position, base_schematic, decor_schematic, quality)
    VALUES ('%s', '%s', '%s', '%s', '%s', %d)
    ON CONFLICT (id) DO UPDATE
    SET position = EXCLUDED.position,
        base_schematic = EXCLUDED.base_schematic,
        decor_schematic = EXCLUDED.decor_schematic,
        quality = EXCLUDED.quality,
        updated_at = CURRENT_TIMESTAMP;
  ]], gate_id, servergate.server_id, pos_str, base_str, decor_str, quality)

  servergate.db.query(sql, function(success, result)
    if success then
      minetest.log("action", "Servergate: Gate " .. gate_id .. " registered in database")
      if callback then
        callback(true)
      end
    else
      minetest.log("error", "Servergate: Failed to register gate: " .. tostring(result))
      if callback then
        callback(false, result)
      end
    end
  end)
end

-- Link two gates together
function servergate.db.link_gates(source_gate_id, dest_gate_id, dest_server_id, callback)
  if not servergate.db.available then
    if callback then
      callback(false, "Database not available")
    end
    return
  end

  local sql = string.format([[
    UPDATE worldgates
    SET destination_gate_id = '%s',
        destination_server_id = '%s',
        updated_at = CURRENT_TIMESTAMP
    WHERE id = '%s';
  ]], dest_gate_id, dest_server_id, source_gate_id)

  servergate.db.query(sql, callback)
end

-- Get gate information from database
function servergate.db.get_gate_info(gate_id, callback)
  if not servergate.db.available then
    if callback then
      callback(false, "Database not available")
    end
    return
  end

  local sql = string.format([[
    SELECT
      g.*,
      s1.name as server_name,
      s1.url as server_url,
      g2.position as dest_position,
      s2.name as dest_server_name,
      s2.url as dest_server_url
    FROM worldgates g
    LEFT JOIN servers s1 ON g.server_id = s1.id
    LEFT JOIN worldgates g2 ON g.destination_gate_id = g2.id
    LEFT JOIN servers s2 ON g.destination_server_id = s2.id
    WHERE g.id = '%s';
  ]], gate_id)

  servergate.db.query(sql, callback)
end

-- Send heartbeat to keep server active
function servergate.db.send_heartbeat()
  if not servergate.db.available or not servergate.server_id then
    return
  end

  local sql = string.format([[
    UPDATE servers
    SET updated_at = CURRENT_TIMESTAMP,
        is_active = TRUE
    WHERE id = '%s';
  ]], servergate.server_id)

  servergate.db.query(sql, nil)
end

-- Initialize database connection and register server
minetest.after(0, function()
  if servergate.db.available then
    servergate.db.register_server()

    -- Send heartbeat every 60 seconds
    local function heartbeat_loop()
      servergate.db.send_heartbeat()
      minetest.after(60, heartbeat_loop)
    end
    minetest.after(60, heartbeat_loop)
  end
end)
