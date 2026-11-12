-- Make sure that GCKI really exists! (If a tutorial from Tips and Tricks is started,
-- the migration will be applied to a mod named "level" and none of our global
-- variables will be defined.)
GCKI = GCKI or require('__gcki-continued__.common')()
GCKI.entered_file()

------------------------------------------------------------------------------------
-- Autodrive inserts a passenger in vehicles it controls, if necessary (for opening
-- gates and shooting). Locking a vehicle with the keys from GCKI will eject every-
-- body in it, so each time a vehicle in auto-drive mode was locked, a new character
-- for the autodrive-passenger would appear on the map. This has been fixed now, so
-- we better remove any of these useless characters from the game!
------------------------------------------------------------------------------------

local e_name = "autodrive-passenger"
GCKI.writeDebugNewBlock("Search surfaces for dummy passengers from Autodrive?")
if prototypes.entity[e_name] then
  GCKI.writeDebug("Yes!")
  local look_for = {name = e_name}
  local e_string

  for name, surface in pairs(game.surfaces) do
    GCKI.writeDebugNewBlock("Checking surface %s!", {GCKI.argprint(surface)})
    --~ for index, character in pairs(surface.find_entities_filtered{name = e}) do
    for index, character in pairs(surface.find_entities_filtered(look_for)) do
      --~ local c_name = character.name
      e_string = GCKI.argprint(character)
      character.destroy()
      GCKI.writeDebug("%s:\tRemoved %s", {index, e_string})
    end
    GCKI.writeDebug("Done.")
  end
else
  GCKI.writeDebug("No: entity prototype does not exist!")
end

------------------------------------------------------------------------------------
-- Use the opportunity to remove some unused variables from the global table
for _, var in ipairs({"surface", "position", "carname"}) do
  if storage[var] then
    storage[var] = nil
    GCKI.writeDebug("Removed unused variable \"storage.[%s]\" from saved game.", {var})
  end
end


------------------------------------------------------------------------------------
GCKI.entered_file("leave")
