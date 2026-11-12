GCKI.entered_file()

local commands = {}


------------------------------------------------------------------------------------
------------------------------------------------------------------------------------
--                                LOCAL DEFINITIONS                               --
------------------------------------------------------------------------------------
------------------------------------------------------------------------------------
commands.get_setting = function(p_index, setting)
  setting = setting:match("^GCKI%-(.+)")
  return mod.player_data[p_index].settings and
          mod.player_data[p_index].settings[setting]
end


local function unlock_vehicle(vehicle_id)
  GCKI.entered_function({vehicle_id})

  local vehicle = vehicle_id and mod.GCKI_vehicles and mod.GCKI_vehicles[vehicle_id]

  if vehicle and vehicle.locker then
    GCKI.writeDebug("Trying to unlock vehicle %s.", {vehicle_id})
    GCKI_vehicle.remove_vehicle_locker(vehicle.entity, vehicle.locker)
    if not vehicle.owner then
      GCKI.writeDebug("No owner found: Removing %s from vehicle list!",
                      {GCKI.argprint(vehicle.entity)})
      GCKI_vehicle.remove_vehicle(vehicle.entity)
    end
  end

  GCKI.entered_function("leave")
end


local function unlock_all_vehicles()
  GCKI.entered_function()

  local cnt, p_cnt = 0, 0
  for player, vehicles in pairs(mod.lockers) do
    p_cnt = p_cnt + 1
    GCKI.show("Vehicles of player "..player, vehicles)
    for v_id, v in pairs(vehicles) do
      unlock_vehicle(v_id)
      cnt = cnt + 1
    end
  end
  GCKI.writeDebug("Unlocked all %s vehicles of %s players!", {cnt, p_cnt})

  GCKI.entered_function("leave")
end


local function unlock_player_vehicles(player)
  GCKI.entered_function({player})

  player = GCKI.ascertain_player(player)
  if not (player and player.valid) then
    GCKI.arg_err(player, "player specification")
  end

  --~ local locked_by_player = global.lockers and global.lockers[player.index]
  local cnt = 0
  for v_id, v in pairs(mod.lockers and mod.lockers[player.index] or {}) do
    unlock_vehicle(v_id)
    cnt = cnt + 1
  end
  GCKI.writeDebug("Unlocked %s vehicles locked by %s.", {cnt, GCKI.argprint(player)})

  GCKI.entered_function("leave")
end



------------------------------------------------------------------------------------
------------------------------------------------------------------------------------
--                                    COMMANDS                                    --
------------------------------------------------------------------------------------
------------------------------------------------------------------------------------

-- Create commands that either toggle settings with Boolean values or print the current
-- state of these settings
commands.create_command = function(setting)
  GCKI.entered_function({setting})

  commands[setting] = function(command)
    GCKI.entered_command(command)

    --~ local player = game.players[command.player_index]
    local player = game.get_player(command.player_index)
    local status = commands.get_setting(player.index, setting)
    local msg

    --~ local arg = command.parameter and GCKI_String.split(GCKI_String.trim(command.parameter), "%s")
    local arg = command.parameter and
                util.split_whitespace(GCKI_string.trim_chars(command.parameter, "%s"))
    arg = arg and next(arg) and string.lower(arg[next(arg)])

    -- Toggle setting if there is no argument or argument is "toggle"
    local toggle = (arg == "toggle") or (not arg)

    -- Show status
    if (arg == "status") then
      msg = "status"
    -- Turn setting on
    elseif (arg == "on") or (toggle and not status) then
      player.mod_settings[setting] = {value = true}
      msg = "toggled"
    -- Turn setting off
    elseif (arg == "off") or (toggle and status) then
      player.mod_settings[setting] = {value = false}
      msg = "toggled"
    end

    -- Output current status (player settings MAY have changed, so get status again!)
    status = commands.get_setting(player.index, setting) and
              {"GCKI-states.on"} or {"GCKI-states.off"}
    -- Print status
    if msg then
      player.print({"GCKI-commands.command-"..msg, setting, status})
    -- Print help text + status
    else
      player.print({"GCKI-commands.command",
        setting,
        {"mod-setting-name."..setting},
        {"GCKI-commands.command-status", setting, status}
      })
    end

    GCKI.entered_command(command, "leave")
  end

  GCKI.entered_function({setting}, "leave")
  return commands[setting]
