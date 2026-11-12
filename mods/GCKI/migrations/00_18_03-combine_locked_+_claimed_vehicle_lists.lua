-- Make sure that GCKI really exists! (If a tutorial from Tips and Tricks is started,
-- the migration will be applied to a mod named "level" and none of our global
-- variables will be defined.)
GCKI = GCKI or require('__gcki-continued__.common')()
GCKI.entered_file()

------------------------------------------------------------------------------------
-- "AAI Programmable Vehicles", "Vehicle Wagons 2" and possibly other mods replace
-- vehicle entities, so we need to keep our lists updated. Until now, we just stored
-- the vehicle entities, without keeping track of the unit_number. That was enough
-- as long as entities were supposed to be valid, but it's hard or even impossible
-- to identify replaced entities.
-- This script rebuilds the lists, using the unit number as index of vehicle data.
------------------------------------------------------------------------------------

-- Only act if the original lists still exist. These will be removed after migration,
-- once they've been consolidated into a new, restructured list (global.GCKI_vehicles).
if storage.vehicles and storage.locked_vehicles and not storage.GCKI_vehicles then

  -- Get the entity of the player who locked this vehicle
  local function is_locked_vehicle(vehicle)
    local locker = nil

    -- Unlocked vehicle
    if (vehicle.operable and vehicle.active and vehicle.minable) then
      GCKI.writeDebug({"GCKI-messages.vehicle-lock_state", vehicle.name, {"GCKI-states.unlocked"}})
    -- Locked vehicle
    else
      --~ GCKI.writeDebug({"GCKI-messages.vehicle-lock_state", GCKI.loc_name(vehicle), {"GCKI-states.locked"}})
      -- Find the player who locked it
      for player_index, vehicles in pairs(storage.locked_vehicles) do
        for _, vehicle2 in pairs(storage.vehicles) do
          if vehicle == vehicle2 then
            --~ locker = game.players[player_index]
            locker = GCKI.ascertain_player(player_index)
            GCKI.writeDebug("%s has been locked by player %s!",
                            {GCKI.argprint(vehicle), GCKI.argprint(locker)})
            break
          end
        end
        if locker then
          break
        end
      end
    end
    return locker and locker.index
  end


  -- Initialize new list
  storage.GCKI_vehicles = {}

  -- Transfer list of owned vehicles to new list
  for player, vehicle in pairs(storage.vehicles) do
    if vehicle.valid then
      GCKI.writeDebug("Adding %s to list.", {GCKI.argprint(vehicle)})
      storage.GCKI_vehicles[vehicle.unit_number] = {
        ["entity"] = vehicle,
        ["owner"] = player,
        ["locker"] = is_locked_vehicle(vehicle),
      }
    end
  end
  GCKI.writeDebug("Added owned vehicles to new list \"storage.GCKI_vehicles\".")

  -- Transfer list of locked vehicles to new list
  for player, table in pairs(storage.locked_vehicles) do
    for _, vehicle in pairs(table) do
      -- Vehicle may already be in list if it also has been claimed by somebody!
      if vehicle.valid and not storage.GCKI_vehicles[vehicle.unit_number] then
        GCKI.writeDebug("Adding %s to list!", {GCKI.argprint(vehicle)})
        storage.GCKI_vehicles[vehicle.unit_number] = {
          ["entity"] = vehicle,
          ["owner"] = nil,
          ["locker"] = player,
        }
      end
    end
  end
  GCKI.writeDebug("Added locked vehicles to new list \"storage.GCKI_vehicles\".")

  -- Remove original lists
  storage.locked_vehicles = nil
  storage.vehicles = nil
  GCKI.writeDebug("Removed old lists \"storage.locked_vehicles\" and \"storage.vehicles\": %s", {storage})
end


------------------------------------------------------------------------------------
GCKI.entered_file("leave")
