GCKI.entered_file()

------------------------------------------------------------------------------------
------------------------------------------------------------------------------------
--                                 LOCAL DEFINITIONS                              --
------------------------------------------------------------------------------------
------------------------------------------------------------------------------------
-- Synchronize data with Autodrive (It's sufficient if one mod calls the sync
-- function! As GCKI will load after Autodrive, we sync from here.)
GCKI.show("AUTODRIVE", AUTODRIVE)
if AUTODRIVE then
  -- Synchronize custom names
  local args = mod.named_vehicles
  GCKI.writeDebug("Trying to synchronize custom names with Autodrive!")
  mod.named_vehicles = GCKI.remote_call(AUTODRIVE_NAME, "sync_names",
                                          args, script.mod_name)

  -- Synchronize original vehicle colors. The cleanup function will remove all the
  -- vehicles that are based on unsupported prototypes from the list.
  GCKI.writeDebug("Trying to synchronize original vehicle colors with Autodrive!")
  args = mod.vehicles_orig_color
  mod.vehicles_orig_color = GCKI.remote_call(AUTODRIVE_NAME, "sync_colors",
                                                args, script.mod_name)

  -- Exchange list of supported prototypes with Autodrive.
  GCKI.writeDebug("Exchanging list of supported prototypes with Autodrive!")
  local owned, locked = {}, {}
  owned = GCKI_ownership.all()
  for v_id, v_data in pairs(mod.GCKI_vehicles) do
    locked[v_id] = v_data.locker
  end
  args = {
    protos = mod.vehicle_prototypes.map,
    owned = owned,
    locked = locked
  }
  local AD_data = GCKI.remote_call(AUTODRIVE_NAME, "exchange_mod_data",
                                    args, script.mod_name)
  mod.AD_prototypes = util.table.deepcopy(AD_data.protos)

  for v_id, p in pairs(AD_data.owned or {}) do
    if mod.GCKI_vehicles and mod.GCKI_vehicles[v_id] then
      mod.GCKI_vehicles[v_id].Autodrive_owner = p
    end
  end

  GCKI.writeDebug("Cleaning Autodrive data!")
  GCKI_cleanup.Autodrive_data()
end


------------------------------------------------------------------------------------
-- Call different output functions (normal output, alerts, hints, rendering)
local function alert_player(player, vehicle, texts)

  if player and vehicle and type(texts) == "table" then
GCKI.writeDebug("Must output message!")
    if texts.msg then
      GCKI.output(player, texts.msg)
    end
    if texts.hint then
      GCKI.hint(player, texts.hint)
    end
    if texts.alert then
      local proto = GCKI_vehicle.is_vehicle(vehicle)
      local icon = {type = "item", name = proto.placeable_by}
      local show_on_map = true
      player.add_custom_alert(vehicle, icon, texts.alert, show_on_map)
    end
    if texts.render then
      GCKI_player.text_on_ground({
        text = texts.render,
        players = player,
        vehicle = vehicle,
      })
    end
  end
end


------------------------------------------------------------------------------------
-- Call different output functions (normal output, alerts, hints, rendering)
local function display_flying_text(tick, players)
  GCKI.entered_function({tick, players})
  tick = tick or game.tick

  local msg, queue, player
  local next_tick = tick + GCKI.FLYING_TEXT_DELAY

  -- Players that have messages scheduled for this tick
  for p_index, p in pairs(players) do
    -- Output the first message in the queue
    queue = mod.player_messages[p_index].flying
    msg = table.remove(queue, 1)

    if msg then
      player = game.get_player(p_index)
      player.create_local_flying_text({
        text = msg,
        position = player.position,
        create_at_cursor = false,
        time_to_live = GCKI.FLYING_TEXT_TTL,
        speed = 1
      })
    end

    -- If there are any more messages, we want to schedule them at next_tick.
    if next(queue) then
      GCKI.writeDebug("Scheduling more for next tick!")
      -- We don't want messages to be sent too fast (readability!), so we remove
      -- any ticks between now and next_tick from the table.
      for t = tick + 1, next_tick - 1 do
        if mod.player_messages.ticks[t] then
          mod.player_messages.ticks[t][p_index] = nil
          GCKI.writeDebug("Removed player %s from scheduled tick %s!", {p_index, t})
          -- Remove that tick from table if the last player was removed
          if not next(mod.player_messages.ticks[t]) then
            mod.player_messages.ticks[t] = nil
            GCKI.writeDebug("Removed tick %s from mod.player_messages.ticks!", {t})
          end
        end
      end
      mod.player_messages.ticks[next_tick] = mod.player_messages.ticks[next_tick] or
                                            {}
      mod.player_messages.ticks[next_tick][p_index] = true
    end
  end

  -- Remove tick from ticks table
  mod.player_messages.ticks[tick] = nil

  GCKI.entered_function({tick}, "leave")
end



------------------------------------------------------------------------------------
--              EJECT PLAYERS AND REMOVE DUMMIES FROM LOCKED VEHICLES             --
------------------------------------------------------------------------------------
local function eject_players(vehicle, occupants)
  GCKI_vehicle.enforce_vehicle_lock(vehicle)
  GCKI_vehicle.color_vehicle(vehicle)
  GCKI_vehicle.set_shooter(vehicle)
end


------------------------------------------------------------------------------------
--    OWNED VEHICLE WAS DESTROYED/REMOVED BUT PLAYER STILL HAS LOCKED VEHICLES    --
------------------------------------------------------------------------------------
local function claim_locked_when_owned_removed(player)
  GCKI.entered_function({player})

  player = GCKI.ascertain_player(player)
  if not (player and player.valid) then
    GCKI.arg_err(player, "player specification")
  end
GCKI.show("player", GCKI.argprint(player))

  local p = player.index
  local p_data = mod.player_data[p]

  --~ local vehicle

  -- Player must have locked vehicles and must not own one
  if p_data.locked_or_owned and not GCKI_ownership.find(p, player.surface) then
    local candidates = {}
    for id, vehicle in pairs(p_data.locked_or_owned) do
      if vehicle.valid and GCKI_ownership.scope(vehicle.surface) ==
          GCKI_ownership.scope(player.surface) then candidates[id] = vehicle end
    end
    local num = table_size(candidates)
    GCKI.writeDebug("%s has lost claimed vehicle but has %s locked vehicles left!",
                    {GCKI.argprint(player), num})

    -- Automatically claim the only locked vehicle left the player still has
    if num == 1 and p_data.settings.autoclaim_locked_vehicle then
      GCKI.writeDebug("Player automatically claims the last locked vehicle!")

      local _, vehicle = next(candidates)
      GCKI_vehicle.add_vehicle_owner(vehicle, player, {keep_color = true})

    -- Show GUI so player can claim one of his locked vehicles
    elseif num > 0 and p_data.settings.guiclaim_locked_vehicle then
      GCKI.writeDebug("Must show GUI so player can claim a locked vehicle!")

      local gui_names = GCKI_gui_names.player_vehicles
      local gui = player.gui.screen[gui_names.frames.main]
      if gui and gui.valid and not gui.visible then
        GCKI.writeDebug("Will unhide %s!", {GCKI.argprint(gui)})
        gui.visible = true
      end
    end
  end

  ------------------------------------------------------------------------------------
  GCKI.entered_function("leave")
end


------------------------------------------------------------------------------------
--       Our keys have been used. Did we select an area or click an entity?       --
------------------------------------------------------------------------------------
local function player_selected_area(event_data)
  GCKI.entered_function(event_data)

  local item = event_data.item

  -- Only continue if our car-key selection tool was used!
  if item ~= GCKI.carkey_name then
    GCKI.entered_function({}, "leave", "wrong selection tool")
    return
  end


  local player = game.get_player(event_data.player_index)
  if not GCKI_ownership.can_use(player, true) then return end
  local p_data = mod.player_data[player.index]

  -- Car-key selection tool was used
  if item == GCKI.carkey_name then

    local area = event_data.area
    local lt = GCKI.normalize_position(area.left_top)
    local rb = GCKI.normalize_position(area.right_bottom)

    -- A click should be registered when left_top and right_bottom are at the same
    -- position. However, I've found that I sometimes slip with the mouse while
    -- clicking, and select a tiny area, so the condition isn't met. Therefore, it
    -- makes sense to allow for a small deviation, measured by "tolerance".
    local dx, dy = math.abs(lt.x - rb.x), math.abs(lt.y - rb.y)
    local tolerance = 0.25
GCKI.show("dx", dx)
GCKI.show("dy", dy)
GCKI.show("dx <= tolerance", dx <= tolerance)
GCKI.show("dy <= tolerance", dy <= tolerance)

    -- Mode depends on which event has been raised and whether the player selected
    -- an area or clicked on the surface.
    -- Click (rotation/no rotation may be reversed by setting):
    --   on_player_selected_area:         summon (no rotation), claim, toggle lock
    --   on_player_alt_selected_area:     summon (with rotation), claim, toggle lock
    -- Area:
    --   on_player_selected_area:         select vehicles
    --   on_player_alt_selected_area:     add vehicles to selection
    --   on_player_reverse_selected_area: remove vehicles from selection
    -- Depending on a per-user setting, the behaviour for Click may be inverted!
    local mode

    -- Player clicked somewhere: Claim, (un)lock, or summon an individual vehicle!
    if (dx <= tolerance) and (dy <= tolerance) then
      GCKI.writeDebug("%s clicked on position!", {GCKI.argprint(player.name)})
      local position = {lt.x + dx/2, lt.y + dy/2}
      GCKI.show("Selected position", position)

      if p_data.settings.select_orientation_from == "vehicle" then
        GCKI.writeDebug("Setting \"use_player_orientation\" has default value!")
        mode = event_data.alt_select and "use_player_orientation"
      else
        GCKI.writeDebug("Setting \"use_player_orientation\" has been changed!")
        mode = (not event_data.alt_select) and "use_player_orientation" or nil
      end
GCKI.show("mode", mode)

      GCKI_events.used_key.key_on_position(player, position, mode, {
        selected = player.selected,
        entities = event_data.entities,
      })

    -- Player selected an area: Display GUI if at least one vehicle is selected!
    elseif next(event_data.entities) then
      mode = (event_data.alt_select and "add") or
              (event_data.reverse_select and "remove")
GCKI.show("mode", mode)
      GCKI_gui.vehicles_selected_area(player, event_data.entities, mode)
    end
  end

  GCKI.entered_function("leave")
end


local common_events = {}
common_events.helper = {}
local helper = common_events.helper


------------------------------------------------------------------------------------
------------------------------------------------------------------------------------
--       HELPER FUNCTIONS NEEDED FOR DRIVING STATE CHANGED AND BUILT EVENTS       --
------------------------------------------------------------------------------------
------------------------------------------------------------------------------------
-- Check whether "driver" or "passenger" is a player
helper.assert_role = function(data, role)
  GCKI.entered_function({data, role})
  return data and role and data[role] and data[role].is_player
end

-- Check whether vehicle is a valid entity controlled by GCKI
helper.assert_vehicle = function(id)
  GCKI.entered_function({id})
  return id and mod.GCKI_vehicles[id] and mod.GCKI_vehicles[id].entity and
          mod.GCKI_vehicles[id].entity.valid
end

--~ -- Enable listeners for optional events
--~ helper.add_optional_event = function(event_id, event_handler)
  --~ GCKI.entered_function({event_id, event_handler})

  --~ local name = GCKI.event_names[event_id]
  --~ script.on_event(event_id, event_handler)

  --~ global.enable_optional_events[name] = true
  --~ GCKI.writeDebug("Enabled event %s.", {name})

  --~ GCKI.entered_function("leave")
--~ end


-- Enable listeners for multiple optional events
-- event_list: array of event IDs or names, e.g. {ID1, NAME2, …}
helper.enable_optional_events = function(event_list)
  GCKI.entered_function({event_list})

  -- Events can be passed on as event ID or as event name. We need the id to turn on
  -- the event handler, and we store the event names in the global table for better
  -- readability.
  local name, id, is_string

  for e, e_name in pairs(event_list or {}) do
    is_string = (type(e_name) == "string")
    id    = is_string and defines.events[e_name] or e_name
    name  = is_string and e_name or GCKI.e_name_names[e_name]

    script.on_event(id, common_events[e_name])
    mod.enable_optional_events[name] = true
    GCKI.writeDebug("Enabled handler for event %s", {GCKI.enquote(name)})
  end

  GCKI.entered_function("leave")
end



------------------------------------------------------------------------------------
-- Disable listeners for optional events
-- event_list: {ID1, ID2, …}
helper.disable_optional_events = function(event_list)
  GCKI.entered_function({event_list})

  GCKI.assert(event_list, {"table", "number", "string"})

  event_list = type(event_list) == "table" and event_list or {event_list}

  -- Events can be passed on as event ID or as event name. We need the event IDs
  -- to turn off the event, and we store the event names in the global table for
  -- better readability.
  local id, name, is_string

  for e, event in pairs(event_list) do
    is_string = (type(event) == "string")
    id    = is_string and defines.events[event] or event
    name  = is_string and event or GCKI.event_names[event]

    script.on_event(id, nil)
    mod.enable_optional_events[name] = nil
    GCKI.writeDebug("Disabled handler for event \"%s\"", {name})
  end

  GCKI.entered_function("leave")
end

-- Check whether we must enable optional events
helper.check_optional_events = function()
  GCKI.entered_function()

  local enable, disable = {}, {}
  for e_name, e_state in pairs(mod.enable_optional_events or {}) do
    if e_state then
      GCKI.writeDebug("Adding event %s to table enable.", {GCKI.enquote(e_name)})
      table.insert(enable, e_name)
    else
      GCKI.writeDebug("Adding event %s to table disable.", {GCKI.enquote(e_name)})
      table.insert(disable, e_name)
    end
  end

