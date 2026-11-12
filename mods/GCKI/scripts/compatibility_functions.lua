GCKI.entered_file()

local common_mods = {}

------------------------------------------------------------------------------------
------------------------------------------------------------------------------------
--                                SPACE EXPLORATION                               --
------------------------------------------------------------------------------------
------------------------------------------------------------------------------------

------------------------------------------------------------------------------------
--                                 Lost in space?                                 --
------------------------------------------------------------------------------------
local not_space = util.list_to_map({"planet", "moon", "vault"})

common_mods.se_vehicle_is_in_space = function (vehicle)
  GCKI.entered_function({vehicle})

  local in_space

  --~ if global.mod_compatibility.SE and
      --~ -- Vehicle is valid and a prototype we care about!
      --~ GCKI_vehicle.is_vehicle(vehicle) and
      --~ -- Spidertrons will always be active if unlocked, even in outer space!
      --~ GCKI.vehicle_prototypes_map.car[vehicle.name] then
  if mod.mod_compatibility.SE and vehicle.valid and
      -- Spidertrons will always be active if unlocked, even in outer space!
      --~ global.vehicle_prototypes_map.car[vehicle.name] then
      mod.vehicle_prototypes.map.car[vehicle.name] then

    local surface_type = GCKI.remote_call("space-exploration", "get_surface_type",
                                          {surface_index = vehicle.surface.index})

    in_space = surface_type and (not not_space[surface_type])
  end

  GCKI.entered_function({vehicle}, "leave")
  return in_space
end



------------------------------------------------------------------------------------
------------------------------------------------------------------------------------
--                             AAI PROGRAMMABLE VEHICE                            --
------------------------------------------------------------------------------------
------------------------------------------------------------------------------------

------------------------------------------------------------------------------------
--                        What item will place this entity?                       --
------------------------------------------------------------------------------------
common_mods.vehicle_is_placed_by_AAI = function (vehicle)
  GCKI.entered_function({vehicle})

  if not script and script.active_mods("aai-programmable-vehicles") then
    GCKI.entered_function({vehicle}, "leave", "AAI Progammable Vehicles is not active!")
    return
  end

  local patterns = {
    "^(.+)%-_%-ghost",
    "^(.+)%-_%-solid",
  }

  local items, look_for
GCKI.show("patterns", patterns)

  for p, pattern in pairs(patterns) do
GCKI.show(p, pattern)
GCKI.show("vehicle.name", vehicle.name)
    look_for = vehicle.name:match(pattern)
GCKI.show("look_for", look_for)
    --~ items = look_for and game.get_filtered_item_prototypes({
    items = look_for and prototypes.get_item_filtered({
      {filter = "place-result", elem_filters = {
        {filter = "type", type = vehicle.type},
        {filter = "name", name = look_for, mode = "and"}
      }}
    })

    if items and not GCKI.is_custom_table_empty(items) then
GCKI.show("Found items!")
      break
    end
  end

  GCKI.entered_function({vehicle}, "leave")
  return items
end



------------------------------------------------------------------------------------
GCKI.entered_file("leave")
return common_mods
