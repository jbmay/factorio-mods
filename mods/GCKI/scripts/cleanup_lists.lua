GCKI.entered_file()

local cleanup = {}




------------------------------------------------------------------------------------
------------------------------------------------------------------------------------
--                               GUI-RELATED TABLES                               --
------------------------------------------------------------------------------------
------------------------------------------------------------------------------------


------------------------------------------------------------------------------------
-- VEHICLES FROM GLOBAL.GCKI_VEHICLES MUST BE VALID ENTITIES OF VALID PROTOTYPES! --
--  We can't use the functions for checking/removing vehicles because they won't  --
--  work with ignored prototypes, so we must replicate some of the code here.     --
------------------------------------------------------------------------------------
-- Returns number of removed vehicles
--~ cleanup.cleanup_GCKI_vehicles = function()
  --~ GCKI.entered_function()

  --~ local orig_vehicles = table_size(global.GCKI_vehicles)
  --~ local keep = {}
  --~ local cnt = 0

  --~ local vehicle, player

  --~ -- Check global.GCKI_vehicles
--~ GCKI.show("global.GCKI_vehicles", global.GCKI_vehicles)
  --~ for v_id, v_data in pairs(global.GCKI_vehicles or {}) do
--~ GCKI.show(v_id, v_data)
    --~ vehicle = GCKI_vehicle.is_vehicle(v_data.entity)
--~ GCKI.show("vehicle", GCKI.argprint(vehicle))

    --~ player = GCKI.ascertain_player(v_data.owner or v_data.locker)
    --~ player = player and player.valid
--~ GCKI.show("player", GCKI.argprint(player))

    --~ -- Keep vehicle if it is still valid and has a valid owner/locker!
    --~ if vehicle and player then
      --~ GCKI.writeDebug("Keeping %s.", {GCKI.argprint(vehicle)})
      --~ keep[v_id] = v_data

    --~ else
      --~ GCKI.writeDebug("Removing global.GCKI_vehicles[%s]: invalid %s",
                      --~ {v_id, player and "vehicle" or "locker/owner"})
      --~ cnt = cnt + 1
    --~ end
  --~ end

  --~ global.GCKI_vehicles = util.table.deepcopy(keep)
  --~ GCKI.writeDebug("global.GCKI_vehicles: removed %s, keeping %s vehicles",
                  --~ {orig_vehicles - table_size(keep), table_size(keep)})

  --~ GCKI.entered_function("leave")
  --~ return cnt
--~ end

cleanup.GCKI_vehicles = function(flags)
  GCKI.entered_function({flags})

  GCKI.assert(flags, {"table", "nil"}, "table of flags or nil")


  --~ local orig_vehicles = table_size(global.GCKI_vehicles)
  local keep = {}
  local cnt = 0

  local vehicle, owner, locker

  -- Check mod.GCKI_vehicles
GCKI.show("mod.GCKI_vehicles", mod.GCKI_vehicles)
  for v_id, v_data in pairs(mod.GCKI_vehicles or {}) do
GCKI.show(v_id, v_data)
    vehicle = GCKI_vehicle.is_vehicle(v_data.entity) and v_data.entity
GCKI.show("vehicle", GCKI.argprint(vehicle))

    -- Vehicle prototype and entity are still valid
    --~ if vehicle and vehicle.valid then
    if vehicle then
      GCKI.writeDebug("%s is a valid vehicle!", {GCKI.argprint(vehicle)})

      -- Keep vehicle if it has a valid owner/locker
      --~ owner = v_data.owner and game.players[v_data.owner]
      --~ locker = v_data.locker and game.players[v_data.locker]
      owner = v_data.owner and GCKI.ascertain_player(v_data.owner)
      locker = v_data.locker and GCKI.ascertain_player(v_data.locker)
