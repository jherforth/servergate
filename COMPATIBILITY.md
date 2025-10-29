# Compatibility Notes

## Coexistence with Original Worldgate/Telemosaic Mods

This mod has been designed to coexist peacefully with the original worldgate mod and/or telemosaic mod if both are installed in the same world.

### Visual Differences

**Servergate Beacons (this mod):**
- Node names: `worldgate:servergate_beacon` and `worldgate:servergate_beacon_off`
- Color: Cyan/Light Blue (`#00FFFF`)
- Purpose: Cross-server player transfers
- Right-click shows destination server URL

**Telemosaic Beacons (telemosaic mod):**
- Node names: `telemosaic:beacon` and `telemosaic:beacon_off`
- Color: Blue (`#4444FF`)
- Purpose: Local teleportation within the same server
- Right-click teleports to destination

### Node Groups

Servergate beacons use the `servergate_beacon` group instead of `telemosaic` or `worldgate_beacon` to avoid conflicts.

### Backward Compatibility

For worlds that used the older version of this mod:

```lua
-- Aliases are automatically registered
minetest.register_alias("worldgate:beacon", "worldgate:servergate_beacon")
minetest.register_alias("worldgate:beacon_off", "worldgate:servergate_beacon_off")
```

Old beacons will automatically convert to the new servergate beacons.

### Using Both Systems

You can have both systems in your world:

1. **Worldgates with Telemosaic Beacons**: Traditional local teleportation
2. **Worldgates with Servergate Beacons**: Cross-server transfers

Players will know which is which by the color:
- **Blue beacons** = Local teleport
- **Cyan beacons** = Server transfer

### Migration from Pure Worldgate/Telemosaic

If you're upgrading a world that used the original worldgate mod:

1. The worldgate structures will remain
2. If telemosaic mod is installed, the blue beacons will continue working for local teleportation
3. New worldgate structures will generate with cyan servergate beacons
4. You can manually replace old beacons with servergate beacons if desired

### Commands

All admin commands work specifically with servergate beacons:

- `/worldgate_info` - Only works when looking at servergate beacons (cyan)
- `/worldgate_link` - Only links servergate beacons
- `/worldgate_list` - Lists servergates on this server

Telemosaic commands continue to work with telemosaic beacons independently.

## Database Independence

The servergate system uses its own database tables and does not interfere with any telemosaic data:

- Servergates: Stored in `worldgates` table
- Telemosaic beacons: Use mod_storage or telemosaic's own system
- No data conflicts between systems

## Performance

Running both systems simultaneously:
- No performance impact
- Each system operates independently
- Servergate beacons managed by ABM every 5 seconds
- Telemosaic beacons managed by telemosaic mod

## Recommended Setup

For a clean server network:

1. **Single Server**: Use telemosaic for local gates only
2. **Multiple Servers**: Use both:
   - Telemosaic for convenient local teleportation
   - Servergates for traveling between servers
3. **Pure Server Network**: Disable `worldgate.native.link` and use only servergates

## Technical Details

### Node Registration Order

The mod registers servergates before checking for telemosaic, ensuring both can coexist.

### Metadata Keys

Servergate beacons use:
- `worldgate:gate_id` - UUID in database
- `worldgate:source` - Original generation position

These don't conflict with telemosaic's metadata keys.

### Group Naming

- `servergate_beacon` - This mod's beacons
- `telemosaic` - Telemosaic mod's beacons
- `worldgate_extender` - Decorative structure nodes (shared, no conflict)

## Questions?

If you experience conflicts:
1. Check that both mods are up to date
2. Verify node names using `/lua minetest.get_node(pos).name`
3. Report issues with full debug logs
