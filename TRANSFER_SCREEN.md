# Transfer Screen Feature

## Overview

When players right-click a linked servergate beacon, they see a beautiful fullscreen transfer interface with:

- A dramatic portal/tunnel background image
- Server name and connection URL
- Step-by-step transfer instructions
- Copy-friendly text field with the server address

## Setup

### 1. Add Transfer Image

Place your transfer background image in the `textures/` directory:

```
worldgate/textures/worldgate_transfer.png
```

**Image Requirements:**
- **Filename**: Must be named `worldgate_transfer.png`
- **Format**: PNG (recommended) or JPG
- **Size**: 1920x1080 or larger recommended
- **Theme**: Portal, tunnel, or transfer-themed imagery works best

### 2. No Code Changes Needed

The transfer screen is automatically shown when:
1. A player right-clicks a servergate beacon (red glowing block)
2. The beacon is linked to a destination server
3. The destination server info is available in the database

## What Players See

### Visual Display

1. **Background**: Your custom portal image fills the screen
2. **Overlay Box**: Semi-transparent black box contains transfer info
3. **Server Name**: Large text showing destination server
4. **Server URL**: The connection address
5. **Text Field**: Pre-filled with server URL for easy copying
6. **Close Button**: Dismisses the screen

### Chat Messages

In addition to the visual screen, players receive detailed chat instructions:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
◈ SERVER TRANSFER INITIATED ◈

Destination: [Server Name]
Server URL: [Server Address]

To complete transfer:
1. Press ESC to access the pause menu
2. Click 'Change Password / Leave' button
3. Use the server address above to reconnect
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

## Customization

### Changing the Image

Simply replace `textures/worldgate_transfer.png` with your own image. Some ideas:

- **Portal Themes**: Swirling vortex, stargate, dimensional rift
- **Server Branding**: Your server's custom logo/artwork
- **Thematic**: Match your server's theme (medieval, sci-fi, fantasy)

### Customizing Text

Edit `src/transfer_screen.lua` to modify:

- Font sizes and colors
- Text positioning
- Additional information fields
- Button styles
- Chat message formatting

### Example Customizations

**Change title color to cyan:**
```lua
"label[8,3.5;" .. minetest.colorize("#00FFFF", "SERVER TRANSFER") .. "]",
```

**Add additional info:**
```lua
"label[8,5.5;Transfer initiated by: " .. player_name .. "]",
```

**Modify instructions:**
```lua
"label[8,6.2;Disconnect and reconnect to complete transfer]",
```

## Technical Details

### File Structure

```
worldgate/
├── src/
│   └── transfer_screen.lua    # Transfer UI logic
├── textures/
│   └── worldgate_transfer.png # Background image
└── init.lua                    # Loads transfer_screen module
```

### How It Works

1. Player right-clicks servergate beacon
2. `worldgate.initiate_transfer()` called in `server_api.lua`
3. Database queried for destination server info
4. `worldgate.transfer_screen.show()` displays formspec
5. Formspec uses `worldgate_transfer.png` as background
6. Player sees visual screen + chat instructions

### Formspec Version

Uses formspec version 4 features:
- `background[]` for fullscreen images
- `box[]` for overlay containers
- `style[]` for font customization
- `field[]` for copyable text

### Fallback Behavior

If the image file is missing:
- Screen still displays with black background
- All text and information remains visible
- Chat messages still sent
- No errors or crashes

## Troubleshooting

### Image Not Showing

1. **Check filename**: Must be exactly `worldgate_transfer.png`
2. **Check location**: Must be in `worldgate/textures/` directory
3. **Restart server**: Textures are loaded at startup
4. **Check permissions**: File must be readable by Minetest

### Screen Not Appearing

1. **Check beacon link**: Beacon must be linked to a destination
2. **Check database**: Server info must exist in database
3. **Check logs**: Look for errors in debug.txt
4. **Test connection**: Verify database connectivity

### Text Overlapping or Misaligned

1. **Image size**: Use 16:9 aspect ratio (1920x1080 recommended)
2. **Formspec scaling**: Adjust coordinates in `transfer_screen.lua`
3. **Font sizes**: Reduce font_size values if text is too large

## Best Practices

### Image Selection

- **High Contrast**: Ensure text is readable over the image
- **Center Focus**: Important imagery should be in the center
- **Resolution**: Higher is better, but keep file size reasonable (<5MB)
- **Format**: PNG for transparency, JPG for photos

### User Experience

- **Clear Instructions**: Make sure transfer steps are easy to follow
- **Visual Appeal**: Choose an exciting, immersive image
- **Branding**: Consider adding your server logo or name
- **Consistency**: Match the image style to your server theme

### Performance

- **File Size**: Keep images under 5MB for fast loading
- **Compression**: Use optimized PNG/JPG compression
- **Resolution**: 1920x1080 is sufficient for most displays
- **Testing**: Test on different screen resolutions

## Future Enhancements

Potential improvements:

- Animated textures (frame-based animation)
- Multiple random background images
- Per-server custom images
- Particle effects overlay
- Sound effects on transfer initiation
- Countdown timer before auto-close

## Examples

### Minimal Setup

Just drop in an image:
```bash
cp my_portal_image.png worldgate/textures/worldgate_transfer.png
```

### Custom Theme

Edit transfer_screen.lua and add themed colors:
```lua
-- Sci-fi theme
"box[3,3;10,4;#001133CC]",
"label[8,3.5;" .. minetest.colorize("#00FFFF", "DIMENSIONAL TRANSFER") .. "]",
```

### Server Network

Different images per server:
1. Create multiple textures with server-specific names
2. Modify transfer_screen.lua to select image based on destination
3. Add logic to choose background dynamically

## Support

If you need help:
1. Check README.md for basic setup
2. Review QUICKSTART.md for configuration
3. Check debug.txt for error messages
4. Ensure database connectivity is working