GCKI.show("owner", GCKI.argprint(owner))
GCKI.show("locker", GCKI.argprint(locker))
      if (owner and owner.valid) or (locker and locker.valid) then
        GCKI.writeDebug("Keeping %s.", {GCKI.argprint(vehicle)})
        keep[v_id] = v_data

      else
        GCKI.writeDebug("No valid owner or locker: removing vehicle!")
        GCKI_vehicle.remove_vehicle(v_id, flags)
        cnt = cnt + 1
      end

    --~ -- We still care about the prototype, but the entity isn't valid
    --~ elseif vehicle then
      --~ GCKI.writeDebug("Removing global.GCKI_vehicles[%s]: invalid entity", {v_id})
      --~ cnt = cnt + 1

    -- Ignored prototype or invalid vehicle!
    else
      if v_data.entity and v_data.entity.valid then
        GCKI.writeDebug("Removing mod.GCKI_vehicles[%s]: obsolete prototype!",
                        {v_id})
        flags = flags or {}
        flags.removed_prototype = true

        GCKI_vehicle.remove_vehicle(v_data.entity, flags)

      -- We still care about the prototype, but the entity isn't valid
      else
        GCKI.writeDebug("Removing mod.GCKI_vehicles[%s]: invalid entity", {v_id})
        GCKI_vehicle.remove_vehicle(v_id, flags)
      end
      cnt = cnt + 1
    end
  end

  mod.GCKI_vehicles = util.table.deepcopy(keep)
  GCKI.writeDebug("mod.GCKI_vehicles: removed %s, keeping %s vehicles",
                  --~ {orig_vehicles - table_size(keep), table_size(keep)})
                  {cnt, table_size(keep)})

  -- Remove vehicles that no longer are in mod.GCKI_vehicles from mod.owners
  for owner, v_id in pairs(mod.owners) do
    if not mod.GCKI_vehicles[v_id] then
      GCKI.writeDebug("Removing obsolete vehicle %s from mod.owners[%s]!",
                      {v_id, owner})
      mod.owners[owner] = nil
    end
  end

  -- Remove vehicles that no longer are in mod.GCKI_vehicles from mod.lockers
  for locker, vehicles in pairs(mod.lockers) do
    GCKI.writeDebugNewBlock("Checking vehicles in mod.lockers[%s]:",{locker})

    for v_id, v in pairs(vehicles) do
      if not mod.GCKI_vehicles[v_id] then
        GCKI.writeDebug("Removing obsolete vehicle %s from mod.lockers[%s]!",
                        {v_id, locker})
        mod.lockers[locker][v_id] = nil
      end
    end
    if not next(mod.lockers[locker]) then
      GCKI.writeDebug("Removing mod.lockers[%s]!", {locker})
      mod.lockers[locker] = nil
    end
  end

  GCKI.entered_function("leave")
  return cnt
end


-- Returns number of removed vehicles
local function cleanup_locked_or_owned()
  GCKI.entered_function()

  --~ local orig_vehicles
  local keep
  local cnt = 0

  local our_vehicle, tab_name, p_count, pass_on_flags

  for p, p_data in pairs(mod.player_data) do
GCKI.show("Checking data of player "..p, p_data)
    keep = {}
    p_count = 0
    --~ orig_vehicles = p_data.locked_or_owned and table_size(p_data.locked_or_owned)
    tab_name = string.format("mod.player_data[%s].locked_or_owned", p)

    for v_id, vehicle in pairs(p_data.locked_or_owned or {}) do
      GCKI.show(v_id, GCKI.argprint(vehicle))
      -- Keep vehicle if it is valid (entity + prototype), …
      if GCKI_vehicle.is_vehicle(vehicle) then
        -- … is still on mod.GCKI_vehicles
        our_vehicle = mod.GCKI_vehicles[v_id]
        if our_vehicle and (our_vehicle.owner == p or our_vehicle.locker == p) then
          GCKI.writeDebug("Keeping %s.", {GCKI.argprint(vehicle)})
          keep[v_id] = vehicle
        else
          GCKI.writeDebug("Removing %s: %s",
                          {tab_name, our_vehicle and "wrong locker/owner" or
                                                    "not our vehicle"})
          pass_on_flags = {
            keep_color = true,
            keep_gui = true,
            skip_event_check = true,
          }
          GCKI_vehicle.remove_vehicle(vehicle, pass_on_flags)
          p_count = p_count + 1
        end
      else
        -- Entity is still valid, but we don't care about the prototype
        if vehicle and vehicle.valid then
          GCKI.writeDebug("Removing %s[%s]: wrong prototype", {tab_name, v_id})
          pass_on_flags = {
            keep_color = true,
            keep_gui = true,
            skip_event_check = true,
            removed_prototype = true,
          }
          GCKI_vehicle.remove_vehicle(vehicle, pass_on_flags)

        -- Prototype still exists, but there is no valid entity
        else
          GCKI.writeDebug("Removing %s[%s]: not a valid vehicle", {tab_name, v_id})
          pass_on_flags = {
            keep_color = true,
            keep_gui = true,
            skip_event_check = true,
          }
          GCKI_vehicle.remove_vehicle(v_id, pass_on_flags)
        end
        p_count = p_count + 1
      end
    end

GCKI.show("p_count", p_count)
    if p_count > 0 then
      GCKI.writeDebug("Overwriting p_data.locked_or_owned!")
      p_data.locked_or_owned = util.table.deepcopy(keep)
    end
