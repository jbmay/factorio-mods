GCKI.entered_file()

mod_gui = require("mod-gui")

local GCKI_gui = {}

-- Shortcut descriptions belong to prototypes and cannot be changed at runtime.
-- Show the current restriction beside the vehicle-list button instead.
function GCKI_gui.update_key_status(player, reason)
  local flow = mod_gui.get_button_flow(player)
  local label = flow.GCKI_key_status
  if reason then
    if not (label and label.valid) then
      label = flow.add{type = "label", name = "GCKI_key_status"}
    end
    label.caption = {"GCKI-messages.keys-unavailable"}
    label.tooltip = {"GCKI-messages." .. reason}
  elseif label and label.valid then
    label.destroy()
  end
end

------------------------------------------------------------------------------------
------------------------------------------------------------------------------------
--                              Names of GUI elements                             --
------------------------------------------------------------------------------------
------------------------------------------------------------------------------------

GCKI_gui_names = require("__gcki-continued__.scripts.gui_stuff.gui_element_names")


------------------------------------------------------------------------------------
------------------------------------------------------------------------------------
--                                 Local functions                                --
------------------------------------------------------------------------------------
------------------------------------------------------------------------------------



------------------------------------------------------------------------------------
------------------------------------------------------------------------------------
--                                Shared functions                                --
------------------------------------------------------------------------------------
------------------------------------------------------------------------------------


------------------------------------------------------------------------------------
--                 Clear vehicle table, keeping the table headers                 --
------------------------------------------------------------------------------------
GCKI_gui.clear_table = function(tab, columns, vehicles)
  GCKI.entered_function({tab, columns, vehicles})

  GCKI.assert(tab, "LuaGuiElement")         -- The table we want to clear
  GCKI.assert(columns, "table")             -- Array of column names for that table
  GCKI.assert(vehicles, {"table", "nil"})   -- List of vehicles currently in the table
  if not vehicles then
    vehicles = {}
  end

  local remove_row, id

  for e, element in pairs(tab.children) do
    -- Skip the header and start with the first vehicle!
    if e > #columns  then

    -- In the first column, check whether the element refers to a vehicle stored
    -- in "vehicles". remove_row will then be used for all following columns.
      if e % #columns == 1 then
        id = tonumber(element.name:match("^.-(%d+)$"))
        remove_row = not vehicles[id]
      end

      -- Destroy element if we must remove this row
      if remove_row then
        GCKI.writeDebug("Removing %s", {GCKI.argprint(element)})
        element.destroy()
      end
    end

  end

  GCKI.entered_function("leave")
end


------------------------------------------------------------------------------------
--                               Update GUI elements                              --
------------------------------------------------------------------------------------

-- Label
GCKI_gui.set_label = function(element, text)
  GCKI.entered_function({element, text})

  GCKI.assert(element, "LuaGuiElement")
  GCKI.assert(text, "string")

  if element.valid then
    element.caption = text
    GCKI.modified_msg("text", element)
  end
end

-- Textfield
GCKI_gui.set_textfield = function(element, text, enabled)
  GCKI.entered_function({element, text, enabled})

  GCKI.assert(element, "LuaGuiElement")
  GCKI.assert(text, {"string", "number"})
  GCKI.assert(enabled, "boolean", "boolean value")

  if element.valid then
    element.text = text
    element.enabled = enabled
    GCKI.modified_msg("text", element)
  end
end

-- Checkbox
GCKI_gui.set_checkbox = function(element, state, enabled)
  GCKI.entered_function({element, state, enabled})

  GCKI.assert(element, "LuaGuiElement")
  GCKI.assert(state, "boolean")
  GCKI.assert(enabled, "boolean")

  if element.valid then
    element.state = state
    element.enabled = enabled
    GCKI.modified_msg("state", element)
  end
end


------------------------------------------------------------------------------------
--              Player is entering a vehicle name into the textfield              --
--    Check whether name is still valid and adjust textfield style accordingly!   --
------------------------------------------------------------------------------------
GCKI_gui.check_vehicle_name = function(event_data)
  GCKI.entered_function({event_data})

  local element = event_data.element
  local v_id = tonumber(element.name:match("^.+_(%d+)"))
GCKI.show("v_id", v_id)

  -- Remove leading/trailing white space from name
  local new_name = GCKI_string.trim_chars(element.text, "\"%s")
GCKI.show("new_name", GCKI.argprint(new_name))

  local vehicle_names = mod.named_vehicles.by_name
  local old_id = vehicle_names[new_name]
GCKI.show("old_id", old_id)

  local vehicle = mod.named_vehicles.by_id[v_id] and mod.named_vehicles.by_id[v_id].entity

  -- Error: The name is already in use for another vehicle!
  if old_id and old_id ~= v_id then
    element.style = "invalid_value_textfield"
    GCKI.writeDebug("Name \"%s\" is already used for %s!",
                    {new_name, GCKI.argprint(mod.named_vehicles.by_id[old_id].entity)})

    element.tooltip = {
      "GCKI-GUI-vehicle-list-tooltips.id_error",
      vehicle and vehicle.localised_name,
      element.text
    }

  -- Switch to highlighting style if it isn't set yet.
  elseif element.style.name ~= "GCKI_highlighted_value_textfield" then
    element.style = "GCKI_highlighted_value_textfield"
    GCKI.writeDebug("Reset style of textfield!")
    element.tooltip = (new_name == "") and
                        {"GCKI-GUI-vehicle-list-tooltips.id_removed"} or
                        {"GCKI-GUI-vehicle-list-tooltips.id_apply"}

  -- Change tooltip depending on whether the new name is an empty string
  else
    GCKI.writeDebug("Normal input!")
    GCKI.show("element.text", element.text)
    GCKI.show("new_name", new_name)
    element.tooltip = (new_name == "") and
                        {"GCKI-GUI-vehicle-list-tooltips.id_removed"} or
                        {"GCKI-GUI-vehicle-list-tooltips.id_apply"}
  end

  GCKI.entered_function("leave")