GCKI.show("#enable", #enable)
GCKI.show("#disable", #disable)
  if next(enable) then
    GCKI.writeDebug("Must enable %s events!", #enable)
    helper.enable_optional_events(enable)
  end

  if next(disable) then
    GCKI.writeDebug("Must disable %s events!", #disable)
    helper.disable_optional_events(disable)
  end

  GCKI.entered_function("leave")
end

-- Check whether we must enable GUI events (at least one player needs a GUI)
helper.need_gui_events = function()
  GCKI.entered_function()

  local enable, force, p_data

  -- Check all forces for which we have data
  for f_name, f_data in pairs(mod.force_data) do

    -- Ignore force if shortcuts are not enabled for it!
    if f_data.show_shortcuts then
      force = game.forces[f_name]
      GCKI.writeDebug("%s has shortcuts enabled!", {GCKI.argprint(force)})

      -- Check data of all players on force
      for p, player in pairs(force.players) do
        if player.connected then
          GCKI.writeDebug("%s is connected. Checking player_data for open GUIs!",
                          {GCKI.argprint(player)})
          p_data = mod.player_data[p]
GCKI.show("p_data", p_data)

          -- Player needs GUI events if data for any GUI are stored
          if p_data and (p_data.locked_or_owned or p_data.selected_vehicles or
                          p_data.show_on_camera or p_data.show_on_map) then
GCKI.show("enable", enable)
            GCKI.writeDebug("%s needs GUI events!", {GCKI.argprint(player)})
            enable = true
            break
          end
        else
          GCKI.writeDebug("%s is not connected!", {GCKI.argprint(player)})
        end
      end
    end
  end

  -- Enable/disable GUI events?
  GCKI.writeDebug("%s GUI events!", {enable and "Need" or "Don't need"})
  if enable and not mod.show_guis then
    GCKI.writeDebug("Setting flag mod.show_gui!")
    mod.show_guis = true

    GCKI.writeDebug("Enabling GUI events!")
    helper.enable_optional_events(GCKI_event_lists.gui_events)

  elseif mod.show_guis and not enable then
    GCKI.writeDebug("Removing flag mod.show_gui!")
    mod.show_guis = nil

    GCKI.writeDebug("Disabling GUI events!")
    helper.disable_optional_events(GCKI_event_lists.gui_events)

  else
    GCKI.writeDebug("GUI events are already %sabled!", {enable and "en" or "dis"})
  end

  GCKI.entered_function("leave")
  return enable
end


-- Check whether we must enable shortcut events (at least one force must have
-- reserached the unlock tech)
helper.need_shortcut_events = function()
  GCKI.entered_function()

  local enable, f_data

  for f, force in pairs(game.forces) do
    if next(force.players) then
      GCKI.writeDebug("%s has %s players! Check whether it needs shortcuts!",
                      {GCKI.argprint(force), #force.players})
      f_data = mod.force_data[f]
GCKI.show("f_data", f_data)

      if f_data and f_data.show_shortcuts then
        GCKI.writeDebug("%s needs shortcut events!", {GCKI.argprint(force)})
        enable = true
GCKI.show("enable", enable)
        break
      end
    else
      GCKI.writeDebug("%s has no players!", {GCKI.argprint(force)})
    end
  end

  GCKI.writeDebug("Shortcut events are %s!",
                  {enable and "required" or "not required"})
  --~ if enable and not global.show_guis then
  local events

  if enable then
    GCKI.writeDebug("Enabling shortcut events!")
    events = GCKI_event_lists.shortcut_events
    helper.enable_optional_events(events)

    GCKI.writeDebug("Enabling custom input events!")
    events = GCKI_custom_input_lists.optional.need_vehicle
    GCKI_custom_input.helper.enable_optional_custom_inputs(events)

  --~ elseif global.show_guis and not enable then
  else
    GCKI.writeDebug("Disabling shortcut events!")
    events = GCKI_event_lists.shortcut_events
    helper.disable_optional_events(events)

    GCKI.writeDebug("Disabling custom input events!")
    events = GCKI_custom_input_lists.optional.need_vehicle
    GCKI_custom_input.helper.disable_optional_custom_inputs(events)
  end

  GCKI.entered_function("leave")
  return enable
end


-- Register custom events?
helper.register_custom_events = function()
  GCKI.entered_function()

  if GCKI.is_debug then
    GCKI.writeDebug("Debugging mode is on. Registering our own custom events!")

    for c, ce_name in pairs(GCKI.custom_events) do
GCKI.show(c, ce_name)
      script.on_event(defines.events[ce_name], common_events[ce_name])
      GCKI.writeDebug("Added handler for custom event \"%s\".", {ce_name})
    end
  end
  GCKI.entered_function("leave")
end


--~ -- Get custom events from other mods
--~ helper.get_custom_events_other_mods = function()
  --~ GCKI.entered_function()

  --~ -- Mods may give us a list of all their custom events. We use this function to
  --~ -- filter out just the custom events we're interested in (defined in control.lua,
  --~ -- in GCKI_event_lists.custom_events_other_mods).
  -- local check = function(event_name)
  --~ local listen_to_event = function(event_name)
--~ GCKI.entered_function({event_name})
    --for e, e_name in pairs(GCKI_event_lists.custom_events_other_mods) do
--~ GCKI.show(e, e_name)
      --~ if e_name == event_name then
--~ GCKI.writeDebug("Listening to %s!", {event_name})
        --~ return true
      --~ end
    --~ end
    --~ return GCKI.table_contains(GCKI_event_lists.custom_events_other_mods, event_name)
  --~ end

  --~ local events

  --~ local function check_mod_events(events, mod_name)
--~ GCKI.entered_function({events, mod_name})
--~ GCKI.show("events", events)
--~ GCKI.show("mod_name", mod_name)
    --~ for e_name, e in pairs(events or {}) do
--~ GCKI.show(e_name, e)
      --~ if listen_to_event(e_name) then
        --~ GCKI.writeDebug("Adding custom event \"%s\" from %s to GCKI.event_names!",
                      --~ {e_name, mod_name or "unknown mod"})
        --~ GCKI.event_names[e] = e_name
--~ GCKI.show("GCKI.event_names["..e.."]", GCKI.event_names[e])
--~ GCKI.show("common_events["..e_name.."]", common_events[e_name])
        --~ GCKI.writeDebug("Registering handler for event \"%s\"!", {e_name})
        --~ script.on_event(e, common_events[e_name])
      --~ end
    --~ end
  --~ end
  --~ local function check_mod_events(mod_name)
--~ GCKI.entered_function({mod_name})
--~ GCKI.show("mod_name", mod_name)
    --~ for e_name, e in pairs(events or GCKI.EMPTY_TAB) do
--~ GCKI.show(e_name, e)
      -- if listen_to_event(e_name) then
      --~ if GCKI.table_contains(GCKI_event_lists.custom_events_other_mods, e_name) then
        --~ GCKI.writeDebug("Adding custom event \"%s\" from %s to GCKI.event_names!",
                      --~ {e_name, mod_name or "unknown mod"})
      --  GCKI.event_names[e] = e_name
--~ GCKI.show("GCKI.event_names["..e.."]", GCKI.event_names[e])
--~ GCKI.show("common_events["..e_name.."]", common_events[e_name])
        --~ GCKI.writeDebug("Registering handler for event \"%s\"!", {e_name})
        -- script.on_event(e, common_events[e_name])
        --~ script.on_event(defines.events[e_name], common_events[e_name])
      --~ end
    --~ end
  --~ end


  --~ local mod_map = {
    --~ [AUTODRIVE_NAME] = {
      --~ interface = AUTODRIVE_NAME,
      --~ get_list = "get_custom_event_ids"
    --~ },
    --~ ["SpidertronWeaponSwitcher"] = {
      --~ interface = "SpidertronWeaponSwitcher",
      --~ get_list = "get_events"
    --~ },
    --~ ["CustomColor"] = {
      --~ interface = "CustomColor",
      --~ get_list = "get_event",
    --~ },
  --~ }

  --~ for mod_name, mod_data in pairs(mod_map) do
    --~ if script.active_mods[mod_name] then
      --~ GCKI.writeDebug("Looking for custom events of %s!", {GCKI.enquote(mod_name)})
      --~ events = GCKI.remote_call(mod_data.interface, mod_data.get_list)
      -- check_mod_events(events, mod_name)
      --~ check_mod_events(mod_name)
    --~ end
  --~ end

  --~ GCKI.entered_function("leave")
--~ end


-- Generate event filters for vehicle events
helper.make_event_filters = function()
  GCKI.entered_function()

  local ret = {}

  for proto_type, protos in pairs(mod.vehicle_prototypes.map or {}) do
GCKI.show(proto_type, protos)
    for proto_name, p in pairs(protos) do
      table.insert(ret, {filter = "name", name = proto_name})
    end
  end
GCKI.show("ret", ret)

  GCKI.entered_function("leave")
  return ret
end


-- Add filters to vehicle events!
helper.set_event_filters = function()
  GCKI.entered_function()

  local id

  local have_filters = mod.vehicle_prototypes and
                        mod.vehicle_prototypes.event_filters and
                        next(mod.vehicle_prototypes.event_filters)
GCKI.show("mod.vehicle_prototypes", mod.vehicle_prototypes)

  for e, event in pairs(GCKI_event_lists.filterable_vehicle_events) do
    id = defines.events[event]
--~ GCKI.show("ID for event "..GCKI.enquote(event), id)

    --~ if script.get_event_handler(id) then
      --~ script.set_event_filter(id, global.vehicle_prototypes.event_filters)
      --~ GCKI.writeDebug("Added filters to event \"%s\".", {event})
    --~ end
    if have_filters and script.get_event_handler(id) then
      script.set_event_filter(id, mod.vehicle_prototypes.event_filters)
      GCKI.writeDebug("Attached filters to event \"%s\".", {event})
    else
      script.set_event_filter(id, nil)
      GCKI.writeDebug("Detached filters from event \"%s\".", {event})
    end
  end

  GCKI.entered_function("leave")
end


----------------------------------------------------------------------------------
------------------------------------------------------------------------------------
--                                 EVENT HANDLERS                                 --
------------------------------------------------------------------------------------
------------------------------------------------------------------------------------



------------------------------------------------------------------------------------
--                                  INITIALIZE GAME                               --
------------------------------------------------------------------------------------
common_events.on_init = function(event)
  -- We will only have event data if this is called as script.on_init, not if the
  -- function is called from script.on_configuration_changed!
  if event then
    GCKI.entered_event(event)
  else
    GCKI.entered_function()
  end

  mod = storage

  local function init_table(tab_name)
    GCKI.assert(tab_name, "string")

    if not mod[tab_name] then
      mod[tab_name] = {}
      GCKI.writeDebug("Initialized mod.%s", {tab_name})
      return true
    else
      GCKI.writeDebug("Reusing mod.%s", {tab_name})
    end
  end


  -- Initialize prototype list of prototype name patterns
  init_table("vehicle_prototypes")
GCKI.show("mod.vehicle_prototypes", mod.vehicle_prototypes)

  --~ if event then
    --~ GCKI_prototypes.init_black_and_white_list()
--~ GCKI.show("global.vehicle_prototypes", global.vehicle_prototypes)
  --~ end

  -- Generate list of prototypes we care about
  mod.vehicle_prototypes.map = GCKI_prototypes.get_vehicle_prototypes_map()
  GCKI.writeDebug("Initialized mod.vehicle_prototypes.map")

  -- Generate event filters for vehicle events
  mod.vehicle_prototypes.event_filters = helper.make_event_filters()
  GCKI.writeDebug("Built filters for vehicle events")

  -- Add filters to vehicle events
  helper.set_event_filters()
  GCKI.writeDebug("Attached filters to vehicle events")


  -- Restore or create list of vehicles currently owned or locked by somebody
  -- (sorted by vehicle.unit_number)
  init_table("GCKI_vehicles")

  -- Restore or create lists of vehicles with a custom name
  if init_table("named_vehicles") then
    mod.named_vehicles = { by_id = {}, by_name = {} }
    GCKI.writeDebug("Initialized subtables of mod.named_vehicles")
  end

  -- Restore or create table for original colors of vehicles
  init_table("vehicles_orig_color")

  -- Restore or create list of players and the vehicles they own
  -- (sorted by player.index)
  init_table("owners")

  -- Restore or create list of players and the vehicles they have locked
  -- (sorted by player.index)
  init_table("lockers")

  -- Restore or create list with render messages for connected players
  -- (sorted by player index)
  init_table("player_messages")
  mod.player_messages.ticks = mod.player_messages.ticks or {}
  GCKI.writeDebug("Initialized mod.player_messages.ticks")

  -- Restore or create player data
  init_table("player_data")

  -- Restore or create list of enabled optional events
  init_table("enable_optional_events")

  -- Check whether we must enable any optional events
  GCKI.writeDebugNewBlock("Checking whether we must enable optional events!")
  helper.check_optional_events()

  -- Read startup settings
  GCKI.writeDebugNewBlock("Reading startup settings!")
  GCKI.get_startup_settings()

  -- Read map settings
  GCKI.writeDebugNewBlock("Reading mod map settings!")
  GCKI.get_global_settings()

  -- Check whether any player wants to see debug messages in the game
  GCKI.writeDebugNewBlock("Enable debugging in game?")
  GCKI.set_debug_in_game()

  -- If any player has flying-text messages enabled, we'll need the on_tick event
  GCKI.writeDebugNewBlock("Do any players want to get messages as flying text!")
  GCKI.set_flying_text()

  -- Force data (research state of unlock techs, enabled state of shortcut)
  init_table("force_data")

  -- Compatibility with other mods
  init_table("mod_compatibility")

  -- "Space Exploration"
  mod.mod_compatibility.SE = script.active_mods["space-exploration"] and
                                remote.interfaces["space-exploration"] and true
GCKI.show("mod.mod_compatibility.SE", mod.mod_compatibility.SE)

  -- "Uncle Shred's unminable vehicles"
  mod.mod_compatibility.UnminableVehicles =
                        GCKI.get_global_setting("unminable_vehicles_make_unminable")
  GCKI.show("mod.mod_compatibility.UnminableVehicles",
            mod.mod_compatibility.UnminableVehicles)



  -- Synchronize data with Autodrive (It's sufficient if one mod calls the sync
  -- function! As GCKI will load after Autodrive, we sync from here.)
GCKI.show("AUTODRIVE", AUTODRIVE)
  if AUTODRIVE then
    local args
    --~ -- Synchronize custom names
    --~ local args = mod.named_vehicles
    --~ GCKI.writeDebug("Trying to synchronize custom names with Autodrive!")
    --~ mod.named_vehicles = GCKI.remote_call(AUTODRIVE_NAME, "sync_names",
                                            --~ args, script.mod_name)

    --~ -- Synchronize original vehicle colors. The cleanup function will remove all the
    --~ -- vehicles that are based on unsupported prototypes from the list.
    --~ GCKI.writeDebug("Trying to synchronize original vehicle colors with Autodrive!")
    --~ args = mod.vehicles_orig_color
    --~ mod.vehicles_orig_color = GCKI.remote_call(AUTODRIVE_NAME, "sync_colors",
                                                  --~ args, script.mod_name)

    -- Exchange data with Autodrive.
    GCKI.writeDebugNewBlock("Exchanging data with Autodrive!")
    local owned, locked = {}, {}
    owned = GCKI_ownership.all()
    for v_id, v_data in pairs(mod.GCKI_vehicles) do
      locked[v_id] = v_data.locker
    end
    args = {
      protos = mod.vehicle_prototypes.map,
      owned = owned,
      locked = locked
    }
    local AD_data = GCKI.remote_call(AUTODRIVE_NAME, "exchange_mod_data",
                                      args, script.mod_name)
    mod.AD_prototypes = util.table.deepcopy(AD_data.protos)

    for v_id, p in pairs(AD_data.owned or {}) do
      if mod.GCKI_vehicles and mod.GCKI_vehicles[v_id] then
        mod.GCKI_vehicles[v_id].Autodrive_owner = p
      end
    end

    -- Synchronize custom names
    args = mod.named_vehicles
    GCKI.writeDebug("Trying to synchronize custom names with Autodrive!")
    mod.named_vehicles = GCKI.remote_call(AUTODRIVE_NAME, "sync_names",
                                            args, script.mod_name)

    -- Synchronize original vehicle colors. The cleanup function will remove all the
    -- vehicles that are based on unsupported prototypes from the list.
    GCKI.writeDebug("Trying to synchronize original vehicle colors with Autodrive!")
    args = mod.vehicles_orig_color
    mod.vehicles_orig_color = GCKI.remote_call(AUTODRIVE_NAME, "sync_colors",
                                                  args, script.mod_name)
    --~ GCKI.writeDebug("Cleaning Autodrive data!")
    --~ GCKI_cleanup.Autodrive_data()
  end

  GCKI.writeDebug("Cleaning Autodrive data!")
  GCKI_cleanup.Autodrive_data()


  -- Generate custom event IDs and register custom events
  GCKI.writeDebug("Registering custom events")
  helper.register_custom_events()

  --~ -- Register custom events from other mods. The events we're interested in are
  --~ -- listed in GCKI_event_lists.custom_events_other_mods (control.lua)
  --~ helper.get_custom_events_other_mods()

  ----------------------------------------------------------------------------------
  -- Register events for optional custom-inputs. The events we're interested in
  -- are listed in GCKI_custom_input_lists.optional (control.lua)
  GCKI.writeDebugNewBlock("Trying to register events for optional custom-inputs!")
  GCKI_custom_input.helper.check_optional_events()

  if event then
    GCKI.entered_event(event, "leave")
  else
    GCKI.entered_function("leave")
  end
end



------------------------------------------------------------------------------------
--                               LOAD EXISTING GAME                               --
------------------------------------------------------------------------------------
common_events.on_load = function(event)
  GCKI.entered_event(event)

  mod = storage

  -- Add filters to vehicle events
  if mod.vehicle_prototypes and mod.vehicle_prototypes.event_filters then
    GCKI.writeDebug("Attaching filters to vehicle events!")
    helper.set_event_filters()
  end

  -- Register optional events, if necessary
  helper.check_optional_events()
  helper.register_custom_events()

  --~ -- Register custom events from other mods. The events we're interested in are
  --~ -- listed in G_event_lists.custom_events_other_mods (control.lua)
  --~ helper.get_custom_events_other_mods()

  -- Register events for optional custom-inputs. The events we're interested in are
  -- listed in AD_event_lists.custom_input_events (control.lua)
  GCKI.writeDebugNewBlock("Trying to register events for optional custom-inputs!")
  GCKI_custom_input.helper.register_optional_custom_input_events()

  GCKI.entered_event(event, "leave")
end


------------------------------------------------------------------------------------
--                               CONFIGURATION CHANGED                            --
------------------------------------------------------------------------------------
common_events.on_configuration_changed = function(event)
  GCKI.entered_event(event)

  GCKI.writeDebug("Re-initializing tables!")
  common_events.on_init()
  GCKI.writeDebug("Returned from on_init!")

  -- Make sure we have all/only the force data we need
  GCKI.writeDebugNewBlock("Checking force data!")
  GCKI_cleanup.force_data({skip_event_check = true,})

  -- Make sure our list contains only vehicles that are valid entities and
  -- not based on a blacklisted prototype. Also reset all invalid entities!
  GCKI.writeDebugNewBlock("Removing entries for invalid vehicles from our tables!")
  GCKI_cleanup.cleanup_all_vehicle_lists()
  GCKI_ownership.reconcile()


  -- Make sure that CustomColor will ignore all car-based vehicles that have been
  -- claimed or locked
  do
    GCKI.writeDebugNewBlock("Compiling list of claimed or locked cars!")
    local vehicles = {}
    local vehicle
    for v, v_data in pairs(mod.GCKI_vehicles) do
      vehicle = v_data.entity
      if vehicle and vehicle.valid then
        if v_data.locker then
          GCKI_vehicle.lock_vehicle(vehicle)
          GCKI_vehicle.enforce_vehicle_lock(vehicle)
        end
        if vehicle.type == "car" then
          GCKI.writeDebug("Adding %s", {GCKI.argprint(vehicle)})
          table.insert(vehicles, v_data.entity)
        else
          GCKI.writeDebug("Ignoring %s", {GCKI.argprint(vehicle)})
        end
      end
    end

    GCKI.writeDebugNewBlock("Ask CustomColor to ignore vehicles?")
    if next(vehicles) then
      GCKI.writeDebug("Yes!")
      GCKI.remote_call("CustomColor", "block_vehicle", vehicles, script.mod_name)
    else
      GCKI.writeDebug("No: no vehicles found!")
    end
  end


  -- Remove all GUIs to force a rebuild
  GCKI.writeDebugNewBlock("Trying to remove GUIs of all players!")
  local button_flow, toggle_button

  local pass_on_flags = {
    skip_event_check = true,
    --~ skip_hint = true
  }
  for f, force in pairs(game.forces) do
    if next(force.players) then

      GCKI.writeDebug("Trying to remove GUIs of players on force %s",
                      {GCKI.enquote(f)})
      for g_name, g_data in pairs(GCKI_gui_names) do
        GCKI.writeDebug("Trying to remove GUI %s.", {GCKI.enquote(g_name)})
        GCKI_gui.remove_guis(force, g_data.frames.main, pass_on_flags)

        toggle_button = g_data.buttons and g_data.buttons.toggle_gui
        if toggle_button then
          for p, player in pairs(force.players) do
            button_flow = mod_gui.get_button_flow(player)

            if button_flow and button_flow[toggle_button] and
                                button_flow[toggle_button].valid then

              button_flow[toggle_button].destroy()
              GCKI.writeDebug("Removed toggle button of GUI %s for player %s!",
                              {GCKI.enquote(g_name), p})
            end
          end
        end
      end
    end
  end

  -- Inititalize players
  GCKI.writeDebugNewBlock("Trying to initialize player data!")
  for p, player in pairs(game.players) do
    GCKI_player.init_player(player, pass_on_flags)
  end


  -- Enable shortcut events?
  GCKI.writeDebugNewBlock("Checking shortcut events!")
  helper.need_shortcut_events()

  -- Enable GUI events?
  GCKI.writeDebugNewBlock("Checking GUI events!")
  helper.need_gui_events()

  -- Enable optional events?
  GCKI.writeDebugNewBlock("Checking optional events!")
  helper.check_optional_events()

  GCKI.entered_event(event, "leave")
end


------------------------------------------------------------------------------------
--                              RUNTIME SETTING CHANGED                           --
------------------------------------------------------------------------------------
common_events.on_runtime_mod_setting_changed = function(event)
  GCKI.entered_event(event)

  local player = event.player_index
  local setting = event.setting
GCKI.show("Changed settings", event)

  -- GCKI settings have been changed
  if GCKI.prefixed(setting, "GCKI-") then
    -- Change runtime-global settings
    if event.setting_type == "runtime-global" then
      GCKI.get_global_settings()
      GCKI.writeDebug("Changed global runtime settings!")
    -- Change runtime-per-user settings
    else
      GCKI_player.get_new_user_setting(player, setting)
      GCKI.writeDebug("Changed runtime user setting \"%s\" for %s.",
                      {setting, GCKI.argprint(player)})
    end

  -- Setting of "Uncle Shred's unminable vehicles" has been changed
  elseif setting == "unminable_vehicles_make_unminable" then

    mod.mod_compatibility.UnminableVehicles = settings.global[setting].value
    if not mod.mod_compatibility.UnminableVehicles then
      for id, v in pairs(mod.GCKI_vehicles) do
        GCKI.writeDebugNewBlock("Must %s be minable?", {GCKI.argprint(v)})
        -- Only locked vehicles are unminable
        if v.locker then
          GCKI.writeDebug("No: vehicle been locked. Making it unminable!")
          v.entity.minable_flag = false
        else
          GCKI.writeDebug("Yes: making vehicle minable!")
          v.entity.minable_flag = true
        end
      end
    end
  end

  GCKI.entered_event(event, "leave")
end


------------------------------------------------------------------------------------
--                                GENERATE NEW PLAYER                             --
------------------------------------------------------------------------------------
common_events.on_player_created = function(event)
  GCKI.entered_event(event)

  GCKI_player.init_player(event.player_index)

  GCKI.entered_event(event, "leave")
end

------------------------------------------------------------------------------------
--                            PLAYER (RE-)JOINED THE GAME                         --
------------------------------------------------------------------------------------
common_events.on_player_joined_game = function(event)
  GCKI.entered_event(event)

  local index = event.player_index

  GCKI.writeDebugNewBlock("Initializing data for player %s!", {index})
  GCKI_player.init_player(index)

  GCKI.writeDebugNewBlock("Does player %s have suspended rendered messages?",
                          {index})
  if mod.player_messages[index] and mod.player_messages[index].render then
    -- Set remaining time for messages on ground (keep msgs in table, they will be
    -- removed if they've become invalid next time the player disconnects)
    --~ local player = game.players[index]
    local player = GCKI.ascertain_player(index)
    GCKI.writeDebug("Yes! Trying to render messages for player %s.",
                    {GCKI.argprint(player)})
    local render_object
    for m, msg in pairs (mod.player_messages[index].render) do
      --~ r = msg.ID and rendering.get_object_by_id(msg.ID)
      render_object = GCKI.ascertain_rendering(msg.ID)

      -- Set time_to_live for existing message from 0 to remaining time
      if render_object and render_object.valid then
        render_object.time_to_live = msg.TTL
        GCKI.writeDebug("Activated rendering %s", {m})
      -- Remove expired messages from table
      else
        mod.player_messages[index].render[m] = nil
        GCKI.writeDebug("Removed invalid rendering %s from list", {m})
      end
    end
  else
    GCKI.writeDebug("No!")
  end

  GCKI.entered_event(event, "leave")
end


------------------------------------------------------------------------------------
--                         PLAYER LEFT THE GAME TEMPORARILY                       --
------------------------------------------------------------------------------------
common_events.on_pre_player_left_game = function(event)
  GCKI.entered_event(event)

  local index = event.player_index

  -- Clean up list of rendered messages for player
  GCKI_cleanup.ground_renderings(index)
  GCKI_cleanup.show_on_camera(index)

  -- Replace TTL of each message stored in list of rendered messages for player
  -- with remaining TTL
  local render_object
  for _, msg in pairs (mod.player_messages[index].render) do
    --~ r = msg.ID and rendering.get_object_by_id(msg.ID)
    render_object = GCKI.ascertain_rendering(msg.ID)
    if render_object and render_object.valid then
      msg.TTL = render_object.time_to_live
      -- Set time_to_live for existing message to 0 (msg won't expire)
      render_object.time_to_live = 0
    end
  end

  GCKI.entered_event(event, "leave")
end

------------------------------------------------------------------------------------
--                             PERMANENTLY DELETE PLAYER                          --
------------------------------------------------------------------------------------
common_events.on_pre_player_removed = function(event)
  GCKI.entered_event(event)

  local player = GCKI.ascertain_player(event.player_index)

  GCKI_player.remove_player(player)
  GCKI.writeDebug("Removed %s from the game!", {GCKI.argprint(player)})

  GCKI.entered_event(event, "leave")
end

------------------------------------------------------------------------------------
--          CHECK SETTINGS AGAIN WHEN PLAYER HAS BEEN REMOVED FROM GAME           --
------------------------------------------------------------------------------------
common_events.on_player_removed = function(event)
  GCKI.entered_event(event)

  -- Was removed player the only one who had activated debug_in_game?
  GCKI.set_debug_in_game()

  -- Was removed player the only one who had activated flying_text?
  GCKI.set_flying_text()

  GCKI.entered_event(event, "leave")
end


------------------------------------------------------------------------------------
--                         PLAYER CHANGED TO ANOTHER FORCE                        --
------------------------------------------------------------------------------------
common_events.on_player_changed_force = function(event)
  GCKI.entered_event(event)

  local player = GCKI.ascertain_player(event.player_index)
  local p_data = mod.player_data[player.index]

  local old_force = event.force
  local new_force = player.force
GCKI.show("player", GCKI.argprint(player))
GCKI.show("p_data", p_data)
GCKI.show("old_force", GCKI.argprint(old_force))
GCKI.show("new_force", GCKI.argprint(new_force))

  -- When forces are merged, all players and all vehicles will be transferred to the
  -- new force anyway, so there is nothing to do!
  if p_data and p_data.merging_forces and
                p_data.merging_forces.old == old_force and
                p_data.merging_forces.new == new_force then

    p_data.merging_forces = nil
    local msg = string.format("%s is merging with %s!",
                              GCKI.argprint(old_force),GCKI.argprint(new_force))
    GCKI.entered_event(event, "leave", msg)
    return
  end


  ----------------------------------------------------------------------------------
  -- Players who have temporarily changed to the force from "Blueprint Sandboxes"
  -- shouldn't be able to use their keys.
  if BP_SANDBOXES then
    GCKI.writeDebugNewBlock("Checking whether player entered/left Blueprint Sandbox!")
    local prefix = GCKI.BPS_force_name_prefix
    local reason

    -- Player entered sandbox. Hide GUIs!
    if GCKI.prefixed(new_force.name, prefix) then
      reason = "changed to"
      GCKI.writeDebug("Hiding GUIs of %s!", {GCKI.argprint(player)})
      GCKI_gui.hide_player_guis(player)

      -- Disable shortcut of player
GCKI.show("player.is_shortcut_available("..GCKI.shortcut_name..")",
          player.is_shortcut_available(GCKI.shortcut_name))
      if player.is_shortcut_available(GCKI.shortcut_name) then
        player.set_shortcut_available(GCKI.shortcut_name, false)
        GCKI_gui.update_key_status(player)
        GCKI.writeDebug("Disabled  shortcut %s for %s!",
                        {GCKI.enquote(GCKI.shortcut_name), GCKI.argprint(player)})

        -- Disable shortcut events?
        GCKI.writeDebug("Disable shortcut events?")
        helper.need_shortcut_events()
      end

      -- Mark player as suspended: won't be able to use the shortcut!
      if p_data then
        p_data.suspended = true
        GCKI.writeDebug("Marked %s as suspended!", {GCKI.argprint(player)})
      end

      -- Add player to list of suspended players in data of original force, so that
      -- its data will be kept if next(f_data) returns nil
      local f_data_old = mod.force_data and mod.force_data[old_force.name]
      if f_data_old then
        f_data_old.suspended_players = f_data_old.suspended_players or {}
        f_data_old.suspended_players[player.index] = true
        GCKI.writeDebug("Added %s to list of players suspended by %s!",
                      {GCKI.argprint(player), GCKI.argprint(old_force)})
      end

    -- Player left sandbox. Unhide GUIs!
    elseif GCKI.prefixed(old_force.name, prefix) then
      reason = "returned from"
      --~ GCKI.writeDebug("Unhiding GUIs of %s!", {GCKI.argprint(player)})
      --~ GCKI_gui.unhide_guis(player)
      local f_data_new = mod.force_data and mod.force_data[new_force.name]
GCKI.show("f_data_new", f_data_new)

      -- Unhide toggle button?
      if f_data_new.researched and next(f_data_new.researched) and
          p_data.locked_or_owned and next(p_data.locked_or_owned) then

        local t_name = GCKI_gui_names.player_vehicles.buttons.toggle_gui
        local button_flow = mod_gui.get_button_flow(player)
        local button = button_flow[t_name]
      GCKI.show("button", GCKI.argprint(button))
        if button and button.valid and not button.visible then
          GCKI.writeDebug("Unhiding toggle button!")
          button.visible = true
        end
      end


      -- Enable shortcut?
      GCKI.writeDebugNewBlock("Enable shortcut %s for %s?",
                              {GCKI.enquote(GCKI.shortcut_name), GCKI.argprint(player)})
      if f_data_new.show_shortcuts then
        GCKI.writeDebug("Yes!")
        GCKI_ownership.update_shortcut(player)
      else
        GCKI.writeDebug("No!")
      end

      -- Enable shortcut events?
      GCKI.writeDebugNewBlock("Enable shortcut events?")
      helper.need_shortcut_events()

      -- Enable GUI events?
      GCKI.writeDebugNewBlock("Enable GUI events?")
      helper.need_gui_events()

      -- Remove suspended mark from player data!
      if p_data and p_data.suspended then
        p_data.suspended = nil
        GCKI.writeDebug("%s is no longer suspended!", {GCKI.argprint(player)})
      end

      -- Remove player from list of suspended players in data of original force
      --~ local f_data_new = mod.force_data and mod.force_data[new_force.name]
      if f_data_new and f_data_new.suspended_players then
        f_data_new.suspended_players[player.index] = nil
        GCKI.writeDebug("Removed %s from list of players suspended by %s!",
                      {GCKI.argprint(player), GCKI.argprint(old_force)})

        if not next(f_data_new.suspended_players) then
          f_data_new.suspended_players = nil
          GCKI.writeDebug("Removed mod.force_data[%s].suspended_players!",
                        {new_force.name})
        end
      end
    end

    -- Leave early?
    if reason then
      local msg = string.format("%s %s special force of \"blueprint-sandboxes\"",
                                --~ GCKI.argprint(player), reason)
                                GCKI.argprint(player) or "nil", reason)
      GCKI.entered_event(event, "leave", msg)
      return
    end
  end
  ----------------------------------------------------------------------------------

  -- Initialize data of new force
  GCKI.writeDebugNewBlock("Initializing data for new force!")
  GCKI_force.init_force_data(new_force)

  -- Back up the list of vehicles claimed or locked by the player, we will need it
  -- for reference later!
  local p_vehicles = table.deepcopy(p_data.locked_or_owned) or {}

  -- Player takes vehicles to new force
  if mod.settings.player_keeps_vehicles then
    -- Assign player's vehicles to the new force!
    for v, vehicle in pairs(p_vehicles) do
      if vehicle.valid then
        vehicle.force = new_force
        GCKI.writeDebug("%s belongs to %s now.",
                        {GCKI.argprint(vehicle), GCKI.argprint(new_force)})
      end
    end

    -- Raise event if the player has claimed/locked vehicles
    if next(p_vehicles) then
      GCKI.writeDebugNewBlock("Raising event!")
GCKI.show("GCKI.custom_events.on_vehicle_changed_force", GCKI.custom_events.on_vehicle_changed_force)
      local raise_id = GCKI.custom_events.on_vehicle_changed_force
      script.raise_event(raise_id, {
        old_force = old_force,
        new_force = new_force,
        player = player,
        vehicles = p_vehicles,
        name = raise_id,
      })
    end

    -- Mark vehicles that belong to the old force for removal from player selection
    local unselect = { [player.name] = {} }
    for v, vehicle in pairs(p_data.selected_vehicles or {}) do
      if not p_vehicles[v] then
        table.insert(unselect[player.name], vehicle)
      end
    end
GCKI.show("unselect", unselect)

    -- Mark the players' vehicles for removal from other players' GUI
    local o_data
    for v, vehicle in pairs(p_vehicles or {}) do
      for o, other in pairs(old_force.players or {}) do
        unselect[other.name] = unselect[other.name] or {}
        o_data = mod.player_data[o]

        if o_data.selected_vehicles and o_data.selected_vehicles[v] then
          table.insert(unselect[other.name], vehicle)
        end
      end
    end
GCKI.show("unselect", unselect)

    -- Remove vehicles from GUIs
    for p, vehicles in pairs(unselect) do
      if next(vehicles) then
        GCKI.writeDebug("Must remove %s vehicles from GUI of vehicles selected by %s.",
                        {#vehicles, GCKI.argprint(p)})
        GCKI_gui_select_area.remove_from_gui(p, vehicles)
      end
    end


  -- Vehicles remain with the old force
  else
    GCKI.writeDebug("Must reset all vehicles belonging to %s!", {GCKI.argprint(player)})
    GCKI_vehicle.reset_player_vehicles(player)

    -- Player could only have selected vehicles that belonged to the old force
    p_data.selected_vehicles = {}
    GCKI.show("p_data.selected_vehicles", p_data.selected_vehicles)

    -- Remove minimap
    p_data.show_on_map = nil
    GCKI.show("p_data.show_on_map", p_data.show_on_map)

    -- Remove camera
    p_data.show_on_camera = nil
    GCKI.show("p_data.show_on_camera", p_data.show_on_camera)


    -- Update GUIs
    for v, vehicle in pairs(p_vehicles or {}) do
      GCKI.writeDebugNewBlock("Updating GUIs for %s!", {GCKI.argprint(vehicle)})
      GCKI_gui.update_guis(vehicle)
    end
  end


  -- Eject occupants from old force if player keeps vehicles, or player if vehicles
  -- are abandoned on changing forces.
  if mod.settings.eject_on_changed_force then
    GCKI.writeDebug("Eject players from vehicle belonging to another force!")
    local occupants, o

    -- Players must also be ejected if they are riding in some vehicle that is not
    -- the one they have claimed!
    local pv = player.vehicle
    if pv and pv.valid then
      -- Player is in a vehicle we care about -- add it to the list!
      if GCKI_vehicle.is_vehicle(pv) then
        p_vehicles[pv.unit_number] = pv
        GCKI.writeDebug("Added %s to list of vehicles belonging to %s!",
                        {GCKI.argprint(pv), GCKI.argprint(player)})

      -- Player is in a car/spider-vehicle we don't care about, or in a train
      else
        local check = function(v_data)
          return v_data and v_data.is_player and v_data.index == player.index
        end

        local role
        role  = (check(GCKI_vehicle.get_occupant_entity_data(pv.get_driver())) and
                  "driver") or
                (check(GCKI_vehicle.get_occupant_entity_data(pv.get_passenger())) and
                  "passenger")
        if role then
          pv["set_"..role](nil)
          GCKI.writeDebug("Ejected %s (%s) from %s!",
                          {GCKI.argprint(player), role, GCKI.argprint(pv)})
        end
      end
    end

GCKI.show("p_vehicles", p_vehicles)
    -- Eject players from GCKI-vehicles
    for v, vehicle in pairs(p_vehicles or {}) do
GCKI.show(v, GCKI.argprint(vehicle))
      if vehicle.valid then
        occupants =  GCKI_vehicle.get_occupants(vehicle)
GCKI.show("occupants", occupants)
        -- Remove human players from vehicle unless they belong to the same force.
        for role, occupant in pairs(occupants or {}) do
          o = occupant.entity
          if occupant.is_player and o and o.valid and o.force ~= vehicle.force then
            GCKI.writeDebug("Ejecting %s from %s!", {role, GCKI.argprint(vehicle)})
            -- Make sure we'll skip on_player_driving_changed_state!
            mod.player_data[occupant.index].last_action_tick = game.tick
            vehicle["set_"..role](nil)
          end
        end
      end
    end
  end

  -- Close GUIs pertaining to entities, techs, stats etc. of the old force.
  local gui = player.opened
  if gui and not player.opened_self then
    GCKI.writeDebug("Must close GUI %s of %s!", {GCKI.argprint(gui), GCKI.argprint(player)})
    player.opened = nil
  end

  -- Remove data of old force?
  GCKI.writeDebugNewBlock("Remove data of old force?")
  GCKI_force.remove_force_data(old_force)

  GCKI.entered_event(event, "leave")
end


------------------------------------------------------------------------------------
--          RESEARCH HAS FINISHED -- CHECK WHETHER IT WAS AN UNLOCK TECH          --
------------------------------------------------------------------------------------
--~ common_events.on_research_finished = function(event)
  --~ GCKI.entered_event(event)

  --~ local tech = event.research
  --~ local tech_list

  --~ -- We must enable shortcuts for the force!
  --~ if GCKI.unlock_tech_map[tech.name] then
    --~ GCKI.writeDebug("Must enable %s!", {GCKI.enquote(GCKI.shortcut_name)})
    --~ local force = tech and tech.force

    --~ -- Update global table
    --~ global.force_data[force.name] = global.force_data[force.name] or {}
    --~ global.force_data[force.name].researched = global.force_data[force.name].researched or {}
    --~ global.force_data[force.name].researched[tech.name] = true
    --~ global.force_data[force.name].show_shortcuts = true

    --~ -- Make shortcut available for all players on the force
    --~ for p, player in pairs(force.players) do
      --~ player.set_shortcut_available(GCKI.shortcut_name, true)
      --~ GCKI.writeDebug("Enabled  shortcut %s for %s!",
                      --~ {GCKI.enquote(GCKI.shortcut_name), GCKI.argprint(player)})
    --~ end

    --~ -- Initialize GUIs of all players on the force
    --~ GCKI.writeDebug("Must initialize GUIs for players of %s!", {GCKI.argprint(force)})
    --~ GCKI_gui.init_guis(force)

    --~ -- Enable shortcut events
    --~ for e, e_name in pairs(GCKI_event_lists.shortcut_events) do
      --~ GCKI.enable_optional_events(defines.events[e_name], common_events[e_name], true)

    --~ end
    --~ GCKI.writeDebug("Enabled shortcut events!")

    --~ -- Enable GUI events
    --~ for e, e_name in pairs(GCKI_event_lists.gui_events) do
      --~ GCKI.enable_optional_events(defines.events[e_name], common_events[e_name], true)
    --~ end
    --~ GCKI.writeDebug("Enabled GUI events!")

  --~ -- Tech is not related to our shortcuts
  --~ else
    --~ GCKI.writeDebug("Nothing to do for %s!", {GCKI.argprint(tech)})
  --~ end

  --~ GCKI.entered_event(event, "leave")
--~ end

common_events.on_research_finished = function(event)
  GCKI.entered_event(event)

  local tech = event.research
  local force = tech and tech.force
  local events

  -- If the tech was unlocked by script, it may have been researched on account of a
  -- force that has no players (the team cheats from "Creative Mod" do that).
  if event.by_script and not next(force.players) then
    if mod.force_data[force.name] then
      mod.force_data[force.name] = nil
      GCKI.writeDebug("Removed mod.force_data[%s]!", {GCKI.enquote(force.name)})
    end
    GCKI.entered_event(event, "leave", GCKI.argprint(force).." has no players!")
    return
  end


  --~ local tech_list

  -- We must enable shortcuts for the force!
  if GCKI.unlock_tech_map[tech.name] then
    GCKI.writeDebug("Must enable %s!", {GCKI.enquote(GCKI.shortcut_name)})

    -- Update global table
    --~ mod.force_data[force.name] = mod.force_data[force.name] or {}
    --~ mod.force_data[force.name].researched = mod.force_data[force.name].researched or {}
    --~ mod.force_data[force.name].researched[tech.name] = true
    --~ mod.force_data[force.name].show_shortcuts = true
    mod.force_data[force.name] = mod.force_data[force.name] or {}
    local f_data = mod.force_data[force.name]
    f_data.researched = f_data.researched or {}
    f_data.researched[tech.name] = true
    f_data.show_shortcuts = true

    -- Make shortcut available for all players on the force
    for p, player in pairs(force.players) do
      GCKI_ownership.update_shortcut(player)
      GCKI.writeDebug("Enabled shortcut %s for %s!",
                      {GCKI.enquote(GCKI.shortcut_name), GCKI.argprint(player)})
    end

    -- Initialize GUIs of all players on the force
    GCKI.writeDebug("Must initialize GUIs for players of %s!", {GCKI.argprint(force)})
    GCKI_gui.init_guis(force)

    -- Enable shortcut events
    GCKI.writeDebug("Enabling shortcut events!")
    events = GCKI_event_lists.shortcut_events
    helper.enable_optional_events(events)

    -- Enable custom input events
    GCKI.writeDebug("Enabling custom input events!")
    events = GCKI_custom_input_lists.optional.need_vehicle
    GCKI_custom_input.helper.enable_optional_custom_inputs(events)


    -- Enable GUI events?
    GCKI.writeDebug("Enabling GUI events?")
    helper.need_gui_events()

  -- Tech is not related to our shortcuts
  else
    GCKI.writeDebug("Nothing to do for %s!", {GCKI.argprint(tech)})
  end

  GCKI.entered_event(event, "leave")
end


------------------------------------------------------------------------------------
--          TECH WAS UNRESEARCHED -- CHECK WHETHER IT WAS AN UNLOCK TECH          --
------------------------------------------------------------------------------------
common_events.on_research_reversed = function(event)
  GCKI.entered_event(event)

  local tech = event.research
  --~ local tech_list

  -- One of our unlock techs has been unresearched.
  if GCKI.unlock_tech_map[tech.name] then
    local force = tech and tech.force
    -- Remove tech from list of researched techs
    mod.force_data[force.name] = mod.force_data[force.name] or {}
    mod.force_data[force.name].researched = mod.force_data[force.name].researched or {}
    mod.force_data[force.name].researched[tech.name] = nil

    -- Is the shortcut still unlocked?
    local unlock = GCKI.is_unlock_tech_researched(force)
GCKI.show("unlock", unlock)
    -- Write shortcut state to force_data for faster lookup
    mod.force_data[force.name].show_shortcuts = unlock or nil

    -- Update shortcut state for all players on the force
    local shortcut = GCKI.shortcut_name
    for p, player in pairs(force.players) do
      -- Toggle shortcut
      GCKI_ownership.update_shortcut(player)
      GCKI.writeDebug("%sabled  shortcut %s for %s!",
                      {unlock and "En" or "Dis", GCKI.enquote(shortcut), GCKI.argprint(player)})

      -- The last (or only) unlock tech has been unresearched
      if not unlock then
        -- Remove the keys from players' cursor if the shortcut is disabled!
        local cursor = player.cursor_stack
        if cursor and cursor.valid_for_read and cursor.name == GCKI.carkey_name then
          cursor.clear()
          GCKI.writeDebug("Removed %s from cursor of %s!",
                          {GCKI.enquote(GCKI.carkey_name), GCKI.argprint(player)})
        end

        -- Give up vehicles?
GCKI.show("mod.settings.lose_vehicles_on_unresearch",
  mod.settings.lose_vehicles_on_unresearch)
        if mod.settings.lose_vehicles_on_unresearch then
          GCKI.writeDebug("%s must give up all vehicles!", {GCKI.argprint(player)})
          GCKI_player.give_up_vehicles(player)
        end
      end
    end

    -- If the force doesn't have the shortcut anymore, we hide our GUIs from all
    -- players on that force
    if not unlock and next(force.players) then
      GCKI.writeDebug("Must remove GUIs of all players on %s!",
                      {GCKI.argprint(force)})
      GCKI_gui.disable_all_guis(force)
    end

    -- Disable shortcut events if no other force has unlocked the shortcut yet!
    GCKI.writeDebug("Disable shortcut events?")
    helper.need_shortcut_events()

    -- Disable GUI events if no other force has unlocked the shortcut yet!
    GCKI.writeDebug("Disabling GUI events?")
    helper.need_gui_events()

  -- Nothing to do for unrelated techs
  else
    GCKI.writeDebug("Nothing to do for %s!", {GCKI.argprint(tech)})

  end

  GCKI.entered_event(event, "leave")
end



------------------------------------------------------------------------------------
--                     ALL TECHS OF THE FORCE HAVE BEEN RESET                     --
------------------------------------------------------------------------------------
common_events.on_force_reset = function(event)
  GCKI.entered_event(event)

  local force = event.force
  local f_data = mod.force_data[force.name]

  if f_data then
    -- Remove list of researched techs
    f_data.researched = nil
    GCKI.writeDebug("Removed mod.force_data[%s].researched!", {force.name})

    -- Shortcuts are not available!
    f_data.show_shortcuts = nil

    -- Update shortcut state for all players on the force
    local shortcut = GCKI.shortcut_name
    local cursor

    for p, player in pairs(force.players) do
      -- Toggle shortcut
      GCKI_ownership.update_shortcut(player)
      GCKI.writeDebug("Disabled  shortcut %s for %s!",
                      {GCKI.enquote(shortcut), GCKI.argprint(player)})

      -- Remove the keys from players' cursor if the shortcut is disabled!
      cursor = player.cursor_stack
      if cursor and cursor.valid_for_read and cursor.name == GCKI.carkey_name then
        cursor.clear()
        GCKI.writeDebug("Removed %s from cursor of %s!",
                        {GCKI.enquote(GCKI.carkey_name), GCKI.argprint(player)})
      end

      -- Give up vehicles?
GCKI.show("mod.settings.lose_vehicles_on_reset",
          mod.settings.lose_vehicles_on_reset)
      if mod.settings.lose_vehicles_on_reset then
        GCKI.writeDebug("%s must give up all vehicles!", {GCKI.argprint(player)})
        GCKI_player.give_up_vehicles(player)
      end
    end

    -- Hide our GUIs from all players on that force
    if next(force.players) then
      GCKI.writeDebug("Must remove GUIs of all players on %s!", {GCKI.argprint(force)})
      GCKI_gui.disable_all_guis(force)
    end

    -- Disable shortcut events if no other force has unlocked the shortcut yet!
    GCKI.writeDebug("Disable shortcut events?")
    helper.need_shortcut_events()

    -- Disable GUI events if no other force has unlocked the shortcut yet!
    GCKI.writeDebug("Disabling GUI events?")
    helper.need_gui_events()
  end

  GCKI.entered_event(event, "leave")
end




------------------------------------------------------------------------------------
--          FORCES ARE ABOUT TO BE MERGED -- SKIP ON_PLAYER_CHANGED_FORCE         --
------------------------------------------------------------------------------------
-- Mark players of removed force, so we can skip on_player_changed_force for them!
common_events.on_forces_merging = function(event)
  GCKI.entered_event(event)

  local old_force = event.source
  local new_force = event.destination
  local p_data

  for p, player in pairs(old_force.players) do
GCKI.show(p, GCKI.argprint(player))
    mod.player_data[player.index] = mod.player_data[player.index] or {}
    p_data = mod.player_data[player.index]
    p_data.merging_forces = {old = old_force, new = new_force}
    GCKI.writeDebug("Marked %s for skipping on_player_changed_force!",
                    {GCKI.argprint(player)})
  end

  -- Delete data of force that is to be removed
  if mod.force_data[old_force.name] then
    mod.force_data[old_force.name] = nil
    GCKI.writeDebug("Removed data of %s!", {GCKI.argprint(old_force)})
  end


  GCKI.entered_event(event, "leave")
end



------------------------------------------------------------------------------------
--                                     TIMERS                                     --
------------------------------------------------------------------------------------

-- on_tick
common_events.on_tick = function(event)
  --~ GCKI.entered_event(event)

  local tick = event.tick

  -- Has the flag been set yet? (Check for nil: Boolean values may be "false"!)
  if mod.need_flying_text == nil then
GCKI.writeDebug("Calling GCKI.set_flying_text!")
    GCKI.set_flying_text()
  end

  -- Check whether any flying text is scheduled for this tick
  local msgs = mod.player_messages.ticks[tick]
  -- Display flying text messages scheduled for this tick
  if mod.need_flying_text and msgs then
    display_flying_text(tick, msgs)
  end

  -- Unsubscribe from event if no further messages are scheduled
  if not next(mod.player_messages.ticks) then
    script.on_event(defines.events.on_tick, nil)
    mod.enable_optional_events.on_tick = nil
    GCKI.writeDebug("Disabled on_tick event handler!")
  end

  --~ GCKI.entered_event(event, "leave")
end



-- on_nth_tick
common_events.on_nth_tick = function(event)
  GCKI.entered_event(event)
  ----------------------------------------------------------------------------------
  -- Use "elseif" so we always call just one function, even if intervals overlap! --
  ----------------------------------------------------------------------------------
  -- There's nothing to do while a new game is initialized! (Moreover, the event
  -- will be triggered for each nth_tick, so we'd waste time on running overlapping
  -- functions repeatedly.)
  if event.tick == 0 then
    GCKI.writeDebugNewBlock("Nothing to do: starting a new game!")

  -- Remove invalid vehicles from GCKI_vehicles. (Space Exploration removes them
  -- sometimes without raising an event, for performance reasons.) Also reset all
  -- vehicles that are not of a valid type!
  elseif event.nth_tick == GCKI.CLEANUP_VEHICLES_INTERVAL then
    GCKI.writeDebugNewBlock("Cleaning vehicle lists!")
    GCKI_cleanup.cleanup_all_vehicle_lists()

  -- Update force data and check player data
  elseif event.nth_tick == GCKI.CLEANUP_PLAYERDATA_INTERVAL then
    GCKI.writeDebugNewBlock("Checking force data!")
    --~ local pass_on_flags = {
      --~ -- keep_gui = true,
      --~ skip_event_check = true,
    --~ }
    --~ GCKI_cleanup.force_data(pass_on_flags)
    GCKI_cleanup.force_data()
    GCKI_events.helper.need_shortcut_events()

    -- If any vehicles are removed from a player's list of owned/locked or selected
    -- vehicles, we must update GUIs and check whether GUI events are still needed!
    GCKI.writeDebugNewBlock("Trying to remove invalid vehicles from player data!")
    --~ pass_on_flags.keep_gui = true
    local pass_on_flags = {
      keep_gui = true,
      skip_event_check = true,
    }

    local removed_vehicles = GCKI_cleanup.player_data(pass_on_flags)
GCKI.show("removed_vehicles", removed_vehicles)

    if removed_vehicles > 0 then
      -- Rebuild GUIs of all players
      GCKI.writeDebug("Rebuilding GUIs of all players!")
      GCKI_gui.init_guis()

      -- Do we still need GUI events?
      GCKI.writeDebug("Checking whether we need GUI events!")
      GCKI_events.helper.need_gui_events()
    end

  -- Remove/restore expired renderings
  elseif event.nth_tick == GCKI.CLEANUP_RENDERINGS_INTERVAL then
    -- Remove expired renderings on ground
    GCKI.writeDebug("Trying to remove records of expired renderings on the ground!")
    GCKI_cleanup.ground_renderings()

    -- Remove expired vehicles from named-vehicle lists, or restore expired
    -- renderings (e.g. renderings created by removed mods) if the vehicle still is
    -- valid.
    GCKI.writeDebug("Trying to fix renderings of custom vehicle names!")
    GCKI_cleanup.customname_renderings()
  end

  GCKI.entered_event(event, "leave")
end


local function remove_orig_vehicle_color(id_or_entity)
  GCKI.entered_function({id_or_entity})

  local v_id = (type(id_or_entity) == "number" and id_or_entity) or
                (GCKI_vehicle.is_vehicle(id_or_entity) and id_or_entity.unit_number)
GCKI.show("v_id", v_id)

  if v_id and mod.vehicles_orig_color[v_id] then
    mod.vehicles_orig_color[v_id] = nil
    GCKI.writeDebug("Removed mod.vehicles_orig_color[%s]!", {v_id})
  end

  GCKI.entered_function("leave")
end


------------------------------------------------------------------------------------
--              NEW VEHICLE HAS BEEN PLACED BY PLAYER, BOT, OR SCRIPT             --
------------------------------------------------------------------------------------
common_events.on_built_entity = function(event)
  GCKI.entered_event(event)

  -- Make this general, as copies of this function will be used for script_raised_*
  -- events!
  local vehicle = event.created_entity or event.entity

  --~ -- If vehicle was unloaded by vehicle wagons, restore its data
  --~ if event.name == defines.events.script_raised_built then
    --~ local v_data = event.GCKI_data and
                      --~ table.deepcopy(event.GCKI_data) or {}
    --~ local AD_data = event.autodrive_data and
                      --~ table.deepcopy(event.autodrive_data) or {}
--~ GCKI.show("vehicle", GCKI.argprint(vehicle))
--~ GCKI.show("v_data", v_data)
--~ GCKI.show("AD_data", AD_data)

    --~ v_data.Autodrive_owner = AUTODRIVE and
                              --~ (v_data.Autodrive_owner or AD_data.owner) or nil
    --~ v_data.custom_name = v_data.custom_name or AD_data.custom_name
    --~ v_data.named_by = v_data.named_by or AD_data.named_by
    --~ v_data.orig_color = v_data.orig_color or AD_data.orig_color

--~ GCKI.show("v_data after looking for event.autodrive_data", v_data)
--~ GCKI.show("event.GCKI_data", event.GCKI_data)
    --~ GCKI.writeDebugNewBlock("Trying to restore data of %s!",
                            --~ {GCKI.argprint(vehicle)})
    --~ GCKI_vehicle.restore_vehicle(vehicle, v_data, event.mod_name)

    --~ -- local pass_on_flags = {ignore_Autodrive = true}
    --~ -- GCKI_vehicle.restore_vehicle(vehicle, v_data, event.mod_name, pass_on_flags)

  --~ -- Otherwise store vehicle color
  --~ else
    --~ GCKI_vehicle.store_orig_color(vehicle)
  --~ end

  -- If vehicle was unloaded by vehicle wagons, restore its data
  if event.name == defines.events.script_raised_built then
    local v_data = event.GCKI_data and
                      table.deepcopy(event.GCKI_data) or {}
    local AD_data = event.autodrive_data and
                      table.deepcopy(event.autodrive_data) or {}
GCKI.show("vehicle", GCKI.argprint(vehicle))
GCKI.show("v_data", v_data)
GCKI.show("AD_data", AD_data)

    v_data.Autodrive_owner = AUTODRIVE and
                              (v_data.Autodrive_owner or AD_data.owner) or nil
    v_data.custom_name = v_data.custom_name or AD_data.custom_name
    v_data.named_by = v_data.named_by or AD_data.named_by
    v_data.orig_color = v_data.orig_color or AD_data.orig_color

GCKI.show("v_data after looking for event.autodrive_data", v_data)
GCKI.show("event.GCKI_data", event.GCKI_data)
    GCKI.writeDebugNewBlock("Trying to restore data of %s!",
                            {GCKI.argprint(vehicle)})
    GCKI_vehicle.restore_vehicle(vehicle, v_data, event.mod_name)

    -- local pass_on_flags = {ignore_Autodrive = true}
    -- GCKI_vehicle.restore_vehicle(vehicle, v_data, event.mod_name, pass_on_flags)

  -- Otherwise store vehicle color
  else
    GCKI_vehicle.store_orig_color(vehicle)
  end

  GCKI.entered_event(event, "leave")
end
-- Copying the function is necessary so the handlers will be registered when we loop
-- over the event list!
common_events.on_robot_built_entity = common_events.on_built_entity
common_events.script_raised_built = common_events.on_built_entity
common_events.script_raised_revive = common_events.on_built_entity



------------------------------------------------------------------------------------
--                               VEHICLE WAS CLONED                               --
------------------------------------------------------------------------------------
common_events.on_entity_cloned = function(event)
  GCKI.entered_event(event)

  -- Occupants are ejected before vehicle is cloned, so this would do nothing! The
  -- second event will be skipped anyway because it follows too soon.
  local old_id = event.source.unit_number
  local old_vehicle = old_id and mod.GCKI_vehicles[old_id]

  local new_vehicle = event.destination
  local new_id = new_vehicle and new_vehicle.unit_number

  local keep_color = true


  -- Copy entry to list of original vehicle colors
  local v_colors = mod.vehicles_orig_color
  local new_color = v_colors[old_id] and v_colors[old_id].color and
                                          util.table.deepcopy(v_colors[old_id].color)
GCKI.show("new_color", new_color)

  v_colors[new_id] = {
    entity = new_vehicle,
    color = new_color or util.table.deepcopy(new_vehicle.color)
  }
  GCKI.writeDebug("%s entry for original color %s new %s!", {
    new_color and "Copied" or "Created",
    new_color and "to" or "of",
    GCKI.argprint(new_vehicle)
  })


  -- Only run this if the old vehicle was controlled by GCKI!
  if old_vehicle and new_vehicle then
    local flags = {keep_color = keep_color}
    if old_vehicle.locker then
      GCKI_vehicle.add_vehicle_locker(new_vehicle, old_vehicle.locker, flags)
    end
    if old_vehicle.owner then
      GCKI_vehicle.add_vehicle_owner(new_vehicle, old_vehicle.owner, flags)
    end
    GCKI_vehicle.color_vehicle(new_vehicle)
GCKI.writeDebug("Added cloned %s to list!", {GCKI.argprint(new_vehicle)})
  end

  GCKI.entered_event(event, "leave")
end

------------------------------------------------------------------------------------
--                             A PLAYER STOLE A VEHICLE                           --
------------------------------------------------------------------------------------
common_events.on_pre_player_mined_item = function(event)
  GCKI.entered_event(event)

  local vehicle = event.entity
  --~ local player = game.players[event.player_index]
  local player = GCKI.ascertain_player(event.player_index)

  local owner = GCKI_vehicle.get_owner(vehicle)
  --~ local msg, hint, alert, render
  local msg, hint, render

  -- Remove entry from list of original vehicle colors
  GCKI.writeDebug("Removing entry from list of original vehicle colors!")
  remove_orig_vehicle_color(vehicle)

  -- Only check for owner is needed, as locked vehicles can't be mined
  if owner then
    if owner == player then
      msg = {"GCKI-messages.player-vehicle_no_more"}
      hint = {"GCKI-messages.hints-use_key_new"}
    -- Somebody else stole the vehicle, so inform the owner in any possible way!
    else
      -- Normal output
      msg = {"GCKI-messages.owner-stolen_by_player", player.name, GCKI.loc_name(vehicle)}
      hint = {"GCKI-messages.hints-use_key_new"}
      render = {"",
        {"GCKI-render-messages.owner-stolen_by_player", GCKI.loc_name(vehicle), player.name},
        "\n",
        {"GCKI-messages.hints-use_key_new"}
      }
    end

    -- Output stuff
    alert_player(owner, vehicle, {msg = msg, hint = hint, render = render})

    -- Remove vehicle from tables
    GCKI_vehicle.remove_vehicle(vehicle)

    -- If the vehicle owner still has any locked vehicles, show the GUI!
    if owner.valid and mod.lockers[owner.index] then
      GCKI.writeDebug("Showing GUI of vehicles locked by %s because owned %s disappeared!",
                      {GCKI.argprint(owner), GCKI.argprint(vehicle)})

      claim_locked_when_owned_removed(owner)
    end
  end

  GCKI.entered_event(event, "leave")
end


------------------------------------------------------------------------------------
--                               BOTS STOLE A VEHICLE                             --
------------------------------------------------------------------------------------
common_events.on_robot_pre_mined = function(event)
  GCKI.entered_event(event)

  local vehicle = event.entity
  local owner = GCKI_vehicle.get_owner(vehicle)

  -- Remove entry from list of original vehicle colors
  GCKI.writeDebug("Removing entry from list of original vehicle colors!")
  remove_orig_vehicle_color(vehicle)

  -- Only check for owner is needed, as locked vehicles can't be mined
  if owner then
    local msg = {"GCKI-messages.owner-stolen_by_bots", GCKI.loc_name(vehicle)}
    local hint = {"GCKI-messages.hints-use_key_new"}
    local render = {"",
      {"GCKI-render-messages.owner-stolen_by_bots", GCKI.loc_name(vehicle)},
      "\n",
      {"GCKI-messages.hints-use_key_new"}
    }
    --~ alert_player(owner, vehicle, {msg = msg, hint = hint, alert = alert, render = render})
    alert_player(owner, vehicle, {msg = msg, hint = hint, render = render})

    -- Remove vehicle from tables
    GCKI_vehicle.remove_vehicle(vehicle)

    -- If the vehicle owner still has any locked vehicles, show the GUI!
    if owner.valid and mod.lockers[owner.index] then
      GCKI.writeDebug("Showing GUI of vehicles locked by %s because owned %s disappeared!",
                      {GCKI.argprint(owner), GCKI.argprint(vehicle)})

      claim_locked_when_owned_removed(owner)
    end

  end

  GCKI.entered_event(event, "leave")
end


------------------------------------------------------------------------------------
--                        VEHICLE IS ABOUT TO BE DESTROYED                        --
------------------------------------------------------------------------------------
common_events.on_entity_died = function(event)
  local is_function = event and
                      type(event.name) ~= "number" and type(event.tick ~= "number")
  if is_function then
    GCKI.entered_function({event})
  else
    GCKI.entered_event(event)
  end

  -- If called by on_object_destroyed, the vehicle is no longer valid but we get its
  -- unit_number.
  local vehicle = event.entity
  local v_id = (vehicle and vehicle.valid and vehicle.unit_number) or
                event.unit_number


  local v_data = GCKI_vehicle.get_vehicle_data(vehicle or v_id)
  local owner, locker
  if v_data then
    --~ owner = v_data.owner and game.players[v_data.owner]
    --~ locker = v_data.locker and game.players[v_data.locker]
    owner = v_data.owner and game.get_player(v_data.owner)
    locker = v_data.locker and game.get_player(v_data.locker)
  end

  -- When a vehicle has been loaded onto a vehicle wagon, we want to reserve its
  -- custom name, so it can be reassigned to the new entity when its unloaded.
  local keep_custom_name = event.vehicle_loaded
GCKI.show("keep_custom_name", keep_custom_name)
  local player, msg, hint, alert, render
  --~ local player, p_data, msg, hint, alert, render


  ------------------------------------------------------------------------------------
  -- Build message for owner
  if owner then
GCKI.writeDebug("Destroyed vehicle had owner!")
    msg = {
      "GCKI-messages.owner-vehicle_destroyed",
      GCKI.loc_name(vehicle),
      vehicle.surface.name,
      GCKI.format_position(vehicle.position)
    }
    hint = {"GCKI-messages.hints-use_key_new"}
    alert = {"GCKI-alert-messages.owner-vehicle_destroyed", GCKI.loc_name(vehicle)}
    render = {"",
      {"GCKI-render-messages.owner-vehicle_destroyed", GCKI.loc_name(vehicle)},
      "\n",
      --~ {"GCKI-messages.hints-use_key_new"}
      hint
    }
    player = owner

  -- Build message for locker (will not be rendered if this vehicle is owned by someone)
  elseif locker then
GCKI.writeDebug("Destroyed vehicle had locker!")
    msg = {
      "GCKI-messages.locker-vehicle_destroyed",
      GCKI.loc_name(vehicle),
      vehicle.surface.name,
      GCKI.format_position(vehicle.position)
    }
    alert = {"GCKI-alert-messages.locker-vehicle_destroyed", GCKI.loc_name(vehicle)}
    render = {"GCKI-render-messages.locker-vehicle_destroyed", GCKI.loc_name(vehicle)}
    player = locker
  end

  -- Output messages for that player
  if player then
    GCKI.writeDebug("Must output message!")
    alert_player(player, vehicle, {msg = msg, hint = hint, alert = alert, render = render})
  end


  -- Remove vehicle from tables of owned/locked vehicles
  if owner or locker then
    local pass_on_flags = {
      keep_custom_name = keep_custom_name,
      keep_color = true,
      dying = true,
    }
    GCKI_vehicle.remove_vehicle(vehicle, pass_on_flags)
  end


  -- If the vehicle had a custom name, remove it from named_vehicles list
  if mod.named_vehicles.by_id[v_id] and not keep_custom_name then
    GCKI_vehicle.remove_vehicle_name(v_id, script.mod_name)
  end


  -- Remove entry from list of original vehicle colors
  GCKI.writeDebug("Removing entry from list of original vehicle colors!")
  remove_orig_vehicle_color(v_id)


  -- Remove vehicle from all GUIs of all players
  GCKI.writeDebug("Must remove %s from all GUIs!",
                  {(vehicle and vehicle.valid) and GCKI.argprint(vehicle) or
                                                    "vehicle "..v_id})
  GCKI_gui.remove_from_guis(vehicle or v_id)


  -- If vehicle was owned by a player and the player has locked vehicles, show GUI
  if owner and owner.valid and mod.lockers[owner.index] then
    GCKI.writeDebug("Showing GUI of vehicles locked by %s because owned %s disappeared!",
                    {GCKI.argprint(owner), GCKI.argprint(vehicle)})

    claim_locked_when_owned_removed(owner)
  end

  -- If setting player setting "render_text" is active and vehicle was on camera,
  -- switch from watching entity to watching position
  if player and player.valid then
    local p_data = mod.player_data[player.index]

    local c_data = p_data and p_data.show_on_camera

    local ps = p_data and p_data.settings
    --~ local render = ps and ps.render_text
    render = ps and ps.render_text
    local render_time = ps and ps.render_time

    -- Change camera focus
    if render and c_data and c_data.entity == vehicle then
      GCKI.writeDebug("Must turn camera to position of %s!",
                      {GCKI.argprint(vehicle)})
      c_data.position = vehicle.position
      c_data.entity = nil
      c_data.render_text_until_tick = event.tick + render_time
      GCKI_gui_player_vehicles_camera.update_camera({
        player_index = player.index,
        vehicle = vehicle
      })

    -- Close camera GUI if player wants no text rendered on the ground
    elseif not render then
      GCKI.writeDebug("Turning off camera of %s!", {GCKI.argprint(player)})
      GCKI_gui_player_vehicles_camera.close_gui(player)
    end
  end


  -- Disable event handlers for custom inputs?
  GCKI.writeDebugNewBlock("Do we still need handlers for custom inputs events?")
  GCKI_custom_input.helper.check_optional_events()


  if is_function then
    GCKI.entered_function("leave")
  else
    GCKI.entered_event(event, "leave")
  end
end
-- Copying the function is necessary so script_raised_destroy will be registered
-- when we loop over the event list!
common_events.script_raised_destroy = common_events.on_entity_died



------------------------------------------------------------------------------------
--                               VEHICLE WAS DESTROYED                            --
------------------------------------------------------------------------------------
-- Something registered with script.register_on_object_destroyed() was destroyed. It
-- is no longer valid, but we can get the unit_number and use it to remove data if
-- the destroyed object was one of our vehicles.
common_events.on_object_destroyed = function(event)
  GCKI.entered_event(event)

  if event.type ~= defines.target_type.entity then
    GCKI.entered_event(event, "leave", "don't care about object type!")
    return
  end

  local v_id = event.useful_id
GCKI.show("v_id", v_id)

  -- Vehicle Wagons will register vehicle it loads for on_object_destroyed. However,
  -- once an object has been registered for this event, the registration cannot be
  -- reverted! We therefore must check vehicle states as well as vehicles that are
  -- marked as 'not available' (e.g. because they are on a vehicle wagon).
  GCKI.writeDebugNewBlock("Do we have data of the destroyed object?")
  if mod.GCKI_vehicles[v_id] then
    GCKI.writeDebug("Yes: mod.vehicles[%s]!", {v_id})
    common_events.on_entity_died({unit_number = v_id})

  elseif mod.on_vehicle_wagon and mod.on_vehicle_wagon[v_id] then
    GCKI.writeDebug("Yes: mod.on_vehicle_wagon[%s]. Removing vehicle data!", {v_id})
    common_events.on_entity_died({unit_number = v_id})

    GCKI.writeDebugNewBlock("Removing mod.on_vehicle_wagon[%s]!", {v_id})
    mod.on_vehicle_wagon[v_id] = nil
  else
    GCKI.writeDebug("No: ignoring destroyed entity %s!", {v_id})
  end

  GCKI.entered_event(event, "leave")
end


------------------------------------------------------------------------------------
--                             VEHICLE WAS TELEPORTED                             --
------------------------------------------------------------------------------------
-- Vehicle Wagons teleports loaded vehicles to a hidden surface. If neither source
-- nor destination are that hidden surface, update surface info on GUIs.
common_events.script_raised_teleported = function(event)
  GCKI.entered_event(event)

  if event.mod_name == GCKI_NAME then
    GCKI.entered_event(event, "leave", "We raised this event ourselves!")
    return
  end

  local vehicle = event.entity
  local v_id = vehicle and vehicle.valid and vehicle.unit_number
  if not v_id then
    GCKI.writeDebug("Something strange happened: %s is not a valid vehicle!",
                    {GCKI.argprint(vehicle)})
    return
  end

  local new = vehicle.surface
  --~ local old = game.surfaces[event.old_surface_index]
  local old = game.get_surface(event.old_surface_index)

  GCKI.writeDebugNewBlock("Has %s been moved to another surface?",
                          {GCKI.argprint(vehicle)})
  if old ~= new then
    GCKI_ownership.reconcile()
    GCKI.writeDebug("Yes! Has it been loaded/unloaded by Vehicle Wagons?")
    -- Loaded by VehicleWagon
    if new.name == GCKI.VW_hidden_surface_name then
      GCKI.writeDebug("%s was loaded to a vehicle wagon!", {GCKI.argprint(vehicle)})
      GCKI_vehicle.vehicle_wagons_load(vehicle)

    -- Unloaded by VehicleWagon
    elseif old.name == GCKI.VW_hidden_surface_name then
      GCKI.writeDebug("%s was unloaded from a vehicle wagon!",
                      {GCKI.argprint(vehicle)})
      local v_data = mod.on_vehicle_wagon and mod.on_vehicle_wagon[v_id] or {}

      -- Add custom name to data?
      GCKI.writeDebugNewBlock("Does %s have a custom name?",
                              {GCKI.argprint(vehicle)})
      local named = mod.named_vehicles
      if named and named.by_id[v_id] then
        GCKI.writeDebug("Yes: adding name %s to v_data!",
                        {GCKI.enquote(named.by_id[v_id].name)})
        v_data.custom_name = named.by_id[v_id].name

      else
        GCKI.writeDebug("No!")
      end

      -- Add original color to data?
      GCKI.writeDebugNewBlock("Do  we have the original color of %s?",
                              {GCKI.argprint(vehicle)})
      local colors = mod.vehicles_orig_color
      if colors and colors[v_id] then
        GCKI.writeDebug("Yes: adding original color %s to v_data!",
                        {colors[v_id].color or GCKI.EMPTY_TAB}, "line")
        v_data.orig_color = colors[v_id].color

      else
        GCKI.writeDebug("No!")
      end
    --~ local AD_data = event.autodrive_data and
                      --~ table.deepcopy(event.autodrive_data) or {}
--~ GCKI.show("vehicle", GCKI.argprint(vehicle))
--~ GCKI.show("v_data", v_data)
--~ GCKI.show("AD_data", AD_data)

    --~ v_data.Autodrive_owner = AUTODRIVE and
                              --~ (v_data.Autodrive_owner or AD_data.owner) or nil
    --~ v_data.custom_name = v_data.custom_name or AD_data.custom_name
    --~ v_data.named_by = v_data.named_by or AD_data.named_by
    --~ v_data.orig_color = v_data.orig_color or AD_data.orig_color

--~ GCKI.show("v_data after looking for event.autodrive_data", v_data)
--~ GCKI.show("event.GCKI_data", event.GCKI_data)
    --~ GCKI.writeDebugNewBlock("Trying to restore data of %s!",
                            --~ {GCKI.argprint(vehicle)})
      --~ GCKI_vehicle.restore_vehicle(vehicle, v_data, event.mod_name)
      GCKI_vehicle.restore_vehicle(vehicle, v_data)

      -- Remove mod.on_vehicle_wagon[v_id]
      GCKI.writeDebugNewBlock("Remove %s from list of loaded vehicles?",
                              {GCKI.argprint(vehicle)})
      if mod.on_vehicle_wagon then
        GCKI.argprint("Yes!")
        mod.on_vehicle_wagon[v_id] = nil
        if not next(mod.on_vehicle_wagon) then
          GCKI.writeDebug("Removing mod.on_vehicle_wagon!")
          mod.on_vehicle_wagon = nil
        end
      else
        GCKI.writeDebug("No: mod.on_vehicle_wagon doesn't exist!")
      end

    -- Moved between other surfaces
    else
      GCKI.writeDebug("Must check for missing renderings of %s!",
                      GCKI.argprint(vehicle))
      GCKI_vehicle.restore_renderings(vehicle, event.name_render_text_id)

      -- Update surface index for show_on_camera and show_on_map
      local p_data
      for p, player in pairs(game.players) do
        p_data = mod.player_data[p]
        if p_data.show_on_camera and p_data.show_on_camera.id == v_id then
          p_data.show_on_camera.surface_index = vehicle.surface.index
          GCKI.writeDebug("Updated show_on_camera.surface_index!")
        end

        if p_data.show_on_map and p_data.show_on_map.id == v_id then
          p_data.show_on_map.surface_index = vehicle.surface.index
          GCKI.writeDebug("Updated show_on_map.surface_index!")
        end
      end

      -- Update surface name in GUIs?
      GCKI.writeDebug("Updating %s on GUIs!", {GCKI.argprint(vehicle)})
      GCKI_gui.update_guis(vehicle)
    end

  -- Teleported to position on old surface
  else
    GCKI.writeDebug("No, %s is still on the same surface!",
                    {GCKI.argprint(vehicle)})
  end

  GCKI.entered_event(event, "leave")
end


------------------------------------------------------------------------------------
--                         DRIVING STATE OF A PLAYER CHANGED                      --
------------------------------------------------------------------------------------
common_events.on_player_driving_changed_state = function(event)
  GCKI.entered_event(event)

  local player_index = event.player_index
  --~ local player = game.players[player_index]
  local player = GCKI.ascertain_player(player_index)
GCKI.show("Player", player and player.name or "no name")
  local p_data = mod.player_data[player_index]

GCKI.show("current tick", event.tick)
GCKI.show("p_data.last_action_tick", p_data.last_action_tick)

  ----------------------------------------------------------------------------------
  --                                 Leave early?                                 --
  ----------------------------------------------------------------------------------
  local skip, skip_msg

  -- In editor or god mode, there is no character, so the game would crash if
  -- we continued.
  if not player.character then
    local c = GCKI.controller_names[player.controller_type]
    GCKI.entered_event(event, "leave", "nothing to do in "..c.." mode.")
    return
  end

  --~ local is_vehicle = GCKI_vehicle.is_vehicle(event.entity)
  --~ local vehicle = is_vehicle and event.entity
  local vehicle = event.entity
  --~ local is_vehicle = GCKI_vehicle.is_vehicle(vehicle)

  --~ local skip_msg

  -- Vehicle is not valid!
  if not (vehicle and vehicle.valid) then
    skip_msg = "Vehicle has been destroyed while the player was in it!"

  -- Vehicle is not of a prototype controlled by us
  elseif not GCKI_vehicle.is_vehicle(vehicle) then
    if AUTODRIVE and GCKI_vehicle.is_Autodrive_vehicle(vehicle) then
      GCKI.writeDebug("Recoloring Autodrive vehicle!")
      GCKI_vehicle.color_vehicle(vehicle)
      skip_msg = "Autodrive vehicle, not ours!"
        --~ elseif AUTODRIVE then
          --~ skip_msg = "Not a valid prototype in GCKI or Autodrive!"
    else
      skip_msg = "Not a valid prototype!"
    end
  end
  if skip_msg then
    GCKI.entered_event(event, "leave", skip_msg)
    return
  end


  local locked = mod.GCKI_vehicles[vehicle.unit_number]
  if locked and locked.locker then
    GCKI_vehicle.enforce_vehicle_lock(vehicle)
    if player.vehicle == vehicle then
      GCKI_vehicle.color_vehicle(vehicle, player)
    else
      GCKI_vehicle.color_vehicle(vehicle)
    end
    GCKI_vehicle.set_shooter(vehicle)
    GCKI.entered_event(event, "leave", "checked locked vehicle access")
    return
  end

  local occupants

  --~ -- We care about this vehicle
  -- if vehicle and vehicle.valid then
  --~ if is_vehicle then
    --~ occupants =  GCKI_vehicle.get_occupants(vehicle)

    --~ -- Replaced vehicle (This has precedence because we must decrement skip_state_change!)
    --~ if p_data.skip_state_change and p_data.skip_state_change > 0 then
      --~ skip = true
      --~ skip_msg = "Player's vehicle has been replaced by another mod!"

      --~ p_data.skip_state_change = p_data.skip_state_change - 1
      --~ if p_data.skip_state_change <= 0 then
        --~ p_data.skip_state_change = nil
      --~ end
      --~ eject_players(vehicle, occupants)

    --~ -- Entered event too soon
    --~ ------------------------------------------------------------------------------------
    --~ -- If a vehicle is locked, players shouldn't be able to enter it. However, if they
    --~ -- hit <ENTER> in rapid succession, they may succeed in entering it without being
    --~ -- immediately ejected due to the action delay. So let's check whether the vehicle
    --~ -- is already marked as locked and eject everybody inside!
    --~ ----------------------------------------------------------------------------------
    --~ elseif p_data.last_action_tick and
            --~ (event.tick - p_data.last_action_tick) < GCKI.ACTION_DELAY then
      --~ skip = true
      --~ skip_msg = "Less than "..GCKI.ACTION_DELAY.." ticks since last event!"

      --~ eject_players(vehicle, occupants)
    --~ end

  --~ -- Wrong vehicle type or invalid vehicle
  --~ else
    --~ skip = true
    --~ -- Not one of the entity prototypes we want!
    --~ if not is_vehicle then
      --~ skip_msg = "Not a valid prototype!"

    --~ -- Vehicle doesn't exist anymore!
    --~ elseif not (vehicle and vehicle.valid) then
      --~ skip_msg = "Vehicle has been destroyed while the player was in it!"
    --~ end
  --~ end

  --~ if skip then
    --~ GCKI.entered_event(event, "leave", skip_msg or "")
    --~ return
  --~ end
  -- We care about this vehicle
  --~ if vehicle and vehicle.valid then
  --~ if is_vehicle then
    occupants =  GCKI_vehicle.get_occupants(vehicle)
GCKI.show("occupants", occupants)
    -- Replaced vehicle (This has precedence because we must decrement skip_state_change!)
GCKI.show("p_data.skip_state_change", p_data.skip_state_change)
    if p_data.skip_state_change and p_data.skip_state_change > 0 then

      skip = true
      skip_msg = "Player's vehicle has been replaced by another mod!"

      p_data.skip_state_change = p_data.skip_state_change - 1
      if p_data.skip_state_change <= 0 then
        p_data.skip_state_change = nil
      end
      eject_players(vehicle, occupants)

    -- Entered event too soon
    ---------------------------------------------------------------------------------
    -- If a vehicle is locked, players shouldn't be able to enter it. However, if
    -- they hit <ENTER> in rapid succession, they may succeed in entering it without
    -- being immediately ejected due to the action delay. So let's check whether the
    -- vehicle is already marked as locked and eject everybody inside!
    ----------------------------------------------------------------------------------
    elseif p_data.last_action_tick and
            (event.tick - p_data.last_action_tick) < GCKI.ACTION_DELAY then
      skip = true
      skip_msg = "Less than "..GCKI.ACTION_DELAY.." ticks since last event!"

      eject_players(vehicle, occupants)
    end

  --~ -- Wrong vehicle type or invalid vehicle
  --~ else
    --~ skip = true
    --~ -- Not one of the entity prototypes we want!
    --~ if not is_vehicle then
      --~ skip_msg = "Not a valid prototype!"

    --~ -- Vehicle doesn't exist anymore!
    --~ elseif not (vehicle and vehicle.valid) then
      --~ skip_msg = "Vehicle has been destroyed while the player was in it!"
    --~ end
  --~ end

  if skip then
    GCKI.entered_event(event, "leave", skip_msg or "")
    return
  end

  ----------------------------------------------------------------------------------
  ----------------------------------------------------------------------------------
  --                        The real function starts here!                        --
  ----------------------------------------------------------------------------------
  ----------------------------------------------------------------------------------
  p_data.last_action_tick = event.tick
GCKI.writeDebug("Set p_data.last_action_tick")
  ----------------------------------------------------------------------------------
  --        COMPATIBILITY WITH MODS THAT PLACE DUMMY CHARACTERS IN VEHICLES       --
  -- Remove dummy characters inserted by other mods so they don't spam the        --
  -- surface if they are ejected, and so the player can get in the driver's seat. --
  ----------------------------------------------------------------------------------
  local removed = GCKI_vehicle.remove_dummy(vehicle, occupants)
GCKI.show("removed", removed)

  local v_data = GCKI_vehicle.get_vehicle_data (vehicle)
  local owner, locker

  if v_data then
    --~ owner = v_data.owner and game.players[v_data.owner]
    --~ locker = v_data.locker and game.players[v_data.locker]
    owner = v_data.owner and game.get_player(v_data.owner)
    locker = v_data.locker and game.get_player(v_data.locker)
  end

  local driver = occupants and occupants.driver and
                  occupants.driver.is_player and occupants.driver.entity
  local passenger = occupants and occupants.passenger and
                    occupants.passenger.is_player and occupants.passenger.entity


GCKI.show("Locker", locker and locker.name or "no locker")
GCKI.show("Owner", owner and owner.name or "no owner")

  -- Dummy was driver and player is passenger? Make player driver!
GCKI.show("driver", driver)
GCKI.show("player == passenger", (player == passenger))

  if occupants and (not driver) and (player == passenger) then
GCKI.writeDebug("There was a dummy driver, but it has been removed.\nMaking %s driver of %s!",
                {GCKI.argprint(player), GCKI.argprint(vehicle)})
    vehicle.set_driver(player)
    occupants.driver = table.deepcopy(occupants.passenger)
    occupants.passenger = nil
GCKI.show("Updated occupants", occupants)
  end

  local pass_on_data = {
    player = player,
    vehicle = vehicle,
    occupants = occupants,
    owner = owner,
    locker = locker,
  }

  -- Vehicle has an owner or is locked
  if owner or locker then
    GCKI_events.driving.locked_or_owned_vehicle(pass_on_data)

  -- Vehicle has no owner and is unlocked
  else
    GCKI_events.driving.unlocked_no_owner(pass_on_data)
  end

  -- Adjust vehicle color
  --~ GCKI_vehicle.color_vehicle(vehicle)
  --~ GCKI_vehicle.color_vehicle(vehicle, player)
GCKI.show("player.vehicle", GCKI.argprint(player.vehicle))
GCKI.show("vehicle", GCKI.argprint(vehicle))
GCKI.show("player.vehicle == vehicle", player.vehicle == vehicle)
  if player.vehicle == vehicle then
    GCKI.writeDebug("%s entered %s!",
                    {GCKI.argprint(player), GCKI.argprint(vehicle)})
    GCKI_vehicle.color_vehicle(vehicle, player)
  else
    GCKI.writeDebug("%s left %s!", {GCKI.argprint(player), GCKI.argprint(vehicle)})
    GCKI_vehicle.color_vehicle(vehicle)
  end

  -- Adjust shooter
  GCKI_vehicle.set_shooter(vehicle, occupants)

  GCKI.entered_event(event, "leave")
end


------------------------------------------------------------------------------------
--                                SHORTCUT WAS USED                               --
------------------------------------------------------------------------------------
common_events.on_gui_opened = function(event)
  local vehicle = event.entity
  local player = game.get_player(event.player_index)
  if vehicle and vehicle.valid and player and
      not GCKI_vehicle.can_access_vehicle(vehicle, player) then
    player.opened = nil
    GCKI.output(player, {"GCKI-messages.vehicle-access-denied", GCKI.loc_name(vehicle)})
  end
end

common_events.on_player_changed_surface = function(event)
  local player = game.get_player(event.player_index)
  if player then GCKI_ownership.update_shortcut(player) end
end

common_events.on_player_controller_changed = common_events.on_player_changed_surface

common_events.on_lua_shortcut = function(event)
  GCKI.entered_event(event)

  --~ local player = game.players[event.player_index]
  local player = GCKI.ascertain_player(event.player_index)

  -- In editor or god mode, there is no character, so the game would crash if we continued.
  if not player.character then
    local c = GCKI.controller_names[player.controller_type]
    GCKI.entered_event(event, "leave", "nothing to do in "..c.." mode.")
    return
  end

  -- We're in character mode!
  local shortcut = event.prototype_name

  -- Bail out if this wasn't one of our own shortcuts!
  -- (We only have one now, but there may be more in the future.)
  if not GCKI.prefixed(shortcut, "GCKI_") then
    GCKI.entered_event(event, "leave", "Nothing to do for shortcut \""..shortcut.."\"!")
    return
  end

  -- Everything is OK, we can proceed!
  if shortcut == GCKI.shortcut_name then
    if not GCKI_ownership.can_use(player, true) then return end
    if player.clear_cursor() then
      player.cursor_stack.set_stack({name = GCKI.carkey_name, count = 1})
      GCKI.writeDebug("Changed cursor_stack of player %s", {player.name})
    end
  end

  GCKI.entered_event(event, "leave")
end


------------------------------------------------------------------------------------
--                           SELECT-TOOL (KEY) WAS USED                           --
------------------------------------------------------------------------------------
-- Normally selected area: Init GUI
common_events.on_player_selected_area = function(event)
  GCKI.entered_event(event)

  local item = event.item

  if not GCKI.prefixed(item, "GCKI_") then
    GCKI.entered_event(event, "leave", "Wrong selection tool!")
    return
  end

  player_selected_area(event)

  GCKI.entered_event(event, "leave")
end


-- Alt-selected area: Add to GUI
common_events.on_player_alt_selected_area = function(event)
  GCKI.entered_event(event)

  local item = event.item

  if not GCKI.prefixed(item, "GCKI_") then
    GCKI.entered_event(event, "leave", "Nothing to do for shortcut \""..item.."\"!")
    return
  end

  --~ event.add_vehicles = true
  event.alt_select = true
  player_selected_area(event)

  GCKI.entered_event(event, "leave")
end


-- Reverse-selected area: Remove from GUI
common_events.on_player_reverse_selected_area = function(event)
  GCKI.entered_event(event)

  local item = event.item

  if not GCKI.prefixed(item, "GCKI_") then
    GCKI.entered_event(event, "leave", "Nothing to do for shortcut \""..item.."\"!")
    return
  end

  --~ event.remove_vehicles = true
  event.reverse_select = true
  player_selected_area(event)

  GCKI.entered_event(event, "leave")
end


------------------------------------------------------------------------------------
--                              GUI-ACTION DETECTED!                              --
------------------------------------------------------------------------------------
-- Button clicks
common_events.on_gui_click = function(event)
  GCKI.entered_event(event)

  local element = event.element.name

  -- Return immediately if clicked element is not from one of our GUIs!
  if not GCKI.prefixed(element, GCKI.gui_prefix) then
    -- GCKI.entered_function({}, "leave", "Nothing to do for element \""..element.."\"!")
    GCKI.entered_event(event, "leave", string.format("Nothing to do for %s!", GCKI.argprint(event.element)))
    return
  end

  -- Clicked element from vehicle list for selected area
  if GCKI.prefixed(element, GCKI.gui_select_area_prefix) then
    GCKI.writeDebug("Click on GUI for selected vehicles!")
    GCKI_gui_select_area.on_gui_click(event)
  --~ end

  -- Clicked element from minimap GUI
  --~ if GCKI.prefixed(element, GCKI.gui_player_vehicles_map_prefix) then
  elseif GCKI.prefixed(element, GCKI.gui_player_vehicles_map_prefix) then
    GCKI.writeDebug("Click on minimap GUI!")
    GCKI_gui_player_vehicles_map.on_gui_click(event)
  --~ end

  -- Clicked element from camera GUI
  --~ if GCKI.prefixed(element, GCKI.gui_player_vehicles_camera_prefix) then
  elseif GCKI.prefixed(element, GCKI.gui_player_vehicles_camera_prefix) then
    GCKI.writeDebug("Click on camera GUI!")
    GCKI_gui_player_vehicles_camera.on_gui_click(event)
  --~ end

  -- Clicked element from list of owned/locked vehicles
  --~ if GCKI.prefixed(element, GCKI.gui_player_vehicles_prefix) then
  elseif GCKI.prefixed(element, GCKI.gui_player_vehicles_prefix) then
    GCKI.writeDebug("Click on GUI for claimed/locked vehicles!")
    GCKI_gui_player_vehicles.on_gui_click(event)
  end

  GCKI.entered_event(event, "leave")
end


------------------------------------------------------------------------------------
-- Text entered into text field
common_events.on_gui_text_changed = function(event)
  GCKI.entered_event(event)

  local element = event.element.name

  -- Return immediately if textfield is not from one of our GUIs!
  if not GCKI.prefixed(element, GCKI.gui_prefix) then
    GCKI.entered_event(event, "leave", string.format("Nothing to do for %s!", GCKI.argprint(event.element)))
    return
  end

  -- Input vehicle name (selected area)
  if GCKI.prefixed(element, GCKI.gui_select_area_prefix) then
    GCKI_gui_select_area.on_gui_text_changed(event)

  -- Input vehicle name (vehicles owned/locked by player)
  elseif GCKI.prefixed(element, GCKI.gui_player_vehicles_prefix) then
    GCKI_gui_player_vehicles.on_gui_text_changed(event)
  end

  GCKI.entered_event(event, "leave")
end


------------------------------------------------------------------------------------
-- Finished modifiying text field (confirmed change by using ENTER key)
common_events.on_gui_confirmed = function(event)
  GCKI.entered_event(event)

  local element = event.element.name

  -- Return immediately if textfield is not from one of our GUIs!
  if not GCKI.prefixed(element, GCKI.gui_prefix) then
    GCKI.entered_event(event, "leave", string.format("Nothing to do for %s!", GCKI.argprint(event.element)))
    return
  end


  -- Edited name of vehicle (selected area)
  if GCKI.prefixed(element, GCKI.gui_select_area_prefix) then
    GCKI_gui_select_area.on_gui_confirmed(event)

  -- Edited name of vehicle (claimed/locked vehicles)
  elseif GCKI.prefixed(element, GCKI.gui_player_vehicles_prefix) then
    GCKI_gui_player_vehicles.on_gui_confirmed(event)
  end

  GCKI.entered_event(event, "leave")
end


------------------------------------------------------------------------------------
--                             ENTITY-RELATED EVENTS!                             --
------------------------------------------------------------------------------------
-- Vehicle has been recolored!
common_events.on_entity_color_changed = function(event)
  GCKI.entered_event(event)

  local vehicle = event.entity
GCKI.show("vehicle", GCKI.argprint(vehicle))
GCKI.show("vehicle.color", vehicle and vehicle.valid and serpent.line(vehicle.color or "no vehicle"))

  --~ if not GCKI_vehicle.is_vehicle(vehicle) then
    --~ GCKI.entered_event(event, "leave", "nothing to do for "..GCKI.argprint(vehicle))
    --~ return
  --~ end
  if not (GCKI_vehicle.is_vehicle(vehicle) or
          (AUTODRIVE and GCKI_vehicle.is_Autodrive_vehicle(vehicle))) then
    GCKI.entered_event(event, "leave", "nothing to do for "..GCKI.argprint(vehicle))
    return
  end

  local v_id = vehicle.unit_number

  -- Quit if we've changed the color ourselves!
  if mod.expect_color_change then
    GCKI.writeDebugNewBlock("Looking for expected color changes!")
    local expected = mod.expect_color_change[v_id]
GCKI.show("expected color", expected)

    -- Vehicle has expected color, we can quit!
    if expected and GCKI.compare_colors(expected, vehicle.color) then
      GCKI.writeDebug("Removing mark for %s.", {GCKI.argprint(vehicle)})
      GCKI_vehicle.unmark_color_change(vehicle)

      GCKI.entered_event(event, "leave", "expected color change")
      return
    end
  end

  -- We don't want to raise on_entity_color_changed unless necessary, so we only
  -- update the color if it's original and new color are different.
  mod.vehicles_orig_color = mod.vehicles_orig_color or {}
  local v_colors = mod.vehicles_orig_color
  --~ local store = {
    --~ entity = vehicle,
    --~ color = util.table.deepcopy(vehicle.color)
  --~ }
GCKI.show("v_colors", v_colors)

  --~ -- Add new entry
  --~ if not v_colors[v_id] then
    --~ GCKI.writeDebug("Adding global.vehicles_orig_color[%s]: %s",
                    --~ {v_id, vehicle.color})
    --~ v_colors[v_id] = util.table.deepcopy(store)

    --~ GCKI.writeDebug("Resetting vehicle color!")
    --~ GCKI_vehicle.color_vehicle(vehicle)

  --~ -- Update existing entry?
  --~ elseif not GCKI.compare_colors(v_colors[v_id], vehicle.color) then
    --~ GCKI.writeDebug("Updating global.vehicles_orig_color[%s]: %s",
                    --~ {v_id, vehicle.color})
    --~ v_colors[v_id].color = util.table.deepcopy(store.color)

    --~ GCKI.writeDebug("Resetting vehicle color!")
    --~ GCKI_vehicle.color_vehicle(vehicle)

  --~ -- Color hasn't changed!
  --~ else
    --~ GCKI.writeDebug("Color of %s didn't change!", {GCKI.argprint(vehicle)})
  --~ end

  -- Add or update entry
  --~ if not (v_colors[v_id] and GCKI.compare_colors(v_colors[v_id], vehicle.color)) then
  local stored = v_colors[v_id]
  if not (stored and GCKI.compare_colors(stored.color, vehicle.color)) then
    GCKI.writeDebug("%s mod.vehicles_orig_color[%s]: %s",
                    {stored and "Updating" or "Adding", v_id, vehicle.color}, "line")
    --~ v_colors[v_id] = {
      --~ entity = vehicle,
      --~ color = util.table.deepcopy(vehicle.color)
    --~ }
    GCKI_vehicle.store_orig_color(vehicle)

    GCKI.writeDebug("Resetting vehicle color!")
    GCKI_vehicle.color_vehicle(vehicle)

  -- Color hasn't changed!
  else
    GCKI.writeDebug("Color of %s didn't change!", {GCKI.argprint(vehicle)})
  end

  GCKI.entered_event(event, "leave")
end


------------------------------------------------------------------------------------
-- Spider vehicle has been renamed via the entity GUI
common_events.on_entity_renamed = function(event)
  GCKI.entered_event(event)

  local vehicle = GCKI_vehicle.is_vehicle(event.entity) and event.entity
GCKI.show("vehicle", GCKI.argprint(vehicle))

  -- Return if this is none of the spider-vehicles we care about!
  if not vehicle or vehicle.type ~= "spider-vehicle" then
    GCKI.entered_event(event, "leave", "not a proper spider-vehicle type")
    return
  end

  -- If by_script is true, event.player_index will be nil!
GCKI.show("game.players["..tostring(event.player_index).."]",
          GCKI.argprint(event.player_index and game.get_player(event.player_index)))
GCKI.show("vehicle.last_user", GCKI.argprint(vehicle.last_user))
  --~ local player = event.player_index and game.players[event.player_index] or
                                        --~ vehicle.last_user
  local player = event.player_index and game.get_player(event.player_index) or
                                        vehicle.last_user
GCKI.show("player", GCKI.argprint(player))

  local old_name = event.old_name
  local new_name = vehicle.entity_label
  local named_id = mod.named_vehicles.by_name[old_name]
  local named_by = mod.named_vehicles.by_id[named_id] and
                    mod.named_vehicles.by_id[named_id].named_by
GCKI.show("old_name", old_name)
GCKI.show("new_name", new_name)
GCKI.show("named_id", named_id)
GCKI.show("named_by", GCKI.argprint(named_by))

  local update_guis

  -- We've stored the old name!
  if named_by then
GCKI.writeDebug("Name %s has been stored!", {GCKI.argprint(old_name)})

    if old_name ~= new_name then
GCKI.writeDebug("%s and %s differ!", {GCKI.argprint(old_name), GCKI.argprint(new_name)})
      -- Name has been changed by someone who was not authorized!
GCKI.show(player.index.." ~= "..GCKI.argprint(named_by), player.index ~= named_by)
      if player.index ~= named_by then
        GCKI.writeDebug("%s is not allowed to change custom name of %s. Reset!",
                        {GCKI.argprint(player), GCKI.argprint(vehicle)})
        vehicle.entity_label = old_name

      -- Update name!
      else
        GCKI.writeDebug("%s may change custom name of %s.",
                        {GCKI.argprint(player), GCKI.argprint(vehicle)})

        -- We've got a new name
        if new_name then
GCKI.writeDebug("Changing custom name to %s.", {GCKI.argprint(new_name)})
          local args = {player = player, vehicle = vehicle, new_name = new_name}
          GCKI_vehicle.edit_vehicle_name(args, script.mod_name)

        -- Remove the name!
        else
          -- Unlike edit_vehicle_name, remove_vehicle_name won't update the GUIs!
          update_guis = true

          GCKI.writeDebug("Removing custom name %s.", {GCKI.argprint(old_name)})
          GCKI_vehicle.remove_vehicle_name(vehicle.unit_number, script.mod_name)
        end

      end
    end

  -- The vehicle has been claimed or locked, but has no custom name yet/anymore
  --~ elseif mod.GCKI_vehicles[vehicle.unit_number] then
  elseif GCKI_vehicle.is_vehicle(vehicle) then
    if new_name then
      GCKI.writeDebug("Adding new custom name %s to %s!",
                      {GCKI.argprint(new_name), GCKI.argprint(vehicle)})
      local args = {player = player, vehicle = vehicle, new_name = new_name}
      GCKI_vehicle.edit_vehicle_name(args, script.mod_name)
    else
      -- Unlike edit_vehicle_name, remove_vehicle_name won't update the GUIs!
      update_guis = true

      GCKI.writeDebug("Removing custom name %s from %s!",
                      {GCKI.argprint(old_name), GCKI.argprint(vehicle)})
      GCKI_vehicle.remove_vehicle_name(vehicle.unit_number, script.mod_name)
    end
  end

  if update_guis then
    -- Update GUIs!
    GCKI.writeDebug("Must update name of %s in GUIs!", {GCKI.argprint(vehicle)})
    GCKI_gui.update_guis(vehicle)
  end

  GCKI.entered_event(event, "leave")
end


------------------------------------------------------------------------------------
------------------------------------------------------------------------------------
-- Toggled checkbox
common_events.on_gui_checked_state_changed = function(event)
  GCKI.entered_event(event)

  local element = event.element.name

  -- Return immediately if checkbox is not from one of our GUIs!
  if not GCKI.prefixed(element, GCKI.gui_prefix) then
    GCKI.entered_event(event, "leave", string.format("Nothing to do for %s!", GCKI.argprint(event.element)))
    return
  end

  -- Toggled element of GUI for player-selected vehicles
  if GCKI.prefixed(element, GCKI.gui_select_area_prefix) then
    GCKI_gui_select_area.on_gui_checked_state_changed(event)

  -- Toggled element of GUI for vehicles owned/locked by player
  elseif GCKI.prefixed(element, GCKI.gui_player_vehicles_prefix) then
    GCKI_gui_player_vehicles.on_gui_checked_state_changed(event)
  end

  GCKI.entered_event(event, "leave")
end



------------------------------------------------------------------------------------
--    GCKI custom events. Just to verify the event is raised with correct data!   --
------------------------------------------------------------------------------------
--~ common_events.on_GCKI_teleported_vehicle = function(event)
  --~ GCKI.entered_event(event)

  --~ GCKI.entered_event(event, "leave")
--~ end

common_events.on_vehicle_changed_force = function(event)
  GCKI.entered_event(event)

  GCKI.entered_event(event, "leave")
end


------------------------------------------------------------------------------------
--                          Custom events from other mods                         --
------------------------------------------------------------------------------------
-- SpidertronWeaponSwitcher: When a spidertron is switched, the entity is destroyed
-- and replaced with a new one that has different weapons
common_events.on_spidertron_switched = function(event)
  GCKI.entered_event(event)

  local new_entity = event.new_spidertron
  local old_entity = event.old_spidertron

  -- Both entities must be valid and of a prototype we support
  if GCKI_vehicle.is_vehicle(new_entity) and
      GCKI_vehicle.is_vehicle(old_entity) then

    GCKI.writeDebug("Must replace %s with %s in GUIs and tables!",
                  {GCKI.argprint(old_entity), GCKI.argprint(new_entity)})

    GCKI_vehicle.replace_vehicle({
      new_entity = new_entity,
      --~ old_entity_unit_number = old_entity.unit_number,
      old_entity = old_entity,
    })
  end

  GCKI.entered_event(event, "leave")
end



-- Custom Color: A car has been added or its color has been changed
common_events.car_saved = function(event)
  GCKI.entered_event(event)

  GCKI.entered_event(event, "leave")
end


-- Custom Color: Stopped managing this car
common_events.car_removed = function(event)
  GCKI.entered_event(event)

  GCKI.entered_event(event, "leave")
end


-- Custom Color: Color of car has been changed by player
common_events.car_paint_player = function(event)
  GCKI.entered_event(event)

  GCKI.entered_event(event, "leave")
end


-- Custom Color: Original color of car has been restored
common_events.car_return_color = function(event)
  GCKI.entered_event(event)

  GCKI.entered_event(event, "leave")
end

------------------------------------------------------------------------------------
GCKI.entered_file("leave")
return common_events