GCKI.show("p_data.locked_or_owned", p_data.locked_or_owned)
GCKI.show("mod.player_data["..p.."].locked_or_owned",
          mod.player_data[p].locked_or_owned)
    GCKI.writeDebug("%s: removed %s, keeping %s vehicles",
                    {tab_name, p_count, table_size(keep)})

    if p_data.locked_or_owned and not next(p_data.locked_or_owned) then
      GCKI.writeDebug("Removing mod.player_data[%s].locked_or_owned!", {p})
      p_data.locked_or_owned = nil
    end

    cnt = cnt + p_count
  end

  GCKI.entered_function("leave")
  return cnt
end

  --~ for p, player_data in pairs(global.player_data) do
    --~ if not global.player_data[p] then
      --~ GCKI_player.init_player(p)
    --~ end
    --~ p_data = global.player_data[p]
--~ GCKI.show("p_data", p_data)

    --~ for v, vehicle in pairs(p_data and p_data.locked_or_owned or {}) do
--~ GCKI.show("v ("..v..")", GCKI.argprint(vehicle))
      --~ if not (vehicle and vehicle.valid and
                          --~ GCKI_vehicle.is_vehicle(vehicle)) then
--~ GCKI.writeDebug("Must remove vehicle %s from list and GUIs!", {v})
      --~ -- GCKI_vehicle.remove_vehicle(vehicle, {
        --~ GCKI_vehicle.remove_vehicle(v, {
          --~ keep_color = true,
          --~ keep_gui = true,
          --~ removed_prototype = true,
        --~ })
        --~ cnt = cnt + 1
      --~ end
    --~ end

      --~ -- Camera may still be on because players should see the message rendered on
      --~ -- the ground when their vehicle has been destroyed or stolen!
      --~ if p_data and p_data.show_on_camera then
        --~ GCKI_gui_player_vehicles_camera.close_gui(p)
        --~ GCKI.writeDebug("Camera of %s is now invisible!", {GCKI.argprint(p)})
      --~ end

    --~ else
--~ GCKI.writeDebug("Keeping %s.", {GCKI.argprint(vehicle)})
    --~ end
  --~ end

  --~ -- Rebuild GUIs if at least one vehicle has been removed
  --~ if keep_gui then
    --~ GCKI.writeDebug("Flag \"keep_gui\" has been set, keeping GUIs!")
  --~ elseif cnt == 0 then
    --~ GCKI.writeDebug("No vehicle has been removed, keeping GUIs!")
  --~ else
    --~ GCKI.writeDebug("Removed %s vehicle(s) from tables. Must rebuild GUIs!", {cnt})
    --~ GCKI_gui.init_guis()
  --~ end

  -- local ret = (cnt > 0) and cnt or nil

  --~ GCKI.entered_function("leave")
  -- return ret
  --~ return cnt
--~ end


------------------------------------------------------------------------------------
--           REMOVE VEHICLES WE DON'T CARE ABOUT FROM PLAYER SELECTIONS           --
------------------------------------------------------------------------------------
local function cleanup_selected_vehicles()
  GCKI.entered_function()

  local cnt = 0
  --~ local p_count, p_data, check, reason, keep
  local p_count, reason, keep

  for p, p_data in pairs(mod.player_data or {}) do
    GCKI.writeDebug("Checking tables of player %s: %s", {p, p_data})
    keep = {}
    p_count = 0

    for v_id, vehicle in pairs(p_data and p_data.selected_vehicles or {}) do
      --~ reason = nil

      -- Keep valid vehicles of valid prototypes
      if GCKI_vehicle.is_vehicle(vehicle) then
        GCKI.writeDebug("Keeping %s in list of vehicles selected by player %s!",
                        {GCKI.argprint(vehicle), p})
        keep[v_id] = vehicle

      -- Remove vehicles if prototype or entity is not vald
      else
        GCKI.writeDebug("Removing %s from list of vehicles selected by player %s!",
                        {GCKI.argprint(vehicle), p})

        -- Valid entity, obsolete prototype
        if vehicle and vehicle.valid then
          reason = "Invalid prototype"
          GCKI_vehicle.remove_vehicle(vehicle, {
            keep_color = true,
            keep_gui = true,
            skip_event_check = true,
            removed_prototype = true
          })
        -- Invalid entity
        else
          reason = "Invalid vehicle"
          GCKI_vehicle.remove_vehicle(v_id, {
            keep_color = true,
            keep_gui = true,
            skip_event_check = true,
          })
        end
        GCKI.writeDebug("%s: Removed %s from list of vehicles selected by player %s!",
                        {reason, GCKI.argprint(vehicle), p})
        p_count = p_count + 1
      end
    end

    if p_count > 0 then
      GCKI.writeDebug("Overwriting mod.player_data[%s].selected_vehicles!", {p})
      mod.player_data[p].selected_vehicles = util.table.deepcopy(keep)
    end

    cnt = cnt + p_count
  end
  GCKI.writeDebug("Removed %s vehicle(s) from tables!", {cnt})

  GCKI.entered_function("leave")
  return cnt
end


------------------------------------------------------------------------------------
--    REMOVE EXPIRED VEHICLES FROM CAMERA IF THE RENDERING ON GROUND IS INVALID   --
------------------------------------------------------------------------------------
cleanup.show_on_camera = function(player, flags)
  GCKI.entered_function({player, flags})

  --~ player = GCKI.ascertain_player(player)
  GCKI.assert(player, {"LuaPlayer", "number", "table", "nil"},
                        "player specification or nil")
GCKI.show("player", GCKI.argprint(player))
  -- Get player index if we have a valid player  specification
  local p_index = (type(player) == "number" and player) or
                  (player and player.object_name == "LuaPlayer" and
                    player.valid and player.index)

  -- If player was no player specification, this really should be flags!
  --~ if player and not p_index then
    --~ flags = player
    --~ player = nil
  --~ end
  player, flags = GCKI.swap_args(player, flags, not p_index)

  GCKI.assert(flags, {"table", "nil"}, "nil or table of flags")
  local keep_gui = flags and flags.keep_gui
  local skip_event_check = flags and flags.skip_event_check

  local cnt = 0
  local on_cam, related_rendering

  -- Has the function been called for a single player or for all players?
  local data = p_index and {p_index = mod.player_data[p_index]} or
                            mod.player_data or {}

  --~ for p, p_data in pairs(global.player_data or {}) do
  for p, p_data in pairs(data) do
    GCKI.writeDebug("Checking tables of player %s: %s", {p, p_data})

    on_cam = p_data.show_on_camera
    if on_cam then
      --~ related_rendering = on_cam.related_rendering and
                          --~ rendering.get_object_by_id(on_cam.related_rendering)
      related_rendering = GCKI.ascertain_rendering(on_cam.related_rendering)
GCKI.show("related_rendering", related_rendering)

      -- Keep camera on valid entities
      if on_cam.entity and GCKI_vehicle.is_vehicle(on_cam.entity) then
        GCKI.writeDebug("Keeping %s on camera for player %s!",
                        {GCKI.argprint(on_cam.entity), p})
      -- Keep camera on position if there is a valid message rendered on the ground
      --~ elseif related_rendering and rendering.is_valid(related_rendering) then
      elseif related_rendering and related_rendering.valid then
        GCKI.writeDebug("Keeping camera view for player %s on ground rendering!",
                        {p})
      -- Remove show_on_camera from player data and close GUI
      else
        GCKI.writeDebug("Closing camera of player %s!", {p})
        GCKI_gui_player_vehicles_camera.close_gui(p, {
          keep_gui = keep_gui,
          skip_event_check = skip_event_check,
        })
        cnt = cnt + 1
      end
    end
  end
  GCKI.writeDebug("Removed %s vehicle(s) from camera!", {cnt})

  GCKI.entered_function("leave")
  return cnt
end



------------------------------------------------------------------------------------
--   REMOVE EXPIRED VEHICLES FROM MAP VIEW IF THE RENDERING ON GROUND IS INVALID  --
------------------------------------------------------------------------------------
cleanup.show_on_map = function(flags)
  GCKI.entered_function({flags})

  GCKI.assert(flags, {"table", "nil"}, "nil or table of flags")
  local keep_gui = flags and flags.keep_gui
  local skip_event_check = flags and flags.skip_event_check

  local cnt = 0
  local on_map

  --~ -- Has the function been called for a single player or for all players?
  --~ local data = p_index and {p_index = global.player_data[p_index]} or
                            --~ global.player_data or {}

  for p, p_data in pairs(mod.player_data or {}) do
  --~ for p, p_data in pairs(data) do
    GCKI.writeDebug("Checking tables of player %s: %s", {p, p_data})

    on_map = p_data.show_on_map
    --~ if p_data.show_on_map then
    if on_map then
      -- Keep valid entities on map
      --~ if on_map.entity and GCKI_vehicle.is_vehicle(on_map.entity) then
      if GCKI_vehicle.is_vehicle(on_map.entity) then
        GCKI.writeDebug("Keeping %s on map for player %s!",
                        {GCKI.argprint(on_map.entity), p})
      -- Remove show_on_map from player data and close GUI
      else
        GCKI.writeDebug("Closing map of player %s!", {p})
        GCKI_gui_player_vehicles_map.close_gui(p, {
          keep_gui = keep_gui,
          skip_event_check = skip_event_check,
        })
        cnt = cnt + 1
      end
    end
  end
  GCKI.writeDebug("Removed %s vehicle(s) from map GUI!", {cnt})

  GCKI.entered_function("leave")
  return cnt
end


------------------------------------------------------------------------------------
--                         REMOVE DATA OF INVALID PLAYERS                         --
------------------------------------------------------------------------------------
-- Returns number of invalid players
cleanup.invalid_players = function()
  GCKI.entered_function()

  local removed_players = 0
  local keep = {}
  local player

  -- Remove data of invalid players
  for p, p_data in pairs(mod.player_data or {}) do
GCKI.show(p, p_data)
    --~ player = game.players[p]
    player = GCKI.ascertain_player(p)
    if player and player.valid then
      GCKI.writeDebug("Keeping data of %s.", {GCKI.argprint(player)})
      keep[p] = util.table.deepcopy(p_data)
    else
      GCKI.writeDebug("Removing data of invalid player %s!", {p})
      GCKI_player.remove_player(p, {skip_event_check = true})
      removed_players = removed_players + 1
    end
  end

  mod.player_data = util.table.deepcopy(keep)
  GCKI.writeDebug("mod.player_data: removed %s, kept %s players",
                  {removed_players, table_size(keep)})

  GCKI.entered_function("leave")
  return removed_players
end


------------------------------------------------------------------------------------
--    REMOVE VEHICLES WE DON'T CARE ABOUT OR INVALID VEHICLES FROM PLAYER DATA    --
------------------------------------------------------------------------------------
-- Returns number of removed vehicles
cleanup.player_data = function(flags)
  GCKI.entered_function({flags})

  GCKI.assert(flags, {"table", "nil"}, "table of flags or nil")
  --~ local keep_gui = flags and flags.keep_gui
  --~ local skip_event_check = flags and flags.skip_event_check


  -- If any vehicles are removed from these tables in a player's data, the GUIs must
  -- be rebuilt, so we reset the counter.
  local removed_vehicles = cleanup_locked_or_owned(flags) +
                            cleanup_selected_vehicles(flags)

  -- If a vehicle shown on camera or map of a player has become invalid, we'll close
  -- camera/map unless there is a message rendered on the ground about the vehicle.
  --~ cleanup_show_on_camera(flags)
  cleanup.show_on_camera(flags)
  cleanup.show_on_map()

  --~ -- Do we still need GUI events?
  --~ if skip_event_check then
    --~ GCKI.writeDebug("Skipping check for GUI events!")
  --~ else
    --~ GCKI.writeDebug("Checking whether we need GUI events!")
    --~ GCKI_events.helper.need_gui_events()
  --~ end



  GCKI.entered_function("leave")
  return removed_vehicles
end


------------------------------------------------------------------------------------
--         REMOVE DATA STORED FOR FORCES WITHOUT PLAYERS/SUSPENDED PLAYERS        --
------------------------------------------------------------------------------------
--~ cleanup.force_data = function(flags)
  --~ GCKI.entered_function({flags})

  --~ GCKI.assert(flags, {"table", "nil"}, "table of flags or nil")
cleanup.force_data = function()
  GCKI.entered_function()

  --~ local keep_gui = flags and flags.keep_gui
  --~ local skip_event_check = flags and flags.skip_event_check

  local f_data
  local cnt_init, cnt_removed = 0, 0

  local flags = {skip_event_check = true,}

  for f_name, force in pairs(game.forces) do
    f_data = mod.force_data[f_name]

    -- If we have data for this force, check whether we must remove it
    GCKI.writeDebugNewBlock("Do we have data for %s?", {GCKI.argprint(force)})
    if f_data then
      GCKI.writeDebug("Yes!")
      if GCKI_force.remove_force_data(force, flags) then
        cnt_removed = cnt_removed + 1
      end
    --~ -- Ignore forces created by "Blueprint Sandboxes"!
    --~ elseif GCKI.prefixed(f_name, GCKI.BPS_force_name_prefix) then
      --~ GCKI.writeDebug("No. Ignoring %s (created by Blueprint Sandboxes)!",
                      --~ {GCKI.argprint(force)})

    -- Initialize data if the force has connected players.
    else
      GCKI.writeDebug("No. Trying to initialize data!")
      if GCKI_force.init_force_data(force, flags) then
        cnt_init = cnt_init + 1
      end
    end
  end
  GCKI.writeDebug("Initialized data for %s forces!", {cnt_init})
  GCKI.writeDebug("Removed data of %s forces!", {cnt_removed})

  GCKI.entered_function("leave")
end


------------------------------------------------------------------------------------
--           RELEASE CUSTOM NAMES GIVEN TO VEHICLES WE DON'T CARE ABOUT           --
------------------------------------------------------------------------------------
--~ -- Returns number of removed vehicles, or nil if all vehicles are still valid!
-- Returns number of removed vehicles
cleanup.named_vehicles = function(flags)
  GCKI.entered_function({flags})

  GCKI.assert(flags, {"table", "nil"}, "flags or nil")
  local keep_gui          = flags and flags.keep_gui
  local skip_event_check  = flags and flags.skip_event_check

  local cnt = 0
  local keep, vehicle, name_rendering, args

  local named = mod.named_vehicles

  local passon_flags = {removed_prototype = true, keep_gui = true}


  -- Clean up named.by_id
  for v_id, v_data in pairs(named and named.by_id or {}) do
GCKI.show(v_id, v_data)
    keep = nil
    vehicle = v_data.entity

    if vehicle and vehicle.valid then
      -- We'll keep the names of vehicles vehicles that are temporarily unavailable,
      -- e.g. if loaded onto a vehicle wagon. We'll also keep vehicles of prototypes
      -- supported by GCKI.
      if v_data.not_available or GCKI_vehicle.is_vehicle(vehicle) then
        GCKI.writeDebug("Keep name %s from %s!",
                        {GCKI.argprint(v_data.name), GCKI.argprint(vehicle)})
        keep = true

      -- We'll keep the names of vehicles named by other mods, even if they are of a
      -- prototype not supported by GCKI.
      elseif AUTODRIVE and mod.AD_prototypes[vehicle.name] then
        GCKI.writeDebug("Asking AUTODRIVE if custom name is used there!")
        keep = GCKI.remote_call(AUTODRIVE_NAME, "get_custom_name", vehicle, script.mod_name)

      -- Remove name otherwise!
      else
        GCKI.writeDebug("Must remove name %s from %s!",
                        {GCKI.argprint(v_data.name), GCKI.argprint(vehicle)})
      end
    end

    -- We want to keep the name, make sure the vehicle has a valid name rendering!
    if keep then
      GCKI.writeDebug("Will keep name %s of %s. Checking if rendering is valid!",
                      {GCKI.argprint(v_data.name), GCKI.argprint(vehicle)})

        --~ name_rendering = v_data.render_text_id
        --~ name_rendering = v_data.render_text_id and
                          --~ rendering.get_object_by_id(v_data.render_text_id)
        name_rendering = GCKI.ascertain_rendering(v_data.render_text_id)
        --~ if not (name_rendering and rendering.is_valid(name_rendering)) then
        if not (name_rendering and name_rendering.valid) then
          GCKI.writeDebug("Must restore rendering of custom name!")

          args = {
            player = v_data.named_by,
            vehicle = vehicle,
            new_name = v_data.name,
            restore = true,
            keep_gui = keep_gui,
          }
          GCKI_vehicle.edit_vehicle_name(args, script.mod_name)
        end

    -- Remove vehicle from list of named vehicles
    else
      GCKI.writeDebug("Trying to remove name %s from %s!",
                      {GCKI.argprint(v_data.name), GCKI.argprint(vehicle)})
      --~ passon_flags = {removed_prototype = true, keep_gui = true}
      GCKI_vehicle.remove_vehicle_name(v_id, script.mod_name, passon_flags)
      cnt = cnt + 1
    end
  end
  GCKI.writeDebug("Removed %s vehicle(s) from named_vehicles.by_id!", {cnt})


  -- Clean up named.by_name
  local names_cnt = 0
  for v_name, v_id in pairs(named and named.by_name or {}) do
GCKI.show(v_name, v_id)
    if not named.by_id[v_id] then
      GCKI.writeDebug("Removed obsolete custom name %s!", {GCKI.enquote(v_name)})
      named.by_name[v_name] = nil
      names_cnt = names_cnt + 1
    end
  end
  GCKI.writeDebug("Removed %s vehicle(s) from named_vehicles.by_name!", {names_cnt})


  -- Rebuild GUIs if at least one vehicle has been removed
  if keep_gui then
    GCKI.writeDebug("Flag \"keep_gui\" has been set, keeping GUIs!")

  elseif cnt == 0 then
    GCKI.writeDebug("No vehicle has been removed, keeping GUIs!")

  else
    GCKI.writeDebug("Removed %s vehicle(s) from tables. Must rebuild GUIs!", {cnt})
    GCKI_gui.init_guis()
  end

  GCKI.entered_function("leave")
  return cnt
end


------------------------------------------------------------------------------------
--      REMOVE DELETED/INVALID VEHICLES FROM LIST OF ORIGINAL VEHICLE COLORS      --
------------------------------------------------------------------------------------
-- Returns number of removed vehicles
cleanup.vehicles_orig_color = function()
  GCKI.entered_function({})

  local cnt = 0
  local keep = {}
  local vehicle

  for v_id, v_data in pairs(mod.vehicles_orig_color or {}) do
GCKI.show(v_id, v_data)
    vehicle = v_data.entity

    -- Keep vehicle: We still care about the prototype and the entity is valid
    if GCKI_vehicle.is_vehicle(vehicle) then
      keep[v_id] = util.table.deepcopy(v_data)
      GCKI.writeDebug("Keeping entry of %s!", {GCKI.argprint(vehicle)})

    -- Remove vehicle from list
    else
      cnt = cnt + 1
      local reason

      -- We don't care about this prototype anymore, but the entity is still valid
      if vehicle and vehicle.valid then
        reason = "Not a valid prototype"
        -- Restore original color?
        GCKI_vehicle.color_vehicle(vehicle)
      -- No vehicle or entity is invalid
      else
        reason = vehicle and "Not a valid entity" or "No vehicle"
      end
      GCKI.writeDebug("%s: removing entry of vehicle %s!", {reason, v_id})
    end
  end
  mod.vehicles_orig_color = util.table.deepcopy(keep)
  GCKI.writeDebug("Removed %s obsolete entries from mod.vehicles_orig_color!",
                  {cnt})

  GCKI.entered_function("leave")
  return cnt
end


------------------------------------------------------------------------------------
--          REMOVE OBSOLETE DATA STORED FOR AUTODRIVE IF IT ISN'T ACTIVE          --
------------------------------------------------------------------------------------
cleanup.Autodrive_data = function()
  GCKI.entered_function()

  local proto_list = mod.AD_prototypes
  local cnt = 0

  -- If AUTODRIVE is active, are vehicles for which we have stored its data still a
  -- prototype supported by it?
  if AUTODRIVE then
    GCKI.writeDebugNewBlock("Checking vehicle list for obsolete Autodrive data?")
    local vehicle

    -- This only makes sense if we have a list of valid GCKI prototypes!
    if proto_list then
      GCKI.writeDebug("Yes!")
      for v, v_data in pairs(mod.GCKI_vehicles) do
        vehicle = v_data.entity
        if vehicle and vehicle.valid and not proto_list[vehicle.name] then
          GCKI.writeDebug("Autodrive doesn't support prototype of %s. Remove data?",
                        {GCKI.argprint(vehicle)})
          if v_data.Autodrive_owner then
            GCKI.writeDebug("Removing Autodrive owner!")
            v_data.Autodrive_owner = nil
            cnt = cnt + 1
          end
        end
      end
      GCKI.writeDebug("Removed Autodrive data from %s vehicles!", {cnt})
    else
      GCKI.writeDebug("No! Don't have a list of prototypes supported by Autodrive!")
    end

  -- If Autodrive has been removed, remove list of its prototypes as well as  the
  -- data stored with our vehicles.
  else
    GCKI.writeDebug("Autodrive is not active. Removing obsolete data!")
    for v, v_data in pairs(mod.GCKI_vehicles) do
      if v_data.Autodrive_owner then
        v_data.Autodrive_owner = nil
        cnt = cnt + 1
        GCKI.writeDebug("Removed mod.vehicles[%s].Autodrive_owner!", {v})
      end
    end
    GCKI.writeDebug("Removed Autodrive data from %s vehicles!", {cnt})

    if proto_list then
      mod.AD_prototypes = nil
      GCKI.writeDebug("Removed mod.AD_prototypes!")
    end

  end

  GCKI.entered_function("leave")
end

------------------------------------------------------------------------------------
--      Make sure our list contains only vehicles that are valid entities and     --
--      not based on a blacklisted prototype. Also reset all invalid entities!    --
------------------------------------------------------------------------------------
cleanup.cleanup_all_vehicle_lists = function(flags)
  GCKI.entered_function({flags})

  GCKI.assert(flags, {"table", "nil"}, "nil or table of flags")
  --~ local reset_filters = flags and flags.reset_filters

  local pass_on_flags = {
    keep_gui = true,
    skip_event_check = true,
  }

  -- If we remove any vehicle(s) from at least one list, or if at least one player
  -- has become invalid, we must rebuild the GUIs, event filters etc.
  local change_cnt = cleanup.player_data(pass_on_flags) +
                      cleanup.invalid_players(pass_on_flags) +
                      cleanup.named_vehicles(pass_on_flags) +
                      cleanup.GCKI_vehicles(pass_on_flags)
  GCKI.writeDebug("Cleaned vehicle lists that affect GUIs! (%s changes)",
                  {change_cnt})

  -- Clean up the list with the original colors of ALL vehicles (including those
  -- that have not been claimed or locked)
  GCKI.writeDebug("Cleaned list of original vehicle colors (%s changes)",
                  {cleanup.vehicles_orig_color()})

  -- Remove obsolete data if Autodrive has been removed
  GCKI.writeDebug("Looking for obsolete Autodrive data!")
  cleanup.Autodrive_data()

  -- We can leave if nothing has changed!
  if change_cnt == 0 then
    GCKI.entered_function({}, "leave", "Nothing changed!")
    return
  end

  -- Rebuild GUIs of all players
  GCKI.writeDebug("Rebuilding GUIs of all players!")
  GCKI_gui.init_guis()


  GCKI.entered_function("leave")
end



------------------------------------------------------------------------------------
------------------------------------------------------------------------------------
--                              RELATED TO RENDERINGS                             --
------------------------------------------------------------------------------------
------------------------------------------------------------------------------------


------------------------------------------------------------------------------------
--                 REMOVE RECORDS OF EXPIRED ON-GROUND RENDERINGS                 --
------------------------------------------------------------------------------------
cleanup.ground_renderings = function(player)
  GCKI.entered_function({player})

  player = GCKI.ascertain_player(player)

GCKI.show("mod.player_messages", mod.player_messages)

  local function check_renderings(tab, p_index)
    local render_object

    for m, message in pairs(tab or {}) do
      --~ r = message.ID and rendering.get_object_by_id(message.ID)
      render_object = GCKI.ascertain_rendering(message.ID)
      --~ if not rendering.is_valid(message.ID) then
      if not render_object and render_object.valid then
        mod.player_messages[p_index].render[m] = nil
        GCKI.writeDebug("Removed entry for invalid rendering %s!", {message.ID})
      end
    end
  end

  -- Single player
  if player and player.valid then
    GCKI.writeDebug("Looking for records of expired renderings for %s …",
                    {GCKI.argprint(player)})
    local p = player.index
    local tab = mod.player_messages[p] and mod.player_messages[p].render
    check_renderings(tab, p)

  -- All players
  else
    GCKI.writeDebug("Looking for records of expired renderings for all players!")
    for p, p_messages in pairs(mod.player_messages) do
      -- mod.player_messages contains the lists of each player's flying-text and
      -- rendered messages, plus a list "ticks". We must skip the latter!
      if p ~= "ticks" then
        GCKI.writeDebug("Checking renderings of player %s:", {p})
        check_renderings(p_messages.render, p)
      end
    end
  end

  GCKI.entered_function("leave")
end


------------------------------------------------------------------------------------
--                REMOVE RECORDS OF EXPIRED CUSTOM-NAME RENDERINGS                --
------------------------------------------------------------------------------------
cleanup.customname_renderings = function()
  GCKI.entered_function()

  local named = mod.named_vehicles
  --~ local vehicle, r, r_id, args
  local vehicle, args, render_object

  for v, v_data in pairs(named and named.by_id or {}) do
GCKI.show("v", v)
GCKI.show("v_data", v_data)
    vehicle = v_data.entity

    -- Keep custom names of vehicles that have been temporarily removed (e.g. by
    -- Vehicle Wagons)
    if v_data.not_available then
      GCKI.writeDebug("Keeping reserved name of vehicle %s (not available).", {v})

    -- Valid vehicle. Is the rendering still valid?
    --~ if vehicle and vehicle.valid then
    elseif vehicle and vehicle.valid then
      --~ r_id = v_data.render_text_id
      --~ r = v_data.render_text_id and
          --~ rendering.get_object_by_id(v_data.render_text_id)
      render_object = GCKI.ascertain_rendering(v_data.render_text_id)
      --~ if not (r_id and rendering.is_valid(r_id)) then
      if not (render_object and render_object.valid) then
        GCKI.writeDebug("Must restore custom-name rendering for %s!",
                        {GCKI.argprint(vehicle)})
        args = {
          player = v_data.named_by,
          vehicle = vehicle,
          new_name = v_data.name,
        }
        GCKI_vehicle.edit_vehicle_name(args, script.mod_name)
      end

    --~ -- Keep custom names of vehicles that have been temporarily removed (e.g. by
    --~ -- Vehicle Wagons)
    --~ elseif v_data.not_available then
      --~ GCKI.writeDebug("Keeping reserved name of vehicle %s (not available).", {v})

    -- Remove custom names of other invalid vehicles
    else
      GCKI.writeDebug("Removing vehicle name of expired vehicle %s!", v)
      GCKI_vehicle.remove_vehicle_name(v, script.mod_name)
    end
  end

  GCKI.entered_function("leave")
end



------------------------------------------------------------------------------------
GCKI.entered_file("leave")
return cleanup