end


------------------------------------------------------------------------------------
--    Check whether name is still valid and adjust textfield style accordingly!   --
------------------------------------------------------------------------------------
GCKI_gui.check_vehicle_names_confirmed = function(event_data)
  GCKI.entered_function({event_data})

  local element = event_data.element
  local v_id = tonumber(element.name:match("^.+_(%d+)"))
GCKI.show("v_id", v_id)

  -- Remove leading/trailing white space from name
  local new_name = GCKI_string.trim_chars(element.text, "\"%s")
GCKI.show("new_name", GCKI.argprint(new_name))

  local vehicle_ids = mod.named_vehicles.by_id
  local vehicle_names = mod.named_vehicles.by_name
  local old_id = vehicle_names[new_name]
GCKI.show("old_id", old_id)

  local vehicle

  -- Error: The name is already in use for another vehicle!
  if old_id and old_id ~= v_id then
    vehicle = vehicle_ids[old_id] and vehicle_ids[old_id].entity
    element.style = "invalid_value_textfield"
    --~ GCKI.writeDebug("Name \"%s\" is already used for %s!",
                    --~ {new_name, GCKI.argprint(global.named_vehicles.by_id[old_id].entity)})
    GCKI.writeDebug("Name \"%s\" is already used for %s!",
                    {new_name, GCKI.argprint(vehicle)})

    element.tooltip = {
      "GCKI-GUI-vehicle-list-tooltips.id_error",
      vehicle.localised_name,
      element.text
    }

  -- Switch to normal (not highlighted, no error warning) style if it isn't set yet.
  elseif element.style.name ~= "GCKI_stretchable_textfield" then
    --~ local vehicle = global.named_vehicles.by_id[v_id] and
                    --~ global.named_vehicles.by_id[v_id].entity
    vehicle = vehicle_ids[v_id] and vehicle_ids[v_id].entity
    element.style = "GCKI_stretchable_textfield"
    GCKI.writeDebug("Reset style of textfield!")

    element.tooltip = {
      "GCKI-GUI-vehicle-list-tooltips.id",
      vehicle.localised_name,
      element.text
    }

  end

  GCKI.entered_function("leave")
end


------------------------------------------------------------------------------------
--                      Add/change/remove custom vehicle name                     --
------------------------------------------------------------------------------------
GCKI_gui.edit_vehicle_name = function(event_data)
  GCKI.entered_function({event_data})

  --~ local player = game.players[event_data.player_index]
  local player = GCKI.ascertain_player(event_data.player_index)
  local p_data = mod.player_data[player.index]

  local element = event_data.element

  local v_id = tonumber(element.name:match("^.+_(%d+)"))
  local vehicle = v_id and
                  (p_data.selected_vehicles and p_data.selected_vehicles[v_id]) or
                  (mod.GCKI_vehicles[v_id] and mod.GCKI_vehicles[v_id].entity)


GCKI.show("v_id", v_id)
GCKI.show("vehicle", GCKI.argprint(vehicle))

  -- Remove leading/trailing white space and quotation marks from name
  local new_name = GCKI_string.trim_chars(element.text, "\"%s")
GCKI.show("new_name", GCKI.argprint(new_name))

  local update_minimap_and_camera

  -- Vehicle must be valid and we must have a string!
  if vehicle and vehicle.valid and new_name then

    -- In the text field, display the name in quotation marks to distinguish it
    -- from the vehicle's unit_number
    element.text = GCKI.enquote(new_name)

    -- New name is an empty string: Clear custom name and display unit_number!
    if new_name == "" then
      element.text = tostring(v_id)
      update_minimap_and_camera = true

      GCKI.writeDebug("Must remove custom name!")
      --~ GCKI_vehicle.remove_vehicle_name(v_id)
      GCKI_vehicle.remove_vehicle_name(v_id, script.mod_name)

    -- The name is already used for another vehicle: Reset and display unit_number!
    elseif mod.named_vehicles.by_name[new_name] and
            mod.named_vehicles.by_name[new_name] ~= v_id then
GCKI.writeDebug("Name is already in use")
      element.text = mod.named_vehicles.by_id[v_id] and
                      mod.named_vehicles.by_id[v_id].name or tostring(v_id)
      GCKI.writeDebug("Can't assign custom name \"%s\" to %s (already used for vehicle %s)!",
                        {new_name, GCKI.argprint(vehicle), mod.named_vehicles.by_name[new_name]})

    -- We can use the new name for the vehicle
    else
      update_minimap_and_camera = true
      local args = {player = player, vehicle = vehicle, new_name = new_name}
      GCKI_vehicle.edit_vehicle_name(args, script.mod_name)

    end

    if update_minimap_and_camera then
      -- Minimap
      if p_data.show_on_map then
        p_data.show_on_map.name = GCKI.loc_name(vehicle)
        GCKI.show("Updated mod.player_data["..player.index.."].name",
                  p_data.show_on_map.name)
      end
      -- Camera
      if p_data.show_on_camera then
        p_data.show_on_camera.name = GCKI.loc_name(vehicle)
        GCKI.show("Updated mod.player_data["..player.index.."].name",
                  p_data.show_on_camera.name)
      end
    end

    -- Reset style and tooltip!
    element.style = "GCKI_stretchable_textfield"
    element.tooltip = {"GCKI-GUI-vehicle-list-tooltips.id", vehicle.localised_name, element.text}

    GCKI_gui.update_guis(vehicle)
  end

  GCKI.entered_function("leave")
