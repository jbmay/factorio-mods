GCKI.entered_file()

local common_vehicle = {}

------------------------------------------------------------------------------------
------------------------------------------------------------------------------------
--                                 LOCAL DEFINITIONS                              --
------------------------------------------------------------------------------------
------------------------------------------------------------------------------------


------------------------------------------------------------------------------------
--       Lock a vehicle. It should always be safe to use the default values!      --
------------------------------------------------------------------------------------
common_vehicle.lock_vehicle = function(vehicle)
  GCKI.entered_function({vehicle})

  GCKI.writeDebugNewBlock("Do we have a valid vehicle?")
  if vehicle and vehicle.valid then
    GCKI.writeDebug("Yes: turning off properties!")
    -- Default locked status
    for p, property in pairs({"active", "operable", "minable"}) do
GCKI.show("vehicle["..property.."]", vehicle[property])
      vehicle[property] = false
GCKI.show("New value", vehicle[property])
    end
  end

  GCKI.entered_function({vehicle}, "leave")
end

------------------------------------------------------------------------------------
--  Unlock a vehicle. We can't just toggle all properties because adjustments may --
--  be necessary for other mods!                                                  --
------------------------------------------------------------------------------------
common_vehicle.unlock_vehicle = function(vehicle)
  GCKI.entered_function({vehicle})

  ------------------------------------------------------------------------------------
  -- Set properties to default unlocked status!
  if vehicle and vehicle.valid then
    for p, property in pairs({"active", "operable", "minable"}) do
      vehicle[property] = true
    end
    GCKI.writeDebug("Unlocked %s!", {GCKI.argprint(vehicle)})
  end


  ------------------------------------------------------------------------------------
  -- Adjustments for other mods

  if mod.mod_compatibility then
    -- "Space Exploration" will deactive all vehicles if they are in outer space!
    if GCKI_mods.se_vehicle_is_in_space(vehicle) then

      vehicle.active      = false
      GCKI.writeDebug("Made %s inactive (Reason: Compatibility with \"Space Exploration\")",
                      {GCKI.argprint(vehicle)})
    end

    -- "Unminable Vehicles"
    -- If "unminable_vehicles_make_unminable" is enabled, vehicles are never minable!
    if mod.mod_compatibility.UnminableVehicles then
      vehicle.minable     = false
      GCKI.writeDebug("Made %s inactive (Reason: Compatibility with \"Unminable Vehicles\")",
                      {GCKI.argprint(vehicle)})
    end
  end

  GCKI.entered_function({vehicle}, "leave")
end


------------------------------------------------------------------------------------
--                CHECK WHETHER THIS IS A VEHICLE WE WANT TO HANDLE               --
--                             (Returns boolean value)                            --
------------------------------------------------------------------------------------
common_vehicle.is_vehicle = function(vehicle)
  GCKI.entered_function({vehicle})

  local ret = (type(vehicle) == "userdata" and
                vehicle.object_name == "LuaEntity" and vehicle.valid and
                mod.vehicle_prototypes.map[vehicle.type] and
                mod.vehicle_prototypes.map[vehicle.type][vehicle.name]) or false

  GCKI.show("It's a valid vehicle", ret)
  return ret
end


------------------------------------------------------------------------------------
--    CHECK WHETHER THIS VEHICLE IS BASED ON A PROTOTYPE SUPPORTED BY AUTODRIVE   --
--                             (Returns boolean value)                            --
------------------------------------------------------------------------------------
common_vehicle.is_Autodrive_vehicle = function(vehicle)
  GCKI.entered_function({vehicle})

  GCKI.assert(vehicle, {"LuaEntity", "nil"}, "entity or nil")
  local ret = vehicle and vehicle.valid and mod.AD_prototypes and
                                            mod.AD_prototypes[vehicle.name]

  GCKI.show("Vehicle is supported by Autodrive", ret or false)
  return ret
end


------------------------------------------------------------------------------------
--                             GET VEHICLE UNIT_NUMBER                            --
--                          (Returns unit_number or nil)                          --
------------------------------------------------------------------------------------
common_vehicle.get_vehicle_id = function(vehicle_or_id)
  GCKI.entered_function({vehicle_or_id})

local ret = (type(vehicle_or_id) == "number" and vehicle_or_id) or
            (common_vehicle.is_vehicle(vehicle_or_id) and vehicle_or_id.unit_number)
GCKI.show("ID", ret)
  return ret
end


