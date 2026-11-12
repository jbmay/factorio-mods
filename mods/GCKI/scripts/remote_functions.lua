GCKI.entered_file()

------------------------------------------------------------------------------------
------------------------------------------------------------------------------------
--                                LOCAL DEFINITIONS                               --
------------------------------------------------------------------------------------
------------------------------------------------------------------------------------


------------------------------------------------------------------------------------
------------------------------------------------------------------------------------
--                              ADD REMOTE INTERFACE                              --
------------------------------------------------------------------------------------
------------------------------------------------------------------------------------
remote.add_interface(GCKI_NAME, {

  ------------------------------------------------------------------------------------
  -- Returns player who locked the vehicle or nil if it's unlocked
  vehicle_locked_by = function(vehicle)
    GCKI.writeDebug("GCKI: Entered interface function vehicle_locked_by")
    return GCKI_vehicle.get_locker(vehicle)
  end,


  ------------------------------------------------------------------------------------
  -- Returns player who owns the vehicle or nil if it has no owner
  vehicle_owned_by = function(vehicle)
    GCKI.writeDebug("GCKI: Entered interface function vehicle_owned_by")
    return GCKI_vehicle.get_owner(vehicle)
  end,


  ------------------------------------------------------------------------------------
  -- Returns unit_number of vehicle owned by the player, or nil
  owned_by_player = function(player)
    GCKI.writeDebug("GCKI: Entered interface function owned_by_player")
    local p = GCKI_player.get_player_index(player)

    local owner = p and game.get_player(p)
    return owner and GCKI_ownership.find(p, owner.surface)
  end,


  ------------------------------------------------------------------------------------
  -- Returns dummy characters in a vehicle or nil
  dummies_in_vehicle = function(vehicle)
    GCKI.writeDebug("GCKI: Entered interface function dummies_in_vehicle")
    return GCKI_vehicle.is_dummy_inside(vehicle)
  end,


  ------------------------------------------------------------------------------------
  -- For mods like AAI that replace vehicles
  -- (add new vehicle to list immediately after old one has been removed)
  on_entity_replaced = function(event)
    GCKI.writeDebug("GCKI: Entered interface function on_entity_replaced")
    return GCKI_vehicle.replace_vehicle(event)
  end,


  ------------------------------------------------------------------------------------
  -- Make data GCKI stores with a vehicle available to other mods. Make that
  -- general, so other mods can use this even if we add some new data in the future!
  get_vehicle_data = function(vehicle)
    GCKI.writeDebug("GCKI: Entered interface function get_vehicle_data")
    local data = GCKI_vehicle.get_vehicle_data(vehicle)

    GCKI.writeDebug("GCKI: End of interface function get_vehicle_data")
    return data
  end,


  --~ -- Can the player load/unload the vehicle onto/from a Vehicle Wagon?
  --~ can_load_unload_vehicle = function(player, vehicle, mod_name)
    --~ GCKI.writeDebugNewBlock("Autodrive: Entered remote function can_load_unload_vehicle(%s, %s)",
                  --~ {player, vehicle, GCKI.enquote(mod_name or "")}, "line")

    --~ player = GCKI.ascertain_player(player)
    --~ if not (player and player.valid) then
      --~ GCKI.arg_err(player, "player specification")
    --~ end
    --~ GCKI.assert(vehicle, {"LuaEntity", "number"}, "vehicle entity or unit_number")
    --~ GCKI.assert(mod_name, {"string", "nil"}, "name of the mod calling this function")

    --~ local v_id = (type(vehicle) == "number") and
                    --~ vehicle or
                    --~ (vehicle.valid and vehicle.unit_number)

    --~ local v_data = v_id and (mod.vehicles and mod.vehicles[v_id]) or
                            --~ (mod.on_vehicle_wagon and mod.on_vehicle_wagon[v_id])
--~ GCKI.show("v_id", v_id)
--~ GCKI.show("v_data", v_data)
--~ GCKI.show("not v_data", not v_data)
--~ GCKI.show("v_data.owner == player.index", v_data and v_data.owner == player.index)
--~ GCKI.show("v_data.GCKI_locked_by == player.index", v_data and v_data.GCKI_locked_by == player.index)

    --~ local ret = true
    --~ local blocked_by

    --~ -- Check local vehicle data!
    --~ GCKI.writeDebugNewBlock("Can we use local data?")
    --~ if v_data then
      --~ GCKI.writeDebug("Yes!")
      -- ret = (v_data.owner == player.index) or
      --      (v_data.locker == player.index) or
      --      (v_data.Autodrive_owner == player.index)
      --~ blocked_by = GCKI.ascertain_player(v_data.owner or
                                          --~ v_data.locker or
                                          --~ v_data.Autodrive_owner)

      --~ ret = (not blocked_by) or
            --~ (not blocked_by.valid) or
            --~ (blocked_by.index == player.index)

    --~ -- Ask Autodrive if it's active!
    --~ elseif AUTODRIVE then
      --~ GCKI.writeDebug("No: asking Autodrive!")
      --~ ret, blocked_by = GCKI.remote_call(AUTODRIVE_NAME,
                                          --~ "can_load_unload_vehicle", player, v_id,
                                          --~ script.mod_name)
    --~ -- Neither GCKI nor Autodrive know this vehicle
    --~ else
      --~ GCKI.writeDebug("No!")
    --~ end
--~ GCKI.show("ret", ret)
--~ GCKI.show("blocked_by", blocked_by)

    --~ GCKI.writeDebug("%s: End of remote function can_load_unload_vehicle",
                    --~ {script.mod_name})
    --~ return ret, blocked_by
  --~ end,
  -- Can the player load/unload the vehicle onto/from a Vehicle Wagon?
  can_load_unload_vehicle = function(args, mod_name)
    GCKI.writeDebugNewBlock("GCKI: Entered remote function can_load_unload_vehicle(%s, %s)",
                  {args, GCKI.enquote(mod_name or "")}, "line")

    GCKI.assert(args, "table", "table of arguments")
    GCKI.assert(mod_name, {"string", "nil"}, "name of the mod calling this function")

    local player = GCKI.ascertain_player(args.player)
    if not (player and player.valid) then
      GCKI.arg_err(player, "player specification")
    end

    local vehicle = args.vehicle
    GCKI.assert(vehicle, {"LuaEntity", "number"}, "vehicle entity or unit_number")

    local v_id = (type(vehicle) == "number") and
                    vehicle or
                    (vehicle.valid and vehicle.unit_number)

    local v_data = v_id and (mod.vehicles and mod.vehicles[v_id]) or
                            (mod.on_vehicle_wagon and mod.on_vehicle_wagon[v_id])
GCKI.show("v_id", v_id)
GCKI.show("v_data", v_data)
GCKI.show("not v_data", not v_data)
GCKI.show("v_data.owner == player.index", v_data and v_data.owner == player.index)
GCKI.show("v_data.GCKI_locked_by == player.index", v_data and v_data.GCKI_locked_by == player.index)

    local ask_Autodrive = args.ask_Autodrive
    GCKI.assert(ask_Autodrive, {"boolean", "nil"}, "Boolean or nil")
GCKI.show("ask_Autodrive", ask_Autodrive)

    local ret = true
    local blocked_by

    -- Check local vehicle data!
    GCKI.writeDebugNewBlock("Can we use local data?")
    if v_data then
      GCKI.writeDebug("Yes!")
      --~ ret = (v_data.owner == player.index) or
            --~ (v_data.locker == player.index) or
            --~ (v_data.Autodrive_owner == player.index)
      blocked_by = GCKI.ascertain_player(v_data.owner or
                                          v_data.locker or
                                          v_data.Autodrive_owner)

      ret = (not blocked_by) or
            (not blocked_by.valid) or
            (blocked_by.index == player.index)

    -- Ask Autodrive if it's active!
    --~ elseif AUTODRIVE then
    elseif ask_Autodrive then
      GCKI.writeDebug("No: asking Autodrive!")
      ret, blocked_by = GCKI.remote_call(AUTODRIVE_NAME, "can_load_unload_vehicle",
                                          {player = player, vehicle = v_id},
                                          script.mod_name)
GCKI.writeDebug("Returned from Autodrive!")
    -- Neither GCKI nor Autodrive know this vehicle
    else
      GCKI.writeDebug("No!")
    end
GCKI.show("ret", ret)
GCKI.show("blocked_by", blocked_by)

    GCKI.writeDebug("%s: End of remote function can_load_unload_vehicle",
                    {script.mod_name})
    return ret, not ret and blocked_by or nil
  end,


  -- For mods like Autodrive that want to assign a unique custom name to vehicles:
  -- Check whether the player can give this custom name to a vehicle. (Fails if the
  -- vehicle was already named by another player, or if the name is already used.)
  can_rename_vehicle = function(args, mod_name)
    GCKI.writeDebug("GCKI: Entered function can_rename_vehicle(%s, %s)",
                    {args, GCKI.enquote(mod_name or "")}, "line")

    GCKI.assert(args.mod_name, {"string", "nil"}, "custom name")
    GCKI.assert(args.vehicle, {"number", "LuaEntity"}, "unit_number or entity")
    GCKI.assert(args.new_name, {"string"}, "custom name")
    local player = GCKI.ascertain_player(args.player)
    if not (player and player.valid) then
      GCKI.arg_err(player, "player specification")
    end

    GCKI.writeDebug("GCKI: Tail call to GCKI_vehicle.can_rename_vehicle()")
    return GCKI_vehicle.can_rename_vehicle(args, mod_name)
  end,


  -- Called when mods like Autodrive have assigned a unique custom name to a vehicle
  renamed_vehicle = function(args, mod_name)
    GCKI.writeDebug("GCKI: Entered function renamed_vehicle(%s, %s)",
                    {args, mod_name}, "line")

    GCKI.assert(mod_name, {"string", "nil"}, "mod name")
    local vehicle, player = args.vehicle, args.player
    local new_name, render_text_id = args.new_name, args.render_text_id

    GCKI.assert(vehicle, {"number", "LuaEntity"}, "unit_number or entity")
    GCKI.assert(new_name, {"string"}, "custom name")
    GCKI.assert(render_text_id, {"LuaRenderObject", "number", "nil"}, "render_text_id")

    local named_by = GCKI.ascertain_player(player)
    if not (named_by and named_by.valid) then
      GCKI.arg_err(player, "player specification")
    end
GCKI.show("named_by", GCKI.argprint(named_by))

    GCKI.writeDebug("Changing name of %s!", {GCKI.argprint(vehicle)})
    GCKI_vehicle.edit_vehicle_name(args, mod_name)

    GCKI.writeDebug("GCKI: End of function renamed_vehicle")
  end,


  -- Called when mods like Autodrive removed the custom name of a vehicle
  remove_custom_name = function(id_or_name, mod_name)
    GCKI.writeDebug("GCKI: Entered function remove_custom_name(%s, %s)",
                    {id_or_name, mod_name})

    GCKI.assert(id_or_name, {"number", "string"}, "unit_number or custom name")
    GCKI.assert(mod_name, {"string", "nil"}, "mod name")

    mod.named_vehicles = mod.named_vehicles or { by_id = {}, by_name = {} }
    local named = mod.named_vehicles

    local id = (type(id_or_name) == "number" and id_or_name) or
                named.by_name[id_or_name]

    if id and named.by_id[id] then
      GCKI.writeDebug("Removing custom name of %s!",
                      {GCKI.argprint(named.by_id[id].entity)})
      local vehicle = named.by_id[id].entity
GCKI.show("vehicle", GCKI.argprint(vehicle))
GCKI.show("named.by_id["..id.."]", named.by_id[id])
      GCKI_vehicle.remove_vehicle_name(id, mod_name)
GCKI.show("vehicle after remove_vehicle_name", vehicle)
GCKI.show("named.by_id["..id.."] after remove_vehicle_name", named.by_id[id])

      --~ local vehicle = global.GCKI_vehicles[id]
      --~ if vehicle then
        --~ GCKI.writeDebug("Updating GUIs!")
        --~ GCKI_gui.update_guis(vehicle)
      --~ end
    end

    GCKI.writeDebug("GCKI: End of function remove_custom_name")
  end,


  -- Mods like Autodrive may want to check whether this vehicle has a custom name in
  -- GCKI in order to preserve the custom name even if its used for a prototype that
  -- they don't care about.
  get_custom_name = function(id_or_vehicle, mod_name)
    GCKI.writeDebug("GCKI: Entered function get_custom_name(%s, %s)",
                  {id_or_vehicle, mod_name})

    GCKI.assert(id_or_vehicle, {"number", "LuaEntity"}, "unit_number or entity")
    GCKI.assert(mod_name, {"string", "nil"}, "mod name")

    local id, ret

    if type(id_or_vehicle) == "number" then
      id = id_or_vehicle
    elseif id_or_vehicle.valid then
      for t, v_type in pairs(GCKI.vehicle_types) do
        if id_or_vehicle.type == v_type then
          id = id_or_vehicle.unit_number
          break
        end
      end
    end
    GCKI.show("id", id)

    ret = id and mod.named_vehicles.by_id[id]

    --~ -- Removed: We now sync the names with GCKI!
    --~ if (not ret) and AUTODRIVE and mod_name ~= AUTODRIVE_NAME then
      --~ GCKI.writeDebut("Asking Autodrive for custom name of vehicle %s.", {id})
      --~ ret = GCKI.remote_call(AUTODRIVE_NAME, "get_custom_name", id, script.mod_name)
    --~ end

    GCKI.writeDebug("GCKI: End of function get_custom_name")
    return ret
  end,


  -- Synchronize custom names with list from other mod and return synchronized list.
  sync_names = function(custom_names, mod_name)
    GCKI.writeDebug("GCKI: Entered function sync_names(%s, %s)",
                  {custom_names, mod_name})

    GCKI.assert(custom_names, "table", "table of custom names")
    GCKI.assert(mod_name, {"string", "nil"})

    local ours_by_id    = mod.named_vehicles.by_id
    local ours_by_name  = mod.named_vehicles.by_name
    local by_id         = custom_names.by_id
    local by_name       = custom_names.by_name

    local added, discarded = 0, 0
    local vehicle

    for name, id in pairs(by_name) do
      -- Name resolves to correct ID
      if by_id[id] and by_id[id].name == name then
        vehicle = by_id[id].entity

        -- Vehicle is still in the game
        if (vehicle and vehicle.valid) or by_id[id].not_available then
          ours_by_id[id] = table.deepcopy(by_id[id])
          ours_by_name[name] = id
          added = added + 1
        else
          discarded = discarded + 1
        end
      else
        discarded = discarded + 1
      end
    end
    GCKI.writeDebug("Added %s names, discarded %s.",
                    {added, discarded})

    GCKI.writeDebug("GCKI: End of function sync_names")
    return mod.named_vehicles
  end,


  ----------------------------------------------------------------------------------
  -- For Vehicle Wagons: Mod doesn't store data and destroy entities when loading
  -- vehicles onto a wagon in Factorio 2.0. Instead, it just teleports the vehicle
  -- to a secret surface. We need this to migrate data stored for vehicles loaded in
  -- Factorio 1.1.
  vehicle_wagons_migration = function(vehicles)
    GCKI.writeDebug("GCKI: Entered interface function vehicle_wagons_migration(%s)",
                    {GCKI.argprint(vehicles)})
    GCKI.assert(vehicles, "table", "vehicle data from Vehicle Wagons")

    if not next(vehicles) then
      GCKI.writeDebug("Nothing to do: received no data!")
      return
    end

    mod.on_vehicle_wagon = mod.on_vehicle_wagon or {}
    local vehicle

    for v, v_data in pairs(vehicles) do
      vehicle = v_data.entity
      GCKI.writeDebugNewBlock("Add data for vehicle %s?", {GCKI.argprint(vehicle)})
      if vehicle and vehicle.valid then
        GCKI.writeDebug("Yes!")
        mod.on_vehicle_wagon[vehicle.unit_number] = table.deepcopy(v_data)
      else
        GCKI.writeDebug("No: %s vehicle!", {vehicle and "not a valid" or "no"})
      end
    end

    GCKI.writeDebug("GCKI: End of interface function vehicle_removed")
  end,


  ------------------------------------------------------------------------------------
  -- For mods like Vehicle Wagons that temporarily remove a vehicle and
  -- restore it after an indeterminate time)
  vehicle_removed = function(vehicle, modname)
    GCKI.writeDebug("GCKI: Entered interface function vehicle_removed(%s, %s)",
                {GCKI.argprint(vehicle), GCKI.argprint(modname)})
    local id = GCKI_vehicle.get_vehicle_id(vehicle)

    if id then
      local v = mod.GCKI_vehicles[id]
  GCKI.show("vehicle", vehicle.name)
  GCKI.show("modname", modname)

      --~ local player = v and v.owner and game.players[v.owner]
      local player = GCKI.ascertain_player(v and v.owner)
  GCKI.show("v", v)
  GCKI.show("player", GCKI.argprint(player))

      -- Inform owner of vehicle that vehicle has disappeared
      if player and v and v.entity and v.entity.valid then
        GCKI.output(player, {"GCKI-messages.owner-vehicle_unavailable", GCKI.loc_name(v.entity)})
        GCKI.hint(player, {"GCKI-messages.hints-wait_for_vehicle", GCKI.loc_name(v.entity)})
      end

  GCKI.show("mod.player_data["..tostring(v and (v.owner or v.locker)).."]",
            mod.player_data[v and (v.owner or v.locker)])

      -- Remove vehicle
      GCKI_vehicle.remove_vehicle(vehicle, {
        --~ -- If the function was called by Vehicle Wagons, there's no need to tell it
        --~ -- that we just removed the vehicle.
        --~ dont_tell_vehicle_wagons = (modname == "VehicleWagon2"),

        -- If the vehicle has a custom name, we want to preserve it until the vehicle
        -- is restored or removed for good (e.g., the vehicle wagon carrying it died.)
        keep_custom_name = true,
        -- It makes no sense to recolor a vehicle that's about to be destroyed!
        keep_color = true,
        --~ -- Mods are supposed to call this before destroying a vehicle. We'll catch the
        --~ -- script_raised_destroy event and remove the vehicle from GUIs when it fires.
        --~ keep_gui = true,
      })

      -- If vehicle has a custom name, mark it as reserved
      local named = mod.named_vehicles.by_id[id]
      if named then
        named.not_available = true
      end
    end

    GCKI.writeDebug("GCKI: End of interface function vehicle_removed")
  end,


  ------------------------------------------------------------------------------------
  -- For mods like Vehicle Wagons that temporarily remove a vehicle and hide it
  -- on/in another entity (the proxy, e.g. the vehicle wagon a vehicle is loaded
  -- on). This function should be called when the proxy is destroyed.
  -- (GCKI allows to set unique customized vehicle names. If a vehicle is tempora-
  -- rily unavailable, we want to reserve the name, so it can be reused when the
  -- vehicle is restored. When the proxy is removed, the vehicle is gone for good
  -- and the vehicle's custom name should be made available to other vehicles.)
  vehicle_proxy_destroyed = function(vehicle_data)
    GCKI.writeDebug("GCKI: Entered interface function vehicle_proxy_destroyed")

    GCKI.writeDebug("Proxy for a stored vehicle has been removed!\nVehicle data: %s",
              {vehicle_data})

    local name = vehicle_data and vehicle_data.GCKI_data and
                                  vehicle_data.GCKI_data.custom_name
    if name and mod.named_vehicles and
                mod.named_vehicles.by_name and
                mod.named_vehicles.by_name[name] then

      GCKI.writeDebug("Must release custom vehicle name \"%s\"!", {name})
      GCKI_vehicle.remove_vehicle_name(name, script.mod_name)
    end

    GCKI.writeDebug("GCKI: End of interface function get_custom_event_ids")
  end,

  ------------------------------------------------------------------------------------
  -- Returns ID of all our custom events or the custom event specified by event_name
  get_custom_event_ids = function(event_name)
    GCKI.writeDebug("GCKI: Entered interface function get_custom_event_ids")
GCKI.show("event_name", event_name)
    local ret
    if event_name then
      ret = GCKI.custom_events[event_name]
      if not ret then
        GCKI.arg_err(event_name, "name of a custom event")
      end
    else
      ret = GCKI.custom_events
    end

GCKI.show("ret", ret)
    GCKI.writeDebug("GCKI: End of interface function get_custom_event_ids")
    return ret
  end,


  ----------------------------------------------------------------------------------
  -- Reset vehicle color
  reset_vehicle_color = function(vehicle, player, mod_name, mod_args)
    GCKI.writeDebug("%s: Entered interface function reset_vehicle_color(%s, %s, %s)", {
      "GCKI",
      GCKI.argprint(vehicle),
      GCKI.argprint(player),
      mod_name and
        GCKI.enquote(mod_name)..tostring(mod_args and ", "..serpent.line(mod_args)) or
        ""
    })

    GCKI.assert(vehicle, "LuaEntity", "entity")
    if not vehicle.valid then
      GCKI.arg_err(vehicle, "entity")
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
    GCKI.assert(mod_args, {"table", "nil"}, "nil or table of arguments")
GCKI.show("player", GCKI.argprint(player))
GCKI.show("mod_name", mod_name)
GCKI.show("mod_args", mod_args)

    --~ if mod_args then
      --~ local ignore_next_event = mod_args.GCKI_skip_next_event
      --~ if ignore_next_event then
        --~ GCKI.writeDebug("Removing flag GCKI_skip_next_event from mod_args!")
        --~ mod_args.GCKI_skip_next_event = nil
      --~ end
    --~ end


    local ret
    if GCKI_vehicle.is_vehicle(vehicle) then
      GCKI_vehicle.color_vehicle(vehicle, player, mod_name, mod_args)
      ret = true
    end
GCKI.show("ret", ret)
    GCKI.writeDebug("GCKI: End of interface function reset_vehicle_color")
    return ret
  end,


  ----------------------------------------------------------------------------------
  -- Store color as vehicle's original color
  store_orig_color = function(vehicle, color, mod_name)
    GCKI.writeDebug("GCKI: Entered interface function store_orig_color!")
    GCKI.show("vehicle", GCKI.argprint(vehicle))
    GCKI.show("color", GCKI.argprint(color))
    GCKI.show("mod_name", GCKI.argprint(mod_name))

    local c = GCKI.ascertain_color(color)
    color, mod_name = GCKI.swap_args(color, mod_name, color and not c)
GCKI.show("color after swap_args", color)
GCKI.show("mod_name after swap_args", mod_name)

    --~ GCKI_vehicle.store_orig_color(vehicle, color)
    GCKI_vehicle.store_orig_color(vehicle, color, mod_name)

    GCKI.writeDebug("GCKI: End of function store_orig_color")
  end,


  ----------------------------------------------------------------------------------
  -- When another mod calls this function, we mark the vehicle for a pending color
  -- change so that we may ignore the actual event.
  mark_for_colorchange = function(vehicle, new_color, mod_name)
    GCKI.writeDebug("GCKI: Entered function mark_for_colorchange(%s, %s, %s)",
                  {GCKI.argprint(vehicle), new_color, GCKI.enquote(mod_name)})

    if vehicle and vehicle.valid and new_color then
      GCKI.writeDebug("Marking %s for coming color change!", GCKI.argprint(vehicle))
      GCKI_vehicle.mark_for_color_change(vehicle, new_color)
    else
      GCKI.writeDebug("Missing %s!",
                    {vehicle and vehicle.valid and "color" or "vehicle"})
    end

    GCKI.writeDebug("GCKI: End of function mark_for_colorchange")
  end,


  -- Autodrive: Owner of vehicle has changed (new owner/no owner) -- update vehicle!
  set_Autodrive_owner = function(vehicle, owner)
    GCKI.writeDebug("GCKI: Entered function set_Autodrive_owner(%s, %s)",
                  {GCKI.argprint(vehicle), GCKI.argprint(owner)})

    GCKI.assert(owner, {"number", "LuaPlayer", "nil"}, "player specification or nil")
    owner = GCKI.ascertain_player(owner)

    local v_id = (type(vehicle) == "number" and vehicle) or
                 --~ (vehicle and vehicle.valid and vehicle.type == "car" and vehicle.unit_number) or
                 (GCKI_vehicle.is_vehicle(vehicle) and vehicle.unit_number) or
                 nil

    mod.GCKI_vehicles = mod.GCKI_vehicles or {}
    local v = v_id and mod.GCKI_vehicles[v_id]
GCKI.show("v.entity", GCKI.argprint(v and v.entity))

    if v then
      if v.Autodrive_owner == owner then
        GCKI.writeDebug("No change!")
      else
        GCKI.writeDebug("Autodrive %s its owner of %s!", {
          (not v.Autodrive_owner and "added") or
            (not owner and "removed") or "changed",
          GCKI.argprint(v.entity)
        })
        v.Autodrive_owner = (owner and owner.valid) and owner.index or nil
      end
GCKI.show("v.Autodrive_owner", GCKI.argprint(v.Autodrive_owner))
    else
      GCKI.writeDebug("Ignoring vehicle because it's not on the GUI.")
    end

    GCKI.writeDebug("GCKI: End of function set_Autodrive_owner()")
  end,

})

GCKI.show("Registered remote functions", remote.interfaces[GCKI_NAME])

------------------------------------------------------------------------------------
GCKI.entered_file("leave")