end


------------------------------------------------------------------------------------
--                  Checkbox was used to change owner of vehicle                  --
------------------------------------------------------------------------------------
GCKI_gui.change_vehicle_owner = function(event_data, lock_checkbox)
  GCKI.entered_function({event_data, lock_checkbox})

  --~ local player = game.players[event_data.player_index]
  local player = GCKI.ascertain_player(event_data.player_index)
  local p_data = mod.player_data[player.index]

  local element = event_data.element

  local v_id = tonumber(element.name:match("^.+_(%d+)"))
  local vehicle = v_id and
                  (p_data.selected_vehicles and p_data.selected_vehicles[v_id]) or
                  (mod.GCKI_vehicles[v_id] and mod.GCKI_vehicles[v_id].entity)

  local v_data = mod.GCKI_vehicles[v_id]

GCKI.show("element.tooltip", element.tooltip)
GCKI.show("lock_checkbox.tooltip", lock_checkbox.tooltip)


  -- Remove owner
  if v_data and v_data.owner then
    GCKI.writeDebug("Must remove %s as owner of %s!",
                    {GCKI.argprint(player), GCKI.argprint(vehicle)})
    GCKI_vehicle.remove_vehicle_owner(vehicle, player)

    -- If vehicle was unlocked, it has been removed from the GUI and its elements
    -- are no longer valid!
    if element and element.valid then
      element.tooltip = ""
      GCKI.writeDebug("Removed tooltip of %s!", GCKI.argprint(element))
    end
    if lock_checkbox and lock_checkbox.valid then
      lock_checkbox.tooltip = lock_checkbox.enabled and lock_checkbox.state and {
        "GCKI-GUI-vehicle-list-tooltips.unlock_warning",
        vehicle.localised_name,
        mod.named_vehicles.by_id[v_id] and
          GCKI.enquote(mod.named_vehicles.by_id[v_id].name) or v_id
      } or ""
      GCKI.writeDebug("Set tooltip of %s!", GCKI.argprint(element))
    end

  -- Add owner
  else
    GCKI.writeDebug("%s is the new owner of %s!",
                    {GCKI.argprint(player), GCKI.argprint(vehicle)})
    GCKI_vehicle.add_vehicle_owner(vehicle, player)
    lock_checkbox.tooltip = ""
  end

  GCKI.entered_function("leave")
end


------------------------------------------------------------------------------------
--                  Checkbox was used to change locker of vehicle                 --
------------------------------------------------------------------------------------
GCKI_gui.change_vehicle_locker = function(event_data, owner_checkbox)
  GCKI.entered_function({event_data, owner_checkbox})

  --~ local player = game.players[event_data.player_index]
  local player = GCKI.ascertain_player(event_data.player_index)
  local p_data = mod.player_data[player.index]

  local element = event_data.element

  local v_id = tonumber(element.name:match("^.+_(%d+)"))
  local vehicle = v_id and
                  (p_data.selected_vehicles and p_data.selected_vehicles[v_id]) or
                  (mod.GCKI_vehicles[v_id] and mod.GCKI_vehicles[v_id].entity)

GCKI.show("element.tooltip", element.tooltip)
GCKI.show("owner_checkbox.tooltip", owner_checkbox.tooltip)
GCKI.show("owner_checkbox.state", owner_checkbox.state)



  if vehicle and vehicle.valid then
    local locker = GCKI_events.used_key.toggle_lock(player, vehicle)
GCKI.show("locker", locker)
    -- Vehicle has been locked, everything is OK
    if locker then
      owner_checkbox.tooltip = ""
GCKI.writeDebug("Cleared tooltip of %s", {GCKI.argprint(owner_checkbox)})

    -- Vehicle has been unlocked. If there was no owner, it has been removed from
    -- the GUI and its GUI elements are no longer valid!
    else
GCKI.show("element after toggling lock", GCKI.argprint(element))
GCKI.show("owner_checkbox after toggling lock", GCKI.argprint(owner_checkbox))
      if element and element.valid then
        element.tooltip = ""
        GCKI.writeDebug("Removed tooltip of %s!", GCKI.argprint(element))
      end
      if owner_checkbox and owner_checkbox.valid then
        owner_checkbox.tooltip = owner_checkbox.enabled and owner_checkbox.state and {
          "GCKI-GUI-vehicle-list-tooltips.unlock_warning",
          vehicle.localised_name,
          mod.named_vehicles.by_id[v_id] and
            GCKI.enquote(mod.named_vehicles.by_id[v_id].name) or v_id
        } or ""
        GCKI.writeDebug("Set tooltip of %s!", GCKI.argprint(element))
      end
GCKI.show("element.tooltip", element and element.valid and element.tooltip)
GCKI.show("elementowner_checkbox.tooltip", owner_checkbox and owner_checkbox.valid and owner_checkbox.tooltip)
    end
  end

  GCKI.entered_function("leave")
end