------------------------------------------------------------------------------------
--                     CHOOSE THE OCCUPANT WITH WEAPONS CONTROL                   --
-- If there are two players inside a vehicle, Autodrive hands over gun control to --
-- the driver, without checking which player actually is in charge of the weapons.--
-- vehicle: vehicle.entity or vehicle.unit_number
------------------------------------------------------------------------------------
-- vehicle: entity; occupants: table (optional)
common_vehicle.set_shooter = function(vehicle, occupants)
  GCKI.entered_function({vehicle, occupants})

  if common_vehicle.is_vehicle(vehicle) then
    occupants = occupants or common_vehicle.get_occupants(vehicle)

    if occupants then
      -- If the vehicle has a passenger and this passenger is no dummy inserted by
      -- other mods, he will be in charge of the weapons
      vehicle.driver_is_gunner = not (occupants.passenger and
                                  occupants.passenger.is_player and
                                  occupants.passenger.entity and
                                  occupants.passenger.entity.valid)
    -- If nobody is in the vehicle, make sure the Autodrive passenger can shoot!
    -- (Passenger will only be there when it's needed for shooting or opening gates)
    else
      vehicle.driver_is_gunner = false
    end

GCKI.show("vehicle.driver_is_gunner", vehicle.driver_is_gunner)
  end

  GCKI.entered_function({vehicle}, "leave")
end


------------------------------------------------------------------------------------
--       CHECK WHETHER VEHICLE IS CONTROLLED BY MODS LIKE AUTODRIVE OR AAI        --
--                        (Returns array of dummies or nil)                       --
------------------------------------------------------------------------------------
common_vehicle.is_dummy_inside = function(vehicle, occupants) -- vehicle: entity
  GCKI.entered_function({vehicle, occupants})

  -- Initialize return value
  local dummy = {}

  if common_vehicle.is_vehicle(vehicle) then
    occupants = occupants or common_vehicle.get_occupants(vehicle)

    for role, occupant in pairs(occupants or {}) do
GCKI.show("role", role)
      dummy[role] = (not occupant.is_player) and occupant.entity or nil
    end
  end
  GCKI.show("Is dummy inside", next(dummy) and dummy or false)
  GCKI.entered_function({vehicle}, "leave")

  return next(dummy) and dummy
end


------------------------------------------------------------------------------------
--                        CHECK WHETHER VEHICLE HAS AN OWNER                      --
--                     (Returns the player who owns it, or nil)                   --
------------------------------------------------------------------------------------
common_vehicle.get_owner = function(vehicle) -- vehicle: entity or entity.unit_nuber
  GCKI.entered_function({vehicle})

  local v_id = common_vehicle.get_vehicle_id(vehicle)
  local v = v_id and mod.GCKI_vehicles[v_id]
  local owner = v and v.owner and game.get_player(v.owner)

  GCKI.show("Owner", owner and GCKI.argprint(owner) or "nil")
  return owner
end


------------------------------------------------------------------------------------
--                          CHECK WHETHER VEHICLE IS LOCKED                       --
--              (Returns entity of the player who locked it, or nil)              --
------------------------------------------------------------------------------------
common_vehicle.get_locker = function(vehicle)
  GCKI.entered_function({vehicle})

  local v_id = common_vehicle.get_vehicle_id(vehicle)
  local v = v_id and mod.GCKI_vehicles[v_id]
  local locker = v and v.locker and game.get_player(v.locker)

  GCKI.show("Locker", locker and GCKI.argprint(locker) or "nil")

  return locker
end


------------------------------------------------------------------------------------
--                          CHECK WHETHER VEHICLE IS LOCKED                       --
--              (Returns entity of the player who locked it, or nil)              --
------------------------------------------------------------------------------------
common_vehicle.get_vehicle_data = function(vehicle)
  GCKI.entered_function({vehicle})

  local id = common_vehicle.get_vehicle_id(vehicle)

  local data = {}

  if id then
    local v = mod.GCKI_vehicles[id]

    -- Owner/Locker
    if v then
      data.owner = v.owner
      data.locker = v.locker

      --~ data.Autodrive_owner = v.Autodrive_owner
      data.Autodrive_owner = AUTODRIVE and v.Autodrive_owner
    end

    -- Customized vehicle name
    local named = mod.named_vehicles.by_id[id]
    data.custom_name = named and named.name
    data.named_by = named and named.named_by

    -- Original color
    local orig_color = mod.vehicles_orig_color[id]
    data.orig_color = (orig_color and orig_color.color) or
                      --~ (v.entity and v.entity.valid and v.entity.color)
                      (vehicle and vehicle.valid and vehicle.color)
  end

GCKI.show("Return data", data)
  GCKI.entered_function("leave")
  return next(data) and data or nil
end


------------------------------------------------------------------------------------
--                          TOGGLE LOCKED-ICON ON VEHICLE                         --
------------------------------------------------------------------------------------
common_vehicle.locked_icon = function(vehicle, flags)
  GCKI.entered_function({vehicle})

  local removed_prototype = flags and flags.removed_prototype
  local v_id = (removed_prototype and vehicle and
                                      vehicle.valid and vehicle.unit_number) or
                common_vehicle.get_vehicle_id(vehicle)

  local v = v_id and mod.GCKI_vehicles[v_id]
GCKI.show("v", v)
  if v and v.entity and v.entity.valid then
    -- Set icon
    --~ if v.locker and not (v.lock_icon and rendering.is_valid(v.lock_icon)) then
    if v.locker and not (v.lock_icon and v.lock_icon.valid) then
GCKI.writeDebug("Adding locked icon")
      v.lock_icon = rendering.draw_sprite{
        sprite = "GCKI_locked-icon",
        target = v.entity,
        target_offset = {0, -0.5},
        surface = v.entity.surface,
        render_layer = "entity-info-icon-above",
        only_in_alt_mode = true,
      }
    -- Remove icon
    --~ elseif v.lock_icon and rendering.is_valid(v.lock_icon) and not v.locker then
      --~ rendering.destroy(v.lock_icon)
      --~ v.lock_icon = nil
    elseif v.lock_icon and v.lock_icon.valid and not v.locker then
      v.lock_icon.destroy()
      v.lock_icon = nil
GCKI.writeDebug("Removed locked icon")
    end
  end

  GCKI.entered_function({vehicle}, "leave")
end


------------------------------------------------------------------------------------
--                 CHECK WHETHER VEHICLE MUST BE REMOVED FROM LIST                --
--          We only need to store vehicles that have locker and/or owner!         --
--                             (Returns boolean value)                            --
------------------------------------------------------------------------------------
common_vehicle.must_remove_vehicle = function(vehicle) -- vehicle.unit_number or vehicle entity
  GCKI.entered_function({vehicle})

  local v_id = common_vehicle.get_vehicle_id(vehicle)
  local v = v_id and mod.GCKI_vehicles[v_id]
GCKI.show("v_id", GCKI.argprint(v_id))
GCKI.show("v", GCKI.argprint(v))

  -- Ignore vehicles that are not in our list!
  if not v then
    GCKI.entered_function({}, "leave", "No data stored for "..GCKI.argprint(vehicle).."!")
    return false
  end

  local ret

GCKI.show("v", v)
  -- If vehicle is valid, we must remove it if it has neither owner nor locker
  if v.entity and v.entity.valid then
    ret = not (v.owner or v.locker)
  -- Vehicle doesn't exist anymore but the table may still have entries for owner/locker
  else
    ret = true
  end

  GCKI.show("Must remove vehicle", ret ~= nil and ret or "nil")
  GCKI.entered_function({vehicle}, "leave")
  return ret
end


------------------------------------------------------------------------------------
--                      CLEAN UP TABLES WHEN VEHICLE IS REMOVED                   --
------------------------------------------------------------------------------------
common_vehicle.remove_vehicle = function(vehicle_or_id, flags)
  GCKI.entered_function({vehicle_or_id, flags})

  GCKI.assert(vehicle_or_id, {"LuaEntity", "number"}, "entity or unit_number")
  GCKI.assert(flags, {"table", "nil"}, "nil or table of flags")

  local removed_prototype               = flags and flags.removed_prototype
  local keep_color                      = flags and flags.keep_color
  local keep_custom_name                = flags and flags.keep_custom_name
  local keep_gui                        = flags and flags.keep_gui
  local keep_gui_visible                = flags and flags.keep_gui_visible
  --~ local dont_tell_vehicle_wagons        = flags and flags.dont_tell_vehicle_wagons
  local dont_tell_CustomColor           = flags and flags.dont_tell_CustomColor
  local remove_camera                   = flags and flags.remove_camera
  local skip_event_check                = flags and flags.skip_event_check
  local dying                           = flags and flags.dying

  --~ local entity, pass_on, pass_on_flags, locker_or_owner, p_data
  local pass_on, pass_on_flags, locker_or_owner, p_data


  local vehicle, v, v_id
  if removed_prototype or type(vehicle_or_id) ~= "number" then
    vehicle = vehicle_or_id
    v_id = vehicle and vehicle.valid and vehicle.unit_number
  else
    v_id = vehicle_or_id
  end
  v = v_id and mod.GCKI_vehicles[v_id]
GCKI.show("v", v)
GCKI.show("v_id", v_id)
  vehicle = v and v.entity
GCKI.show("vehicle", GCKI.argprint(vehicle))

  -- We have vehicle data. If we have been called by remove_vehicle_locker or by
  -- remove_vehicle_owner, the vehicle could have neither owner nor locker.
  if v then
    GCKI.writeDebug("%s is on our list!", {GCKI.argprint(v.entity)})
    locker_or_owner = v.locker or v.owner
GCKI.show("locker_or_owner", locker_or_owner)
    if locker_or_owner then
      if vehicle and vehicle.valid then
        pass_on = vehicle
      else
        pass_on = v_id
      end
GCKI.show("vehicle", GCKI.argprint(vehicle))
      p_data = mod.player_data and mod.player_data[locker_or_owner]
GCKI.show("locker_or_owner", locker_or_owner)
GCKI.show("p_data", p_data)


      -- Mark vehicle for removal from minimap. (Keep the camera to show the rendering!)
GCKI.show("p_data.show_on_map", p_data and p_data.show_on_map)
GCKI.show("v_id", v_id)
      if p_data and p_data.show_on_map and p_data.show_on_map.id == v_id then
        p_data.show_on_map = nil
        GCKI.writeDebug("Removed mod.player_data[%s].show_on_map!", {locker_or_owner})
      end


      -- Mark vehicle for removal from camera. (We'll only do that if player force was
      -- reset or unresearched the unlock techs, because we usually want the camera to
      -- focus on the rendered message if the vehicle has been destroyed or stolen.)
  GCKI.show("p_data.show_on_camera", p_data and p_data.show_on_camera)
  GCKI.show("v_id", v_id)
      if remove_camera and
          p_data and p_data.show_on_camera and p_data.show_on_camera.id == v_id then
        p_data.show_on_camera = nil
        GCKI.writeDebug("Removed mod.player_data[%s].show_on_camera!",
                        {locker_or_owner})
      end

      pass_on_flags = {
        -- Don't update color and GUIs twice if vehicle has both locker and owner!
        keep_color = true,
        keep_gui = true,
        -- Don't call back remove_vehicles from remove_vehicle_locker!
        keep_vehicle = true,
        --~ -- Don't call back "Vehicle Wagons" if they told us to remove the vehicle!
        --~ dont_tell_vehicle_wagons = dont_tell_vehicle_wagons,
        -- We'll call "Custom Color" once, after we have removed owner and locker!
        dont_tell_CustomColor = dont_tell_CustomColor,
        -- Bypass check for valid prototype when we clean up vehicle lists
        removed_prototype = removed_prototype,
        -- Don't call back from remove_vehicle_owner or remove_vehicle_locker!
        removing_vehicle = true,
        -- Skip check whether events are still needed
        skip_event_check = skip_event_check,
      }

      -- Remove locker
      if v.locker then
        GCKI.writeDebug("Removing locker: "..tostring(v.locker))
        common_vehicle.remove_vehicle_locker(pass_on, v.locker, pass_on_flags)
      end

      -- Remove owner
      if v.owner then
        GCKI.writeDebug("Removing owner: "..tostring(v.owner))
        common_vehicle.remove_vehicle_owner(pass_on, v.owner, pass_on_flags)
      end
    end


    -- Ask "CustomColor" to remove vehicle from ignore list?
    GCKI.writeDebugNewBlock("Tell CustomColor to remove %s from ignore list?",
                            {GCKI.argprint(vehicle)})
    if dont_tell_CustomColor then
      GCKI.writeDebug("No: forbidden by flag!")
    elseif vehicle and vehicle.valid and vehicle.type == "car" then
      GCKI.writeDebug("Yes!")
      GCKI.remote_call("CustomColor", "unblock_vehicle", vehicle, script.mod_name)
    else
      GCKI.writeDebug("No: %s is not a car!", {GCKI.argprint(vehicle)})
    end

    -- Recolor vehicle?
    GCKI.writeDebugNewBlock("Recolor %s?", {GCKI.argprint(vehicle)})
    if keep_color then
      GCKI.writeDebug("No: forbidden by flag 'keep_color'!")
    elseif dying then
      GCKI.writeDebug("No: forbidden by flag 'dying'!")
    elseif not (vehicle and vehicle.valid) then
      GCKI.writeDebug("No: not a valid vehicle!")
    else
      GCKI.writeDebug("Yes!")
      common_vehicle.color_vehicle(vehicle)
    end

    --~ -- If the vehicle has died, remove original color
    --~ GCKI.writeDebugNewBlock("Remove vehicle from mod.vehicles_orig_color?")
    --~ if dying then
      --~ if mod.vehicles_orig_color and mod.vehicles_orig_color[v_id] then
        --~ GCKI.writeDebug("Yes: vehicle is dying or has been destroyed!")
        --~ mod.vehicles_orig_color[v_id] = nil
      --~ else
        --~ GCKI.writeDebug("No: no data found for vehicle!")
      --~ end
    --~ else
      --~ GCKI.writeDebug("No!")
    --~ end

    -- Remove vehicle from table
    mod.GCKI_vehicles[v_id] = nil
    GCKI.writeDebugNewBlock("Removed mod.GCKI_vehicles[%s]!", {v_id})

  -- Not a GCKI-controlled vehicle
  else
    GCKI.writeDebug("%s is not a valid vehicle!", GCKI.argprint(vehicle))
  end


  -- Remove custom name
  if keep_custom_name then
    GCKI.writeDebug("Skipping check for custom name of %s!",
                    {GCKI.argprint(vehicle)})
  else
    v = mod.named_vehicles and mod.named_vehicles.by_id and
                                mod.named_vehicles.by_id[v_id]
GCKI.show("v", v)
    if v then
      vehicle = v.entity
      GCKI.writeDebug("%s has a custom name!", {GCKI.argprint(vehicle)})

      common_vehicle.remove_vehicle_name(v_id, script.mod_name,
                                          {keep_gui = keep_gui})
    end
  end


  -- Update GUIs!
GCKI.show("flags", flags)
GCKI.show("keep_gui", keep_gui)
  if keep_gui then
    GCKI.writeDebug("Won't update GUI yet!")
  elseif vehicle and vehicle.valid then
    GCKI.writeDebug("Must update GUIs for %s!", {GCKI.argprint(vehicle)})
    GCKI_gui.update_guis(vehicle, {keep_gui_visible = keep_gui_visible})
  end

  GCKI.entered_function("leave")
end



------------------------------------------------------------------------------------
-- Vehicle Wagons will move loaded vehicles to a hidden surface. We move data for --
-- GCKI-controlled vehiceles to a separate table and remove these vehicles from   --
-- the GUIs.                                                                      --
------------------------------------------------------------------------------------
common_vehicle.vehicle_wagons_load = function(vehicle)
  GCKI.entered_function({vehicle})
  local id = GCKI_vehicle.get_vehicle_id(vehicle)

  if id then
    local v = mod.GCKI_vehicles[id]
GCKI.show("vehicle", vehicle.name)
--~ GCKI.show("modname", modname)

    --~ local player = v and v.owner and game.players[v.owner]
    local player = GCKI.ascertain_player(v and v.owner)
GCKI.show("v", v)
GCKI.show("player", GCKI.argprint(player))

    -- Inform owner of vehicle that vehicle has disappeared
    --~ if player and v and v.entity and v.entity.valid then
    if player and v.entity and v.entity.valid then
      GCKI.output(player, {
        "GCKI-messages.owner-vehicle_unavailable",
        GCKI.loc_name(v.entity)
      })
      GCKI.hint(player, {
        "GCKI-messages.hints-wait_for_vehicle",
        GCKI.loc_name(v.entity)
      })
    end

GCKI.show("mod.player_data["..tostring(v and (v.owner or v.locker)).."]",
          mod.player_data[v and (v.owner or v.locker)])

    -- Remove vehicle
    --~ GCKI_vehicle.remove_vehicle(vehicle, {
      --~ -- If the function was called by Vehicle Wagons, there's no need to tell it
      --~ -- that we just removed the vehicle.
      --~ dont_tell_vehicle_wagons = (modname == "VehicleWagon2"),
      --~ -- If the vehicle has a custom name, we want to preserve it until the vehicle
      --~ -- is restored or removed for good (e.g., the vehicle wagon carrying it died.)
      --~ keep_custom_name = true,
      --~ -- It makes no sense to recolor a vehicle that's about to be destroyed!
      --~ keep_color = true,
      --~ -- -- Mods are supposed to call this before destroying a vehicle. We'll catch the
      --~ -- -- script_raised_destroy event and remove the vehicle from GUIs when it fires.
      --~ -- keep_gui = true,
    --~ })

    -- Copy data of GCKI-controlled vehicles
    GCKI.writeDebugNewBlock("Do we have vehicle data?")
    if v then
      GCKI.writeDebug("Yes: Copying data!")
      mod.on_vehicle_wagon = mod.on_vehicle_wagon or {}
      mod.on_vehicle_wagon[id] = table.deepcopy(v)
      --~ local v_data = mod.on_vehicle_wagon[id]

      --~ -- Add original color to data
      --~ v_data.orig_color = mod.vehicles_orig_color and
                          --~ mod.vehicles_orig_color[id] and
                          --~ mod.vehicles_orig_color[id].color

    else
      GCKI.writeDebug("No!")
    end


    -- Remove vehicle
    GCKI_vehicle.remove_vehicle(vehicle, {
      --~ -- If the function was called by Vehicle Wagons, there's no need to tell it
      --~ -- that we just removed the vehicle.
      --~ dont_tell_vehicle_wagons = true,
      -- If the vehicle has a custom name, we want to preserve it until the vehicle
      -- is restored or removed for good (e.g., the vehicle wagon carrying it died.)
      keep_custom_name = true,
      -- The vehicle is moved to another surface, which doesn't affect color!
      keep_color = true,
      -- We must hide camera view of this vehicle!
      remove_camera = true,
      -- -- Mods are supposed to call this before destroying a vehicle. We'll catch the
      -- -- script_raised_destroy event and remove the vehicle from GUIs when it fires.
      -- keep_gui = true,

      -- No data cleanup required, the vehicle is still alive on another surface!
      dont_tell_CustomColor = true
    })

    -- If vehicle has a custom name, mark it as reserved
    local named = mod.named_vehicles.by_id[id]
    if named then
      named.not_available = true
    end
  end

  GCKI.entered_function("leave")
end




------------------------------------------------------------------------------------
-- Check whether the player can give this custom name to a vehicle. (Fails if the --
-- vehicle was already named by another player, or if the name is already used.)  --
------------------------------------------------------------------------------------
common_vehicle.can_rename_vehicle = function(args, mod_name)
  GCKI.entered_function({args, mod_name})

  GCKI.assert(mod_name, {"string", "nil"}, "mod name")

  local vehicle, player, new_name = args.vehicle, args.player, args.new_name
  GCKI.assert(vehicle, {"number", "LuaEntity"}, "unit_number or entity")
  GCKI.assert(new_name, {"string", "nil"}, "custom name")

  player = GCKI.ascertain_player(player)
  if not (player and player.valid) then
    GCKI.arg_err(player, "player specification")
  end


  --~ -- Ask Autodrive if we can rename the vehicle?
  --~ if AUTODRIVE and mod_name ~= AUTODRIVE_NAME then
    --~ GCKI.writeDebug("Is it OK for Autodrive that we name the vehicle?")

    --~ local args = {vehicle = vehicle, player = player, new_name = new_name or ""}
    --~ if not GCKI.remote_call(AUTODRIVE_NAME, "can_rename_vehicle",
                              --~ args, script.mod_name) then
        --~ GCKI.entered_function({}, "leave", "Autodrive says no")
        --~ return
    --~ else
        --~ GCKI.writeDebug("Autodrive allows us to proceed!")
    --~ end

  --~ -- Autodrive isn't active, or this function was called by Autodrive
  --~ else
    --~ local msg = AUTODRIVE and "Skipped callback to AUTODRIVE." or
                              --~ "AUTODRIVE is not active!"
    --~ GCKI.writeDebug("%s", {msg})
  --~ end



  local p = player.index

  local ret
  local id = (type(vehicle) == "number" and vehicle) or
             (vehicle.valid and vehicle.unit_number)

  mod.named_vehicles = mod.named_vehicles or { by_id = {}, by_name = {}}

  local by_id = mod.named_vehicles.by_id
  local by_name = mod.named_vehicles.by_name
  local v = id and mod.GCKI_vehicles[id]

  local autodrive_owner = v and v.Autodrive_owner
GCKI.show("autodrive_owner", autodrive_owner)
GCKI.show("v", v)

  local locked_or_owned = v and (v.locker or v.owner) and true or false
  local player_is_owner = (locked_or_owned and v.owner == p or autodrive_owner == p)
  local player_is_locker = (locked_or_owned and v.locker == p)
  local named_by = (by_id[id] and by_id[id].named_by) or
                    (new_name and by_name[new_name] and
                                  by_id[by_name[new_name]] and
                                  by_id[by_name[new_name]].named_by)
  local named_by_player = (named_by == p)
  local same_vehicle = (by_name[new_name] == id)
GCKI.show("by_id", by_id)
GCKI.show("by_name", by_name)
GCKI.show("locked_or_owned", locked_or_owned)
GCKI.show("player_is_owner", player_is_owner)
GCKI.show("player_is_locker", player_is_locker)
GCKI.show("named_by", named_by)
GCKI.show("named_by_player", named_by_player)
GCKI.show("same_vehicle", same_vehicle)

  -- Name is already in use, it can't be used for another vehicle.
  if new_name and by_name[new_name] then
    ret = (same_vehicle and player_is_owner or player_is_locker or named_by_player)
    GCKI.writeDebug("Name is already in use. Player %s rename it.",
                  {ret and "can" or "can't"})

  -- Vehicle already has a name: Only the player who named it can rename it
  elseif id and by_id[id] then
    ret = named_by_player
    GCKI.writeDebug("Vehicle already has a name. Player %s rename it.",
                  {ret and "can" or "can't"})
  -- Unnamed vehicle controlled by GCKI
  elseif v then
    -- If not owned/locked in GCKI, vehicle can be renamed by Autodrive owner, or
    -- by any player if there is no Autodrive owner
    ret = not (locked_or_owned) or
          player_is_owner or player_is_locker or named_by_player
    GCKI.writeDebug("Player %s rename Autodrive vehicle.",
                  {ret and "can" or "can't"})
  -- Unnamed vehicles not controlled by our mod can be renamed by any player!
  else
    ret = true
    GCKI.writeDebug("Not an Autodrive/GCKI vehicle -- player can rename it!")
  end

  GCKI.entered_function("leave")
  return ret
end



------------------------------------------------------------------------------------
--                          ADD CUSTOM NAME TO A VEHICLE                          --
------------------------------------------------------------------------------------
common_vehicle.add_vehicle_name_rendering = function(player, vehicle, custom_name)
  GCKI.entered_function({player, vehicle, custom_name})

  GCKI.assert(custom_name, "string", "vehicle name")
  local named_by = GCKI.ascertain_player(player)

  local v_id = common_vehicle.get_vehicle_id(vehicle)
  local ret
GCKI.show("v_id", v_id)

  -- Create rendering of name for vehicle
  if v_id and named_by and named_by.valid then
    ret = rendering.draw_text({
      text = custom_name,
      surface = vehicle.surface,
      --~ target = vehicle,
      --~ target_offset = {x = 0, y = .5},
      target = {
        entity = vehicle,
        offset = {x = 0, y = .5},
      },
      color = mod.player_data[named_by.index].settings.render_color,
      alignment = "center",
      scale_with_zoom = false,
    })
    GCKI.writeDebug("Created text rendering %s (target: %s, text: %s)!",
                    {ret, GCKI.argprint(vehicle), GCKI.enquote(custom_name)})
  end

  GCKI.entered_function("leave")
  return ret
end


------------------------------------------------------------------------------------
--                  ADD OR CHANGE THE CUSTOM NAME OF THE VEHICLE                  --
------------------------------------------------------------------------------------
common_vehicle.edit_vehicle_name = function(args, mod_name)
  GCKI.entered_function({args, mod_name})

  GCKI.assert(mod_name, {"string", "nil"}, "mod name")

  local player, vehicle = args.player, args.vehicle
  --~ local new_name, render_text_id = args.new_name, args.render_text_id
  local new_name = args.new_name
  local new_render_text = GCKI.ascertain_rendering(args.render_text_id)
  if not (new_render_text and new_render_text.valid) then
    new_render_text = nil
  end
GCKI.show("new_render_text", new_render_text)

  -- If a vehicle is replaced with another entity (e.g. by AAI), we skip checking
  -- whether we may rename it! We also won't ask other mods for permission.
  local restore = args.restore

  -- When cleaning up vehicle lists in on_configuration_changed, we want to wait
  -- until we are done with checking all lists and then rebuild all GUIs of all
  -- connected players.
  local keep_gui = args.keep_gui

  player = GCKI.ascertain_player(player)
  GCKI.assert(new_name, "string", "custom vehicle name")

  local named_vehicles = mod.named_vehicles
GCKI.show("player and player.valid", player and player.valid)
--~ GCKI.show("common_vehicle.is_vehicle(vehicle)", common_vehicle.is_vehicle(vehicle))
GCKI.show("vehicle", GCKI.argprint(vehicle))

  if player and player.valid and vehicle and vehicle.valid then
    GCKI.writeDebug("%s is a valid vehicle!", GCKI.argprint(vehicle))

    --~ -- Ask Autodrive if we can rename the vehicle
    --~ if AUTODRIVE and mod_name ~= AUTODRIVE_NAME and not restore then
      --~ GCKI.writeDebug("Is it OK for Autodrive that we name the vehicle?")

      --~ local args = {vehicle = vehicle, player = player, new_name = new_name}
      --~ local can_rename = GCKI.remote_call(AUTODRIVE_NAME, "can_rename_vehicle",
                                          --~ args, script.mod_name)
      --~ if not can_rename then
        --~ GCKI.entered_function({}, "leave", "\"Autodrive\" said no!")
        --~ return
      --~ else
        --~ GCKI.writeDebug("Autodrive allows us to proceed!")
      --~ end

    --~ -- Autodrive isn't active, or this function was called by Autodrive
    --~ else
      --~ local msg = (restore and "Transferring custom name to other vehicle!") or
                  --~ (AUTODRIVE and "Skipped callback to AUTODRIVE.") or
                  --~ "AUTODRIVE is not active!"
      --~ GCKI.writeDebug("%s", {msg})
    --~ end

    --~ -- Autodrive didn't object: proceed!
    local p_data = mod.player_data[player.index]
    local v_id = vehicle.unit_number
    local old_id = named_vehicles.by_name[new_name]
    --~ local new_rendering
GCKI.show("p_data", p_data)
GCKI.show("v_id", v_id)
GCKI.show("old_id", old_id)

    local by_id = named_vehicles.by_id[v_id]

GCKI.show("not named_vehicles.by_id["..v_id.."]", not named_vehicles.by_id[v_id])
    -- Add name to list of named vehicles
    if not by_id then
GCKI.writeDebug("Must add a new name!")
      local named_by = (old_id and named_vehicles.by_id[old_id]) and
                        named_vehicles.by_id[old_id].named_by or
                        player.index
GCKI.show("named_by", named_by)

      -- Add data for new entity
      named_vehicles.by_id[v_id] = {
        entity = vehicle,
        name = new_name,
        named_by = named_by,
        render_text_id = new_render_text or
                          common_vehicle.add_vehicle_name_rendering(player, vehicle, new_name)
      }
      --~ by_id = named_vehicles.by_id[v_id]

GCKI.show("named_vehicles.by_id["..v_id.."]", named_vehicles.by_id[v_id])
--~ GCKI.show("named_vehicles.by_id["..v_id.."]", by_id)
      -- Remove data stored for the old entity
      if old_id and old_id ~= v_id and named_vehicles.by_id[old_id] then
        --~ local render_text = named_vehicles.by_id[old_id].render_text_id
        --~ if render_text and rendering.is_valid(render_text) then
          --~ rendering.destroy(render_text)
        --~ end
        --~ local r_id = named_vehicles.by_id[old_id].render_text_id
        --~ local r = r_id and rendering.get_object_by_id(r_id)
        local r_id = named_vehicles.by_id[old_id].render_text_id
        local render_object = GCKI.ascertain_rendering(r_id)
        if render_object and render_object.valid then
          render_object.destroy()
        end
        named_vehicles.by_id[old_id] = nil
        GCKI.writeDebug("Removed mod.named_vehicles.by_id[%s]!", {old_id})
      end

      -- Update pointer from name to ID
      named_vehicles.by_name[new_name] = v_id
      GCKI.writeDebug("Added custom name \"%s\" to %s.", {new_name, GCKI.argprint(vehicle)})

    -- Change name in list of named vehicles
    else
      GCKI.writeDebugNewBlock("Vehicle already has a name -- change it?")
      local old_name = by_id.name
GCKI.show("by_id", by_id)
GCKI.show("old_name", old_name)


      --~ local render_object = GCKI.ascertain_rendering(by_id.render_text_id)
      local render_object = GCKI.ascertain_rendering(by_id.render_text_id)
GCKI.show("render_object", render_object)
GCKI.show("new_render_text", new_render_text)
GCKI.show("render_object ~= new_render_text", render_object ~= new_render_text)
      if new_render_text and new_render_text.valid then
        if render_object and render_object.valid and
            render_object ~= new_render_text then
          GCKI.writeDebug("Destroying obsolete name rendering!")
          render_object.destroy()
          --~ render_object = new_render_text
        end
        GCKI.writeDebug("Updating by_id.render_text_id!")
        by_id.render_text_id = new_render_text

        GCKI.writeDebug("Updating var 'render_object'!")
        render_object = new_render_text
      end
GCKI.show("render_object", render_object)

      -- Custom name didn't change
      if new_name == old_name then
        GCKI.writeDebug("No: old name and new name are the same!")

      -- Store new text
      else
        mod.named_vehicles.by_id[v_id].name = new_name

        -- If we already have a valid rendering, we can change its text!
        --~ if by_id.render_text_id and rendering.is_valid(by_id.render_text_id) then
          --~ rendering.set_text(by_id.render_text_id, new_name)
          --~ GCKI.writeDebug("Replaced text of existing rendering!")
        --~ local r = by_id.render_text_id and
                  --~ rendering.get_object_by_id(by_id.render_text_id)
        --~ local render_object = GCKI.ascertain_rendering(by_id.render_text_id)
        if render_object and render_object.valid then
          render_object.text = new_name
          GCKI.writeDebug("Replaced text of existing rendering!")

        -- If the previous rendering has become invalid, create a new one!
        else
          by_id.render_text_id = common_vehicle.add_vehicle_name_rendering(player, vehicle, new_name)
          render_object = by_id.render_text_id
          GCKI.writeDebug("Created new rendering %s of custom name \"%s\" for %s.",
                          {by_id.render_text_id, new_name, GCKI.argprint(vehicle)})
        end

        -- Update mod.named_vehicles.by_name
        named_vehicles.by_name[old_name] = nil
        named_vehicles.by_name[new_name] = v_id
        GCKI.writeDebug("Changed custom name of %s from \"%s\" to \"%s\"!",
                        {GCKI.argprint(vehicle), old_name, new_name})
      end

      -- Is the render_object still valid?
      GCKI.writeDebugNewBlock("Is the name rendering still valid?")
      if render_object and render_object.valid then
        GCKI.writeDebug("Yes! Update rendering text?")
        if render_object.text == new_name then
          GCKI.writeDebug("No: already shows correct name!")
        else
          GCKI.writeDebug("Yes: changing name from %s to %s!",
                          {render_object.text, new_name})
          render_object.text = new_name
        end

      -- If the previous rendering has become invalid, create a new one!
      else
        GCKI.writeDebug("No: recreating rendering!")
        by_id.render_text_id = common_vehicle.add_vehicle_name_rendering(player, vehicle, new_name)
      end

    end

    -- Inform Autodrive that vehicle has been renamed
    GCKI.writeDebug("Inform Autodrive?")
    if AUTODRIVE and mod_name ~= AUTODRIVE_NAME and not restore then
      GCKI.writeDebug("Trying to inform Autodrive about new name.")
      local pass_on = {
        vehicle = vehicle,
        player = player,
        new_name = new_name,
        render_text_id = named_vehicles.by_id[v_id].render_text_id,
      }
      GCKI.remote_call(AUTODRIVE_NAME, "renamed_vehicle", pass_on, script.mod_name)
    else
      GCKI.writeDebug("%s",
                    {AUTODRIVE and "Skipping callback to Autodrive!" or
                                    "Autodrive is not active!"})
    end


    -- Use custom name as entity_label if this is a "spider-vehicle" prototype
    if vehicle.type == "spider-vehicle" then
      -- Changing the label will raise on_entity_renamed, so we skip this if the
      -- vehicle already has the new label!
      GCKI.writeDebugNewBlock("Change label of %s?", {GCKI.argprint(vehicle)})
      if vehicle.entity_label ~= new_name then
        new_name = (new_name ~= "") and new_name or nil
        GCKI.writeDebug("Yes! New label: %s", {GCKI.argprint(new_name)})
        --~ vehicle.entity_label = (new_name ~= "") and new_name or nil
        vehicle.entity_label = new_name
      else
        GCKI.writeDebug("No, %s already has the correct label!",
                      {GCKI.argprint(vehicle)})
      end
    end


    -- Update GUIs?
    if not keep_gui then
      local update_guis = mod.GCKI_vehicles[v_id]
      if update_guis then
        GCKI.writeDebug("%s %s %s.", {
          GCKI.argprint(vehicle),
          update_guis.owner and "belongs to" or "has been locked by",
          GCKI.argprint(game.get_player(update_guis.owner or update_guis.locker)),
        })
      else
        for p, player_data in pairs(mod.player_data) do
          if player_data.selected_vehicles and
              player_data.selected_vehicles[v_id] then
            update_guis = true
            GCKI.writeDebug("%s has been selected by %s.",
                            --~ {GCKI.argprint(vehicle), GCKI.argprint(game.players[p])})
                            {GCKI.argprint(vehicle), GCKI.argprint(game.get_player(p))})
            break
          end
        end
      end
  GCKI.show("update_guis", update_guis)
      if update_guis then
        GCKI.writeDebug("Must update name of %s in GUIs!", {GCKI.argprint(vehicle)})
        GCKI_gui.update_guis(vehicle)
      end
    end
  end

  GCKI.entered_function("leave")
