--
-- Transfer screen display for cross-server transfers
--

worldgate.transfer_screen = {}

-- Show transfer screen to player with server information
function worldgate.transfer_screen.show(player, dest_server_name, dest_server_url, gate_name)
  local player_name = player:get_player_name()

  -- Build formspec with transfer image background
  local formspec = {
    "formspec_version[4]",
    "size[16,10]",
    "bgcolor[#000000FF;true]",
    "background[0,0;16,10;worldgate_transfer.png]",
    "",
    "box[3,3;10,4;#000000CC]",
    "",
    "style[title;font=bold;font_size=32]",
    "label[8,3.5;SERVER TRANSFER]",
    "",
    "style[info;font_size=20]",
    "label[8,4.5;Destination: " .. minetest.formspec_escape(dest_server_name or "Unknown Server") .. "]",
    "",
    "style[url;font=mono;font_size=16]",
    "label[8,5.2;" .. minetest.formspec_escape(dest_server_url or "No URL") .. "]",
    "",
    "style[instructions;font_size=18]",
    "label[8,6.2;To complete transfer, disconnect and connect to:]",
    "",
    "field[4,6.8;8,0.6;connect_cmd;;" .. minetest.formspec_escape(dest_server_url or "") .. "]",
    "",
    "button[6,7.6;4,0.8;close;Close]",
  }

  minetest.show_formspec(player_name, "worldgate:transfer_screen", table.concat(formspec, "\n"))

  -- Also send chat message with connection info
  minetest.chat_send_player(player_name,
    minetest.colorize("#FF6666", "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"))
  minetest.chat_send_player(player_name,
    minetest.colorize("#FFAA00", "◈ SERVER TRANSFER INITIATED ◈"))
  minetest.chat_send_player(player_name, "")
  minetest.chat_send_player(player_name,
    minetest.colorize("#00FF00", "Destination: ") .. (dest_server_name or "Unknown"))
  minetest.chat_send_player(player_name,
    minetest.colorize("#00FF00", "Server URL: ") .. (dest_server_url or "No URL"))
  minetest.chat_send_player(player_name, "")
  minetest.chat_send_player(player_name,
    minetest.colorize("#FFFF00", "To complete transfer:"))
  minetest.chat_send_player(player_name,
    "1. Press ESC to access the pause menu")
  minetest.chat_send_player(player_name,
    "2. Click 'Change Password / Leave' button")
  minetest.chat_send_player(player_name,
    "3. Use the server address above to reconnect")
  minetest.chat_send_player(player_name,
    minetest.colorize("#FF6666", "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"))
end

-- Handle formspec submissions
minetest.register_on_player_receive_fields(function(player, formname, fields)
  if formname ~= "worldgate:transfer_screen" then
    return
  end

  if fields.close or fields.quit then
    minetest.close_formspec(player:get_player_name(), "worldgate:transfer_screen")
    return true
  end
end)
