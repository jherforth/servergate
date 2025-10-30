--
-- Servergate mapgen
--

-- Do not register mapgen if servergate mapgen is disabled
if not servergate.settings.mapgen then
  return
end

minetest.log("info", "Servergate: Mapgen module loaded - full implementation needed")