end


------------------------------------------------------------------------------------
--                               REMOVE VEHICLE NAME                              --
------------------------------------------------------------------------------------
common_vehicle.remove_vehicle_name = function(id, mod_name, flags)
  GCKI.entered_function({id, mod_name, flags})

  GCKI.assert(id, {"number", "string"})
  GCKI.assert(mod_name, {"string", "table", "nil"})
  GCKI.assert(flags, {"table", "nil"})
GCKI.show("id", id)
GCKI.show("mod_name", mod_name)
GCKI.show("flags", flags)

  if type(mod_name) == "table" and not flags then
    flags, mod_name = mod_name, flags
  end
GCKI.show("mod_name after check", mod_name)
GCKI.show("flags after check", flags)

  local keep_gui = flags and flags.keep_gui
  --~ local removed_prototype = flags and flags.removed_prototype

  local name, by_id, vehicle
  local named = mod.named_vehicles


  -- Function was called with unit_number
  if type(id) == "number" then
    name = named.by_id[id] and named.by_id[id].name

  -- Function was called with name
  else
    name = id
    id = name and named.by_name[name]
  end
  by_id = id and named.by_id[id]

  GCKI.show("name", name)
  GCKI.show("id", id)
  GCKI.show("by_id", by_id)

  local is_spider_vehicle

  -- Remove name from mod.named_vehicles
  if by_id then

    -- Tell Autodrive to remove the vehicle name?
    if AUTODRIVE and mod_name ~= AUTODRIVE_NAME then
      GCKI.writeDebug("Telling Autodrive to remove custom name of vehicle %s!", {id})
      GCKI.remote_call(AUTODRIVE_NAME, "remove_custom_name", id, script.mod_name)
    else
      local msg = AUTODRIVE and "Skipped callback to AUTODRIVE." or
                                "AUTODRIVE is not active!"
      GCKI.writeDebug("%s", {msg})
    end

    vehicle = by_id.entity
    is_spider_vehicle = vehicle and vehicle.valid and
                                    vehicle.type == "spider-vehicle"
GCKI.show("is_spider_vehicle", is_spider_vehicle)

    -- Remove rendering
    --~ local render_text = by_id.render_text_id
    --~ local render_text = by_id.render_text_id and
                        --~ rendering.get_object_by_id(by_id.render_text_id)
    local render_object = GCKI.ascertain_rendering(by_id.render_text_id)
GCKI.show("render_object", render_object)
    --~ if render_text and rendering.is_valid(render_text) then
      --~ rendering.destroy(render_text)
    if render_object and render_object.valid then
      render_object.destroy()
      GCKI.writeDebug("Removed rendered name of %s!",
                      {(vehicle or name) and GCKI.argprint(vehicle or name) or
                       "unknown vehicle"})
    end

    -- Remove vehicle from ID list
    mod.named_vehicles.by_id[id] = nil
    GCKI.writeDebug("Removed mod.named_vehicles.by_id[%s]!", {id})
  end


  -- Remove vehicle from name list
  if name and named.by_name[name] then
    named.by_name[name] = nil
    GCKI.writeDebug("Removed mod.named_vehicles.by_name[%s]!", {GCKI.argprint(name)})
  end


  -- Won't update GUIs if we're running this from on_configuration_changed
  if keep_gui then
    GCKI.writeDebug("Keeping vehicle %s on GUIs for now!", {id})

  -- Update GUIs if the vehicle is on GUIs of any player
  else
    -- Vehicle has been claimed or locked
    local is_on_gui = mod.GCKI_vehicles[id] and mod.GCKI_vehicles[id].entity
  GCKI.show("is_on_gui", GCKI.argprint(is_on_gui))
    -- Also update GUIs if a player selected this vehicle.
    if not is_on_gui then
      for p, p_data in pairs(mod.player_data) do
        is_on_gui = p_data.selected_vehicles and p_data.selected_vehicles[id]
        if is_on_gui then
          break
        end
      end
    end
    GCKI.show("is_on_gui", GCKI.argprint(is_on_gui))
    GCKI.show("vehicle", GCKI.argprint(vehicle))

    if is_on_gui then
      GCKI.writeDebug("Updating GUIs!")
      GCKI_gui.update_guis(is_on_gui)
    end
  end

  -- If vehicle was based on a spider-vehicle prototype, reset vehicle.entity_label!
GCKI.show("is_spider_vehicle", is_spider_vehicle)
  if is_spider_vehicle and vehicle.entity_label then
    GCKI.writeDebug("Removing custom name %s!", {GCKI.argprint(name)})
    vehicle.entity_label = nil
  end

  GCKI.entered_function("leave")
end