end


-- Create command to unlock all vehicles
commands.unlock = function(command)
  GCKI.entered_command(command)

  --~ local player = game.players[command.player_index]
  local player = game.get_player(command.player_index)

  -- ID may be a unit_number or the custom name given to the vehicle
  local id = tonumber(command.parameter) or command.parameter
  if type(id) == "string" then
    GCKI.writeDebug("Try to get ID by custom name!")
    id = mod.named_vehicles.by_name[id]
  end

GCKI.show("player", GCKI.argprint(player))
GCKI.show("id", id)
GCKI.show("type(id)", type(id))


  -- Vehicle ID was specified
  if id then
    GCKI.writeDebug("%s requested unlock of vehicle %s!",
                    {GCKI.argprint(player), id})
GCKI.show("player.admin", player.admin)
GCKI.show("mod.lockers["..player.index.."]["..id.."]",
          mod.lockers and mod.lockers[player.index] and mod.lockers[player.index][id])
    -- Player must be admin,
    if player.admin or
      -- or must have locked this vehicle
      (mod.lockers and mod.lockers[player.index] and
                          mod.lockers[player.index][id]) then
GCKI.writeDebug("Must unlock vehicle!")
      unlock_vehicle(id)
    end

  -- Admins may unlock vehicles of all players!
  elseif player.admin then
    GCKI.writeDebug("Admin %s requested unlock of all vehicles!",
                    {GCKI.argprint(player)})
    unlock_all_vehicles()

  -- Normal players may only unlock their own vehicles
  else
    GCKI.writeDebug("Must remove locker from all vehicles of %s!",
                    {GCKI.argprint(player)})
    unlock_player_vehicles(player)
  end

  GCKI.entered_command(command, "leave")
end


-- Create command to unlock all vehicles locked by the specified player.
-- This command can only be used if the player is an admin!
commands.unlock_player = function(command)
  GCKI.entered_command(command)

  --~ local player = game.players[command.player_index]
  local player = game.get_player(command.player_index)

  -- Return immediately if player is not an admin!
  if not player.admin then
    GCKI.command_err(player, {"GCKI-command-errors.must-be-admin"})
    GCKI.entered_command(command, "leave", GCKI.argprint(player).." is not an admin!")
    return
  end

  -- Get the player whose vehicles we want to reset
  local p = tonumber(command.parameter) or command.parameter
  local target = GCKI.ascertain_player(p)

  local lockers = mod.lockers

  -- Specified player doesn't exist
  if not target then
    GCKI.writeDebug("Not a valid player: %s!", {command.parameter})
    GCKI.command_err(player, {"GCKI-command-errors.no-such-player", p or ""})

  -- Specified player hasn't locked any vehicles
  elseif not (lockers and lockers[target.index] and next(lockers[target.index])) then
    GCKI.writeDebug("%s hasn't claimed or locked any vehicles!",
                    {GCKI.argprint(target)})
    GCKI.command_err(player, {"GCKI-command-errors.player-has-no-vehicles", target})

  -- Unlock vehicles!
  else
    GCKI.writeDebug("Must reset all vehicles of %s!", {GCKI.argprint(target)})
    unlock_player_vehicles(target)
  end

  GCKI.entered_command(command, "leave")
end


-- Create command to reset one or all vehicles
-- (removes owner/locker, color and custom name)
commands.reset = function(command)
  GCKI.entered_command(command)

  --~ local player = game.players[command.player_index]
  local player = game.get_player(command.player_index)

  -- ID may be a unit_number or the custom name given to the vehicle
  local id = tonumber(command.parameter) or command.parameter
  if type(id) == "string" then
    GCKI.writeDebug("Try to get ID by custom name!")
    id = mod.named_vehicles.by_name[id]
  end
