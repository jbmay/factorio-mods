GCKI.entered_file()

local common_player = {}

------------------------------------------------------------------------------------
-- Adjust per-user runtime settings
local function adjust_user_settings(player, settings)
  GCKI.entered_function({player, settings})

  local index = common_player.get_player_index(player) or
                GCKI.arg_err(player, "player specification")

  settings = (type(settings) == "string" and {settings}) or
              (type(settings) == "table" and settings) or
              GCKI.arg_err(settings, "settings")

  local ps = mod.player_data[index].settings

  for s, setting in pairs(settings) do
GCKI.show(s, setting)
    -- Check debugging settings
    if setting == "debug_in_game" then
      GCKI.writeDebug("Adjusting setting \"debug_in_game\"!")
      GCKI.set_debug_in_game()

    -- Check flying_text settings
    elseif setting == "flying_text" then
      GCKI.writeDebug("Calling GCKI.set_flying_text()")
      GCKI.set_flying_text()

    -- Adjust render_time
    elseif setting == "render_time" then
      GCKI.writeDebug("Adjusting setting \"render_time\"!")
      ps[setting] = ps[setting] * 60

    --~ -- Adjust render_color
    --~ elseif setting == "render_color" then
      --~ ps[setting] = GCKI.colors[ps[setting]]
    end
  end
  GCKI.entered_function("leave")
end


--~ -- Check whether any of the unlock techs for the keys have been researched
--~ common_player.is_unlock_researched = function(force)
  --~ GCKI.entered_function({player})

  --~ player = GCKI.ascertain_player(player)
  --~ if not (player and player.valid) then
    --~ GCKI.arg_err(player, "player specification")
  --~ end


  --~ local ret, tech
  --~ local force = player.force
  --~ local techs = force.technologies

  --~ for tech_name, t in pairs(GCKI.unlock_tech_map) do
    --~ tech = techs[tech_name]
    --~ if tech and tech.researched then
        --~ ret = true
        --~ GCKI.writeDebug("Tech %s has been researched by %s!", {tech_name, GCKI.argprint(force)})
        --~ break
    --~ end
  --~ end


  --~ GCKI.entered_function("leave")
  --~ return ret
--~ end

------------------------------------------------------------------------------------
--                            INITIALIZE PLAYER SETTINGS                          --
------------------------------------------------------------------------------------
common_player.init_player = function(player, flags)
  GCKI.entered_function({player, flags})

  player = GCKI.ascertain_player(player)
  if not (player and player.valid) then
    GCKI.arg_err(player, "player specification")
  end

  GCKI.assert(flags, {"table", "nil"}, "nil or table or flags")
  local skip_event_check = flags and flags.skip_event_check

  -- Restore or create player data for connected players
  local player_id = player.index

  mod.player_data[player_id] = mod.player_data[player_id] or {}
  local p_data = mod.player_data[player_id]

  --~ global.force_data[player.force.name] = global.force_data[player.force.name] or {}
  --~ local f_data = global.force_data[player.force.name]
  GCKI_force.init_force_data(player.force)
  local f_data = mod.force_data[player.force.name]
GCKI.show("f_data", f_data)
  -- Restore or create list with render messages for connected players
  -- (Contains array of messages: {ID = id, TTL = time_to_live})
  local p_msgs
  mod.player_messages[player_id] = mod.player_messages[player_id] or {}
  p_msgs = mod.player_messages[player_id]
  p_msgs.flying = p_msgs.flying or {}
  p_msgs.render = p_msgs.render or {}

  -- Restore user settings
  GCKI.writeDebugNewBlock("Reading user settings!")
  common_player.get_user_settings(player_id)

  -- Show the shortcut?
  GCKI.writeDebugNewBlock("Check shortcut!")
  local unlock_shortcut = GCKI.is_unlock_tech_researched(player.force) or false