------------------------------------------------------------------------------------
--                            MARK VEHICLE AS UNLOCKED                            --
-- Required arguments: vehicle (unit_number/entity), player (index, name, entity) --
-- Optional arguments: keep (Skip must_remove_vehicle() if it is NOT nil/false!)  --
------------------------------------------------------------------------------------
common_vehicle.remove_vehicle_locker = function(vehicle_or_id, player_id, flags)
  GCKI.entered_function({vehicle_or_id, player_id, flags})


  -- We need an entity, so make sure "vehicle" either refers to a vehicle from our
  -- list or is a valid vehicle prototype!
  GCKI.assert(vehicle_or_id, {"LuaEntity", "number"}, "vehicle or unit_number")

  -- The player may have been removed, so we must get the index of the locker!
  GCKI.assert(player_id, "number", "index of locker")

  GCKI.assert(flags, {"table", "nil"})

  local player = game.get_player(player_id)
  local removed_prototype = flags and flags.removed_prototype
  local v_id, vehicle

  if type(vehicle_or_id) == "number" then
    v_id = vehicle_or_id

  else
    vehicle = (removed_prototype or common_vehicle.is_vehicle(vehicle_or_id)) and
                vehicle_or_id
GCKI.show("vehicle", GCKI.argprint(vehicle))
    v_id = vehicle and vehicle.valid and vehicle.unit_number
  end
GCKI.show("vehicle", GCKI.argprint(vehicle))
GCKI.show("v_id", v_id)


  -- Only proceed if we have IDs of both vehicle and player!
  if v_id and player_id then
    local keep_vehicle          = flags and flags.keep_vehicle
    local keep_color            = flags and flags.keep_color
    local keep_gui              = flags and flags.keep_gui
    local skip_event_check      = flags and flags.skip_event_check
    --~ local dont_tell_CustomColor = flags and flags.dont_tell_CustomColor
    local removing_vehicle      = flags and flags.removing_vehicle

    local v = v_id and mod.GCKI_vehicles[v_id]

    if v and v.locker and v.locker == player_id then

      -- Actually unlock the  vehicle (We must do this before informing
      -- "Autodrive", as it's looking for vehicle.active == true!)
GCKI.writeDebug("Must unlock vehicle!")
      common_vehicle.unlock_vehicle(v.entity)

      -- Notify "Autodrive" that vehicle has no locker
      if AUTODRIVE and common_vehicle.is_Autodrive_vehicle(v.entity) then
        GCKI.writeDebug("Telling Autodrive that %s has been locked!",
                        {GCKI.argprint(v.entity)})
        GCKI.remote_call(AUTODRIVE_NAME, "set_GCKI_locker", v_id, nil)
      else
        GCKI.writeDebug("Skipping call to Autodrive: %s!",
          {AUTODRIVE and GCKI.argprint(v.entity).. "is not supported" or
                          "not active"})
      end

      --~ -- Ask "CustomColor" to remove vehicle from ignore list?
--~ GCKI.show("v.owner", v.owner)
      --~ GCKI.writeDebugNewBlock("Tell CustomColor to remove %s from ignore list?",
                              --~ {GCKI.argprint(v.entity)})
      --~ if dont_tell_CustomColor or v.owner then
        --~ GCKI.writeDebug("No: %s!",
                        --~ {v.owner and "still has an owner" or "forbidden by flag"})
      --~ else
        --~ GCKI.writeDebug("Yes!")
        --~ remote.call("CustomColor", "unblock_vehicle", v.entity, script.mod_name)
      --~ end

      -- Remove vehicle from list of vehicle locked by locker
      if mod.lockers[player_id] then
        mod.lockers[player_id][v_id] = nil
GCKI.writeDebug("Removed mod.lockers[%s][%s]!", {player_id, v_id})
      end

      -- Remove locker from vehicle data
      v.locker = nil
GCKI.writeDebug("Removed locker from vehicle data!")



      -- Remove "locked" icon
GCKI.writeDebug("Must remove locked icon of %s!", {GCKI.argprint(v.entity)})
      common_vehicle.locked_icon(v.entity, {removed_prototype = removed_prototype})

      -- Remove vehicle from player's list of owned/locked vehicles unless it still
      -- has an owner
      local p_data = mod.player_data and mod.player_data[player_id]
      if p_data and p_data.locked_or_owned and not v.owner then
        GCKI.writeDebug("Removing vehicle from list of vehicles owned/locked by %s",
                        {GCKI.argprint(player)})
        p_data.locked_or_owned[v_id] = nil
        if not next(p_data.locked_or_owned) then
          p_data.locked_or_owned = nil
        end
      end

      -- Remove unlocked vehicle from list if nobody owns it. Skip this when the
      -- function has been called by remove_vehicle ("keep_vehicle" will be true)!
      --~ if (not keep_vehicle) and common_vehicle.must_remove_vehicle(v.entity) then
--~ GCKI.writeDebug("Must remove vehicle!")
        --~ common_vehicle.remove_vehicle(v_id, {
          --~ keep_custom_name = true,
          --~ skip_event_check = skip_event_check
        --~ })
      --~ end
      GCKI.writeDebugNewBlock("Call remove_vehicle?")
      if keep_vehicle or not common_vehicle.must_remove_vehicle(v.entity) then
        GCKI.writeDebug("No: %s!",
                        {keep_vehicle and "ordered by flag" or "still has owner"})
      else
        GCKI.writeDebug("Yes!")
        common_vehicle.remove_vehicle(v_id, {
          keep_custom_name = true,
          keep_gui = not keep_gui,
          skip_event_check = skip_event_check,
        })
      end
GCKI.writeDebug("Returned from remove_vehicle!")

      -- Update GUIs!
      if keep_gui then
        GCKI.writeDebug("Won't update GUI yet!")
      else
        GCKI.writeDebug("Must update GUI!")
        GCKI_gui.update_guis(v.entity)
      end
    end

  else
    GCKI.writeDebug("Nothing to do! (Vehicle: %s\tPlayer: %s)",
                    {v_id, GCKI.argprint(player_id)})
  end

  GCKI.entered_function("leave")
end


------------------------------------------------------------------------------------
--                        MARK VEHICLE AS LOCKED BY PLAYER                        --
--    Each player may only own one vehicle at any time, but may lock his vehicle  --
--    before exchanging it, and may thus, in effect, own more than one vehicle.   --
------------------------------------------------------------------------------------
common_vehicle.add_vehicle_locker = function(vehicle, player, flags)
  -- vehicle:           unit_number (for GCKI-controlled vehicles) or entity
  -- player:            index or name or entity
  GCKI.entered_function({vehicle, player, flags})

  -- We need an entity, so make sure "vehicle" either refers to a vehicle from our
  -- list or is a valid vehicle prototype!
  vehicle = (mod.GCKI_vehicles[vehicle] and mod.GCKI_vehicles[vehicle].entity) or
            (common_vehicle.is_vehicle(vehicle) and vehicle)
  if not (vehicle and vehicle.valid) then
    GCKI.entered_function({}, "leave",
                              GCKI.argprint(vehicle).." is not a valid vehicle")
    return
  end
  local v_id = vehicle.unit_number


  player = GCKI.ascertain_player(player)
  if not (player and player.valid) then
    GCKI.entered_function({}, "leave",
                              GCKI.argprint(player).." is not a valid player")
    return
  end
  local player_id = player.index
  local p_data = mod.player_data[player_id]
GCKI.show("p_data", p_data)

GCKI.writeDebug("Have vehicle and player!")

  GCKI.assert(flags, {"table", "nil"})
  local keep_gui                  = flags and flags.keep_gui
  local ignore_Autodrive          = flags and flags.ignore_Autodrive
  local dont_tell_CustomColor     = flags and flags.dont_tell_CustomColor
  local keep_orig_color           = flags and flags.keep_orig_color
  local keep_owner_on_gui         = flags and flags.keep_owner_on_gui



  local v = mod.GCKI_vehicles[v_id]
GCKI.show("v", v)

  -- Vehicle is already in list -- add "locker"
  if v then
    v.locker = player_id
    GCKI.writeDebug("Added locker to mod.GCKI_vehicles[%s]!", {v_id})

  -- Add new vehicle!
  else
    -- If we add a new vehicle, it may already have an owner in Autodrive!
    local AD_owner
    GCKI.writeDebugNewBlock("Ask Autodrive for owner of %s?",
                            {GCKI.argprint(vehicle)})
    if AUTODRIVE and common_vehicle.is_Autodrive_vehicle(vehicle) then
      GCKI.writeDebug("Yes!")
      AD_owner = GCKI.remote_call(AUTODRIVE_NAME, "get_vehicle_owner", v_id)
    else
      GCKI.writeDebug("No: %s!",
                      {AUTODRIVE and "prototype not supported by Autodrive" or
                                      "Autodrive is not active"})
    end
GCKI.show("AD_owner", GCKI.argprint(AD_owner))

    -- Register vehicle with mod.GCKI_vehicles
    mod.GCKI_vehicles[v_id] = {
      entity      = vehicle,
      locker      = player_id,
      Autodrive_owner = AD_owner,
    }
    GCKI.writeDebug("Added new vehicle to mod.GCKI_vehicles!")
  end

    -- Store vehicle in list of vehicles owned/locked by player
GCKI.writeDebug("Adding new vehicle to p_data.locked_or_owned!")
    p_data.locked_or_owned = p_data.locked_or_owned or {}
    p_data.locked_or_owned[v_id] = vehicle
GCKI.show("p_data.locked_or_owned", p_data.locked_or_owned)

    -- Add vehicle to GUI of player's owned/locked vehicles
GCKI.writeDebug("Adding new vehicle to GUI for vehicles owned/locked by player!")
    local passon_flags = {skip_event_check = true}
    GCKI_gui_player_vehicles.add_to_gui(player, vehicle, passon_flags)

  --~ end

  -- Add vehicle to list of vehicles locked by the player
  mod.lockers[player_id] = mod.lockers[player_id] or {}
  mod.lockers[player_id][v_id] = v_id
  GCKI.writeDebug("Added mod.lockers[%s][%s]!", {player_id, v_id})

  -- Actually lock the vehicle!
  GCKI.writeDebug("Locking vehicle!")
  common_vehicle.lock_vehicle(vehicle)

  -- Set "locked" icon
  GCKI.writeDebug("Setting locked icon!")
  common_vehicle.locked_icon(vehicle)

  -- Notify "Autodrive" that vehicle has been locked
  --~ if AUTODRIVE and common_vehicle.is_Autodrive_vehicle(vehicle) then
    --~ GCKI.writeDebug("Telling Autodrive that %s has been locked!",
                    --~ {GCKI.argprint(vehicle)})
    --~ remote.call(AUTODRIVE_NAME, "set_GCKI_locker", v_id, player_id)
  --~ else
    --~ GCKI.writeDebug("Skipping call to Autodrive: %s is not supported!",
                    --~ {GCKI.argprint(vehicle)})
  --~ end

  GCKI.writeDebugNewBlock("Tell Autodrive that %s has been locked?",
                          {GCKI.argprint(vehicle)})
  if ignore_Autodrive or not AUTODRIVE then
    GCKI.writeDebug("No: %s!",
                    {AUTODRIVE and "forbidden by flag" or
                                    "Autodrive is not active"})
  elseif common_vehicle.is_Autodrive_vehicle(vehicle) then
    GCKI.writeDebug("Yes!")
    remote.call(AUTODRIVE_NAME, "set_GCKI_locker", v_id, player_id)
  else
    GCKI.writeDebug("Skipping call to Autodrive: %s is not supported!",
                    {GCKI.argprint(vehicle)})
  end


  GCKI.writeDebugNewBlock("Ask CustomColor to ignore %s?",
                          {GCKI.argprint(vehicle)})
  if dont_tell_CustomColor or vehicle.type ~= "car" then
    GCKI.writeDebug("No: %s!", {
      dont_tell_CustomColor and "forbidden by flag" or
                                GCKI.argprint(vehicle).." is not a car"
    })
  else
    GCKI.writeDebug("Yes!")
    GCKI.remote_call("CustomColor", "block_vehicle", vehicle, script.mod_name)
  end


  -- Update GUIs!
  if not keep_gui then
    GCKI.writeDebug("Must rebuild GUI!")
    --~ local passon_flags = {skip_event_check = true}
    GCKI_gui.update_guis(vehicle)
  end

  GCKI.entered_function({{vehicle, player}}, "leave")
end


------------------------------------------------------------------------------------
--                            MARK VEHICLE AS UNOWNED                             --
-- Required arguments: vehicle (unit_number/entity), player (index, name, entity) --
-- Optional arguments: flags   (table of {flag = boolean})                        --
--      Flag names should be self-explanatory.
------------------------------------------------------------------------------------
common_vehicle.remove_vehicle_owner = function(vehicle_or_id, player_or_id, flags)
  GCKI.entered_function({vehicle_or_id, player_or_id, flags})

  local player = GCKI.ascertain_player(player_or_id)
  local player_id = player and player.valid and player.index

  GCKI.assert(flags, {"table", "nil"}, "nil or table of flags")
  local removed_prototype = flags and flags.removed_prototype

  GCKI.assert(vehicle_or_id, {"LuaEntity", "number"}, "vehicle or unit_number")

  local v_id
  if removed_prototype then
    GCKI.writeDebug("Removing owner because prototype is no longer valid!")
    local t = type(vehicle_or_id)
    if t == "number" then
      v_id = vehicle_or_id
    elseif t == "table" and vehicle_or_id.valid then
      v_id = vehicle_or_id.unit_number
    end
  else
    v_id = common_vehicle.get_vehicle_id(vehicle_or_id)
  end
GCKI.show("vehicle_or_id", GCKI.argprint(vehicle_or_id))
GCKI.show("v_id", v_id)
GCKI.show("player", GCKI.argprint(player))
GCKI.show("player_id", player_id)

  -- Only proceed if we have IDs of both vehicle and player!
  if v_id and player_id then
GCKI.writeDebug("Have player and vehicle!")

    -- Get flags
    GCKI.writeDebug("Got flags: %s", {(flags and next(flags)) and flags or "no"})
    local keep_vehicle                  = flags and flags.keep_vehicle
    local keep_color                    = flags and flags.keep_color
    local keep_gui                      = flags and flags.keep_gui
    local keep_gui_visible              = flags and flags.keep_gui_visible
    --~ local dont_tell_vehicle_wagons      = flags and flags.dont_tell_vehicle_wagons
    --~ local dont_tell_CustomColor         = flags and flags.dont_tell_CustomColor
    local skip_event_check              = flags and flags.skip_event_check

    local v = v_id and mod.GCKI_vehicles[v_id]
GCKI.show("v", v)
GCKI.show("player_id", player_id)
GCKI.show("player_id == v.owner", v and player_id == v.owner)

    if v and player_id == v.owner then
GCKI.writeDebug("Player is owner!")
      -- Notify "Autodrive" that vehicle has no owner
      GCKI.writeDebugNewBlock("Tell Autodrive that %s no longer has an owner?",
                              {GCKI.argprint(v.entity)})
      if AUTODRIVE and common_vehicle.is_Autodrive_vehicle(v.entity) then
        GCKI.writeDebug("Yes!")
        GCKI.remote_call(AUTODRIVE_NAME, "set_GCKI_owner", v_id, nil)
      else
        GCKI.writeDebug("No: %s!",
          {AUTODRIVE and GCKI.argprint(v.entity).." is not supported" or
                          "Autodrive is not active"})
      end

      -- Mod doesn't care any longer as vehicles are kept on a secret surface!
      --~ -- Notify "Vehicle Wagons" that vehicle has no owner
      --~ GCKI.writeDebug("Tell VehicleWagon2 that %s has been released?",
                      --~ {GCKI.argprint(v.entity)})
      --~ if dont_tell_vehicle_wagons then
        --~ GCKI.writeDebug("No: forbidden by flag!")
      --~ else
        --~ GCKI.writeDebug("Yes!")
        --~ GCKI.remote_call("VehicleWagon2", "release_owned_by_player", player_id)
      --~ end

      --~ -- Ask "CustomColor" to remove vehicle from ignore list?
--~ GCKI.show("v.locker", v.locker)
      --~ GCKI.writeDebugNewBlock("Tell CustomColor to remove %s from ignore list?",
                              --~ {GCKI.argprint(v.entity)})
      --~ if dont_tell_CustomColor or v.locker then
        --~ GCKI.writeDebug("No: %s!",
                        --~ {v.locker and "is still locked" or "forbidden by flag"})
      --~ else
        --~ GCKI.writeDebug("Yes!")
        --~ remote.call("CustomColor", "unblock_vehicle", v.entity, script.mod_name)
      --~ end


      -- If vehicle is locked, keep it in the list of vehicles owned/locked by the
      -- player, and skip recoloring!
      if v.locker then
        GCKI.writeDebug("Vehicle is locked: keeping it on list!")
        if not keep_color then
          keep_color = true
          GCKI.show("Updated flag keep_color", keep_color)
        end

      -- Remove vehicle from player's list of owned/locked vehicles
      else
        GCKI.writeDebug("Vehicle has no locker!")
        local locked_or_owned = mod.player_data and
                                mod.player_data[player_id] and
                                mod.player_data[player_id].locked_or_owned
        if locked_or_owned and locked_or_owned[v_id] then
          locked_or_owned[v_id] = nil
          GCKI.writeDebug("Removed mod.player_data[%s].locked_or_owned[%s]",
                          {player_id, v_id})
          if not next(locked_or_owned) then
            mod.player_data[player_id].locked_or_owned = nil
            GCKI.writeDebug("Removed mod.player_data[%s].locked_or_owned!",
                            {player_id})
          end
        end
      end

      -- Remove player from list of owners
      GCKI.writeDebug("Removing player %s from mod.owners", {player_id})
      mod.owners[player_id] = nil

      -- Remove owner from vehicle data
      GCKI.writeDebug("Removing player %s from vehicle data", {v.owner})
      v.owner = nil
GCKI.show("v", v)

      ------------------------------------------------------------------------------
      -- Recolor vehicle if nobody has locked it. Skip this when called from a
      -- function that will act on both owner and locker!
      if keep_color then
        GCKI.writeDebug("Keeping color!")
      else
        GCKI.writeDebug("Must recolor %s!", {GCKI.argprint(v.entity)})
        common_vehicle.color_vehicle(v.entity)
      end

      -- Remove vehicle from list of owned/locked vehicles if nobody has locked it.
      -- Skip this when called by remove_vehicle ("keep_vehicle" will be true)!
      GCKI.writeDebugNewBlock("Call remove_vehicle?")
      if keep_vehicle or not common_vehicle.must_remove_vehicle(v.entity) then
        GCKI.writeDebug("No: %s!",
                        {keep_vehicle and "ordered by flag" or "still has owner"})
      else
        GCKI.writeDebug("Yes!")
        common_vehicle.remove_vehicle(v_id, {
          keep_custom_name = true,
          keep_color = not keep_color,
          keep_gui = not keep_gui,
          keep_gui_visible = keep_gui_visible,
          skip_event_check = skip_event_check,
        })
      end
    end

    -- Update GUIs! If keep_gui_visible is set, we won't hide the GUI for vehicles
    -- owned/locked by a player when the last vehicle is removed. (This is important
    -- when the player owns an unlocked vehicle and claims a new one. When the last
    -- vehicle has been removed and the new vehicle is added, the GUI will remain
    -- invisible.)
    if keep_gui then
      GCKI.writeDebug("Won't update GUI yet!")
    elseif v and v.entity then
      GCKI.writeDebug("Must update GUI!")
      -- This will update the vehicle info on the GUIs of all connected players. We
      -- delay the check whether GUI events are still needed until all GUIs have
      -- been updated!
      local pass_on_flags = {
        keep_gui_visible = keep_gui_visible,
        --~ skip_event_check = true,
      }
      GCKI_gui.update_guis(v.entity, pass_on_flags)

      -- Do we still need GUI events?
      GCKI.writeDebug("Checking whether we need GUI events!")
      GCKI_events.helper.need_gui_events()
    end

  else
    GCKI.writeDebug("Nothing to do! (Vehicle: %s\tPlayer: %s)",
                    {GCKI.argprint(v_id), GCKI.argprint(player_id)})
  end

  GCKI.entered_function({}, "leave")
end


------------------------------------------------------------------------------------
--                        MARK VEHICLE AS OWNED BY PLAYER                         --
--                Each player may only own one vehicle at any time!               --
------------------------------------------------------------------------------------
common_vehicle.add_vehicle_owner = function(vehicle, player, flags)
  -- vehicle:           unit_number (for GCKI-controlled vehicles) or entity
  -- player:            index or name or LuaPlayer
  -- flags:             table of Booleans, indexed by flag name
  GCKI.entered_function({vehicle, player, flags})

  -- We need an entity, so make sure "vehicle" either refers to a vehicle from our
  -- list or is a valid vehicle prototype!
  vehicle = (mod.GCKI_vehicles[vehicle] and vehicle.entity) or
            (common_vehicle.is_vehicle(vehicle) and vehicle)
  if not (vehicle and vehicle.valid) then
    GCKI.entered_function({}, "leave",
                              GCKI.argprint(vehicle).." is not a valid vehicle!")
    return
  end
GCKI.show("vehicle after getting the entity", GCKI.argprint(vehicle))
  local v_id = vehicle.unit_number

  player = GCKI.ascertain_player(player)
  if not (player and player.valid) then
    GCKI.entered_function({}, "leave",
                              GCKI.argprint(player).." is not a valid player!")
    return
  end
  local player_id = player.index
  local p_data = mod.player_data[player_id]

  GCKI.writeDebug("Have player and vehicle!")

  -- Flags are used to skip things. This is useful if several changes are applied to
  -- the vehicle in succession, e.g. if a vehicle is replaced/cloned)
  GCKI.assert(flags, {"table", "nil"})
  local keep_color                = flags and flags.keep_color
  local keep_gui                  = flags and flags.keep_gui
  local ignore_Autodrive          = flags and flags.ignore_Autodrive
  local dont_tell_CustomColor     = flags and flags.dont_tell_CustomColor
  local keep_orig_color           = flags and flags.keep_orig_color
  local keep_owner_on_gui         = flags and flags.keep_owner_on_gui

  local skip

  local v = mod.GCKI_vehicles[v_id]
  local locker = v and common_vehicle.get_locker(v.entity)