------------------------------------------------------------------------------------
--                            Create a GUI flow element                           --
------------------------------------------------------------------------------------
--~ GCKI_gui.make_flow = function(flow_data)
  --~ GCKI.entered_function({flow_data})

  --~ if type(flow_data) ~= "table" then
    --~ GCKI.entered_function("leave", "Missing argument!")
    --~ return
  --~ end

  --~ -- Create flow
  --~ local ret = flow_data.parent.add({
    --~ type = "flow",
    --~ name = flow_data.name,
    --~ direction = flow_data.direction or "vertical",
    --~ visible = true,
  --~ })

  --~ -- Add title?
  --~ if flow_data.caption then
    --~ ret.add({
      --~ type = "label",
      --~ name = "title",
      --~ caption = flow_data.caption,
      --~ style = "frame_title",
      --~ ignored_by_interaction = true,
    --~ })
  --~ end

  --~ GCKI.entered_function("leave")
  --~ return ret
--~ end
GCKI_gui.make_flow = function(flow_data)
  GCKI.entered_function({flow_data})

  if type(flow_data) ~= "table" then
    GCKI.entered_function("leave", "Missing argument!")
    return
  end
GCKI.show("flow_data.parent", GCKI.argprint(flow_data.parent))

  -- Create flow
  local ret = flow_data.parent.add({
    type = "flow",
    name = flow_data.name,
    direction = flow_data.direction or "vertical",
    visible = true,
  })
  GCKI.created_msg(ret)

  local title, dragspace, close_button

  -- Add title?
  if flow_data.caption then
    title = ret.add({
      type = "label",
      name = "title",
      caption = flow_data.caption,
      style = "frame_title",
      --~ ignored_by_interaction = true,
      ignored_by_interaction = false,
    })
    title.style.vertically_stretchable = flow_data.vertically_stretchable or false
    title.drag_target = flow_data.parent
    GCKI.created_msg(title)
  end

GCKI.show("flow_data.parent", GCKI.argprint(flow_data.parent))
  -- Spacer to push closing button to the right (can be used to drag GUI)
  if flow_data.dragspace then
    dragspace = ret.add({
      type = "empty-widget",
      name = "dragspace",
      style = "draggable_space_header",
    })
    dragspace.drag_target = flow_data.parent
    dragspace.style.horizontally_stretchable = true
    dragspace.style.vertically_stretchable = true
    GCKI.created_msg(dragspace)
  end

  -- Closing button
  if flow_data.close_button_name then
    close_button = ret.add({
      type = "sprite-button",
      name = flow_data.close_button_name,
      visible = true,
      style = "frame_action_button",
      --~ sprite = "utility/close_white",
      sprite = "utility/close",
      mouse_button_filter = {"left"},
    })
    GCKI.created_msg(close_button)
  end

  GCKI.entered_function("leave")
  return ret
end



--~ ------------------------------------------------------------------------------------
--~ --                                    Init GUIs                                   --
--~ ------------------------------------------------------------------------------------
--~ GCKI_gui.init_guis = function()
  --~ GCKI.entered_function()

  --~ local p_data
  --~ for p, player in pairs(game.players) do
    --~ p_data = global.player_data[p]

    --~ -- Update GUI for vehicles selected by player
    --~ GCKI.writeDebug("Initializing GUI for vehicles selected by %s!", {GCKI.argprint(player)})
    --~ GCKI_gui_select_area.init_gui(p, p_data.selected_vehicles)

    --~ -- Update GUI for vehicles owned/locked by player
    --~ GCKI.writeDebug("Initializing GUI for vehicles owned/locked by %s!", {GCKI.argprint(player)})
      --~ GCKI_gui_player_vehicles.init_gui(p)

    --~ -- Update GUI for minimap of vehicles owned/locked by player
    --~ GCKI.writeDebug("Initializing GUI for vehicles owned/locked by %s (minimap)!", {GCKI.argprint(player)})
      --~ GCKI_gui_player_vehicles_map.init_gui(p)

    --~ -- Update GUI for camera view of vehicles owned/locked by player
    --~ GCKI.writeDebug("Initializing GUI for vehicles owned/locked by %s (camera)!", {GCKI.argprint(player)})
      --~ GCKI_gui_player_vehicles_camera.init_gui(p)
  --~ end

  --~ GCKI.entered_function("leave")
