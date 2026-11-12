GCKI.entered_file()

-- Make black-/whitelist of prototypes based on active mods
GCKI.writeDebug("data-final-fixes.lua: Initializing list of GCKI vehicle prototypes")
GCKI.vehicle_prototypes_map = GCKI_prototypes.get_vehicle_prototypes_map()
GCKI.show("GCKI.vehicle_prototypes_map", GCKI.vehicle_prototypes_map)


-- "DMV Directional Movement Vehicles" will create a spider-vehicle for each car
-- prototype and overwrite the place_result of the car item. We must create a new
-- item that will place the original prototype so that we can get the vehicle icon
-- for use in our GUIs (If DMV is added to a running game, car-based entities that
-- already are used in the game would have no icon on the GUI.)
GCKI.writeDebug("data-final-fixes.lua: Recreate items for car prototypes?")
require("prototypes.3-recreate-car-items")

GCKI.writeDebug("data-final-fixes.lua: Adding circuits to recipes producing vehicles")
require("prototypes.3-add-circuits-to-vehicle-recipes")

GCKI.writeDebug("data-final-fixes.lua: Adding filters to selection tool")
require("prototypes.3-add-filters-to-selection-tool")

GCKI.writeDebug("data-final-fixes.lua: Adding technology_to_unlock to shortcut")
require("prototypes.3-add-unlock-tech-to-shortcut")

------------------------------------------------------------------------------------
GCKI.entered_file("leave")