GCKI.show("locker", GCKI.argprint(locker))

  -- Player can only own a locked vehicle if he also locked it!
  if locker and locker.index ~= player_id then
    skip = true
    GCKI.writeDebug("%s has been locked by somebody else (player %s)!",
                    {GCKI.argprint(vehicle), locker.index})

  -- Vehicle is already in list -- add "owner"
  elseif v then
GCKI.writeDebug("Restoring owner of locked and abandoned vehicle!")
    v.owner = player_id

  -- Add new vehicle!
  else
    GCKI.writeDebugNewBlock("Adding new vehicle.")

    -- If we add a new vehicle, it may already have an owner in Autodrive!
    local AD_owner
    GCKI.writeDebugNewBlock("Ask Autodrive for owner of %s?",
                            {GCKI.argprint(vehicle)})
    if AUTODRIVE and common_vehicle.is_Autodrive_vehicle(vehicle) then
      GCKI.writeDebug("Yes!")
      AD_owner = GCKI.remote_call(AUTODRIVE_NAME, "get_vehicle_owner", v_id)
    else
      GCKI.writeDebug("No: %s!",
                      {AUTODRIVE and "prototype not supported by Autodrive" or
                                      "Autodrive is not active"})
    end
GCKI.show("AD_owner", GCKI.argprint(AD_owner))

    GCKI.writeDebugNewBlock("Can we store the original color of %s?",
                            {GCKI.argprint(vehicle)})
    if keep_orig_color then
      GCKI.writeDebug("No: forbidden by flag!")
    elseif not common_vehicle.can_store_orig_color(vehicle, AD_owner) then
      GCKI.writeDebug("No: can't store original color!")
    else
      GCKI.writeDebug("Yes: storing original color!")
      local pass_on_flags = {ignore_Autodrive = ignore_Autodrive, }
      common_vehicle.store_orig_color(vehicle, pass_on_flags)
    end

    -- Register vehicle in mod.GCKI_vehicles
    GCKI.writeDebugNewBlock("Adding new vehicle to mod.GCKI_vehicles!")
    mod.GCKI_vehicles[v_id] = {
      entity          = vehicle,
      owner           = player_id,
      Autodrive_owner = AD_owner,
    }
GCKI.show("mod.GCKI_vehicles["..v_id.."]", mod.GCKI_vehicles[v_id])
  end

  -- Only proceed if we've actually set a new owner!
  if skip then
    GCKI.entered_function({}, "leave", "no owner has been added")
    return
  end

  -- Remove owner from previously owned vehicle
  local last_owned = mod.owners[player_id]
  if last_owned then
GCKI.writeDebug("Mark previously owned vehicle as unowned!")
    local pass_on_flags = {
      keep_gui_visible  = true,
      keep_owner_on_gui = keep_owner_on_gui,
    }
    -- If the old vehicle is the only vehicle on the GUI, and if it already is
    -- unlocked, we must remove it from the list but we want to keep the GUI as the
    -- new vehicle will be added a bit later.
--~ GCKI.show("p_data.locked_or_owned", p_data.locked_or_owned)
--~ GCKI.show("table_size(p_data.locked_or_owned)",
      --~ p_data.locked_or_owned and table_size(p_data.locked_or_owned))
--~ GCKI.show("last_owned", last_owned)
--~ GCKI.show("p_data.locked_or_owned["..last_owned.."]",
      --~ p_data.locked_or_owned and p_data.locked_or_owned[last_owned])
    --~ if p_data.locked_or_owned and
        --~ table_size(p_data.locked_or_owned) == 1 and
        --~ p_data.locked_or_owned[last_owned] then

      --~ pass_on_flags = {keep_gui_visible = true}
      --~ GCKI.writeDebug("%s is the last vehicle on the GUI, but we'll keep the GUI visible!",
                      --~ {last_owned and global.GCKI_vehicles[last_owned] and
                        --~ GCKI.argprint(global.GCKI_vehicles[last_owned].entity)})
    --~ end
    common_vehicle.remove_vehicle_owner(last_owned, player_id, pass_on_flags)
  end

  -- Add vehicle to list of owned vehicles
  mod.owners[player_id] = v_id
GCKI.writeDebug("Stored player as owner of new vehicle!")

  -- Store vehicle in list of vehicles owned/locked by player
GCKI.writeDebug("Adding new vehicle to p_data.locked_or_owned!")
  p_data.locked_or_owned = p_data.locked_or_owned or {}
  p_data.locked_or_owned[v_id] = vehicle
GCKI.show("p_data.locked_or_owned", p_data.locked_or_owned)

  -- Add vehicle to GUI of player's owned/locked vehicles
--~ GCKI.writeDebug("Adding new vehicle to GUI for vehicles owned/locked by player!")
  local pass_on_flags = {skip_event_check = true,}
  --~ GCKI_gui_player_vehicles.add_to_gui(player_id, vehicle, pass_on_flags)
  GCKI.writeDebugNewBlock("Add new vehicle to GUI for vehicles owned/locked by %s",
                          {GCKI.argprint(player)})
  if keep_owner_on_gui then
    GCKI.writeDebug("No: forbidden by flag!")
  else
    GCKI.writeDebug("Yes!")
    --~ local pass_on_flags = {skip_event_check = true,}
    GCKI_gui_player_vehicles.add_to_gui(player_id, vehicle, pass_on_flags)
  end

  -- Recolor vehicle?
  GCKI.writeDebugNewBlock("Recolor %s?", {GCKI.argprint(vehicle)})
  if keep_color then
    GCKI.writeDebug("No!")
  else
    GCKI.writeDebug("Yes!")
    common_vehicle.color_vehicle(vehicle)
  end

  -- Notify "Autodrive" that vehicle now has an owner
  GCKI.writeDebugNewBlock("Tell Autodrive that %s has a new owner?",
                          {GCKI.argprint(vehicle)})
  if ignore_Autodrive or not AUTODRIVE then
    GCKI.writeDebug("No: %s!",
                {AUTODRIVE and "forbidden by flag" or "Autodrive is not active"})

  elseif common_vehicle.is_Autodrive_vehicle(vehicle) then
    GCKI.writeDebug("Yes!")
    GCKI.remote_call(AUTODRIVE_NAME, "set_GCKI_owner", v_id, player_id)
  end

  --~ -- Notify "Vehicle Wagons" that a player owns a new vehicle. If a vehicle
  --~ -- belonging to that player has been loaded on a wagon, the owner flag can be
  --~ -- removed from that vehicle.
  --~ GCKI.writeDebug("Tell VehicleWagon that owner of %s has claimed another vehicle?",
                  --~ {"vehicle "..v_id})
  --~ if remote.interfaces["VehicleWagon2"] then
    --~ GCKI.writeDebug("Yes!")
    --~ GCKI.remote_call("VehicleWagon2", "release_owned_by_player", player_id)
  --~ else
    --~ GCKI.writeDebug("No: mod is not active!")
  --~ end


  -- Notify "CustomColor" that vehicle now has an owner
  GCKI.writeDebugNewBlock("Ask CustomColor to ignore %s?",
                          {GCKI.argprint(vehicle)})
  if dont_tell_CustomColor or vehicle.type ~= "car" then
    GCKI.writeDebug("No: %s!", {
      dont_tell_CustomColor and "forbidden by flag" or
                                GCKI.argprint(vehicle).." is not a car"
    })
  else
    GCKI.writeDebug("Yes!")
    GCKI.remote_call("CustomColor", "block_vehicle", vehicle, script.mod_name)
  end



  -- Update GUIs!
  if not keep_gui then
    GCKI.writeDebug("Must rebuild GUIs!")
    GCKI_gui.update_guis(vehicle)
  end

  GCKI.entered_function({{vehicle, player}}, "leave")
end