--~ end
------------------------------------------------------------------------------------
--Init GUIs of all players in the game, all players on a force, or a single player--
------------------------------------------------------------------------------------
GCKI_gui.init_guis = function(force_or_player)
  GCKI.entered_function({force_or_player})

  --~ local force = GCKI.ascertain_force(force_or_player)
  --~ local player = not (force and force.valid) and
                  --~ GCKI.ascertain_player(force_or_player)

  --~ local players = (player and player.valid and {player}) or
                  --~ (force and force.valid and force.players) or
                  --~ game.players

  local players
  do
    local force = GCKI.ascertain_force(force_or_player)
    local player = not (force and force.valid) and
                    GCKI.ascertain_player(force_or_player)

    players = (player and player.valid and {player}) or
              (force and force.valid and force.players) or
              game.players
  end


  local p_data
  -- Must initialize global vars if mod is added to existing game and another mod
  -- called our remote interface before we could run on_init()
  mod.player_data = mod.player_data or {}
  for p, player in pairs(players) do
    mod.player_data[p] = mod.player_data[p] or {}
    p_data = mod.player_data[p]

    -- Update GUI for vehicles selected by player
    --~ GCKI.writeDebug("Initializing GUI for vehicles selected by %s!", {GCKI.argprint(player)})
    --~ GCKI_gui_select_area.init_gui(p, p_data.selected_vehicles)
    if p_data and p_data.selected_vehicles then
      GCKI.writeDebug("Initializing GUI for vehicles selected by %s!",
                      {GCKI.argprint(player)})
      GCKI_gui_select_area.init_gui(p, p_data.selected_vehicles)
    end

    -- Update GUI for vehicles owned/locked by player
    GCKI.writeDebug("Initializing GUI for vehicles owned/locked by %s!",
                    {GCKI.argprint(player)})
    GCKI_gui_player_vehicles.init_gui(p)

    -- Update GUI for minimap of vehicles owned/locked by player
    GCKI.writeDebug("Initializing GUI for vehicles owned/locked by %s (minimap)!", {GCKI.argprint(player)})
    GCKI_gui_player_vehicles_map.init_gui(p)

    -- Update GUI for camera view of vehicles owned/locked by player
    GCKI.writeDebug("Initializing GUI for vehicles owned/locked by %s (camera)!", {GCKI.argprint(player)})
    GCKI_gui_player_vehicles_camera.init_gui(p)
  end

  GCKI.entered_function("leave")
end