GCKI.show("unlock_shortcut", unlock_shortcut)

  player.set_shortcut_available(GCKI.shortcut_name, unlock_shortcut and GCKI_ownership.can_use(player))
  if f_data then
    f_data.show_shortcuts = unlock_shortcut
    GCKI.writeDebug("%sabled shortcut %s!",
                    {unlock_shortcut and "En" or "Dis",
                      GCKI.enquote(GCKI.shortcut_name)})
  end

  -- Do we need events for custom inputs?
  GCKI.writeDebugNewBlock("Check whether we need optional events for custom inputs!")
  GCKI_custom_input.helper.check_optional_events()


  -- Player will only have GUIs if the shortcut has been unlocked!
  if unlock_shortcut then
    GCKI.writeDebug("Check whether %s has GUIs!", {GCKI.argprint(player)})

    local pass_on_flags_init = {
      skip_event_check = skip_event_check
    }
    local pass_on_flags_close = {
      skip_event_check = skip_event_check,
      dont_create = true,
    }
    -- Initialize main GUI for vehicles claimed or locked by player
    local show_gui = p_data.locked_or_owned and true or false
    GCKI.writeDebug("Must %sable GUI for vehicles locked/owned by %s!",
                    {show_gui and "en" or "dis", GCKI.argprint(player)})
    if show_gui then
      --~ GCKI_gui_player_vehicles.init_gui(player_id)
      GCKI_gui_player_vehicles.init_gui(player_id, pass_on_flags_init)
    else
      --~ GCKI_gui_player_vehicles.close_gui(player)
      GCKI_gui_player_vehicles.close_gui(player, pass_on_flags_close)
    end

    -- Check toggle button!
    GCKI.writeDebug("Must %sable and %s GUI toggle button!",
                    {show_gui and "en" or "dis", show_gui and "show" or "hide"})
    GCKI_gui_player_vehicles.toggle_button_is_visible(player, show_gui)


    -- Initialize GUI for vehicles selected by player
    show_gui = p_data.selected_vehicles and true or false
    GCKI.writeDebug("Must %sable GUI for vehicles selected by %s!",
                    {show_gui and "en" or "dis", GCKI.argprint(player)})
    --~ if show_gui then
      --~ GCKI_gui_select_area.init_gui(player_id)
    --~ else
      --~ GCKI_gui_select_area.close_gui(player)
    --~ end
    if show_gui then
      GCKI_gui_select_area.init_gui(player_id, pass_on_flags_init)
    else
      GCKI_gui_select_area.close_gui(player, pass_on_flags_close)
    end

    -- Initialize GUI for vehicles shown on map
    local on_map = p_data.show_on_map
GCKI.show("on_map", on_map)
    show_gui = on_map and on_map.entity and on_map.entity.valid and true or false
    GCKI.writeDebug("Must %sable map GUI for %s!",
                    {show_gui and "en" or "dis", GCKI.argprint(player)})
    --~ if show_gui then
      --~ GCKI_gui_player_vehicles_map.init_gui(player_id)
    --~ else
      --~ GCKI_gui_player_vehicles_map.close_gui(player)
    --~ end
    if show_gui then
      GCKI_gui_player_vehicles_map.init_gui(player_id, pass_on_flags_init)
    else
      GCKI_gui_player_vehicles_map.close_gui(player, pass_on_flags_close)
    end

    -- Initialize GUI for vehicles shown on camera
    local on_cam = p_data.show_on_camera
GCKI.show("on_cam", on_cam)
    show_gui = on_cam and (on_cam.entity and on_cam.entity.valid) and true or false
    GCKI.writeDebug("Must %sable camera GUI for %s!",
                    {show_gui and "en" or "dis", GCKI.argprint(player)})
    --~ if show_gui then
      --~ GCKI_gui_player_vehicles_camera.init_gui(player_id)
    --~ else
      --~ GCKI_gui_player_vehicles_camera.close_gui(player)
    --~ end
    if show_gui then
      GCKI_gui_player_vehicles_camera.init_gui(player_id, pass_on_flags_init)
    else
      GCKI_gui_player_vehicles_camera.close_gui(player, pass_on_flags_close)
    end
  end

  -- Do we need GUI events?
  if skip_event_check then
    GCKI.writeDebug("Skipping check whether GUI events are necessary!")
  else
    GCKI.writeDebug("Checking whether we need GUI events!")
    GCKI_events.helper.need_gui_events()
  end

  GCKI.entered_function({player}, "leave")
end



