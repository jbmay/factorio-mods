GCKI.entered_file()

local common_force = {}

------------------------------------------------------------------------------------
--    Check whether a force has researched at least one of the necessary techs!   --
------------------------------------------------------------------------------------
common_force.is_unlock_tech_researched = function(force, techs)
  GCKI.entered_function({force, techs})

  -- We'll need a valid force!
  do
    local f = GCKI.ascertain_force(force)
    if not (f and f.valid) then
      GCKI.arg_err(force, "force specification")
    end
    force = f
  end
  -- Fall back to default unlock techs if no techs are passed on!
  --~ techs = (type(techs) == "string" and {techs}) or
          --~ (type(techs) == "table" and next(techs) and techs) or
          --~ GCKI.unlock_tech_map
  do
    local t = type(techs)
    if t == "string" then
      techs = {techs}
    elseif t == "nil" or not next(techs) then
      techs = GCKI.unlock_tech_map
    end
  end

  mod.force_data[force.name] = mod.force_data[force.name] or {}
  local f_data = mod.force_data[force.name]
  local force_researched = f_data.researched

  local ret = false

  -- List of tech is initialized
  if force_researched then
    if next(force_researched) then
      for t, tech in pairs(techs) do
        if force_researched[tech] then
          ret = true
          GCKI.writeDebug("%s has researched tech \"%s\"!",
                          {GCKI.argprint(force), tech})
          break
        end
      end
    end

  -- Must initialize tech list
  else
    f_data.researched = {}
    for tech, t  in pairs(techs) do
      if force.technologies[tech] and force.technologies[tech].researched then
        f_data.researched[tech] = true
        ret = true
      end
    end
  end

  GCKI.entered_function("leave")
  return ret
end

------------------------------------------------------------------------------------
--                            INITIALIZE PLAYER SETTINGS                          --
------------------------------------------------------------------------------------
common_force.init_force_data = function(force)
  GCKI.entered_function({force})

  local f = GCKI.ascertain_force(force)
  if not (f and f.valid) then
    GCKI.arg_err(force, "force specification")
  end
  force = f

  -- Remove data of forces with no connected players
  if not next(force.connected_players) then
    if mod.force_data[force.name] then
      GCKI.writeDebug("Removing obsolete force data!")
      mod.force_data[force.name] = nil
    end
    GCKI.entered_function({}, "leave", "no connected players")
    return
  end

  -- Ignore forces created by "Blueprint Sandboxes"!
  if GCKI.prefixed(force.name, GCKI.BPS_force_name_prefix) then
    local msg = string.format("ignoring %s (created by Blueprint Sandboxes)!",
                              GCKI.argprint(force))
    GCKI.entered_function({}, "leave", msg)
    return
  end

  local ret

  -- Initialize force data?
  GCKI.writeDebugNewBlock("Initialize force data?")
  if not mod.force_data[force.name] then
    GCKI.writeDebug("Yes!")
    mod.force_data[force.name] = {}
    ret = true
  else
    GCKI.writeDebug("No, mod.force_data[%s] already exists!", {force.name})
  end
  local f_data = mod.force_data[force.name]


  -- Show the shortcut?
  GCKI.writeDebugNewBlock("Has %s researched an unlock tech?",
                          {GCKI.argprint(force)})
  if common_force.is_unlock_tech_researched(force) then
    GCKI.writeDebug("Yes!")

    if next(force.connected_players) then
      GCKI.writeDebug("%s players are connected, must show shortcuts!",
                      {#force.connected_players})
      f_data.show_shortcuts = true
    else
      GCKI.writeDebug("No %s on force, disabling shortcut %s!",
                      {next(force.players) and "connected players" or "players",
                        GCKI.enquote(GCKI.shortcut_name)})
      f_data.show_shortcuts = nil
    end

  else
    GCKI.writeDebug("No!")
    f_data.show_shortcuts = nil
  end
GCKI.show("mod.force_data", mod.force_data)

  -- Do we need events for custom inputs?
  GCKI.writeDebugNewBlock("Check whether we need optional events for custom inputs!")
  GCKI_custom_input.helper.check_optional_events()

  GCKI.entered_function("leave")
  return ret
end



------------------------------------------------------------------------------------
--                 Remove data for forces without players or                --
------------------------------------------------------------------------------------
common_force.remove_force_data = function(force, flags)
  GCKI.entered_function({force, flags})

  local f = GCKI.ascertain_force(force)
  if not (f and f.valid) then
    GCKI.arg_err(force, "force specification")
  end
  force = f


  GCKI.assert(flags, {"table", "nil"}, "nil or table of flags")
  local skip_event_check = flags and flags.skip_event_check

  local f_data = mod.force_data[force.name]
  if not f_data then
    GCKI.entered_function({}, "leave", "no data stored for force")
    return
  end

  local ret
  --~ -- Ignore forces created by "Blueprint Sandboxes"!
  --~ if GCKI.prefixed(force.name, GCKI.BPS_force_name_prefix) then
    --~ local msg = string.format("ignoring %s (created by Blueprint Sandboxes)!",
                              --~ GCKI.argprint(force))
    --~ GCKI.entered_function({}, "leave", msg)
    --~ return
  --~ end
  -- Remove data of forces created by "Blueprint Sandboxes"!
  if GCKI.prefixed(force.name, GCKI.BPS_force_name_prefix) then
    if mod.force_data[force.name] then
      GCKI.writeDebug("Removing obsolete force data!")
      mod.force_data[force.name] = nil
      ret = true
    end

    GCKI.entered_function({}, "leave", "created by \"Blueprint Sandboxes\"")
    return ret
  end

  GCKI.writeDebugNewBlock("Are any (suspended) players on force?")
GCKI.show("next(force.players)", next(force.players))
GCKI.show("next(force.connected_players)", next(force.connected_players))
GCKI.show("f_data.suspended_players)", f_data.suspended_players)
  --~ if next(force.players) or
      --~ (f_data.suspended_players and next(f_data.suspended_players)) then
  if next(force.connected_players) or
      (f_data.suspended_players and next(f_data.suspended_players)) then
    GCKI.writeDebug("Yes! Keeping force data!")
  else
    GCKI.writeDebug("No! Removing force data!")
    mod.force_data[force.name] = nil
    ret = true
  end
  --~ if not next(force.players) or
      --~ not (f_data.suspended_players and next(f_data.suspended_players)) then
    --~ GCKI.writeDebug("No! Removing force data!")
    --~ global.force_data[force.name] = nil
  --~ else
    --~ GCKI.writeDebug("Yes! Keeping force data!")
  --~ end

  GCKI.writeDebugNewBlock("Check whether shortcut events are still needed?")
  --~ local skip_event_check = flags and flags.skip_event_check
  if skip_event_check then
    GCKI.writeDebug("No!")
  else
    GCKI.writeDebug("Yes!")
    GCKI_events.helper.need_shortcut_events()
  end

  GCKI.entered_function("leave")
  return ret
end


------------------------------------------------------------------------------------
GCKI.entered_file("leave")
return common_force