------------------------------------------------------------------------------------
--                             LOCK OR UNLOCK A VEHICLE                           --
--         (Returns index of locker, or nil if vehicle has been unlocked)         --
------------------------------------------------------------------------------------
common_vehicle.lock_or_unlock = function(vehicle, player)
  GCKI.entered_function({vehicle, player})

  local v_id = common_vehicle.get_vehicle_id(vehicle)

  player = GCKI.ascertain_player(player)
  local player_id = player and player.index

  --~ local skip, ret
  local ret

  -- Only proceed if we have IDs of both vehicle and player!
  if v_id and player_id then

    local v_data = v_id and mod.GCKI_vehicles[v_id]
    local v = v_data and v_data.entity
    if v and v.valid then
GCKI.writeDebug("Changing lock status of %s", {GCKI.argprint(v)})
      -- Remove locker
      if v_data.locker and v_data.locker == player_id then
        common_vehicle.remove_vehicle_locker(v_id, player_id)
      -- Add locker
      elseif not v_data.locker then
        common_vehicle.add_vehicle_locker(v_id, player_id)
      end
    end

  GCKI.writeDebug("mod.GCKI_vehicles[%s].locker: %s",
                  {v_id, mod.GCKI_vehicles[v_id] and mod.GCKI_vehicles[v_id].locker or "nil"})

  else
    GCKI.writeDebug("Nothing to do! (Vehicle: %s\tPlayer: %s)", {GCKI.argprint(v_id), GCKI.argprint(player_id)})
  end

  ret = v_id and mod.GCKI_vehicles[v_id] and mod.GCKI_vehicles[v_id].locker
GCKI.show("Locker", ret)

  GCKI.entered_function({vehicle, player}, "leave")
  return ret
end


------------------------------------------------------------------------------------
-- Who's in a vehicle?
-- car:                           get_driver(), get_passenger()
-- locomotive, artillery-wagon, cargo-wagon, fluid-wagon:   get_driver()
-- (Returns table with the fields "driver"/"passenger" and the respective player, or nil)
------------------------------------------------------------------------------------
common_vehicle.get_occupant_entity_data = function(occupant)
GCKI.entered_function({occupant})
  local ret

  if occupant and occupant.valid then
    -- player entity
    if occupant.is_player() then
      GCKI.writeDebug("occupant is a player.")
      ret = {entity = occupant, index = occupant.index, is_player = true}
    -- character connected to player
    elseif occupant.player then
      GCKI.writeDebug("occupant is a character connected to player.")
      ret = {entity = occupant.player, index = occupant.player.index, is_player = true}
    -- character associated with a player
    elseif occupant.associated_player then
      GCKI.writeDebug("occupant is a character connected to player.")
      ret = {entity = occupant.associated_player, index = occupant.associated_player.index, is_player = true}
    -- occupant is an unconnected character (dummy)
    else
      GCKI.writeDebug("occupant is a dummy character.")
      ret = {entity = occupant}
    end
  end
GCKI.entered_function({occupant}, "leave")
  return ret
end

common_vehicle.get_occupants = function(vehicle)
  GCKI.entered_function({vehicle})

GCKI.show("vehicle", GCKI.argprint(vehicle))
  -- Check argument
  if not common_vehicle.is_vehicle(vehicle) then
    GCKI.arg_err(vehicle, "vehicle specification")
  end

  local occupants = {}
  occupants.driver      = common_vehicle.get_occupant_entity_data(vehicle.get_driver())
  occupants.passenger   = common_vehicle.get_occupant_entity_data(vehicle.get_passenger())


  GCKI.show("occupants", occupants or "nil")
  GCKI.entered_function({vehicle}, "leave")
  return next(occupants) and occupants
end


------------------------------------------------------------------------------------
--                         GET NAMES OF VEHICLE OCCUPANTS                         --
--                           (Returns localized string)                           --
------------------------------------------------------------------------------------
-- vehicle: entity      occupants: result of common_vehicle.get_occupants (optional)
common_vehicle.get_occupant_names = function(vehicle, occupants)
  GCKI.entered_function({vehicle})

  -- No need to get the occupants again if we already know who's inside the vehicle!
  occupants = common_vehicle.is_vehicle(vehicle) and
                occupants or common_vehicle.get_occupants(vehicle)

  if occupants then
    local driver = occupants.driver and occupants.driver.is_player and occupants.driver.entity
    local passenger = occupants.passenger and occupants.passenger.is_player and occupants.passenger.entity

    local function get_string(name, role)
      return { "GCKI-messages.player-role", name, {"GCKI-words."..role} }
    end

    --~ local d_string = driver and {
      --~ "GCKI-messages.player-role",
      --~ driver.name,
      --~ {"GCKI-words.driver"}
    --~ }
    --~ local p_string = passenger and {
      --~ "GCKI-messages.player-role",
      --~ passenger.name,
      --~ {"GCKI-words.passenger"}
    --~ }
    local d_string = driver and get_string(driver.name, "driver")
    local p_string = passenger and get_string(passenger.name, "passenger")

    if driver and passenger then
      occupants = {"GCKI-words.and", d_string, p_string}
    else
      occupants = d_string or p_string
    end
  end

  GCKI.writeDebug("Occupants: %s", {occupants}, "line")
  GCKI.entered_function({vehicle}, "leave")
  return occupants
end


------------------------------------------------------------------------------------
--                              CHANGE VEHICLE COLOR                              --
-- This function is also used to color vehicles controlled by Autodrive, even if  --
-- there is no owner/locker in GCKI. So we need an entity, not a unit_number!     --
-- We need player and mod_name only if this function is called by Autodrive.      --
------------------------------------------------------------------------------------
common_vehicle.color_vehicle = function(vehicle, player, mod_name, mod_args)
  GCKI.entered_function({vehicle, player, mod_name, mod_args})

  -- We always need a valid vehicle!
  if not (common_vehicle.is_vehicle(vehicle) or
          (AUTODRIVE and common_vehicle.is_Autodrive_vehicle(vehicle))) then
    local msg = (not vehicle and "no vehicle") or
                (vehicle.valid and "prototype not supported") or
                "invalid vehicle"
    GCKI.entered_function({}, "leave", msg)
    return
  end
GCKI.show("vehicle", GCKI.argprint(vehicle))
GCKI.show("vehicle.color", vehicle.color)
GCKI.show("player", GCKI.argprint(player))
GCKI.show("mod_name", mod_name)
GCKI.show("mod_args", mod_args)

  -- Optional player, could also be replaced by mod_name
  GCKI.assert(player, {"LuaPlayer", "number", "string", "nil"},
                        "player specification or nil")
  if player then
    local p = GCKI.ascertain_player(player)
    if p and p.valid then
      GCKI.show("Got valid player", GCKI.argprint(p))
      player = p
    else
      GCKI.writeDebug("Swapping values of 'player' and 'mod_name'!")
      player, mod_name = GCKI.swap_args(player, mod_name, type(player) == "string")
    end
  end

  -- We only need mod_name if this function is entered on account of another mod.
  GCKI.assert(mod_name, {"string", "nil"}, "mod name or nil")
  if mod_name then
    GCKI.writeDebug("Have mod_name, checking mod_args!")
    GCKI.assert(mod_args, {"table", "nil"}, "nil or table of arguments")
  -- Mods may only pass on arguments if they also give us 'mod_name'!
  elseif mod_args then
    GCKI.arg_err(mod_args, "argument if there is no mod_name")
  end

  -- Read mod_args
  local store_color, ignore_next_event
  GCKI.writeDebugNewBlock("Are there any mod_args?")
  if mod_args and next(mod_args) then
    GCKI.writeDebug("Yes!")
    --~ store_color = mod_args.store_original_color
    store_color       = mod_args.GCKI_store_original_color
    ignore_next_event = mod_args.GCKI_skip_next_event
  else
    GCKI.writeDebug("No!")
  end

  -- Store original color?
  local v_id = vehicle.unit_number
  local v = v_id and mod.GCKI_vehicles[v_id]

  --~ local owner, locker, color, color_m, p
  local color, color_m, p
GCKI.show("v_id", v_id)
GCKI.show("v", v)

  -- GCKI vehicles must have an owner and/or a locker!
  if v then
GCKI.writeDebug("Found GCKI vehicle!")
    for r, role in pairs({"owner", "locker", "Autodrive_owner"}) do
      p = GCKI.ascertain_player(v[role])
      if p and p.valid then
        GCKI.writeDebug("%s has %s!", {GCKI.argprint(vehicle), role})
        color = p.color
        color_m = role.." (player "..p.index..")"
        break
      else
        GCKI.writeDebug("No %s!", {role})
      end
    end
GCKI.show("p", GCKI.argprint(p))
GCKI.show("color", color)
GCKI.show("color_m", GCKI.argprint(color_m))

  -- Not a GCKI vehicle! We can use the color of "player", if available.
  elseif player then
GCKI.writeDebug("Using color of %s!", {GCKI.argprint(player)})
    if player and player.valid then
      color = player.color
      color_m = "player "..player.index
    end
  end

GCKI.show("AUTODRIVE", AUTODRIVE)
GCKI.show("mod_name", mod_name)
GCKI.show("mod_name ~= AUTODRIVE_NAME", mod_name ~= AUTODRIVE_NAME)
  -- We still have no color, Autodrive is active, and function has been called by
  -- some other mod!
  if (not color) and AUTODRIVE then
    -- TODO: Autodrive announced that it's going to change the color.
    if mod_name == AUTODRIVE_NAME then
      GCKI.writeDebug("Skipping callback to Autodrive!")

    -- Called by another mod: ask Autodrive if color can be changed
    else
      GCKI.writeDebug("Asking Autodrive for vehicle owner!")
      -- Check whether there is an owner in Autodrive
      p = GCKI.remote_call(AUTODRIVE_NAME, "get_vehicle_owner", vehicle)
GCKI.show("p", GCKI.argprint(p))
      p = GCKI.ascertain_player(p)
GCKI.show("p", GCKI.argprint(p))
      -- Vehicle has an owner in Autodrive
      if p and p.valid then
        color = p.color
        color_m = "autodrive_owner (player "..p.index..")"
      end
    end
  end
GCKI.show("color", color)

  local colored_vehicle
  -- Change vehicle color to color of GCKI owner/locker, Autodrive owner, or player
  local function paint(new_color, msg)
    if not color or GCKI.compare_colors(color, vehicle.color) then
      GCKI.writeDebug("%s already has the correct color!", {GCKI.argprint(vehicle)})
    else
      GCKI.writeDebug(msg)
      common_vehicle.mark_for_color_change(vehicle, new_color)
      vehicle.color = new_color
      colored_vehicle = true
    end
  end

  local color_msg
  local v_colors = mod.vehicles_orig_color
GCKI.show("v_colors", v_colors)

  -- Color is derived from a player
  if color then
    GCKI.writeDebugNewBlock("Got color from player!")
    color_msg = string.format("Changing color of %s to color of %s",
                              GCKI.argprint(vehicle), color_m)
    paint(color, color_msg)

  -- Change vehicle color to its original color, if available
  elseif v_colors[v_id] and v_colors[v_id].color then
    GCKI.writeDebugNewBlock("Using original color!")
    --~ -- Paint vehicle unless it already has its original color
    --~ if not GCKI.compare_colors(v_colors[v_id].color, vehicle.color) then
      color_msg = string.format("Changing color of %s back to original color %s",
                    GCKI.argprint(vehicle), serpent.line(v_colors[v_id]))
      paint(v_colors[v_id].color, color_msg)
    --~ -- Don't paint vehicle, just output default message!
    --~ else
      --~ paint()
    --~ end

  -- Change vehicle color to default color
  else
    GCKI.writeDebugNewBlock("Using default color!")
    color_msg = string.format("Changing color of %s", GCKI.argprint(vehicle))
    paint(GCKI.colors["no_color"], color_msg)
  end
  GCKI.show("Changed vehicle color", colored_vehicle or false)

  -- Mark vehicle for color change. That's relevant if another mod has informed us
  -- that it will change the vehicle color.
  if ignore_next_event then
    GCKI.writeDebug("%s asked us to skip the next on_entity_color_changed event!",
                    {GCKI.enquote(mod_name)})
    common_vehicle.mark_for_color_change(vehicle, vehicle.color, mod_name)
  end

  GCKI.entered_function({vehicle, player}, "leave")
  return
end


-- Mark vehicle for pending color change
common_vehicle.mark_for_color_change = function(vehicle, new_color, mod_name)
  GCKI.entered_function({vehicle, new_color, mod_name})

  GCKI.assert(vehicle, "LuaEntity", "vehicle")
  GCKI.assert(new_color, "table", "color")
  GCKI.assert(mod_name, {"string", "nil"}, "name of calling mod or nil")

  mod.expect_color_change = mod.expect_color_change or {}
  mod.expect_color_change[vehicle.unit_number] = new_color
  GCKI.writeDebug("Marked %s for color change!", {GCKI.argprint(vehicle)})

  --~ if AUTODRIVE and mod_name ~= AUTODRIVE_NAME then
    --~ GCKI.writeDebug("Telling Autodrive to prepare for color change!")
    --~ GCKI.remote_call(AUTODRIVE_NAME, "mark_for_colorchange", vehicle, new_color)
  --~ else
    --~ GCKI.writeDebug("Skipping call to Autodrive because %s!",
                    --~ {AUTODRIVE and "it called us" or "it is not active"})
  --~ end

  GCKI.entered_function("leave")
end

-- Remove mark for pending color change of vehicle
common_vehicle.unmark_color_change = function(vehicle)
  GCKI.entered_function({vehicle})

  GCKI.assert(vehicle, "LuaEntity", "vehicle")

  if mod.expect_color_change then
    if mod.expect_color_change[vehicle.unit_number] then
      mod.expect_color_change[vehicle.unit_number] = nil
      GCKI.writeDebug("Removed mark for color change of %s!", {GCKI.argprint(vehicle)})
    end
    if not next(mod.expect_color_change) then
      mod.expect_color_change = nil
      GCKI.writeDebug("Removed mod.expect_color_change!")
    end
  end

  GCKI.entered_function("leave")
end

-- Store original color of a vehicle
common_vehicle.store_orig_color = function(vehicle, color, mod_name, flags)
  GCKI.entered_function({vehicle, color, mod_name, flags})

  local c = GCKI.ascertain_color(color)
GCKI.show("c", c)

  GCKI.assert(color, {"table", "string", "nil"},
                      "color specification, mod name, table of flags, or nil")
  GCKI.assert(mod_name, {"string", "table", "nil"},
                          "mod name, table of flags, or nil")
  GCKI.assert(flags, {"table", "nil"}, "table of flags, or nil")

  color, mod_name = GCKI.swap_args(color, mod_name, color and not (c and mod_name))
  mod_name, flags = GCKI.swap_args(mod_name, flags, type(mod_name) == "table")
GCKI.show("color", color)
GCKI.show("mod_name", mod_name)
GCKI.show("flags", flags)

  local ignore_Autodrive = flags and flags.ignore_Autodrive