------------------------------------------------------------------------------------
--                 CLEAN UP TABLES WHEN PLAYER IS REMOVED FROM GAME               --
------------------------------------------------------------------------------------
common_player.remove_player = function(player_or_id, flags) -- player: player.index or player entity
  GCKI.entered_function({player_or_id, flags})

  GCKI.assert(player_or_id, {"LuaPlayer", "number"}, "player specification")

  local player, player_id
  if type(player_or_id) == "number" then
    player_id = player_or_id
    --~ player = game.players[player_id]
    player = game.get_player(player_id)
  else
    player = player_or_id
    player_id = player.valid and player.index
  end

  GCKI.assert(flags, {"table", "nil"}, "nil or table of flags")

  if player_id then
    -- Get vehicle owned by player
    local v_owned = GCKI_ownership.all(player_id)
    -- Get vehicles locked by player
    local v_locked = mod.lockers[player_id]
    -- Get named vehicles
    local v_named = mod.named_vehicles.by_id

    local skip_event_check = flags and flags.skip_event_check
    local pass_on_flags = {
      keep_gui = true,
      skip_event_check = skip_event_check,
    }
    -- Set a flag in player data marking pending removal of player, so we can skip
    -- updating the player's GUIs!
    if mod.player_data[player_id] then
      mod.player_data[player_id].to_be_removed = true
      GCKI.writeDebug("Marked %s for removal!", GCKI.argprint(player))
    end

    local vehicle

    -- Remove list of player runtime settings
    -- (Moved to GCKI_player.remove_player()!)

    -- Remove player as owner of vehicle in list
    for id in pairs(v_owned) do
      vehicle = mod.GCKI_vehicles[id]
      if vehicle then
        GCKI.writeDebug("Player %s is no longer the owner of %s!",
                        {GCKI.argprint(player), GCKI.argprint(vehicle)})
        GCKI_vehicle.remove_vehicle_owner(id, player_id, pass_on_flags)
      end
    end

    -- Remove player as locker of vehicles in list and unlock vehicles
    for _, v in pairs(v_locked or {}) do
      vehicle = mod.GCKI_vehicles[v]
      GCKI_vehicle.lock_or_unlock(vehicle.entity, player)
      -- Remove vehicle from list if it has neither owner nor locker
      if GCKI_vehicle.must_remove_vehicle(v) then
        GCKI_vehicle.remove_vehicle(v, pass_on_flags)
      end
      GCKI.writeDebug("Unlocked %s locked by %s",
                      {GCKI.loc_name(vehicle), player.name})
    end

    -- Remove player as person who named a vehicle from list of named vehicles
    for v, v_data in pairs(v_named or {}) do
      if v_data.named_by and v_data.named_by == player_id then
        v_named[v].named_by = nil
        GCKI.writeDebug("Removed mod.named_vehicles.by_id[%s].named_by (named by player %s)",
                        {v, player_id})
      end
    end

    --  Remove messages rendered on the ground rendered for the player
    --~ for _, msg in pairs(mod.player_messages[player_id].render or {}) do
      --~ if msg.ID and rendering.is_valid(msg.ID) then
        --~ rendering.destroy(msg.ID)
        --~ GCKI.writeDebug("Destroyed message with ID %s rendered for player %s.", {msg.ID, player.name})
      --~ end
    --~ end
    local render_object
    for _, msg in pairs(mod.player_messages[player_id].render or {}) do
      --~ r = msg.ID and rendering.get_object_by_id(msg.ID)
      render_object = GCKI.ascertain_rendering(msg.ID)
      if render_object and render_object.valid then
        render_object.destroy()
        GCKI.writeDebug("Destroyed message with ID %s rendered for player %s.",
                        {msg.ID, player.name})
      end
    end

    -- Remove list of messages on the ground rendered for the player
    mod.player_messages[player_id] = nil
    GCKI.writeDebug("Removed list of messages rendered on the ground for player %s.", {player.name})

    -- Remove player data
    mod.player_data[player_id] = nil
    GCKI.writeDebug("Removed player_data of player %s.", {player_id})
  end

  GCKI.entered_function({player}, "leave")
end


------------------------------------------------------------------------------------
--         GIVE UP VEHICLES WHEN UNLOCK TECH IS REVERTED OR FORCE IS RESET        --
------------------------------------------------------------------------------------
common_player.give_up_vehicles = function(player) -- player: player.index or player entity
  GCKI.entered_function({player})

  player = GCKI.ascertain_player(player)
  if not (player and player.valid) then
    GCKI.arg_err(player, "player specification")
  end

  local p_data = mod.player_data[player.index]
GCKI.show("p_data", p_data)

  local flags = {
    keep_custom_name = true,
    remove_camera = true,
    skip_event_check = true,
  }

  for v_id, vehicle in pairs(p_data.locked_or_owned or {}) do
GCKI.writeDebug("Trying to remove %s!", {GCKI.argprint(vehicle)})
    GCKI_vehicle.remove_vehicle(vehicle, flags)
  end

  GCKI.entered_function("leave")
end