GCKI.show("id", GCKI.argprint(id))

  -- Vehicle ID was specified
  if id then
    GCKI.writeDebug("%s requested reset of vehicle %s!", {GCKI.argprint(player), id})

    local lockers, owners = mod.lockers, mod.owners

    -- Vehicle must be stored
    if not (mod.GCKI_vehicles and mod.GCKI_vehicles[id]) and
        not (mod.named_vehicles.by_id[id]) then
      GCKI.command_err(player, {"GCKI-command-errors.no-such-vehicle", id})

    -- Player must be admin,
    elseif player.admin or
            -- or must be owner of this vehicle,
            (mod.GCKI_vehicles[id] and mod.GCKI_vehicles[id].owner == player.index) or
            -- or must have locked this vehicle
            (lockers and lockers[player.index] and lockers[player.index][id]) then

      GCKI_vehicle.reset_vehicle(id)
    end

  -- Admins reset all vehicles of all players!
  elseif player.admin then
    if not (mod.GCKI_vehicles and next(mod.GCKI_vehicles)) then
      GCKI.command_err(player, {"GCKI-command-errors.no-locked-or-owned-vehicles"})
    else
      GCKI.writeDebug("Admin %s requested reset of all vehicles!", {GCKI.argprint(player)})
      GCKI_vehicle.reset_all_vehicles()
    end

  -- Normal players reset only their own vehicles
  else
    local lockers, owners = mod.lockers, mod.owners
    if not (owners and owners[player.index]) and
        not (lockers and lockers[player.index] and next(lockers[player.index])) then
      GCKI.command_err(player, {"GCKI-command-errors.no-locked-or-owned-vehicles"})
    else
      GCKI.writeDebug("Must reset all vehicles of %s!", {GCKI.argprint(player)})
      GCKI_vehicle.reset_player_vehicles(player)
    end
  end

  GCKI.entered_command(command, "leave")
end


-- Create command to reset all vehicles (removes owner + locker) of the specified
-- player. This command can only be used if the player is an admin!
commands.reset_player = function(command)
  GCKI.entered_command(command)

  --~ local player = game.players[command.player_index]
  local player = game.get_player(command.player_index)

  -- Return immediately if player is not an admin!
  if not player.admin then
    GCKI.command_err(player, {"GCKI-command-errors.must-be-admin"})
    GCKI.entered_command(command, "leave", GCKI.argprint(player).." is not an admin!")
    return
  end

  -- Get the player whose vehicles we want to reset
  local target_id = tonumber(command.parameter) or command.parameter
  --~ local target = target_id and game.players[target_id]
  local target = target_id and game.get_player(target_id)

  local owners, lockers = mod.owners, mod.lockers

  -- Specified player doesn't exist
  if not target then
    GCKI.writeDebug("Not a valid player: %s!", {target_id or "nil"})
    GCKI.command_err(player,
                      {"GCKI-command-errors.no-such-player", target_id or "nil"})

  -- Specified player hasn't claimed/locked any vehicles
  elseif not (owners and owners[target.index]) and
        not (lockers and lockers[target.index] and next(lockers[target.index])) then
    GCKI.writeDebug("%s hasn't claimed or locked any vehicles!", {
                    GCKI.argprint(target)})
    GCKI.command_err(player,
                      {"GCKI-command-errors.player-has-no-vehicles", target_id})

  -- Reset vehicles!
  else
    GCKI.writeDebug("Must reset all vehicles of %s!", {GCKI.argprint(target)})
    GCKI_vehicle.reset_player_vehicles(target)
  end

  GCKI.entered_command(command, "leave")
end


------------------------------------------------------------------------------------
GCKI.entered_file("leave")
return commands