GCKI.show("vehicle.color", vehicle.color)

  if common_vehicle.is_vehicle(vehicle) then
    GCKI.writeDebug("GCKI vehicle: storing original color!")
    mod.vehicles_orig_color[vehicle.unit_number] = {
      entity = vehicle,
      color = color or vehicle.color,
    }
  end


  GCKI.writeDebugNewBlock("Tell Autodrive to store original color of %s?",
                  {GCKI.argprint(vehicle)})
  --~ if AUTODRIVE and mod_name ~= AUTODRIVE_NAME and
                    --~ common_vehicle.is_Autodrive_vehicle(vehicle) then
    --~ GCKI.writeDebug("Yes!")
    --~ GCKI.remote_call(AUTODRIVE_NAME, "store_orig_color",
                      --~ vehicle, color or vehicle.color, script.mod_name)
  --~ else
    --~ GCKI.writeDebug("Skipping call-back to \"Autodrive\"!")
  --~ end
  if ignore_Autodrive or not AUTODRIVE then
    GCKI.writeDebug("No: %s!",
                    {AUTODRIVE and "forbidden by flag" or "Autodrive is not active"})

  elseif mod_name ~= AUTODRIVE_NAME and
          common_vehicle.is_Autodrive_vehicle(vehicle) then
    GCKI.writeDebug("Yes!")
    GCKI.remote_call(AUTODRIVE_NAME, "store_orig_color",
                      vehicle, color or vehicle.color, script.mod_name)
  end

  GCKI.entered_function("leave")
end


-- Can we overwrite the vehicle's original color? If we add a vehicle to our list
-- that already has an owner in Autodrive, Autodrive will already have stored the
-- *real* original color and the new vehicle color is that of the Autodrive owner.
-- We better make sure nobody has selected the vehicle in Autodrive before we agree
-- to overwriting the original color!
common_vehicle.can_store_orig_color = function(vehicle, AD_owner)
  GCKI.entered_function({vehicle, AD_owner})

  --~ if not common_vehicle.is_vehicle(vehicle) then
    --~ GCKI.arg_err(vehicle, "vehicle")
  --~ end
  GCKI.assert(AD_owner, {"number", "nil"}, "player index or nil")

  GCKI.writeDebugNewBlock("Get owner in Autodrive?")
  if AD_owner then
    GCKI.writeDebug("Using passed-on Autodrive owner!", {AD_owner})
  elseif AUTODRIVE and common_vehicle.is_Autodrive_vehicle(vehicle) then
    GCKI.writeDebug("Asking Autodrive for owner of %s!", {GCKI.argprint(vehicle)})
    AD_owner = GCKI.remote_call(AUTODRIVE_NAME, "get_vehicle_owner", vehicle)
  end
GCKI.show("AD_owner", AD_owner)

  local v_id = vehicle.unit_number
  local v_data = mod.GCKI_vehicles and mod.GCKI_vehicles[v_id]

  local orig_color = mod.vehicles_orig_color[v_id] and
                      mod.vehicles_orig_color[v_id].color
GCKI.show("v_data", v_data)
GCKI.show("orig_color", orig_color)
  local ret

  -- Keep the current original color if we have records of a player associated with
  -- this vehicle!
  if v_data and (v_data.owner or v_data.locker or v_data.Autodrive_owner) then
    GCKI.writeDebug("%s already has %s!", {
      GCKI.argprint(vehicle),
      (v_data.owner and "owner") or
        (v_data.locker and "locker") or
        "owner in Autodrive"
    })

  -- No need to update the original color if it is the same as the current vehicle
  -- color!
  elseif GCKI.compare_colors(orig_color, vehicle.color) then
    GCKI.writeDebug("Stored color is the same as current vehicle color!")

  -- If we add a new vehicle, it may already have an owner in Autodrive!
  elseif AD_owner then
    GCKI.writeDebugNewBlock("Does %s have an owner in Autodrive?",
                            {GCKI.argprint(vehicle)})
    AD_owner = GCKI.ascertain_player(AD_owner)
    -- If player and vehicle have the same color, Autodrive probably already has
    -- stored the original color and painted the vehicle!
    if AD_owner and AD_owner.valid and
                    GCKI.compare_colors(AD_owner.color, vehicle.color) then
      GCKI.writeDebug("%s has already been repainted by Autodrive!",
                      {GCKI.argprint(vehicle)})

    else
      GCKI.writeDebug("%s has no owner in Autodrive: can store original color!",
                      {GCKI.argprint(vehicle)})
      ret = true
    end

  -- We can overwrite the stored original color!
  else
    GCKI.writeDebug("Go ahead, store the original color!")
    ret = true
  end

  GCKI.show("Returning", ret)

  GCKI.entered_function("leave")
  return ret
end


------------------------------------------------------------------------------------
--                              CHANGE VEHICLE COLOR                              --
-- This function is also used to color vehicles controlled by Autodrive, even if  --
-- there is no owner/locker in GCKI. So we need an entity, not a unit_number!     --
-- We need player and mod_name only if this function is called by Autodrive.      --
------------------------------------------------------------------------------------
common_vehicle.can_color_vehicle = function(vehicle, player, mod_name, mod_args)
  GCKI.entered_function({vehicle, player, mod_name})

  if not common_vehicle.is_vehicle(vehicle) then
    GCKI.entered_function({}, "leave", "invalid vehicle")
    return
  end

    GCKI.assert(player, {"LuaPlayer", "number", "string", "nil"},
                        "player specification or nil")
    if player then
      local p = GCKI.ascertain_player(player)
      if p and p.valid then
        player = p
      elseif type(player) == "string" and not mod_name then
        mod_name, player = player, nil
      end
    end

    GCKI.assert(mod_name, {"string", "nil"}, "mod name or nil")
    if mod_name then
      GCKI.writeDebug("Have mod_name, checking mod_args!")
      GCKI.assert(mod_args, {"table", "nil"}, "nil or table of arguments")
    elseif mod_args then
      GCKI.arg_err(mod_args, "argument if there is no mod_name")
    end

  --~ player = GCKI.ascertain_player(player)
  --~ if not (player and player.valid) then
    --~ GCKI.arg_err(player, "player")
  --~ end

  --~ if not common_vehicle.is_vehicle(vehicle) then
    --~ GCKI.entered_function({}, "leave", "invalid vehicle")
    --~ return
  --~ end

  GCKI.assert(mod_name, {"string", "nil"}, "mod name")

  local v_id = vehicle.unit_number
  local v = v_id and mod.GCKI_vehicles[v_id]

  --~ local owner, locker, color, color_m, p
  local owner, locker, p
GCKI.show("v_id", v_id)
GCKI.show("v", v)


GCKI.show("AUTODRIVE", AUTODRIVE)
GCKI.show("mod_name ~= AUTODRIVE_NAME", mod_name ~= AUTODRIVE_NAME)

  -- Check whether this is a GCKI vehicle
  if v then
    GCKI.writeDebug("Found GCKI vehicle!")
    owner = v.owner and GCKI.ascertain_player(v.owner)
    locker = v.locker and GCKI.ascertain_player(v.locker)
    if (owner and owner.valid) or (locker and locker.valid) then
      p = owner or locker
    end

  -- Don't call back to Autodrive if we came from there!
  elseif AUTODRIVE and mod_name ~= AUTODRIVE_NAME and
                        mod.AD_prototypes[vehicle.name] then
    GCKI.writeDebug("Asking Autodrive for owner of %s!", {GCKI.argprint(vehicle)})
    p = GCKI.remote_call(AUTODRIVE_NAME, "get_vehicle_owner", vehicle)
GCKI.show("p", GCKI.argprint(p))
  end

  -- Per default, assume that the player may color the vehicle
  local ret = true

  -- If the vehicle has owner or locker in GCKI or Autodrive, check whether this is
  -- the player.
  if p then
    ret = (p == player.index)
    GCKI.show("Player may change color", ret)
  end
GCKI.show("ret", ret)

  GCKI.entered_function("leave")
  return ret
end


------------------------------------------------------------------------------------
--             REPLACE VEHICLE IN LISTS OF CLAIMED AND LOCKED VEHICLES            --
------------------------------------------------------------------------------------
common_vehicle.replace_vehicle = function(event)
  GCKI.entered_function({event})
GCKI.show("driver", GCKI.argprint(event.driver))
GCKI.show("new_entity", GCKI.argprint(event.new_entity))
GCKI.show("new_entity_unit_number", GCKI.argprint(event.new_entity_unit_number))
GCKI.show("old_entity", GCKI.argprint(event.old_entity))
GCKI.show("old_entity_unit_number", GCKI.argprint(event.old_entity_unit_number))
  -- When AAI replaces a vehicle, we always want to know if there is a real player
  -- inside, even if the vehicle isn't controlled by GCKI yet! This way, we can skip
  -- the on_driving_state_changed event.
  local old_vehicle = event.old_entity
  -- If space-capsule from "Space Exploration" has been replaced it has landed and
  -- any players inside will exit it regularly. We don't need to skip the next events
  -- in this case!
GCKI.show("old_vehicle.name", old_vehicle and old_vehicle.valid and old_vehicle.name)
GCKI.show("old_vehicle.name:find(\"se-space-capsule-_-vehicle\", 1, true)",
          old_vehicle and old_vehicle.valid and
            old_vehicle.name:find("se-space-capsule-_-vehicle", 1, true))
  if not (old_vehicle and old_vehicle.valid and
          old_vehicle.name:find("se-space-capsule-_-vehicle", 1, true)) then
    GCKI_player.skip_driving_changed_state(event, 2)
  end

  local v_old_id = (old_vehicle and old_vehicle.valid) and
                    old_vehicle.unit_number or event.old_entity_unit_number
  local v_old = v_old_id and mod.GCKI_vehicles[v_old_id]

  local v_new = event.new_entity
  local v_new_id = v_new and event.new_entity_unit_number


  -- If the old vehicle had a custom name, move that to the new vehicle!
  local new_name = mod.named_vehicles.by_id[v_old_id] and
                    mod.named_vehicles.by_id[v_old_id].name
  if new_name then
    local player = mod.named_vehicles.by_id[v_old_id].named_by
    GCKI.writeDebug("Moving custom name to %s!", {GCKI.argprint(v_new)} )
    --~ common_vehicle.edit_vehicle_name(player, v_new, new_name)
    local args = {
      player = player,
      vehicle = v_new,
      new_name = new_name,
      restore = true,
    }
    common_vehicle.edit_vehicle_name(args, script.mod_name)
  end


  -- Replace vehicle in list of original vehicle colors
  local v_colors = mod.vehicles_orig_color
  local new_color = v_colors[v_old_id] and v_colors[v_old_id].color and
                      util.table.deepcopy(v_colors[v_old_id].color)
GCKI.show("new_color", new_color)

  v_colors[v_new_id] = {
    entity = v_new,
    color = new_color or util.table.deepcopy(v_new.color)
  }
  v_colors[v_old_id] = nil
  GCKI.writeDebug("%s entry for original color %s new %s!", {
    new_color and "Copied" or "Created",
    new_color and "to" or "of",
    GCKI.argprint(v_new)
  })

  --~ -- Swap the vehicle in GUIs
  --~ GCKI_gui.swap_vehicle_on_guis(v_old_id, v_new)



  -- Old vehicle had owner and/or locker
  if v_old then
GCKI.writeDebug("Must act on replaced %s!", {GCKI.argprint(old_vehicle)})

GCKI.show("v_new", GCKI.argprint(v_new))
GCKI.show("v_new_id", v_new_id)
GCKI.show("v_old_id", v_old_id)

    -- Swap the vehicle in GUIs
    GCKI_gui.swap_vehicle_on_guis(v_old_id, v_new)

    -- Add new vehicle to list
    mod.GCKI_vehicles[v_new_id] = { ["entity"] = v_new }

    local pass_on_flags = {
      keep_color = true,
      keep_gui = true,
      keep_owner_on_gui = true,
    }

    -- Add owner to new vehicle?
    GCKI.writeDebugNewBlock("Add owner to new %s?", {GCKI.argprint(v_new)})
    if v_old.owner and game.get_player(v_old.owner) then
      GCKI.writeDebug("Yes: player %s", {v_old.owner})
      common_vehicle.add_vehicle_owner(v_new, v_old.owner, pass_on_flags)
    else
      GCKI.writeDebug("No!")
    end

    -- Add locker to new vehicle?
    GCKI.writeDebugNewBlock("Add locker to new %s?", {GCKI.argprint(v_new)})
    if v_old.locker and game.get_player(v_old.locker) then
      GCKI.writeDebug("Yes: player %s", {v_old.locker})
      common_vehicle.add_vehicle_locker(v_new, v_old.locker, pass_on_flags)
    else
      GCKI.writeDebug("No!")
    end

    -- Recolor new vehicle
    GCKI.writeDebugNewBlock("Trying to recolor new %s!", {GCKI.argprint(v_new)})
    common_vehicle.color_vehicle(v_new)

    -- Remove old vehicle from list
    GCKI.writeDebugNewBlock("Removing old vehicle %s!", {v_old_id})
    common_vehicle.remove_vehicle(v_old_id)

  else
    GCKI.writeDebug("Vehicle with unit_number %s is not controlled by GCKI!",
                    {v_old_id})
  end

  GCKI.entered_function({event}, "leave")
end


------------------------------------------------------------------------------------
--                                VEHICLE RESTORED                                --
--    This is needed for "Vehicle Wagons 2", when it unloads a vehicle that was   --
--                   previously locked or owned by some player.                   --
------------------------------------------------------------------------------------
common_vehicle.restore_vehicle = function(vehicle, vehicle_data, mod_name)
  GCKI.entered_function({vehicle, vehicle_data, mod_name})
--~ common_vehicle.restore_vehicle = function(vehicle, vehicle_data, mod_name, flags)
  --~ GCKI.entered_function({vehicle, vehicle_data, mod_name, flags})

  GCKI.assert(vehicle, "LuaEntity", "vehicle")
  if not (vehicle and vehicle.valid) then
    GCKI.arg_err(vehicle, "vehicle")
  end
  local v_id = vehicle.unit_number

  GCKI.assert(vehicle_data, {"table", "string", "nil"},
                            "vehicle data, mod name, table of flags, or nil")
  GCKI.assert(mod_name, {"string", "table", "nil"},
                          "mod name, table of flags, or nil")
  --~ GCKI.assert(flags, {"table", "nil"}, "table of flags or nil")
GCKI.show("vehicle", GCKI.argprint(vehicle))
GCKI.show("vehicle_data", vehicle_data)
GCKI.show("mod_name", mod_name)
--~ GCKI.show("flags", flags)

  local v_data
  v_data, mod_name = GCKI.swap_args(vehicle_data, mod_name,
                                      type(vehicle_data) == "string")
GCKI.show("vehicle after swapping", GCKI.argprint(vehicle))
GCKI.show("v_data after swapping", v_data)
GCKI.show("mod_name after swapping", mod_name)

  local owner, locker, AD_owner, custom_name, orig_color
  GCKI.writeDebugNewBlock("Read vehicle data?")
  if v_data then
    GCKI.writeDebug("Yes!")
    owner       = v_data.owner and GCKI_player.get_player_index(v_data.owner)
    locker      = v_data.locker and GCKI_player.get_player_index(v_data.locker)
    AD_owner    = v_data.Autodrive_owner and
                    GCKI_player.get_player_index(v_data.Autodrive_owner)
    custom_name = v_data.custom_name
    orig_color  = v_data.orig_color
  else
    GCKI.writeDebug("No data available!")
  end

  -- Always restore custom names, even if GCKI doesn't handle the vehicle prototype!