------------------------------------------------------------------------------------
--             SET FLAG TO SKIP NEXT EVENTS FOR CHANGED DRIVING STATE             --
--                         (Returns player entity or nil)                         --
------------------------------------------------------------------------------------
common_player.skip_driving_changed_state = function(event_data, events_to_skip)
  GCKI.entered_function({event_data, events_to_skip})
  -- The next x on_player_driving_changed_state events will be skipped for human
  -- occupants of vehicle!
  GCKI.assert(events_to_skip, "number", "integer")

  events_to_skip = math.floor(math.abs(events_to_skip))
GCKI.show("events_to_skip", events_to_skip)
GCKI.show("event_data", event_data)
  if event_data then
    local occupants = (event_data.driver or event_data.passenger) and {
                        driver = GCKI_vehicle.get_occupant_entity_data(event_data.driver),
                        passenger = GCKI_vehicle.get_occupant_entity_data(event_data.passenger)
                      }
GCKI.show("occupants", occupants)

    local player
    local vehicle = event_data.old_entity

    if vehicle and vehicle.valid then
      for role, occupant in pairs(occupants or
                                  GCKI_vehicle.get_occupants(vehicle) or {}) do
        player = occupant.is_player and occupant.index
        if player then
          mod.player_data[player].skip_state_change = events_to_skip
    GCKI.writeDebug("Must skip on_driving_state_changed %s times for %s (player %s)!",
                    {events_to_skip, role, player})
        end
      end
    end
  end
  GCKI.entered_function({event_data, events_to_skip}, "leave")
end




------------------------------------------------------------------------------------
--                              GET INDEX OF A PLAYER                             --
--                          (Returns player index or nil)                         --
------------------------------------------------------------------------------------
common_player.get_player_index = function(player)
  GCKI.entered_function({player})

  player = GCKI.ascertain_player(player)

  return player and player.valid and player.index
end


------------------------------------------------------------------------------------
--               RENDER MESSAGES TO A PARTICULAR PLAYER ON THE GROUND             --
------------------------------------------------------------------------------------
common_player.text_on_ground = function(args)
  GCKI.entered_function({args})

  if not (type(args) == "table" and next(args)) then
    GCKI.arg_err(args, "argument")
  end

  local player = GCKI.ascertain_player(args.players) or
                  GCKI.arg_err(args.players, "player specification")
  local ps = mod.player_data[player.index].settings
  --~ if player and global.player_data[player.index].settings.render_text then
  if player and ps and ps.render_text then

    local msg = args.text or GCKI.arg_err(args.text, "message text")
    --~ local vehicle = (args.vehicle and args.vehicle.valid) and args.vehicle or
                      --~ GCKI.arg_err(args.vehicle, "vehicle")
    local vehicle = args.vehicle
    if not (vehicle and vehicle.valid) then
      GCKI.arg_err(args.vehicle, "vehicle")
    end

    local p_data = mod.player_data[player.index]

    --~ local time_to_live = global.player_data[player.index].settings.render_time
    local time_to_live = ps and ps.render_time

    -- Render message on ground
    local id = rendering.draw_text{
      text            = msg,
      surface         = vehicle.surface,
      target          = vehicle.position,
      --~ color           = global.player_data[player.index].settings.render_color,
      color           = ps and ps.render_color,
      players         = {player},
      time_to_live    = time_to_live,
      alignment       = "center"
    }
    -- If recipient of the message is online, add the message to his list of messages
    if player.connected then
