log("Entered file " .. debug.getinfo(1).source)
require("util")


local mod_data = require("__gcki-continued__/mod_data")
-- We want luacheck to ignore "loop is executed at most once"
do
  -- luacheck: ignore
  if data then
  --~ mod_data.include = {"item_functions", "recipe_functions"}
  elseif script then
    mod_data.include = "string_functions"
  end
end


local common = require("__Pi-C_lib__/common")(mod_data)
common.show("common", common)


------------------------------------------------------------------------------------
--                         Schedule output of flying text.                        --
------------------------------------------------------------------------------------
local function schedule_flying_text(player, msg)
  common.entered_function({player, msg})

  player = common.ascertain_player(player)
  msg = (type(msg) == "table") and next(msg) and msg
common.show("msg", msg)

  if player and player.valid and msg then
    local index = player.index

    -- Earliest output will be on next tick!
    local tick = game.tick + 1
    local last_flying = mod.player_messages[index].last_flying

    -- Add message to queue
    mod.player_messages[index].flying = mod.player_messages[index].flying or {}
    table.insert(mod.player_messages[index].flying, msg)
common.writeDebug("Added message to queue of %s: %s", {common.argprint(player), msg})

    -- There already are messages in the queue, don't interfere with their schedule!
    if (not last_flying) or (last_flying < tick) then
      mod.player_messages[index].last_flying = tick
      mod.player_messages.ticks[tick] = mod.player_messages.ticks[tick] or {}
      mod.player_messages.ticks[tick][index] = true

      -- Activate listener for on_tick to output?
      if not mod.enable_optional_events.on_tick then
        script.on_event(defines.events.on_tick, GCKI_events.on_tick)
        mod.enable_optional_events.on_tick = true
        common.writeDebug("Activated listener for on_tick event!")
      end
    end
  end

  common.entered_function("leave")
end


------------------------------------------------------------------------------------
------------------------------------------------------------------------------------
--                            Variables and tables                                --
------------------------------------------------------------------------------------
------------------------------------------------------------------------------------





------------------------------------------------------------------------------------
-- Vehicles must be one of these prototypes
common.vehicle_types = { "car", "spider-vehicle", }

