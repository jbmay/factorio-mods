--~ -- This should now be obsolete, as the bug has been fixed in Factorio 1.1.6!
-- Make sure that GCKI really exists! (If a tutorial from Tips and Tricks is started,
-- the migration will be applied to a mod named "level" and none of our global
-- variables will be defined.)
GCKI = GCKI or require('__gcki-continued__.common')()
GCKI.entered_file()

------------------------------------------------------------------------------------
-- After upgrading to Factorio 1.1, it seems locked vehicles are only set to "not
-- active", but can be mined and are operable. We'd better make sure all these
-- properties are in sync with each other!
------------------------------------------------------------------------------------


storage.UnminableVehicles = script.active_mods["UnminableVehicles"] and
                            settings.global["unminable_vehicles_make_unminable"].value
storage.lockers = storage.lockers or {}
storage.owners = storage.owners or {}
local v, render_object

for index, vehicle in pairs(storage.GCKI_vehicles or {}) do
  v = vehicle.entity
GCKI.writeDebug("%s: %s", {GCKI.argprint(v), vehicle})
  ------------------------------------------------------------------------------------
  -- Remove invalid vehicles from list
  if not (v and v.valid) then
    -- Remove "owner"
    if vehicle.owner and storage.owners and storage.owners[vehicle.owner] then
      storage.owners[vehicle.owner] = nil
GCKI.writeDebug("Removed owner from tables!")
    end

    -- Remove "locker"
    if vehicle.locker and storage.lockers and storage.lockers[vehicle.locker] then
      storage.lockers[vehicle.locker][index] = nil
      if not next(storage.lockers[vehicle.locker]) then
        storage.lockers[vehicle.locker] = nil
      end
      vehicle.locker = nil
GCKI.writeDebug("Removed locker from tables!")
    end

    -- Remove "locked" icons from invalid vehicles!
    GCKI_vehicle.locked_icon(index)

    storage.GCKI_vehicles[index] = nil
GCKI.writeDebug("Removed invalid vehicle %s!", {index})

  ------------------------------------------------------------------------------------
  -- Properly lock vehicles that have a locker
  else
    -- Properly lock vehicles that have a locker
    --~ r = vehicle.lock_icon and rendering.get_object_by_id(vehicle.lock_icon)
    render_object = GCKI.ascertain_rendering(vehicle.lock_icon)
    if vehicle.locker then
      GCKI.writeDebug("Vehicle is locked")
      v.active = false
      v.operable = false
      v.minable = false
      GCKI.writeDebug("Active: %s\tOperable: %s\tMinable: %s",
                      {v.active, v.operable, v.minable})

      -- Restore "locked" icon
      --~ if not (vehicle.lock_icon and rendering.is_valid(vehicle.lock_icon)) then
        --~ GCKI_vehicle.locked_icon(v)
--~ GCKI.writeDebug("Added locked_icon to %s!", {GCKI.argprint(v)})
      --~ end
      --~ if not (r and r.valid) then
      if not (render_object and render_object.valid) then
        GCKI_vehicle.locked_icon(v)
        GCKI.writeDebug("Added locked_icon to %s!", {GCKI.argprint(v)})
      end

    -- Properly unlock vehicles that don't have a locker
    else
      GCKI.writeDebug("Vehicle is unlocked")
      v.active = true
      v.operable = true
      -- If setting from Unminable Vehicles is enabled, no vehicle may be mined!
      v.minable = storage.UnminableVehicles and false or true

      -- Remove "locked" icons from unlocked vehicles!
      --~ if vehicle.lock_icon and rendering.is_valid(vehicle.lock_icon) then
        --~ rendering.destroy(vehicle.lock_icon)
        --~ vehicle.lock_icon = nil
--~ GCKI.writeDebug("Removed lock_icon!")
      --~ end
      --~ if r and r.valid then
        --~ r.destroy()
      if render_object and render_object.valid then
        render_object.destroy()
        vehicle.lock_icon = nil
        GCKI.writeDebug("Removed lock_icon!")
      end
      GCKI.writeDebug("Active: %s\tOperable: %s\tMinable: %s",
      {v.active, v.operable, v.minable})
    end

    -- Update storage.lockers
    if vehicle.locker then
      storage.lockers[vehicle.locker] = storage.lockers[vehicle.locker] or {}
      storage.lockers[vehicle.locker][index] = index
    end

    -- Update storage.owners
    if vehicle.owner then
      -- If owner already has another vehicle registered, remove flag from this vehicle
      if storage.owners[vehicle.owner] and storage.owners[vehicle.owner] ~= index then
        GCKI.writeDebug("%s already owns vehicle %s. Remove owner from %s!", {
          GCKI.argprint(game.players[vehicle.owner]),
          storage.owners[vehicle.owner], index}
        )
        vehicle.owner = nil
      -- Add this vehicle to list of owned vehicles
      else
        storage.owners[vehicle.owner] = index
      end
    end
  end
end


------------------------------------------------------------------------------------
GCKI.entered_file("leave")