------------------------------------------------------------------------------------
--                                   Update GUIs                                  --
------------------------------------------------------------------------------------
GCKI_gui.update_guis = function(vehicle, flags)
  GCKI.entered_function({vehicle, flags})

  GCKI.assert(vehicle, "LuaEntity")
  GCKI.assert(flags, {"table", "nil"})

  -- If keep_gui_visible is set, we won't hide the GUI for vehicles owned/locked
  -- by a player when the last vehicle is removed. (This is important when the
  -- player owns an unlocked vehicle and claims a new one: When the last vehicle
  -- had been removed and we'd add the new vehicle, the GUI would remain invisible.)
  local keep_gui_visible = flags and flags.keep_gui_visible
  --~ local skip_event_check = flags and flags.skip_event_check

  local v = vehicle.unit_number
  local v_name = GCKI.loc_name(vehicle)

  local pass_on_flags

  local p_data
  for p, player in pairs(game.players) do
    p_data = mod.player_data[p]
GCKI.show("p_data of player "..p, p_data)
GCKI.show("p_data.to_be_removed", p_data.to_be_removed)
    if p_data and p_data.to_be_removed then
      GCKI.writeDebug("Skipping GUI update for %s: player is about to be removed!",
                      {GCKI.argprint(player)})
    elseif not player.connected then
      GCKI.writeDebug("Skipping GUI update for %s: player is not connected!",
                      {GCKI.argprint(player)})
    else
      GCKI.writeDebug("Updating GUIs of %s!", {GCKI.argprint(player)})

      -- Update record of names shown on camera and minimap GUIs
      if p_data.show_on_camera and p_data.show_on_camera.id == v then
        p_data.show_on_camera.name = v_name
        GCKI.show("p_data.show_on_camera.name", p_data.show_on_camera.name)
      end
      if p_data.show_on_map and p_data.show_on_map.id == v then
        p_data.show_on_map.name = v_name
        GCKI.show("p_data.show_on_map.name", p_data.show_on_map.name)
      end


      -- Update GUI for vehicles selected by player
      if p_data.selected_vehicles and p_data.selected_vehicles[v] then
        --~ pass_on_flags = { skip_event_check = skip_event_check, }
        pass_on_flags = { skip_event_check = true, }

        -- If this function is run from on_configuration_changed, the vehicle entity
        -- may be valid while the prototype may have been blacklisted in a mod update.
        -- Remove the vehicle from the GUI in this case!
        if not GCKI_vehicle.is_vehicle(vehicle) then
          GCKI.writeDebug("Removing %s from GUI for vehicles selected by %s!",
                          {GCKI.argprint(vehicle), GCKI.argprint(player)})
          GCKI_gui_select_area.remove_from_gui(player, {vehicle, pass_on_flags})

        -- Updating GUI for vehicles selected by player
        else
          GCKI.writeDebug("Updating GUI for vehicles selected by %s!",
                          {GCKI.argprint(player)})
          GCKI_gui_select_area.update_gui(p, vehicle, pass_on_flags)
        end
      end
  GCKI.show("p_data", p_data)

      --------------------------------------------------------------------------------
      -- We must always update the GUIs of vehicles owned/locked by a player, and   --
      -- their minimap and camera views, even if there is no record for them in the --
      -- player data! Otherwise, unlocked vehicles without an owner will remain on  --
      -- the GUI, and the minimap wouldn't be closed -- even if there was no valid  --
      -- vehicle to show!                                                           --
      --------------------------------------------------------------------------------
      -- Update GUI for vehicles owned/locked by player
      GCKI.writeDebug("Updating GUI for vehicles owned/locked by %s!",
                      {GCKI.argprint(player)})

      pass_on_flags = {
        keep_gui_visible = keep_gui_visible,
        --~ skip_event_check = skip_event_check,
        skip_event_check = true,
      }

      GCKI_gui_player_vehicles.update_gui(p, vehicle, pass_on_flags)

      -- Update camera view
      GCKI.writeDebug("Updating GUI for camera of %s!", {GCKI.argprint(player)})
      --~ GCKI_gui_player_vehicles_camera.update_gui(p)
      GCKI_gui_player_vehicles_camera.update_gui(p, pass_on_flags)

      -- Update minimap
      GCKI.writeDebug("Updating GUI for minimap of %s!", {GCKI.argprint(player)})
      --~ GCKI_gui_player_vehicles_map.update_gui(p)
      GCKI_gui_player_vehicles_map.update_gui(p, pass_on_flags)
    end
  end

  -- Do we still need GUI events?
  GCKI.writeDebug("Checking whether we need GUI events!")
  GCKI_events.helper.need_gui_events()

  GCKI.entered_function("leave")
end



------------------------------------------------------------------------------------
--                          Remove vehicle from all GUIs                          --
-- vehicle: unit_number or entity                                           --
-- id: unit_number                                                    --
------------------------------------------------------------------------------------
GCKI_gui.remove_from_guis = function(vehicle)
  GCKI.entered_function({vehicle})

  local id = GCKI_vehicle.get_vehicle_id(vehicle)
  if not id then
    GCKI.arg_err(vehicle, "vehicle specification")
  end

  local pass_on_flags = {skip_event_check =true}

  -- Remove from GUIs of selected vehicles
  local v
  for p, p_data in pairs(mod.player_data) do
    v = p_data.selected_vehicles and p_data.selected_vehicles[id]
    if v then
      GCKI.writeDebug("Removing %s from selected vehicles GUI of player %s!", {GCKI.argprint(v), p})
      GCKI_gui_select_area.remove_from_gui(p, {v}, pass_on_flags)
    end
  end

  -- Vehicle has owner or locker.
  local v_data = mod.GCKI_vehicles[id]
GCKI.show("v_data", v_data)
  if v_data then
    GCKI.writeDebug("%s has owner or locker!", {GCKI.argprint(v_data.entity)})
    local player = v_data.owner or v_data.locker

    GCKI.show("v_data.owner", v_data.owner)
    GCKI.show("v_data.locker", v_data.locker)
    --~ if player and player.valid then
    if player then
      GCKI.writeDebug("Must remove %s from GUI of player %s!",
                      {GCKI.argprint(v_data.entity), player})
      GCKI_gui_player_vehicles.remove_from_gui(player, {vehicle}, pass_on_flags)
    end
  end

  --~ if global.show_guis and not GCKI_events.helper.need_gui_events() then
    --~ GCKI.writeDebug("Disabling GUI events!")
    --~ GCKI.disable_optional_events(GCKI_event_lists.gui_events)
    --~ global.show_guis = nil
  --~ end
  GCKI.writeDebug("Checking whether we need GUI events!")
  GCKI_events.helper.need_gui_events()

  GCKI.entered_function("leave")
end


------------------------------------------------------------------------------------
--                     Remove GUIs of all players on the force                    --
-- force: force, force.index or force.name                                        --
-- gui_name: string                                                               --
-- vehicles: name of vehicle list in player_data                                  --
------------------------------------------------------------------------------------
GCKI_gui.remove_guis = function(force, gui_name, vehicles, flags)
  GCKI.entered_function({force, gui_name, vehicles, flags})

  force = GCKI.ascertain_force(force)
  if not (force and force.valid) then
    GCKI.arg_err(force, "force specification")
  end

  GCKI.assert(gui_name, "string", "GUI name")
  GCKI.assert(vehicles, {"string", "nil", "table"}, "name of vehicle list")
  GCKI.assert(flags, {"table", "nil"}, "nil or table of flags")

  if type(vehicles == "table") then
    flags = vehicles
    vehicles = nil
    GCKI.show("Replaced flags with vehicles", flags)
  end
  local skip_event_check = flags and flags.skip_event_check
  --~ local skip_hint = flags and flags.skip_hint

  local cnt = 0
  local gui, p_data

  for p, player in pairs(force and force.players or game.players) do
    -- Destroy player's GUI
    gui = player.valid and player.gui.screen[gui_name]
    if gui and gui.valid then
      gui.destroy()
      --~ -- We don't show the hint when called from on_configuration_changed!
      --~ if not skip_hint then
        --~ GCKI.hint(player, {"GCKI-messages.hints-gui_removed"})
      --~ end
      cnt = cnt + 1
    end

    -- Remove vehicle list from player data
    p_data = mod.player_data[p]
    if p_data and vehicles and p_data[vehicles] then
      p_data[vehicles]= nil
      GCKI.writeDebug("Removed mod.player_data[%s][%s]!",
                      {p, GCKI.enquote(vehicles)})
    end
  end
  GCKI.writeDebug("Removed %s GUIs!", {cnt})

  -- Check whether we need GUI events
  if cnt > 0 and not skip_event_check then
    GCKI.writeDebug("Checking whether we need GUI events!")
    GCKI_events.helper.need_gui_events()
  else
    GCKI.writeDebug("Skipping check whether we need GUI events!")
  end

  GCKI.entered_function("leave")
end


------------------------------------------------------------------------------------
--                      Hide GUIs of all players on the force                     --
------------------------------------------------------------------------------------
GCKI_gui.hide_guis = function(force, gui_name, flags)
  GCKI.entered_function({force, gui_name, flags})

  force = GCKI.ascertain_force(force)
  if not (force and force.valid) then
    GCKI.arg_err(force, "force specification")
  end

  GCKI.assert(gui_name, "string", "GUI name")

  GCKI.assert(flags, {"table", "nil"}, "nil or table of flags")
  -- When called from GCKI_gui.disable_all_guis(), we don't want to call the GUI
  -- event check each time a GUI has been closed.
  local skip_event_check = flags and flags.skip_event_check
GCKI.show("skip_event_check", skip_event_check)

  local cnt = 0
  local gui

  for p, player in pairs(force and force.players or game.players) do
    -- Hide player's GUI
    gui = player.valid and player.gui.screen[gui_name]
    if gui and gui.valid then
      gui.visible = false
      GCKI.hint(player, {"GCKI-messages.hints-gui_removed"})
      cnt = cnt + 1
    end
  end
  GCKI.show("Hidden GUIs", cnt)

  -- Check whether we still need GUI events?
  --~ if global.show_guis and not GCKI_events.helper.need_gui_events() then
    --~ GCKI.writeDebug("Disabling GUI events!")
    --~ GCKI.disable_optional_events(GCKI_event_lists.gui_events)
    --~ global.show_guis = nil
  --~ end
  if skip_event_check then
    GCKI.writeDebug("Skipping check whether GUI events are necessary!")
  else
    GCKI.writeDebug("Checking whether we need GUI events!")
    GCKI_events.helper.need_gui_events()
  end

  GCKI.entered_function("leave")
end


------------------------------------------------------------------------------------
--                             Hide all GUIs of player                     --
------------------------------------------------------------------------------------
GCKI_gui.hide_player_guis = function(player, flags)
  GCKI.entered_function({player, flags})

  player = GCKI.ascertain_player(player)
  if not (player and player.valid) then
    GCKI.arg_err(player, "player specification")
  end

  GCKI.assert(flags, {"table", "nil"}, "nil or table of flags")
  -- When called from GCKI_gui.disable_all_guis(), we don't want to call the GUI
  -- event check each time a GUI has been closed.
  local skip_event_check = flags and flags.skip_event_check
GCKI.show("skip_event_check", skip_event_check)

  local cnt = 0
  local gui

  -- Hide GUIs
  for g_name, g_data in pairs(GCKI_gui_names) do
GCKI.show("g_name", g_name)
GCKI.show("g_data.frames.main", g_data.frames.main)

    gui = player.gui.screen[g_data.frames.main]
GCKI.show("gui", GCKI.argprint(gui))
    if gui and gui.valid and gui.visible then
      GCKI.writeDebug("Removing %s!", {GCKI.argprint(gui)})
      gui.visible = false
      GCKI.hint(player, {"GCKI-messages.hints-gui_removed"})
      cnt = cnt + 1
    end
  end
  GCKI.show("Hidden GUIs", cnt)

  -- Hide toggle button?
  local t_name = GCKI_gui_names.player_vehicles.buttons.toggle_gui
  local button_flow = mod_gui.get_button_flow(player)
  local button = button_flow[t_name]
GCKI.show("button", GCKI.argprint(button))
  if button and button.valid and button.visible then
    GCKI.writeDebug("Hiding toggle button!")
    button.visible = false
  end


  -- Check whether we still need GUI events?
  --~ if global.show_guis and not GCKI_events.helper.need_gui_events() then
    --~ GCKI.writeDebug("Disabling GUI events!")
    --~ GCKI.disable_optional_events(GCKI_event_lists.gui_events)
    --~ global.show_guis = nil
  --~ end
  if skip_event_check then
    GCKI.writeDebug("Skipping check whether GUI events are necessary!")
  else
    GCKI.writeDebug("Checking whether we need GUI events!")
    GCKI_events.helper.need_gui_events()
  end

  GCKI.entered_function("leave")
end


------------------------------------------------------------------------------------
--                        Swap vehicle in table of GUI                            --
-- Function renames the GUI elements inside the table passed on from the swapping --
-- function of the individual GUIs.                                               --
------------------------------------------------------------------------------------
GCKI_gui.swap_vehicle_in_table = function(gui_data)
  GCKI.entered_function({gui_data})

  GCKI.assert(gui_data, "table")

  local gui_table = gui_data.gui_table
  GCKI.assert(gui_table, "LuaGuiElement")
  if gui_table.type ~= "table" then
    GCKI.arg_err(gui_table, "Gui table")
  end

  local column_names = gui_data.column_names
  GCKI.assert(column_names, "table")

  local old_id = gui_data.old_id
  GCKI.assert(old_id, "number")

  local new_id = gui_data.new_id
  GCKI.assert(new_id, "number")

  --~ local old_name, new_name, col_name
  local old_name, new_name

  for c, column in pairs(column_names) do
GCKI.show(c, column)
    old_name = column..old_id
    new_name = column..new_id

    if gui_table[old_name] and gui_table[old_name].valid then
      gui_table[old_name].name = new_name
    end
  end

  GCKI.entered_function("leave")
end


------------------------------------------------------------------------------------
--                              Swap vehicle on GUIs                              --
--         This is to be called from event handlers and vehicle functions!        --
------------------------------------------------------------------------------------
GCKI_gui.swap_vehicle_on_guis = function(old_vehicle_id, new_vehicle)
  GCKI.entered_function({old_vehicle_id, new_vehicle})

  GCKI.writeDebug("Updating open GUIs!")
  for p, p_data in pairs(mod.player_data) do
GCKI.show(p, p_data)

    -- GUI for vehicles in selected area
    GCKI.writeDebugNewBlock("Swap vehicles in GUI of selected vehicles?")
    if p_data.selected_vehicles and p_data.selected_vehicles[old_vehicle_id] then
      GCKI.writeDebug("Yes!")
GCKI.show("p_data.selected_vehicles", p_data.selected_vehicles)
      GCKI_gui_select_area.swap_vehicle_on_gui(p, old_vehicle_id, new_vehicle)
    else
      GCKI.writeDebug("No!")
    end

    -- GUI for vehicles owned/locked by player
    GCKI.writeDebugNewBlock("Swap vehicles in GUI of selected vehicles?")
    if p_data.locked_or_owned and p_data.locked_or_owned[old_vehicle_id] then
      GCKI.writeDebug("Yes!")
GCKI.show("p_data.locked_or_owned", p_data.locked_or_owned)
      GCKI_gui_player_vehicles.swap_vehicle_on_gui(p, old_vehicle_id, new_vehicle)
    else
      GCKI.writeDebug("No!")
    end

    -- Camera of player
    GCKI.writeDebugNewBlock("Swap vehicles in GUI of selected vehicles?")
    if p_data.show_on_camera and p_data.show_on_camera.id == old_vehicle_id then
      GCKI.writeDebug("Yes!")
GCKI.show("p_data.show_on_camera", p_data.show_on_camera)
      GCKI_gui_player_vehicles_camera.swap_vehicle_on_gui(p, old_vehicle_id, new_vehicle)
    else
      GCKI.writeDebug("No!")
    end

    -- Minimap of player
    GCKI.writeDebugNewBlock("Swap vehicles in GUI of selected vehicles?")
    if p_data.show_on_map and p_data.show_on_map.id == old_vehicle_id then
      GCKI.writeDebug("Yes!")
GCKI.show("p_data.show_on_map", p_data.show_on_map)
      GCKI_gui_player_vehicles_map.swap_vehicle_on_gui(p, old_vehicle_id, new_vehicle)
    else
      GCKI.writeDebug("No!")
    end
  end

  GCKI.entered_function("leave")
end



------------------------------------------------------------------------------------
-- Area was selected with the keys. Show GUI to change the vehicle's custom name, --
-- and claim/give up, or lock/unlock vehicles that either belong to or have been  --
-- locked by the player. (Custom name may also be given if the vehicle has not    --
-- been claimed or locked by any player, unless it already has a custom name.)    --
------------------------------------------------------------------------------------
GCKI_gui.vehicles_selected_area = function(player, vehicles, mode)
  GCKI.entered_function({player, vehicles, mode})

  player = GCKI.ascertain_player(player)
  if not (player and player.valid) then
    GCKI.arg_err(player, "player specification")
  end
  GCKI.assert(vehicles, {"table", "nil"})
  GCKI.assert(mode, {"string", "nil"})  -- "add"/"remove" to modify, nil to init GUI

  local p_data = mod.player_data[player.index]

  -- We can quit if the vehicle list is empty
  if not (vehicles and next(vehicles)) then
    local gui = player.gui.screen[GCKI_gui_names.select_area.frames.main]
    if gui and gui.valid and gui.visible and not p_data.selected then
      GCKI.writeDebug("Must hide GUI of %s!", {GCKI.argprint(player)})
      gui.visible = false
    end
    GCKI.entered_function({}, "leave", "no vehicles")
    return
  end


  -- Player has not yet selected a vehicle and we should not add/remove a vehicle:
  -- initialize the GUI!
  if not mode then
    GCKI.writeDebug("Must initialize GUI!")
    GCKI_gui_select_area.init_gui(player, vehicles)

  -- Player already has a GUI
  elseif p_data.selected_vehicles then

    -- Alt-mode was used: add vehicles!
    if mode == "add" then
GCKI.writeDebug("Must add vehicles!")
      GCKI_gui_select_area.add_to_gui(player, vehicles)

  -- Reverse-mode was used: remove vehicle!
    elseif mode == "remove" then
GCKI.writeDebug("Must remove vehicles!")
      GCKI_gui_select_area.remove_from_gui(player, vehicles)
    end
  end

  GCKI.entered_function("leave")
end


------------------------------------------------------------------------------------
--                Enforce closing of all open GUIs of all players!                --
-- As GUI events are disabled, players can't use or close their GUIs anymore. We  --
-- help them out by removing all GCKI GUIs. If called with a force, we remove the --
-- GUIs of just the players on that force.                                        --
------------------------------------------------------------------------------------
GCKI_gui.disable_all_guis = function(force)
  GCKI.entered_function({force})

  -- We don't check whether any force still needs GUI events each time we've closed
  -- a GUI, but call the function manually after we've hidden all GUIs.
  local flags = { skip_event_check = true, }

  -- Remove GUIs for vehicles owned/locked by players. As this will change owner and
  -- locker, we should first remove the GUIs for selected vehicles, so we will skip
  -- updating them.
  --~ GCKI_gui_select_area.hide_guis(force)
  --~ GCKI_gui_player_vehicles.hide_guis(force)
  --~ GCKI_gui_player_vehicles_camera.hide_guis(force)
  --~ GCKI_gui_player_vehicles_map.hide_guis(force)
  GCKI_gui_select_area.hide_guis(force, flags)
  GCKI_gui_player_vehicles.hide_guis(force, flags)
  GCKI_gui_player_vehicles_camera.hide_guis(force, flags)
  GCKI_gui_player_vehicles_map.hide_guis(force, flags)

  GCKI.writeDebug("Checking whether we need GUI events!")
  GCKI_events.helper.need_gui_events()

  GCKI.entered_function("leave")
end


------------------------------------------------------------------------------------
GCKI.entered_file("leave")
return GCKI_gui