GCKI.writeDebug("Text to ground: %s is connected.", {player.name})
      table.insert(mod.player_messages[player.index].render, {ID = id, TTL = time_to_live})

    -- If recipient of the message is offline, add the message to his list and set its
    -- time_to_live to 0 (message won't expire)
    else
GCKI.writeDebug("Text to ground: %s is offline.", {player.name})
      table.insert(mod.player_messages[player.index].render, {ID = id, TTL = time_to_live})
      rendering.set_time_to_live(id, 0)
    end

    -- If the vehicle is shown on camera, add the rendering ID to player data
    local show_on_camera = p_data and p_data.show_on_camera
    if show_on_camera and show_on_camera.id == vehicle.unit_number then
GCKI.writeDebug("Text to ground: Adding ID to show_on_camera!")
      show_on_camera.related_rendering = id
    end

    -- Add rendering ID to data of players who have the vehicle on camera in Autodrive
    if GCKI_vehicle.is_Autodrive_vehicle(vehicle) then
      GCKI.writeDebug("Telling Autodrive to store rendering!")
      GCKI.remote_call(AUTODRIVE_NAME, "store_related_rendering",
                                        vehicle.unit_number, id, script.mod_name)
    else
      GCKI.writeDebug("Skipping remote call to Autodrive: %s is not supported!",
                      {GCKI.argprint(vehicle)})
    end

  end
  GCKI.entered_function({args}, "leave")
end


------------------------------------------------------------------------------------
-- REMOVE EXPIRED MESSAGES RENDERED ON THE GROUND FROM A PARTICULAR PLAYER'S LIST --
------------------------------------------------------------------------------------
common_player.remove_expired_text_on_ground = function(player) -- player: player.index or entity
  GCKI.entered_function({player})

  player = GCKI.ascertain_player(player)
  local player_id = player and player.index

  if player_id then
    local render_object
    for m, msg in ipairs (mod.player_messages[player_id].render) do
      --~ r = msg.ID and rendering.get_object_by_id(msg.ID)
      render_object = GCKI.ascertain_rendering(msg.ID)
      if not render_object and render_object.valid then
        GCKI.writeDebug("Removing message with id %s", {msg.ID})
        mod.player_messages[player_id].render[m] = nil
      end
    end
  end

  GCKI.entered_function({player}, "leave")
end


------------------------------------------------------------------------------------
-- Read per-user runtime settings
common_player.get_user_settings = function(player)
  GCKI.entered_function({player})

  player = GCKI.ascertain_player(player)
  if not (player and player.valid) then
    GCKI.arg_err(player, "player specification")
  end

  --~ local index = common_player.get_player_index(player) or
                --~ GCKI.arg_err(player, "player specification")
  local index = player.index
  --~ local player = game.players[index]
  local settings = {
    "debug_in_game",
    "flying_text",
    "show_hints",
    "render_text",
    "render_time",
    "render_color",
    "teleport_to_other_surface",
    "autoclaim_locked_vehicle",
    "guiclaim_locked_vehicle",
    "select_orientation_from",
  }
  mod.player_data[index].settings = {}
  local ps = mod.player_data[index].settings

  -- Read raw settings
  for s, setting in ipairs(settings) do
    ps[setting] = player.mod_settings["GCKI-"..setting].value
  end

  -- Adjust individual settings
  adjust_user_settings(index, settings)

  GCKI.entered_function({player}, "leave")
end


------------------------------------------------------------------------------------
-- Change one runtime-per-user setting
common_player.get_new_user_setting = function(player, setting)
  GCKI.entered_function({player, setting})

  player = GCKI.ascertain_player(player)
  if not (player and player.valid) then
    GCKI.arg_err(player, "player specification")
  end

  --~ local index = common_player.get_player_index(player) or
                  --~ GCKI.arg_err(player, "player specification")
  local index = player.index


  setting = type(setting) == "string" and string.match(setting, "^GCKI%-") and
              setting or
              GCKI.arg_err(setting, "setting")

  local var_name = string.gsub(setting, "^GCKI%-", "")

  -- Read raw setting
  mod.player_data[index].settings = mod.player_data[index].settings or {}
  --~ global.player_data[index].settings[var_name] = game.players[index].mod_settings[setting].value
  mod.player_data[index].settings[var_name] = player.mod_settings[setting].value
  -- We must convert render_time and render_color to the format used later on
  adjust_user_settings(index, var_name)

  GCKI.entered_function("leave")
end


------------------------------------------------------------------------------------
-- What is the maximum distance the player can reach?
common_player.get_player_reach = function(player)
  GCKI.entered_function({player})

  player = GCKI.ascertain_player(player)
  if not (player and player.valid) then
    GCKI.arg_err(player, "player_specification")
  end

  return mod.settings.long_reach and
          player.reach_distance or
          player.reach_distance - player.character_reach_distance_bonus
end


------------------------------------------------------------------------------------
-- Is the given position within player.reach_distance from player.position?
common_player.is_in_reach = function(player, position)
  GCKI.entered_function({player, position})

  player = GCKI.ascertain_player(player)
  if not (player and player.valid) then
    GCKI.arg_err(player, "player_specification")
  end

  local max_distance = common_player.get_player_reach(player)
  --~ return not common.distance_exceeds(player.position, position, max_distance)
  return not GCKI_calc.distance_exceeds(player.position, position, max_distance)
end


------------------------------------------------------------------------------------
GCKI.entered_file("leave")
return common_player
