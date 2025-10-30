API
---

All of the API functions for Worldgate are defined in the `worldgate` global variable.

## Server Transfer API

### `servergate.server_api.register_server(callback)`

Registers the current server in the Supabase database. This is called automatically on server startup. The callback receives `(success, server_id)`.

### `servergate.server_api.register_gate(position, base, decor, quality, callback)`

Registers a worldgate in the database. Parameters:
- `position` - Vector position of the gate
- `base` - Base schematic path
- `decor` - Decor schematic path
- `quality` - Gate quality (-1, 0, or 1)
- `callback` - Function called with `(success, data)`

### `servergate.server_api.link_gates(source_gate_id, destination_gate_id, destination_server_id, callback)`

Links two gates together across servers. Parameters:
- `source_gate_id` - UUID of source gate
- `destination_gate_id` - UUID of destination gate
- `destination_server_id` - UUID of destination server
- `callback` - Function called with `(success, data)`

### `servergate.server_api.get_gate_destination(gate_id, callback)`

Retrieves destination information for a gate.

### `servergate.server_api.log_transfer(player_name, source_gate_id, dest_gate_id, dest_server_id, success, callback)`

Logs a player transfer to the database.

### `servergate.initiate_transfer(beacon_pos, player)`

Initiates a server transfer for a player at a beacon. This is called automatically when a player right-clicks a beacon.

### `servergate.link_gates_manual(source_pos, dest_gate_id, dest_server_id)`

Manually link a gate at `source_pos` to a destination gate. Returns `(success, error_message)`.

## Gate Generation API

### `servergate.add_gate(def)`

This function adds a worldgate to the world. This is useful for adding your own custom worldgates to the world. The `def` parameter must be a table with the following fields:

```lua
{
  -- position: The x/y/z location where the worldgate will be generated. This
  -- value must be a vector created with vector.new.
  position = vector.new(...),

  -- base: A schematic specifier that identifies a 'base' schematic that forms
  -- the base, or bottom half, of the worldgate which typically contains a
  -- Telemosaic beacon and range extender marker nodes.
  base = servergate.get_random_base(pcgr),

  -- decor: A schematic specifier that identifies a 'decor' schematic that forms
  -- a decoration placed on the worldgate base. This is typically some form of
  -- housing or adornment for the servergate.
  decor = servergate.get_random_decor(pcgr),

  -- quality: Determines the quality of range extenders that generate as part
  -- of this servergate. It must be an integer with a value of -1, 0, or 1 which
  -- corresponds to lower quality, equal quality, or better quality extenders,
  -- respectively.
  quality = servergate.get_random_quality(pcgr),

  -- exact: A boolean value that specifies if the worldgate should be placed at
  -- the exact position specified. If true, the worldgate will be placed at the
  -- point specified by the position parameter regardless of surrounding
  -- terrain. If false, the mod will attempt to place the worldgate according to
  -- the available terrain which favors the heightmap first, below air second,
  -- then any random position in the mapchunk if all else fails.
  exact = false,

  -- destination: A vector that matches the position of another worldgate that
  -- this worldgate will be linked to automatically. If this value is nil, then
  -- the gate's beacon will be deactivated and it will have no destination.
  destination = nil,
}
```

### `servergate.get_random_base(pcgr)`

This function returns a path to a random schematic file in the `worldgate/schematics/base/` directory that corresponds to a worldgate base. Every built-in base schematic will contain a single beacon and extender marker nodes. The optional argument is a PcgRandom object that can be used to choose the random base schematic.

### `servergate.get_random_decor(pcgr)`

This function returns a path to a random schematic file in the `worldgate/schematics/decor/` directory that corresponds to a worldgate decoration. Decorations typically provide some form of housing or adornment surrounding the worldgate's Telemosaic beacon. A decoration schematic is not necessary for a worldgate to function, but decor does look pretty nice!

The optional argument is a PcgRandom object that can be used to choose the random decor schematic.

### `servergate.get_random_quality(pcgr)`

This function returns a random value of either -1, 0, or 1, values which correspond to the quality values of a servergate. This is useful for creating gates with a random quality. The optional argument is a PcgRandom object that can be used to choose the random value.

### `servergate.get_gates_for_mapblock(position)`

This function returns a list of all gates that should be generated for the mapblock of the given vector location. The `position` parameter must be a vector created with `vector.new`.

### `servergate.reigster_on_worldgate_generated(fn)`

This function registers a callback function that will be called when a worldgate is successfully generated in the world. The function is called with three parameters:

- `location`: A vector representing the point at which the worldgate was actually placed in the world
- `gate`: The definition of the generated worldgate as specified for `servergate.add_gate(def)`
- `strategy`: A string that specifies the placement algorithm that the mapgen function used to place the worldgate, in order of mapgen preference:
  - `"exact"`: The location is the worldgate's `position` value specified with `exact = true`
  - `"heightmap"`: A suitable location was found matching the heightmap for the worldgate's mapchunk
  - `"grounded"`: A suitable location was found by probing downwards from a random air node
  - `"random"`: A location was selected at random with no regards for the surrounding terrain

### `servergate.register_on_worldgate_failed(fn)`

This function registers a callback function that will be called when a worldgate tries but fails to generate. This is most likely to happen if mod settings prevent worldgates from spawning in midair or underwater and such a position is selected via the `random` placement strategy during mapgen. A gate that fails to generate in this manner will not attempt to be generated again.

The callback function is called with just one parameter

- `gate`: The gate definition of the worldgate that failed to generate as specified for `servergate.add_gate(def)`

Dark and Dangerous API
----------------------

**WARNING: ACCESSING THESE FUNCTIONS/VARIABLES CAN CAUSE UNPREDICTABLE LOSS/DAMAGE TO YOUR WORLD; DO NOT USE UNLESS YOU KNOW WHAT YOU ARE DOING**

### `servergate.add_gate_unsafe(def)`

This function fills the same role as `servergate.add_gate(def)`, but it doesn't perform any validation checks to ensure that the gate is valid. This function is used internally during native gate generation for faster performance. Use only if you're sure that your gate definitions do not require validation.