--~ GCKI = require('common')("GCKI")
GCKI = require('common')
GCKI.entered_file()

-- Icons
local zahnfeechen = settings.startup["GCKI-zahnfeechen_icons"].value
local path = GCKI.modRoot.."/graphics/"
GCKI.car_key_icon = string.format(path.."%s.png", zahnfeechen and "car-key-zf" or "car-key")
GCKI.locked_symbol = string.format(path.."%s.png", zahnfeechen and "locked_symbol-zf" or "locked_symbol")
GCKI.writeDebug("Using %s icon for keys and locked symbol.", {zahnfeechen and "zahnfeechen's" or "default"})


-- Create Prototypes
GCKI.writeDebug("data.lua: Creating prototypes")
require("prototypes.1-prototypes")

-- Patterns and functions for making black-/whitelists of vehicle prototype names
GCKI.writeDebug("data.lua: Loading list of vehicle prototypes")
GCKI_prototypes = require("vehicle_lists")

for f, f_name in pairs({
  "add_blacklist_patterns", "add_whitelist_patterns",
  "remove_blacklist_patterns", "remove_whitelist_patterns",
}) do

  GCKI[f_name] = GCKI_prototypes[f_name]
end


GCKI.writeDebug("data.lua: Initializing black-/whitelist patterns for vehicle prototypes")
GCKI_prototypes.init_black_and_white_list()
GCKI.show("GCKI.patterns", GCKI.patterns)


------------------------------------------------------------------------------------
GCKI.entered_file("leave")