GCKI.show("custom_name", custom_name)
  if custom_name then
    -- Try to get the player who named the vehicle either from the vehicle data
    -- passed on to this function, or from the data stored for the last vehicle the
    -- custom name was used for, if available.
    local named_by = v_data.named_by
    if not named_by then
      local n = mod.named_vehicles.by_name[custom_name]
      named_by = n and mod.named_vehicles.by_id[n] and
                        mod.named_vehicles.by_id[n].named_by
    end

    GCKI.writeDebug("Must restore custom name %s!", {GCKI.enquote(custom_name)})
    local args = {
      --~ player = named_by or owner or locker,
      player = named_by or owner or locker or AD_owner,
      vehicle = vehicle,
      new_name = custom_name,
      restore = true
    }
    common_vehicle.edit_vehicle_name(args, script.mod_name)

    if mod.named_vehicles.by_id[v_id].not_available then
      mod.named_vehicles.by_id[v_id].not_available = nil
      GCKI.writeDebug("Removing flag 'not_available'!")
    end
  end


  -- If the original color was stored with the vehicle, it means that we once have
  -- controlled it. It's possible that we don't care about the prototype anymore,
  -- but we still should restore its original color if it differs from its current
  -- color! We therefore store the original color in our global table, so that it
  -- is available to vehicle_functions.color_vehicle. The record will be removed
  -- when the list clean-up is run from on_nth_tick.
GCKI.show("orig_color", orig_color)
  --~ GCKI.writeDebugNewBlock("Restore original vehicle color?")
  --~ if orig_color then
    --~ global.vehicles_orig_color[vehicle.unit_number] = {
      --~ entity = vehicle,
      --~ color = orig_color,
    --~ }
    --~ if not GCKI.compare_colors(orig_color, vehicle.color) then
      --~ GCKI.writeDebug("Recoloring %s!", {GCKI.argprint(vehicle)})
      --~ common_vehicle.color_vehicle(vehicle)
    --~ end
  --~ else
    --~ GCKI.writeDebug("No!")
  --~ end

  local pass_on_flags = {ignore_Autodrive = true}

  GCKI.writeDebugNewBlock("Storing  original vehicle color!")
  -- Current vehicle color will be used if orig_color is not available!
  common_vehicle.store_orig_color(vehicle, orig_color, script.mod_name, pass_on_flags)


  -- Only proceed if vehicle is valid!
  if not common_vehicle.is_vehicle(vehicle) then
    GCKI.writeDebug("Recoloring %s!", {GCKI.argprint(vehicle)})
    common_vehicle.color_vehicle(vehicle)

    GCKI.entered_function({}, "leave",
                          GCKI.argprint(vehicle).." is not of supported prototype")
    return
  end

  --~ GCKI.assert(mod_name, {"string", "nil"})
  mod_name = mod_name and GCKI.enquote(mod_name) or "unknown mod"

  -- Each player may only own one vehicle! If a player has claimed a new one,
  -- remove "owner" from stored data!
  if owner and mod.owners[owner] and mod.owners[owner] ~= v_id then
    GCKI.writeDebug("Player %s has claimed another vehicle!", {owner})
    owner = nil
  end

  -- Add v_data to list (Either locker or owner player who named the vehicle
  -- must exist; owner may not have claimed a new vehicle.)
GCKI.show("owner", owner)
GCKI.show("locker", locker)
  local player = owner or locker
GCKI.show("player", player)
  if player then
    pass_on_flags = {
      keep_color = true,
      keep_orig_color = true,
      ignore_Autodrive = true,
      dont_tell_CustomColor = true,
    }
    GCKI.writeDebug("Adding vehicle %s on account of %s",
                    {GCKI.argprint(vehicle), mod_name})

    -- Initialize vehicle data
    mod.GCKI_vehicles[v_id] = {
      entity      = vehicle,
      Autodrive_owner = AD_owner,
    }

    -- Tell CustomColor to ignore the restored vehicle!
    GCKI.writeDebugNewBlock("Tell CustomColor to ignore restored vehicle?")
    if vehicle.type == "car" then
      GCKI.writeDebug("Yes!")
      GCKI.remote_call("CustomColor", "block_vehicle", vehicle, script.mod_name)
    else
      GCKI.writeDebug("No: %s is not a car!", {GCKI.argprint(vehicle)})
    end


    -- Add owner?
    GCKI.writeDebugNewBlock("Add owner?")
    if owner then
      GCKI.writeDebug("Yes!")
      GCKI.output(game.get_player(player), {"GCKI-messages.owner-vehicle_unloaded",
                                          GCKI.loc_name(vehicle)})
      common_vehicle.add_vehicle_owner(vehicle, owner, pass_on_flags)
    else
      GCKI.writeDebug("No!")
    end

    -- Add locker?
    GCKI.writeDebugNewBlock("Add locker?")
    if locker then
      GCKI.writeDebug("Yes!")
      --~ common_vehicle.add_vehicle_locker(vehicle, locker, {keep_color = keep_color})
      common_vehicle.add_vehicle_locker(vehicle, locker, pass_on_flags)

      GCKI.writeDebug("Added %s as locker to data of %s",
                      --~ {GCKI.argprint(game.players[locker].name),
                        --~ GCKI.argprint(global.GCKI_vehicles[v_id] and
                        --~ global.GCKI_vehicles[v_id].entity)})
                      --~ {GCKI.argprint(game.players[locker].name),
                      {GCKI.argprint(locker),
                        GCKI.argprint(vehicle)})
      -- Inform locker
      if mod.player_data[locker].settings.show_hints then
        --~ GCKI.output(game.players[player], {
        GCKI.hint(game.get_player(player), {
          "GCKI-messages.player-vehicle_unloaded",
          GCKI.loc_name(vehicle)
        })
        if not owner then
          --~ GCKI.output(game.players[player], {
          GCKI.hint(game.get_player(player), {
            "GCKI-messages.vehicle-lock_state",
            GCKI.loc_name(vehicle),
            {"GCKI-states.locked"}
          })
        end
      end

    -- No locker
    else
      GCKI.writeDebug("No!")
    end
  end


  -- Reset vehicle color
  common_vehicle.color_vehicle(vehicle)

  GCKI.entered_function("leave")
end


------------------------------------------------------------------------------------
--                RESET SINGLE VEHICLE                                --
------------------------------------------------------------------------------------
common_vehicle.reset_vehicle = function(vehicle_id)
  GCKI.entered_function({vehicle_id})

  local named = mod.named_vehicles
  local other = mod.GCKI_vehicles

GCKI.show("named.by_name[vehicle_id]", GCKI.argprint(named.by_name[vehicle_id]))
GCKI.show("named.by_id[vehicle_id].entity", GCKI.argprint(named.by_id[vehicle_id] and named.by_id[vehicle_id].entity))
GCKI.show("other[vehicle_id].entity", GCKI.argprint(other[vehicle_id] and other[vehicle_id].entity))

  local vehicle = named.by_name[vehicle_id] or
                  (named.by_id[vehicle_id] and named.by_id[vehicle_id].entity) or
                  (other[vehicle_id] and other[vehicle_id].entity)
GCKI.show("vehicle", GCKI.argprint(vehicle))


  if vehicle then
    GCKI.writeDebug("Trying to reset %s.", {GCKI.argprint(vehicle)})
    common_vehicle.remove_vehicle(vehicle)
  end

  GCKI.entered_function("leave")
end


------------------------------------------------------------------------------------
--                  RESET ALL VEHICLES                                --
------------------------------------------------------------------------------------
common_vehicle.reset_all_vehicles = function()
  GCKI.entered_function()

  local cnt, p_cnt = 0, 0

  -- Vehicles with an owner (these may also be locked)
  GCKI.writeDebug("Looking for vehicles with an owner.")
  for player, vehicle in pairs(mod.owners) do
    p_cnt = p_cnt + 1
    GCKI.show("Vehicle of player "..player, vehicle)
    common_vehicle.reset_vehicle(vehicle)
  end
  GCKI.writeDebug("Reset %s vehicles with an owner!", {p_cnt})

  -- Locked vehicles (these have no owner)
  GCKI.writeDebug("Looking for locked vehicles.")
  p_cnt = 0
  for player, vehicles in pairs(mod.lockers) do
    p_cnt = p_cnt + 1
    GCKI.show("Vehicles of player "..player, vehicles)
    for v_id, v in pairs(vehicles) do
      common_vehicle.reset_vehicle(v_id)
      cnt = cnt + 1
    end
  end
  GCKI.writeDebug("Unlocked all %s vehicles of %s players!", {cnt, p_cnt})

  -- Named vehicles
  GCKI.writeDebug("Looking for named vehicles.")
  cnt = 0
  for v, v_data in pairs(mod.named_vehicles.by_id) do
    if v_data.entity and v_data.entity.valid then
      common_vehicle.reset_vehicle(v)
      cnt = cnt + 1
    end
  end
  GCKI.writeDebug("Removed %s vehicles from mod.named_vehicles!", {cnt})


  GCKI.entered_function("leave")
end


------------------------------------------------------------------------------------
--                Reset vehicles owned/locked by a certain player                 --
------------------------------------------------------------------------------------
common_vehicle.reset_player_vehicles = function(player)
  GCKI.entered_function({player})

  player = GCKI.ascertain_player(player)
  if not (player and player.valid) then
    GCKI.arg_err(player, "player specification")
  end

  -- Vehicle owned by the player
  GCKI.writeDebugNewBlock("Is %s owner of a vehicle?", {GCKI.argprint(player)})
  local owned_by_player = mod.owners and mod.owners[player.index]
GCKI.show("owned_by_player", owned_by_player)
  if owned_by_player then
    GCKI.writeDebug("Yes! Must reset vehicle.")
    common_vehicle.reset_vehicle(owned_by_player)
    GCKI.writeDebug("Reset vehicle owned by %s.", {GCKI.argprint(player)})
  end

  GCKI.writeDebugNewBlock("Has %s locked any vehicles?", {GCKI.argprint(player)})
  local locked_by_player = mod.lockers and mod.lockers[player.index]
GCKI.show("locked_by_player", locked_by_player)
  local cnt = 0
  for v_id, v in pairs(locked_by_player or {}) do
    GCKI.writeDebug("Resetting vehicle %s!", {v_id})
    common_vehicle.reset_vehicle(v_id)
    cnt = cnt + 1
  end
  GCKI.writeDebug("Reset %s vehicles locked by %s.", {cnt, GCKI.argprint(player)})

  GCKI.entered_function("leave")
end


------------------------------------------------------------------------------------
--       REMOVE DUMMIES (FIX FOR AAI PROGRAMMABLE VEHICLES AND SIMILAR MODS)      --
-- Mods may put a dummy driver or passenger into a vehicle if it's unoccupied. It --
-- should be destroyed again if it's not needed anymore -- but if it isn't        --
-- when the vehicle dies, the dummy character is left on the surface, so we have  --
-- to remove it.                                                                  --
-- (Returns: table of removed dummies or empty table)
------------------------------------------------------------------------------------
common_vehicle.remove_dummy = function(vehicle, occupants) -- vehicle: entity
  GCKI.entered_function({vehicle, occupants})

  local v = common_vehicle.is_vehicle(vehicle) and vehicle

  local dummies = (v and common_vehicle.is_dummy_inside(v, occupants)) or {}
GCKI.show("dummies", dummies)
  for role, character in pairs(dummies) do
    GCKI.writeDebug("Removed dummy %s %s from %s!",
                    {role, character and character.name or "nil", {GCKI.loc_name(v)}})
    character.destroy({raise_destroy = true})
  end

GCKI.show("Removed dummies", dummies)
  GCKI.entered_function({vehicle}, "leave")

  return dummies
end


------------------------------------------------------------------------------------
--             RESTORE RENDERINGS AFTER TELEPORITING TO OTHER SURFACE             --
------------------------------------------------------------------------------------
common_vehicle.restore_renderings = function(vehicle_or_id, custom_name_id)
  GCKI.entered_function({vehicle_or_id, custom_name_id})

  GCKI.assert(vehicle_or_id, {"LuaEntity", "number"}, "vehicle or unit_number")
  GCKI.assert(custom_name_id, {"number", "nil"}, "rendering ID or nil")

  local v_id = (type(vehicle_or_id) == "number") and vehicle_or_id or
                vehicle_or_id.valid and vehicle_or_id.unit_number

  --~ local vehicle, named
  --~ if v_id then
    --~ vehicle = global.GCKI_vehicles[v_id]
    --~ named = global.named_vehicles.by_id[v_id]
  --~ end
  local vehicle = mod.GCKI_vehicles[v_id]
  local named = mod.named_vehicles.by_id[v_id]


  -- Selected icon is optional!
  --~ if vehicle and vehicle.locker and
      --~ not (vehicle.lock_icon and rendering.is_valid(vehicle.lock_icon)) then
    --~ GCKI.writeDebug("Must restore rendering for lock icon!")
    --~ vehicle.lock_icon = common_vehicle.locked_icon(vehicle.entity)
  --~ end
  if vehicle and vehicle.locker then
    --~ local icon = vehicle.lock_icon and
                  --~ rendering.get_object_by_id(vehicle.lock_icon)
    local render_object = GCKI.ascertain_rendering(vehicle.lock_icon)
    if not (render_object and render_object.valid) then
      GCKI.writeDebug("Must restore rendering for lock icon!")
      vehicle.lock_icon = common_vehicle.locked_icon(vehicle.entity)
    end
  end

  -- If we have a custom name, render_text_id is required!
  if named then
    -- If we came here because another mod raised a custom event after teleporting
    -- the vehicle to another surface, we will reuse the rendering made by that mod.
    if custom_name_id then
      GCKI.writeDebug("Reusing rendering created by other mod!")
      named.render_text_id = custom_name_id

    --~ elseif not (named.render_text_id and rendering.is_valid(named.render_text_id)) then

      --~ GCKI.writeDebug("Must restore rendering of custom name!")
      --~ named.render_text_id = common_vehicle.add_vehicle_name_rendering(
                               --~ named.named_by, vehicle.entity, named.name)
    else
      --~ local r = named.render_text_id and
                --~ rendering.get_object_by_id(named.render_text_id)
      local render_object = GCKI.ascertain_rendering(named.render_text_id)
      if not (render_object and render_object.valid) then
        GCKI.writeDebug("Must restore rendering of custom name!")
        named.render_text_id = common_vehicle.add_vehicle_name_rendering(
                                 named.named_by, vehicle.entity, named.name)
      end
    end
  end

  GCKI.entered_function({}, "leave")
end



------------------------------------------------------------------------------------
GCKI.entered_file("leave")
return common_vehicle