------------------------------------------------------------------------------------
-- Patterns for black-/whitelisting vehicle prototypes will be stored here in the
-- data stage. (We'll store them in global while the game is running!)
common.patterns = {}

------------------------------------------------------------------------------------
-- Name of the key prototype
common.carkey_name = "GCKI_car-key"

-- Name of the shortcut for the keys
common.shortcut_name = common.carkey_name.."-shortcut"

-- Name of the custom-input for the keys
common.custominput_spawn_carkey = common.carkey_name.."-custom-input"

-- Names of our custom events
common.custom_events = {"on_vehicle_changed_force", }

------------------------------------------------------------------------------------
-- If the distance between owner and vehicle is greater than this value, we will
-- output messages for the owner. (Default: 32 tiles, i.e. 1 chunk)
common.message_owner_distance = 32

------------------------------------------------------------------------------------
-- Claiming/locking/summoning a vehicle and driver state changes are expensive
-- events, so a delay of this many ticks is enforced for these events
common.ACTION_DELAY = 60
-- If there are several messages in a player's flying text queue, we'll wait this
-- many ticks before printing the next message!
common.FLYING_TEXT_DELAY = 30
-- Flying text will be visible for this many ticks
common.FLYING_TEXT_TTL = 300
-- We'll want to clean up tables of GCKI-controlled vehicles about once per hour
common.CLEANUP_VEHICLES_INTERVAL = 60 * 60 * 60 + 666 -- (1h + 11.1s)
-- We'll want to clean up player data about once per minute
common.CLEANUP_PLAYERDATA_INTERVAL = 60 * 60 + 666 -- (1min + 11.1s)
-- We'll want to remove expired renderings from table about every 15 minutes
common.CLEANUP_RENDERINGS_INTERVAL = 60 * 60 * 15

-- Default zoom factor for minimap and camera
common.ZOOM_DEFAULT = 1
-- Maximal zoom will be capped at this value
common.ZOOM_MAX = 4
-- Minimal zoom will be capped at this value
common.ZOOM_MIN = 0.25
-- Increase or reduce zoom factor by this value per click
common.ZOOM_STEP = 0.05

-- Mods and their techs that should unlock our car keys
local unlock_tech_map_by_mod = {
  -- Required mod         Technologies
  ["base"]              = "automobilism",
  ["nullius"]           = "nullius-personal-transportation-1",
  ["cargo-ships"]       = "water_transport",
}
common.unlock_tech_map = {}
for mod_name, tech_names in pairs(unlock_tech_map_by_mod) do
  if common.check_mods(mod_name) then
    -- Prepare for mods that may offer several unlock technologies!
    tech_names = type(tech_names) == "table" and tech_names or {tech_names}
    for t, tech_name in pairs(tech_names) do
      -- In common.is_unlock_tech_researched, we use an array of technology names
      -- and fall back to this list if no techs have been passed on. Therefore, it
      -- is not enough that we can look up the tech name in this list (because it
      -- is used as index), but we must also get the techname as value!
      common.unlock_tech_map[tech_name] = tech_name
    end
  end
end
common.show("common.unlock_tech_map", common.unlock_tech_map)

common.gui_prefix = "GCKI_"
common.gui_select_area_prefix = common.gui_prefix.."select_area_"
common.gui_player_vehicles_prefix = common.gui_prefix.."player_vehicles_"
common.gui_player_vehicles_map_prefix = common.gui_prefix.."player_vehicles_map_"
common.gui_player_vehicles_camera_prefix = common.gui_prefix.."player_vehicles_camera_"



------------------------------------------------------------------------------------
-- Name of the hidden surface from Vehicle Wagons
common.VW_hidden_surface_name = "vehicle-wagon-hidden"

-- Prefix for names of forces created by "Blueprint Sandboxes"
common.BPS_force_name_prefix = "bpsb-sb-f-"

------------------------------------------------------------------------------------
------------------------------------------------------------------------------------
--                            Miscalleneous functions                             --
------------------------------------------------------------------------------------
------------------------------------------------------------------------------------


------------------------------------------------------------------------------------
-- Read startup settings
common.get_startup_settings= function()
  common.entered_function()

  mod.settings = mod.settings or {}

  local s = settings.startup
  local gs = mod.settings

  --~ gs.debug_in_log             = get_value(s["GCKI-debug_in_log"])
  gs.debug_in_log = common.get_setting_value(s["GCKI-debug_in_log"])
  common.show("debug_in_log", gs.debug_in_log)

  common.entered_function("leave")
end

--~ ------------------------------------------------------------------------------------
--~ -- Read a global runtime setting
--~ common.get_global_setting = function(setting)
  --~ -- common.entered_function({setting})

  --~ common.assert(setting, "string", "name of a global setting")

  --~ return get_value(settings.global[setting])
--~ end

------------------------------------------------------------------------------------
-- Read global runtime settings
common.get_global_settings = function()
  common.entered_function()

  mod.settings = {}

  local gs = mod.settings
  local s = common.get_global_setting

  gs.player_keeps_vehicles    = s("GCKI-change-force_player-keeps-vehicles")
  common.show("player_keeps_vehicles", gs.player_keeps_vehicles)

  gs.eject_on_changed_force   = s("GCKI-change-force_eject")
  common.show("eject_on_changed_force", gs.eject_on_changed_force)

  gs.long_reach               = s("GCKI-long_reach")
  common.show("long_reach", gs.long_reach)

  gs.lose_vehicles_on_reset   = s("GCKI-lose-vehicles-on-force-reset")
  common.show("lose_vehicles_on_reset", gs.lose_vehicles_on_reset)

  gs.lose_vehicles_on_unresearch = s("GCKI-lose-vehicles-on-research-reverted")
  common.show("lose_vehicles_on_unresearch", gs.lose_vehicles_on_unresearch)

  common.entered_function("leave")
end


------------------------------------------------------------------------------------
-- Check whether any player has activated a certain Boolean per-user setting. We
-- need that for example to set common.is_debug (skips functions for debugging
-- output unless they are needed), or to deactivate the on-tick scheduling of
-- flying texts.
common.check_bool_user_setting = function(setting)
  local p_settings, state

  if game then
    --~ local stored = mod.player_data
    for p, player in pairs(game.players) do
      p_settings = mod.player_data and mod.player_data[p] and
                    mod.player_data[p].settings
      --~ p_settings = stored and stored[p] and stored[p].settings
      -- If there was only one player who had this set to true, and if this player
      -- is removed from the game, we want to reset this.
      state = p_settings and p_settings[setting]
      -- Once this is true, we can stop checking the other players' settings!
      if state then
        break
      end
    end
  end
  return state or false
end

------------------------------------------------------------------------------------
-- Set common.debug_in_game to true if at least one player has activated the option
common.set_debug_in_game = function()
  if game then
    mod.settings.debug_in_game = common.check_bool_user_setting("debug_in_game")

    -- We only need to know the real values of debug_in_log and debug_in_game in the
    -- actual output function. Before we enter this, it's enough to know whether
    -- we'll need to output anything at all!
    common.is_debug = common.debug_in_log or mod.settings.debug_in_game
  end
end

--~ ------------------------------------------------------------------------------------
--~ -- Look for matching pattern at start of a string
--~ common.prefixed = function(look_in, find_at_start)
  --~ common.assert(look_in, "string")
  --~ common.assert(find_at_start, "string")
  --~ return look_in:sub(1, #find_at_start) == find_at_start
--~ end


----------------------------------------------------------------------------------
--   Check whether a force has researched at least one of the necessary techs!  --
----------------------------------------------------------------------------------
common.is_unlock_tech_researched = function(force, techs)
  common.entered_function({force, techs})

  -- We'll need a valid force!
  force = common.ascertain_force(force)
  if not (force and force.valid) then
    common.arg_err(force, "force specification")
  end

  -- Fall back to default unlock techs if no techs are passed on!
  do
    common.assert(techs, {"string", "table", "nil"}, "name, table of techs or nil")
    local t = type(techs)
    if t == "string" then
      techs = {techs}
    elseif (t == "nil" or not next(techs)) then
      techs = common.unlock_tech_map
    end
  end

  mod.force_data[force.name] = mod.force_data[force.name] or {}
  local force_researched = mod.force_data[force.name].researched

  local ret = false

  -- List of tech is initialized
  if force_researched then
    if next(force_researched) then
      for t, tech in pairs(techs) do
        if force_researched[tech] then
          ret = true
          common.writeDebug("%s has researched tech \"%s\"!", {common.argprint(force), tech})
          break
        end
      end
    end

  -- Must initialize tech list
  else
    mod.force_data[force.name].researched = {}
    for tech, t  in pairs(techs) do
      if force.technologies[tech] and force.technologies[tech].researched then
        mod.force_data[force.name].researched[tech] = true
        ret = true
      end
    end
  end

  common.entered_function("leave")
  return ret
end

------------------------------------------------------------------------------------
-- Set common.flying_text to false if no player has activated the option, so we can
-- skip the scheduling of flying texts in on_tick!
common.set_flying_text = function()
  common.entered_function()
  -- This will be nil in on_load!
  mod.need_flying_text = game and common.check_bool_user_setting("flying_text")
  common.entered_function("leave")
end



------------------------------------------------------------------------------------
------------------------------------------------------------------------------------
--                                String functions                                --
------------------------------------------------------------------------------------
------------------------------------------------------------------------------------

------------------------------------------------------------------------------------
--~ -- Remove characters at beginning or end of a string
--~ common.trim_chars = function(remove_from, left, right)

  --~ common.assert(remove_from, "string")
  --~ common.assert(left, "string")
  --~ right = type(right) == "string" and right or left

  --~ -- "*" returns the longest possible match, "-" the shortest
  --~ local pattern = "^["..left.."]*(.-)["..right.."]*$"
  --~ -- local ret = remove_from:match(pattern)

  --~ -- return ret
  --~ return remove_from:match(pattern)
--~ end

------------------------------------------------------------------------------------
-- Localize entity names for output routines
-- (Returns localized entity name; falls back to entity name, or to default string)
-- (GCKI specific: If players have set a custom name for a vehicle, add this to the
-- localized string!)
common.loc_name = function(entity, flags)
  common.assert(entity, "LuaEntity", "entity")
  common.assert(flags, {"table", "nil"}, "nil or table of flags")

  local ignore_custom_name = flags and flags.ignore_custom_name
  local ignore_unit_number = flags and flags.ignore_unit_number

  -- Get localized name of entity
  local id = entity and entity.valid and entity.unit_number
  local loc_name = (not entity and "nil") or
                    (not entity.valid and entity.object_name) or
                    entity.localised_name or entity.name

  -- If not prevented by flags, get unique identifier to add to localized name
  local append
  do
    -- Try to get custom name?
    if not ignore_custom_name then
      local name_by_id = id and mod.named_vehicles.by_id[id]
      append = name_by_id and name_by_id.name and common.enquote(name_by_id.name)
    end

    -- Fall back to unit_number?
    if not (append or ignore_unit_number) then
      append = id
    end
  end

  return {"", loc_name, append and " ", append}
end



------------------------------------------------------------------------------------
------------------------------------------------------------------------------------
--                                Output functions                                --
------------------------------------------------------------------------------------
------------------------------------------------------------------------------------


--~ ------------------------------------------------------------------------------------
--~ -- Print error messages for invalid commands
--~ common.command_err = function(player, msg)
  --~ common.entered_function({player, msg})

  --~ player = common.ascertain_player(player)

  --~ if player and player.valid then
    --~ local output = {"GCKI-command-errors.error", msg}
    --~ player.print(output)
    --~ log({"", "Command error (player \"", player.name, "\")\n", output})
  --~ end

  --~ --~common.entered_function("leave")
--~ end


------------------------------------------------------------------------------------
-- Output: Print game info to a specific user
common.output = function(player, msg)
  player = common.ascertain_player(player)

  if player and player.valid then
    --~ local settings = global.player_data[player.index] and
                      --~ global.player_data[player.index].settings
    local stored = (mod and mod.player_data) or
                    (storage and storage.player_data)
    local settings = stored and stored[player.index] and
                                stored[player.index].settings
    -- Flying text
    if settings and settings.flying_text then
      schedule_flying_text(player, msg)

    -- Print to console
    else
      player.print({"", msg})
    end
  end
end


------------------------------------------------------------------------------------
-- Hint: Avoid spam by allowing players who know the mod to turn off some messages
common.hint = function(player, msg)
  player = common.ascertain_player(player)
  local settings = player and player.valid and
                    storage.player_data[player.index] and
                    storage.player_data[player.index].settings
  if settings and settings.show_hints then
    common.output(player, {"GCKI-messages.hints", msg})
  end
end

--~ ------------------------------------------------------------------------------------
--~ -- Append strings to a message
--~ common.add_to_msg = function(msg, strings)
  --~ for a, add in pairs(strings) do
    --~ table.insert(msg, add)
  --~ end

  --~ return msg
--~ end


------------------------------------------------------------------------------------
-- Format position (long format)
common.format_position = function(position)
  common.entered_function({position})
  position = common.normalize_position(position)
  return string.format("x=%s, y=%s", position.x, position.y)
end


------------------------------------------------------------------------------------
-- Format position (short format)
common.format_position_short = function(position)
  common.entered_function({position})
  position = common.normalize_position(position)
  --~ return position.x..", "..position.y
  return position.x..", "..position.y
end

--~ ------------------------------------------------------------------------------------
--~ -- Function to measure distance between two positions
--~ common.get_distance = function(pos_a, pos_b)
  --~ common.entered_function({pos_a, pos_b})

  --~ pos_a = common.normalize_position(pos_a)
  --~ pos_b = common.normalize_position(pos_b)

  --~ local x, y = pos_a.x - pos_b.x, pos_a.y - pos_b.y
  --~ return math.sqrt(x*x + y*y)
--~ end

--~ ------------------------------------------------------------------------------------
--~ -- Return true if the distance between pos_a and pos_b is greater than max_distance
--~ common.distance_exceeds = function(pos_a, pos_b, max_distance)
  --~ common.entered_function({pos_a, pos_b, max_distance})

  --~ return common.get_distance(pos_a, pos_b) > max_distance
--~ end


--~ ------------------------------------------------------------------------------------
--~ -- What is the maximum distance the player can reach?
--~ common.get_player_reach = function(player)
  --~ common.entered_function({player})

  --~ player = common.ascertain_player(player)
  --~ if not (player and player.valid) then
    --~ common.arg_err(player, "player_specification")
  --~ end

  --~ return global.settings.long_reach and
          --~ player.reach_distance or
          --~ player.reach_distance - player.character_reach_distance_bonus
--~ end


--~ ------------------------------------------------------------------------------------
--~ -- Is the given position within player.reach_distance from player.position?
--~ common.is_in_reach = function(player, position)
  --~ common.entered_function({player, position})

  --~ player = common.ascertain_player(player)
  --~ if not (player and player.valid) then
    --~ common.arg_err(player, "player_specification")
  --~ end

  --~ local max_distance = common.get_player_reach(player)
  -- return not common.distance_exceeds(player.position, position, max_distance)
  --~ return not GCKI_calc.distance_exceeds(player.position, position, max_distance)
--~ end


--~ -- Remote calls made easy (check for remote interface and function)
--~ common.remote_call = function(interface, func, ...)
  --~ common.entered_function({interface, func, ...})

  --~ common.assert(interface, "string")
  --~ common.assert(func, "string")

  --~ local args = {...}

  --~ local ret
  --~ if remote.interfaces[interface] and remote.interfaces[interface][func] then
    --~ common.writeDebug("Calling function %s of interface %s!", {func, interface})
    --~ ret = remote.call(interface, func, table.unpack(args))
  --~ end

  --~ common.entered_function("leave")
  --~ return ret
--~ end


--~ ----------------------------------------------------------------------------------
--~ --               Swap values of 'a' and 'b' if 'condition' is true              --
--~ ----------------------------------------------------------------------------------
--~ common.swap_args = function(a, b, condition)
  --~ common.entered_function({a, b, condition})

  --~ if a and condition and b == nil then
    --~ b, a = a, nil
    --~ common.show("a", a)
    --~ common.show("b", b)
  --~ end

  --~ common.entered_function("leave")
  --~ return a, b
--~ end

------------------------------------------------------------------------------------
common.entered_file("leave")
return common
