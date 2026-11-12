-- Make sure that GCKI really exists! (If a tutorial from Tips and Tricks is started,
-- the migration will be applied to a mod named "level" and none of our global
-- variables will be defined.)
GCKI = GCKI or require('__gcki-continued__.common')()
GCKI.entered_file()

------------------------------------------------------------------------------------
-- Store color of all vehicles based on one of our prototypes (including vehicles --
-- without owner/locker)                                                          --
------------------------------------------------------------------------------------

-- Initialize table?
GCKI.writeDebugNewBlock("Initialize storage.vehicles_orig_color?")
if not storage.vehicles_orig_color then
  GCKI.writeDebug("Yes!")
  storage.vehicles_orig_color = {}
else
  GCKI.writeDebug("No: table already exists!")
end
local v_colors = storage.vehicles_orig_color

-- Store color of all vehicles based on one of our prototypes (including vehicles
-- without owner/locker)
local vehicles
for s, surface in pairs(game.surfaces) do
  GCKI.writeDebug("Looking for vehicles on %s", {GCKI.argprint(surface)})

  -- This may also find vehicles based on blacklisted prototypes. We'll remove
  -- these entries in on_configuration_changed!
  vehicles = surface.find_entities_filtered({type = GCKI.vehicle_types})
  for v, vehicle in pairs(vehicles) do
    v_colors[vehicle.unit_number] = v_colors[vehicle.unit_number] or {
      entity = vehicle,
      color = util.table.deepcopy(vehicle.color)
    }
    GCKI.writeDebug("Created storage.vehicles_orig_color[%s] for %s!",
                    {vehicle.unit_number, GCKI.argprint(vehicle)})
  end
end


-- Remove orig_color from data of GCKI-controlled vehicles
GCKI.writeDebugNewBlock("Trying to move vehicle colors to new table!")
for v, v_data in pairs(storage.GCKI_vehicles) do
  GCKI.show(v, v_data)
  -- Copy stored color to new table
  if v_data.orig_color then
    --~ if not util.table.compare(v_data.orig_color, v_colors[v].color) then
    if not GCKI.compare_colors(v_data.orig_color, v_colors[v].color) then
      v_colors[v].color = table.deepcopy(v_data.orig_color)
      GCKI.writeDebug("Transferred storage.GCKI_vehicles[%s].orig_color!", {v})
    end

    v_data.orig_color = nil
    GCKI.writeDebug("Removed storage.GCKI_vehicles[%s].orig_color!", {v})
  end
end

------------------------------------------------------------------------------------
GCKI.entered_file("leave")
