-- Make sure that GCKI really exists! (If a tutorial from Tips and Tricks is started,
-- the migration will be applied to a mod named "level" and none of our global
-- variables will be defined.)
GCKI = GCKI or require('__gcki-continued__.common')()
GCKI.entered_file()

------------------------------------------------------------------------------------
-- We should move tables storing info for compatibility with other mods into a    --
-- dedicated subtable in order to keep the global table more tidy!                --
------------------------------------------------------------------------------------
-- Prepare for storing compatibility data of more mods than "Unminable Vehicles"
if not storage.mod_compatibility then
  storage.mod_compatibility = {}
  GCKI.writeDebug("Generated new table \"storage.mod_compatibility\"")

  if storage.UnminableVehicles ~= nil then
    storage.mod_compatibility.UnminableVehicles = table.deepcopy(storage.UnminableVehicles)
    storage.UnminableVehicles = nil
    GCKI.writeDebug("Moved \"storage.UnminableVehicles\" to \"storage.mod_compatibility\"!")
  end
end


------------------------------------------------------------------------------------
--              We now combine different global tables in player_data             --
------------------------------------------------------------------------------------
storage.player_data = storage.player_data or {}
for p, player in pairs(game.players) do
  storage.player_data[p] = storage.player_data[p] or {}
end

local p_data

-- Move settings from global table to player_data
for p, p_settings in pairs(storage.player_settings or {}) do
  p_data = storage.player_data[p]

  if p_data then
    p_data.settings = table.deepcopy(p_settings)
    GCKI.writeDebug("Moved settings of player %s to storage.player_data.", {p})
  end
end
storage.player_settings = nil
GCKI.writeDebug("Removed storage.player_settings!")


-- Move skip_state_change_for_player to player_data
for p, skip in pairs(storage.skip_state_change_for_player or {}) do
  storage.player_data[p].skip_state_change = storage.skip_state_change_for_player[p]
  GCKI.writeDebug("Added storage.player_data[%s].skip_state_change: %s",
                  {p, storage.player_data[p].skip_state_change})
end
storage.skip_state_change_for_player = nil
GCKI.writeDebug("Removed storage.skip_state_change_for_player!")

------------------------------------------------------------------------------------
--           We'll use one timer per player now, remove the global one!           --
------------------------------------------------------------------------------------
storage.ticks_since_action = nil
GCKI.writeDebug("Removed storage.ticks_since_action!")


------------------------------------------------------------------------------------
-- We now use flying text messages in addition to renderings. Store both types as --
-- subtables in a combined table and remove the obsolete storage.render_msgs!     --
------------------------------------------------------------------------------------
storage.player_messages = storage.player_messages or {}
storage.player_messages.ticks = storage.player_messages.ticks or {}

local render_msgs = storage.render_msgs
for p, player in pairs(game.players) do
  -- Create new tables
  storage.player_messages[p] = storage.player_messages[p] or {}
  storage.player_messages[p].flying = storage.player_messages[p].flying or {}
  storage.player_messages[p].render = storage.player_messages[p].render or {}
  storage.player_messages.ticks = storage.player_messages.ticks or {}

  -- Move renderings from old to new table
  local render_object
  for m, msg_data in pairs(render_msgs and render_msgs[p] or {}) do
    --~ r = msg_data.ID and rendering.get_object_by_id(msg_data.ID)
    --~ if r and r.valid then
    render_object = GCKI.ascertain_rendering(msg_data.ID)
    if render_object and render_object.valid then
      table.insert(storage.player_messages[p].render, msg_data)
      GCKI.writeDebug("Player %s: moved msg %s to new table!", {p, m})
    end
  end
  GCKI.show("storage.player_messages["..p.."].render",
            storage.player_messages[p].render)
end

-- Remove old table
storage.render_msgs = nil
GCKI.writeDebug("Removed storage.render_msgs!")


------------------------------------------------------------------------------------
--    Store vehicles that are owned or claimed by players in their player_data    --
------------------------------------------------------------------------------------
local function add_it(player, vehicle)
  local player_data = storage.player_data[player]

  if vehicle and vehicle.valid then
    player_data.locked_or_owned = player_data.locked_or_owned or {}
    player_data.locked_or_owned[vehicle.unit_number] = vehicle
    GCKI.writeDebug("Added %s to list of vehicles locked or owned by player %s.",
                    {GCKI.argprint(vehicle), player})
  end
end

for v, v_data in pairs(storage.GCKI_vehicles or {}) do
  if v_data.entity and v_data.entity.valid then
    if v_data.owner then
      add_it(v_data.owner, v_data.entity)
    elseif v_data.locker then
      add_it(v_data.locker, v_data.entity)
    end
  end
end


------------------------------------------------------------------------------------
--                            Add table for force data                            --
------------------------------------------------------------------------------------
storage.force_data = storage.force_data or {}

-- Show the shortcut?
local unlock, msg
GCKI.writeDebug("Rebuilding storage.force_data!")

for f_name, force in pairs(game.forces) do
  GCKI.writeDebug("Checking force %s.", {GCKI.enquote(f_name)})

  -- Only store data if there are players on the force!
  if next(force.players) then
    unlock = GCKI.is_unlock_tech_researched(f_name)
    storage.force_data[f_name] = storage.force_data[f_name] or {}
    storage.force_data[f_name].show_shortcuts = unlock

    msg = string.format("Must %slock shortcut for players on force \"%%s\"",
                        unlock and "un" or "")
    GCKI.writeDebug(msg, {f_name})

    for p, player in pairs(force.players) do
      player.set_shortcut_available(GCKI.shortcut_name, unlock)
      GCKI.writeDebug("%sabled shortcut %s for %s!", {
        unlock and "En" or "Dis",
        GCKI.enquote(GCKI.shortcut_name),
        GCKI.argprint(player)
      })
    end

  -- Remove data of forces without players
  elseif storage.force_data[f_name] then
    storage.force_data[f_name] = nil
    GCKI.writeDebug("Removed storage.force_data[%s]: no players on force!",
                    {GCKI.enquote(f_name)})
  else
    GCKI.writeDebug("Nothing to do!")
  end
end


-- Remove data of non-existent forces
GCKI.writeDebug("Looking for data of non-existing forces.")
for f_name, f_data in pairs(storage.force_data or {}) do
  if not (game.forces[f_name] and game.forces[f_name].valid) then
    storage.force_data[f_name] = nil
    GCKI.writeDebug("Removed storage.force_data[%s]: force doesn't exist!",
                    {GCKI.enquote(f_name)})
  end
end


------------------------------------------------------------------------------------
GCKI.entered_file("leave")
