-- This file contains everything related to the GUI for vehicles owned, locked,   --
-- or named by a player. Each vehicle should only appear on one player's GUI at   --
-- time.                                                                          --
------------------------------------------------------------------------------------
GCKI.entered_file()

local player_vehicles = {}

------------------------------------------------------------------------------------
------------------------------------------------------------------------------------
--                              Names of GUI elements                             --
------------------------------------------------------------------------------------
------------------------------------------------------------------------------------
local gui_names = GCKI_gui_names.player_vehicles
--~ GCKI.show("player vehicles", gui_names)



------------------------------------------------------------------------------------
------------------------------------------------------------------------------------
--                                Local definitions                                --
------------------------------------------------------------------------------------
------------------------------------------------------------------------------------

-- We'll need these columns for our table:
local columns = {
  "icon", "proto_name", "id",
  "surface", -- "position",
  "toggle_owned", "toggle_lock",
  "map_view", "camera",
}


-- Move existing cells rather than rebuilding them, preserving text edits and the
-- map/camera checkboxes while grouping every displayed vehicle by its planet.
local function sort_vehicle_rows(vehicle_list, vehicles)
  local rows = {}
  for _, vehicle in pairs(vehicles or {}) do
    if vehicle.valid and vehicle_list[gui_names.table_columns.icon .. vehicle.unit_number] then
      local surface = vehicle.surface
      rows[#rows + 1] = {
        id = vehicle.unit_number,
        kind = surface.planet and 1 or 2,
        group = surface.planet and surface.planet.name or surface.name,
        surface = surface.name,
      }
    end
  end
  table.sort(rows, function(a, b)
    if a.kind ~= b.kind then return a.kind < b.kind end
    if a.group ~= b.group then return a.group < b.group end
    if a.surface ~= b.surface then return a.surface < b.surface end
    return a.id < b.id
  end)
  for row, vehicle in ipairs(rows) do
    for column, name in ipairs(columns) do
      local cell = vehicle_list[gui_names.table_columns[name] .. vehicle.id]
      local destination = row * #columns + column -- leave the header row in place
      local current = cell.get_index_in_parent()
      if current ~= destination then vehicle_list.swap_children(current, destination) end
    end
  end
end


local function create_gui(player)
  GCKI.entered_function({player})

  player = GCKI.ascertain_player(player)
  if not (player and player.valid) then
    GCKI.arg_err(player, "player specification")
  end

  --~ local gui, gui_toggle, element, e_name
  local gui, gui_toggle, e_name

  ------------------------------------------------------------------------------------
  ------------------------------------------------------------------------------------
  --                              Define toggle button                              --
  ------------------------------------------------------------------------------------
  ------------------------------------------------------------------------------------
  gui_toggle = mod_gui.get_button_flow(player)
GCKI.show("gui_toggle", GCKI.argprint(gui_toggle))
  e_name = gui_names.buttons.toggle_gui
GCKI.show("e_name", e_name)

  if not (gui_toggle[e_name] and gui_toggle[e_name].valid) then
    -- Must initialize global vars if mod is added to existing game and another mod
    -- called our remote interface before we could run on_init()
    mod.owners = mod.owners or {}
    mod.lockers = mod.lockers or {}
    local owner_or_locker = (mod.owners[player.index] or mod.lockers[player.index]) and
                            true or false

    gui_toggle.add({
      type = "button",
      name = e_name,
      caption = {"GCKI-GUI.toggle-button"},
      tooltip = {"GCKI-GUI-tooltips.toggle-button"},
      enabled = true,
      visible = owner_or_locker,
      ignored_by_interaction = false,
      style = "GCKI_toggle_button"
    })
    GCKI.writeDebug("Created toggle button for GUI of player's vehicles!")
  end

  ------------------------------------------------------------------------------------
  --           Construct the main frame that will contain the entire GUI            --
  ------------------------------------------------------------------------------------
  gui = player.gui.screen
  if not gui[gui_names.frames.main] then
    --~ local gui = gui.add({
      --~ type = "frame",
      --~ name = gui_names.frames.main,
      --~ direction = "vertical",
      --~ -- Hide the GUI for now!
      --~ visible = false,
    --~ })
    --~ GCKI.created_msg(gui)

    --~ -- GUI will be placed at center of screen when the GUI is first created, or when
    --~ -- when the GUI has been closed and is invisible. If the player selects another
    --~ -- area while the GUI is visible, it will be left where the player has placed it.
    --~ gui.auto_center = true
    local new_gui = gui.add({
      type = "frame",
      name = gui_names.frames.main,
      direction = "vertical",
      -- Hide the GUI for now!
      visible = false,
    })
    GCKI.created_msg(new_gui)

    -- GUI will be placed at center of screen when the GUI is first created, or when
    -- when the GUI has been closed and is invisible. If the player selects another
    -- area while the GUI is visible, it will be left where the player has placed it.
    new_gui.auto_center = true
  end
  gui = gui[gui_names.frames.main]

  -- Header: flow for GUI title and closing button
  local header = gui.header
  if not (header and header.valid) then
    header = GCKI_gui.make_flow({
      parent = gui,
      name = "header",
      caption = {
        "GCKI-GUI.gui-title",
        {"mod-name.GCKI"},
        {"GCKI-GUI.gui-title-player-vehicles"}
      },
      direction = "horizontal",
      dragspace = true,
      close_button_name = gui_names.buttons.main_frame_close,
    })
    GCKI.created_msg(header)
  end


  ----------------------------------------------------------------------------------
  --         Add inner frame with inlaid style containing everything else         --
  ----------------------------------------------------------------------------------
  local inner_frame = gui["inner-frame"]
  if not (inner_frame and inner_frame.valid) then
    inner_frame = gui.add({
      type = "frame",
      name = "inner-frame",
      direction = "vertical",
      visible = true,
      style = "GCKI_inner_frame",
    })
    GCKI.created_msg(inner_frame)
  end


  ----------------------------------------------------------------------------------
  --          Add a scrollable flow as container for the table of vehicles         --
  ----------------------------------------------------------------------------------
  local tab_container = inner_frame[gui_names.scroll_panes.list_container]
  if not (tab_container and tab_container.valid) then
    tab_container = inner_frame.add({
      type = "scroll-pane",
      name = gui_names.scroll_panes.list_container,
      direction = "vertical",
    })
    GCKI.created_msg(tab_container)
    --~ container.style.vertically_stretchable = false
  end

  GCKI.entered_function("leave")
  return gui
end


-- Initialize table for vehicle list
local function create_table(tab_container)
  GCKI.entered_function({tab_container})

  GCKI.assert(tab_container, "LuaGuiElement")

  local vehicle_list = tab_container[gui_names.tables.vehicle_list]

  -- There already was a table, but it was from an old version of this mod and the
  -- number of columns we need has changed. As table.column_count is a read-only
  -- value, we must destroy the old table and create it again.
  if vehicle_list and vehicle_list.valid and vehicle_list.column_count ~= #columns then
    GCKI.writeDebug("Column count of vehicle list has changed from %s to %s. Removing old table!",
                    {vehicle_list.column_count, #columns})
    vehicle_list.destroy()
  end

  -- Create table?
  if not (vehicle_list and vehicle_list.valid) then
    vehicle_list = tab_container.add({
      type = "table",
      name = gui_names.tables.vehicle_list,
      column_count = #columns,
      draw_horizontal_lines = true,
      draw_horizontal_line_after_headers = true,
    })
    GCKI.writeDebug("Created table for vehicle list!")

    -- Create table headers
    local label
    for col, col_label in pairs(columns) do
  GCKI.show("Column "..col, col_label)
      label = vehicle_list.add({
        type = "label",
        name = gui_names.table_columns[col_label].."header",
        caption = {"GCKI-GUI-vehicle-list-headers."..col_label},
      })
      label.style.left_padding = 10
      label.style.right_padding = 10
      vehicle_list.style.column_alignments[col] = "center"
    end
  end

  GCKI.entered_function("leave")
  return vehicle_list
end


-- Get the main frame of the player's GUI
local function get_gui(player)
  GCKI.entered_function({player})

  player = GCKI.ascertain_player(player)
  if not (player and player.valid) then
    GCKI.arg_err(player, "player specification")
  end

  local gui = player.gui.screen[gui_names.frames.main]
  if not (gui and gui.valid) then
    GCKI.writeDebug("Must initialize GUI!")
    gui = create_gui(player)
  end

  --~ return player.gui.screen[gui_names.frames.main]
  return gui
end


-- Get the scroll pane that contains the vehicle list from the player's GUI
local function get_gui_tabcontainer(player)
  GCKI.entered_function({player})

  player = GCKI.ascertain_player(player)
  if not (player and player.valid) then
    GCKI.arg_err(player, "player specification")
  end

  local gui = get_gui(player)
  local inner_frame = gui and gui.valid and gui["inner-frame"]
  if not (inner_frame and inner_frame.valid) then
    GCKI.writeDebug("Must initialize GUI (inner frame)!")
    gui = create_gui(player)
    inner_frame = gui["inner-frame"]
  end

  local container = inner_frame[gui_names.scroll_panes.list_container]
  if not (container and container.valid) then
    GCKI.writeDebug("Must initialize GUI (container)!")
    gui = create_gui(player)
    inner_frame = gui["inner-frame"]
    container = inner_frame[gui_names.scroll_panes.list_container]
  end

  GCKI.entered_function("leave")
  return container
end



------------------------------------------------------------------------------------
------------------------------------------------------------------------------------
--                                Shared functions                                --
------------------------------------------------------------------------------------
------------------------------------------------------------------------------------


------------------------------------------------------------------------------------
--                  Initialize GUI for vehicles in selected area                  --
------------------------------------------------------------------------------------
--~ player_vehicles.init_gui = function(player)
  --~ GCKI.entered_function({player})
player_vehicles.init_gui = function(player, flags)
  GCKI.entered_function({player, flags})

  -- Read flags
  GCKI.assert(flags, {"table", "nil"}, "nil or table or flags")
  local skip_event_check = flags and flags.skip_event_check

  -- Make sure we have a valid player
  player = GCKI.ascertain_player(player)
  if not (player and player.valid) then
    GCKI.arg_err(player, "player specification")
  end
  GCKI.show("player", player.name)


  local p_data = mod.player_data[player.index]
  GCKI.show("p_data", p_data)

  local vehicles = p_data and p_data.locked_or_owned or {}

  -- The GUI frames/flows will be built the first time this function is called for
  -- a player. The actual table will be cleared when the GUI is closed. It must be
  -- rebuilt when the player uses the keys to select an area.
  local gui = get_gui(player)


  --~ -- Hide existing GUI and return if there are no vehicles to display
  --~ if not next(vehicles) then
    --~ gui.visible = false
    --~ GCKI.entered_function({}, "leave", "No selected vehicles!")
    --~ return
  -- Hide existing GUI if there are no vehicles to display
  if not next(vehicles) then
    gui.visible = false
    --~ GCKI.entered_function({}, "leave", "No selected vehicles!")
    --~ return
  else
    gui.auto_center = not gui.visible
    GCKI.show("Set gui.auto_center", gui.auto_center)
  end


  ------------------------------------------------------------------------------------
  --                          Create table for vehicle list                         --
  ------------------------------------------------------------------------------------
  --~ local tab_container = gui[gui_names.scroll_panes.list_container]
  local tab_container = get_gui_tabcontainer(player)
GCKI.show("tab_container", GCKI.argprint(tab_container))
  local vehicle_list = tab_container[gui_names.tables.vehicle_list]
GCKI.show("vehicle_list", GCKI.argprint(vehicle_list))

  -- Initialize table for vehicle list?
  do
    GCKI.writeDebugNewBlock("Create or clear table for vehicle list?")
    if not (vehicle_list and vehicle_list.valid) then
      GCKI.writeDebug("%s vehicle list: creating table!",
                      {vehicle_list and "No valid" or "No"})
      create_table(tab_container)

    elseif vehicle_list.column_count ~= #columns then
      GCKI.writeDebug("Number of columns changed: removing old table!")
      vehicle_list.destroy()

      GCKI.writeDebugNewBlock("Recreating table!")
      create_table(tab_container)

    -- Remove everything but the header line and any vehicles staying in the new table.
    else
      GCKI.writeDebug("Clearing existing table!")
      GCKI_gui.clear_table(vehicle_list, columns, vehicles)
    end
  end

  ----------------------------------------------------------------------------------
  --                         Fill table with vehicle data                         --
  ----------------------------------------------------------------------------------
  player_vehicles.add_to_gui(player, vehicles, {skip_event_check = skip_event_check})

  -- Hide existing GUI and return if there are no vehicles to display
  if not next(vehicles) then
    player_vehicles.toggle_button_is_visible(player, false)

    if gui and gui.valid then
      gui.visible = false
    end
  end

  GCKI.entered_function("leave")
end


-- Get the vehicle list from the player's GUI
player_vehicles.get_gui_table = function(player)
  GCKI.entered_function({player})

  player = GCKI.ascertain_player(player)
  if not (player and player.valid) then
    GCKI.arg_err(player, "player specification")
  end

  local tab_name = gui_names.tables.vehicle_list

  local container = get_gui_tabcontainer(player)
  local tab = container and container.valid and container[tab_name]

  if not (tab and tab.valid) then
    tab = create_table(container, tab_name)
  end
  --~ return container and container.valid and container[gui_names.tables.vehicle_list]
  return tab
end


------------------------------------------------------------------------------------
--                 Toggle GUI for vehicles owned/locked by player                 --
------------------------------------------------------------------------------------
player_vehicles.toggle_gui = function(player)
  GCKI.entered_function({player})

  -- Make sure we have a valid player
  player = GCKI.ascertain_player(player)
  if not (player and player.valid) then
    GCKI.arg_err(player, "player specification")
  end
  GCKI.show("player", player.name)

  --~ local p_data = global.player_data[player.index]

  -- Toggle GUI
  --~ local gui = player.gui.screen[gui_names.frames.main]
  --~ if gui and gui.valid then
    --~ gui.visible = not gui.visible
    --~ GCKI.writeDebug("%s %s the list of claimed or locked vehicles.",
                    --~ {player.name, gui.visible and "opened" or "closed"})
  --~ end
  local gui = get_gui(player)
  --~ if gui and gui.valid then
    gui.visible = not gui.visible
    GCKI.writeDebug("%s %s the list of claimed or locked vehicles.",
                    {player.name, gui.visible and "opened" or "closed"})
  --~ end

  -- If player turned on this GUI, we must close the list of selected vehicles!
  --~ local selected = player.gui.screen[GCKI_gui_names.select_area.frames.main]
  --~ if gui and gui.valid and gui.visible and selected and selected.valid and selected.visible then
    --~ GCKI.writeDebug("Must close %s!", {GCKI.argprint(selected)} )
    --~ GCKI_gui_select_area.close_gui(player)
  --~ end
  --~ if gui and gui.valid and gui.visible then
  if gui.visible then
    local selected = player.gui.screen[GCKI_gui_names.select_area.frames.main]
    -- Turn off GUI for selected vehicles
    if selected and selected.valid and selected.visible then
      GCKI.writeDebug("Must close %s!", {GCKI.argprint(selected)} )
      GCKI_gui_select_area.close_gui(player)
    end

    -- Bring GUI to front
    gui.bring_to_front()
  end

  GCKI.entered_function("leave")
end


------------------------------------------------------------------------------------
--   Show or hide the toggle button of GUI for vehicles owned/locked by player    --
------------------------------------------------------------------------------------
player_vehicles.toggle_button_is_visible = function(player, state)
  GCKI.entered_function({player, state})

  -- Make sure we have a valid player
  player = GCKI.ascertain_player(player)
  if not (player and player.valid) then
    GCKI.arg_err(player, "player specification")
  end
  GCKI.show("player", player.name)

  GCKI.assert(state, "boolean")

  local button_flow = mod_gui.get_button_flow(player)
  --~ local toggle_button = mod_gui.get_button_flow(player) and
                        --~ mod_gui.get_button_flow(player)[gui_names.buttons.toggle_gui]
  local toggle_button = button_flow and button_flow[gui_names.buttons.toggle_gui]
GCKI.show("toggle_button", GCKI.argprint(toggle_button))

  if toggle_button and toggle_button.valid and toggle_button.visible ~= state then
GCKI.show("toggle_button.visible", toggle_button.visible)
    toggle_button.visible = state
    toggle_button.enabled = state
    GCKI.writeDebug("Toggle button for GUI with owned/locked vehicles of player %s is now %s!",
                    {player.index, toggle_button.visible and "visible" or "hidden"})
  end

  GCKI.entered_function("leave")
end


------------------------------------------------------------------------------------
--                  Close GUI for vehicles owned/locked by player                 --
------------------------------------------------------------------------------------
player_vehicles.close_gui = function(player)
  GCKI.entered_function({player})

  -- Make sure we have a valid player
  player = GCKI.ascertain_player(player)
  if not (player and player.valid) then
    GCKI.arg_err(player, "player specification")
  end
  GCKI.show("player", player.name)

  --~ local gui = player.gui.screen[gui_names.frames.main]
  local gui = get_gui(player)
GCKI.show("Player's vehicles GUI", GCKI.argprint(gui))

  -- Hide GUI
  --~ if gui and gui.valid and gui.visible then
  if gui.visible then
    gui.visible = false
    GCKI.writeDebug("Closed the list of vehicles selected by %s.",
                    {GCKI.argprint(player)})
  end

  GCKI.entered_function("leave")
end


--~ ------------------------------------------------------------------------------------
--~ --     Remove our GUI from all players on a force, or all players in the game     --
--~ ------------------------------------------------------------------------------------
--~ player_vehicles.remove_guis = function(force)
  --~ GCKI.entered_function({force})

  --~ -- Remove toggle buttons of all players and reset vehicles
  --~ local gui_toggle, p_data
  --~ local e_name = gui_names.buttons.toggle_gui

  --~ for p, player in pairs(force.players) do
    --~ -- Remove toggle button
    --~ gui_toggle = mod_gui.get_button_flow(player)[e_name]
    --~ if gui_toggle and gui_toggle.valid then
      --~ gui_toggle.destroy()
      --~ GCKI.writeDebug("Removed toggle button of %s!", {GCKI.argprint(player)})
    --~ end

    --~ -- Reset the vehicles
    --~ for v, vehicle in pairs(global.player_data[p].locked_or_owned or {}) do
    --~ p_data = global.player_data and global.player_data[p]
    --~ for v, vehicle in pairs(p_data and p_data.locked_or_owned or {}) do
      --~ GCKI_vehicle.remove_vehicle(vehicle, {
        --~ keep_custom_name = true,
        --~ keep_gui = true,
      --~ })
      --~ GCKI.writeDebug("Reset %s!", {GCKI.argprint(vehicle)})

    --~ end
  --~ end

  --~ -- Remove GUIs of all players
  --~ local gui_name = gui_names.frames.main
  --~ GCKI_gui.remove_guis(force, gui_name)

  --~ GCKI.entered_function("leave")
--~ end

------------------------------------------------------------------------------------
--      Close our GUI from all players on a force, or all players in the game     --
------------------------------------------------------------------------------------
player_vehicles.hide_guis = function(force, flags)
  GCKI.entered_function({force, flags})

  -- Hide toggle buttons of all players
  --~ local gui_toggle, p_data
  local gui_toggle
  local e_name = gui_names.buttons.toggle_gui

  for p, player in pairs(force.players) do
    -- Hide toggle button
    gui_toggle = mod_gui.get_button_flow(player)[e_name]
    if gui_toggle and gui_toggle.valid then
      gui_toggle.visible = false
      GCKI.writeDebug("Toggle button of %s is now hidden!", {GCKI.argprint(player)})
    end

    --~ -- Reset the vehicles
    --~ for v, vehicle in pairs(global.player_data[p].locked_or_owned or {}) do
    --~ p_data = global.player_data and global.player_data[p]
    --~ for v, vehicle in pairs(p_data and p_data.locked_or_owned or {}) do
      --~ GCKI_vehicle.remove_vehicle(vehicle, {
        --~ keep_custom_name = true,
        --~ keep_gui = true,
      --~ })
      --~ GCKI.writeDebug("Reset %s!", {GCKI.argprint(vehicle)})

    --~ end
  end

  -- Hide GUIs of all players
  local gui_name = gui_names.frames.main
  GCKI_gui.hide_guis(force, gui_name, flags)

  GCKI.entered_function("leave")
end


------------------------------------------------------------------------------------
--                               Add vehicle to GUI                               --
-- vehicle_list:        Our GUI table of selected vehicles                        --
-- vehicles:            An entity or an array of entities                         --
------------------------------------------------------------------------------------
--~ player_vehicles.add_to_gui = function(player, vehicles)
  --~ GCKI.entered_function({player, vehicles})
player_vehicles.add_to_gui = function(player, vehicles, flags)
  GCKI.entered_function({player, vehicles, flags})

  -- Read flags
  GCKI.assert(flags, {"table", "nil"}, "nil or table or flags")
  local skip_event_check = flags and flags.skip_event_check

  player = GCKI.ascertain_player(player)
  if not (player and player.valid) then
    GCKI.arg_err(player, "player specification")
  end
  GCKI.show("player", player.name)

  --~ local force = player.force
--~ GCKI.show("global.force_data["..force.name.."]", global.force_data[force.name])
--~ error("Break!")
  local p_data = mod.player_data[player.index]

  -- Make sure we always have an array of vehicles!
  --~ GCKI.assert(vehicles, "table")
  GCKI.assert(vehicles, {"LuaEntity", "table"}, "vehicle or table of vehicles")
  if vehicles.object_name == "LuaEntity" then
    vehicles = {vehicles}
  end

  --~ local gui = player.gui.screen[gui_names.frames.main]
  local gui = get_gui(player)
GCKI.show("gui", GCKI.argprint(gui))
  local tab_container = get_gui_tabcontainer(player)
GCKI.show("tab_container", GCKI.argprint(tab_container))
  local vehicle_list = tab_container[gui_names.tables.vehicle_list]
GCKI.show("vehicle_list", GCKI.argprint(vehicle_list))
  if not (vehicle_list and vehicle_list.valid) then
    GCKI.writeDebug("Must create table!")
    vehicle_list = create_table(tab_container)
  end
GCKI.show("vehicle_list", GCKI.argprint(vehicle_list))
--~ error("Break!")
  --~ ------------------------------------------------------------------------------------
  --~ --                     Make sure the toggle button is visible!                    --
  --~ ------------------------------------------------------------------------------------
  --~ GCKI.writeDebug("Must show toggle button!")
  --~ player_vehicles.toggle_button_is_visible(player, true)


  ------------------------------------------------------------------------------------
  --                                Get vehicle info                                --
  ------------------------------------------------------------------------------------
  local element, v_id, v_data, v_locker, v_owner, player_is_owner_or_locker,
        player_named_vehicle, text, named_by,
        show_toggle_button, show_on_map, show_on_camera

  for v, vehicle in pairs(vehicles) do
GCKI.show(v, GCKI.argprint(vehicle))

    -- Vehicle prototype and entity are valid!
    if GCKI_vehicle.is_vehicle(vehicle) then
      show_toggle_button = true
      v_id = vehicle.unit_number
      v_data = mod.GCKI_vehicles[v_id]
      v_locker = v_data and v_data.locker
      v_owner = v_data and v_data.owner
      named_by = v_owner or v_locker or
                  (mod.named_vehicles.by_id[v_id] and mod.named_vehicles.by_id[v_id].named_by)
      text = mod.named_vehicles.by_id[v_id] and mod.named_vehicles.by_id[v_id].name

      player_is_owner_or_locker = (v_owner == player.index) or
                                  (v_locker == player.index)
      player_named_vehicle = (named_by == player.index)

      if type(named_by) == "number" then
        named_by = game.players[named_by] and game.players[named_by].name
      end
  GCKI.show("named_by", named_by)
  GCKI.show("custom name", text)
  GCKI.show("mod.named_vehicles.by_id["..v_id.."]", mod.named_vehicles.by_id[v_id])

      show_on_map = (p_data.show_on_map and p_data.show_on_map.entity and
                      p_data.show_on_map.entity.valid and
                      p_data.show_on_map.entity.unit_number == v_id) and
                      true or false
  GCKI.show("show_on_map", show_on_map)

      show_on_camera = (p_data.show_on_camera and p_data.show_on_camera.entity and
                        p_data.show_on_camera.entity.valid and
                        p_data.show_on_camera.entity.unit_number == v_id) and
                        true or false
  GCKI.show("show_on_camera", show_on_camera)

      ------------------------------------------------------------------------------------
      --                                Add GUI elements                                --
      ------------------------------------------------------------------------------------
GCKI.show("mod.vehicle_prototypes.map", mod.vehicle_prototypes.map)

GCKI.show("vehicle", GCKI.argprint(vehicle))

      --~ local function check_element(e_name, v_id)
        --~ local col_name = gui_names.table_columns[e_name]..v_id
        --~ local element = col_name and vehicle_list[col_name]

        --~ return element and element.valid
      --~ end
      local function check_element(e_name)
        local col_name = gui_names.table_columns[e_name]..v_id
        local elem = col_name and vehicle_list[col_name]

        return elem and elem.valid
      end

      -- Icon
      if not check_element("icon", v_id) then
        element = vehicle_list.add({
          type = "sprite",
          name = gui_names.table_columns.icon..v_id,
          --~ sprite = "item/"..global.vehicle_prototypes_map[vehicle.type][vehicle.name].placeable_by,
          sprite = "item/"..mod.vehicle_prototypes.map[vehicle.type][vehicle.name].placeable_by,
        })
        GCKI.created_msg(element)
      end

      -- Prototype name
      --~ if not vehicle_list[gui_names.table_columns.proto_name..v_id] then
      if not check_element("proto_name", v_id) then
        local pass_on_flags = {ignore_custom_name = true, ignore_unit_number = true}

        element = vehicle_list.add({
          type = "label",
          name = gui_names.table_columns.proto_name..v_id,
          caption = GCKI.loc_name(vehicle, pass_on_flags),
        })
        GCKI.created_msg(element)
      end

      -- ID/Name
      --~ if not vehicle_list[gui_names.table_columns.id..v_id] then
      if not check_element("id", v_id) then
        text = mod.named_vehicles.by_id[v_id] and
                GCKI.enquote(mod.named_vehicles.by_id[v_id].name)
        element = vehicle_list.add({
          type = "textfield",
          name = gui_names.table_columns.id..v_id,
          text = text or v_id,
          lose_focus_on_confirm = true,
          clear_and_focus_on_right_click = true,
          enabled = not (v_owner or v_locker) or
                    player_is_owner_or_locker or
                    player_named_vehicle,
          style = "GCKI_stretchable_textfield",
        })
  GCKI.writeDebug("Setting tooltip of ID column:")

        element.tooltip = element.enabled and
          {"GCKI-GUI-vehicle-list-tooltips.v_id", vehicle.localised_name, element.text} or
          {"GCKI-GUI-vehicle-list-tooltips.id_disabled", named_by, vehicle.localised_name, element.text}
        GCKI.created_msg(element)
      end

      -- Surface
      --~ if not vehicle_list[gui_names.table_columns.surface..v_id] then
      if not check_element("surface", v_id) then
        element = vehicle_list.add({
          type = "label",
          name = gui_names.table_columns.surface..v_id,
          caption = vehicle.surface.name,
        })
        GCKI.created_msg(element)
      end

      -- Toggle ownership
      --~ if not vehicle_list[gui_names.table_columns.toggle_owned..v_id] then
      if not check_element("toggle_owned", v_id) then
        element = vehicle_list.add({
          type = "checkbox",
          name = gui_names.table_columns.toggle_owned..v_id,
          --~ state = (v_owner ~= ""),
          state = (v_owner ~= nil),
          enabled = player_is_owner_or_locker
        })
  GCKI.writeDebug("Setting tooltip of toggle-ownership column:")
  GCKI.show("element.enabled", element.enabled)
  GCKI.show("element.state", element.state)
  GCKI.show("locker", GCKI.argprint(v_locker))
        element.tooltip = element.enabled and element.state and not v_locker and {
          "GCKI-GUI-vehicle-list-tooltips.unclaim_warning",
          vehicle.localised_name,
          mod.named_vehicles.by_id[v_id] and GCKI.enquote(mod.named_vehicles.by_id[v_id].name) or v_id
        } or ""
        GCKI.created_msg(element)
      end

      -- Toggle lock
      if not check_element("toggle_lock", v_id) then
        element = vehicle_list.add({
          type = "checkbox",
          name = gui_names.table_columns.toggle_lock..v_id,
          state = (v_locker ~= nil),
          enabled = player_is_owner_or_locker,
        })
  GCKI.writeDebug("Setting tooltip of toggle-ownership column:")
  GCKI.show("element.enabled", element.enabled)
  GCKI.show("owner", GCKI.argprint(v_owner))
        element.tooltip = element.enabled and element.state and not v_owner and {
          "GCKI-GUI-vehicle-list-tooltips.unlock_warning",
          vehicle.localised_name,
          mod.named_vehicles.by_id[v_id] and GCKI.enquote(mod.named_vehicles.by_id[v_id].name) or v_id
        } or ""
        GCKI.created_msg(element)
      end

      -- Mapview
      --~ if not vehicle_list[gui_names.table_columns.map_view..v_id] then
      if not check_element("map_view", v_id) then
        element = vehicle_list.add({
          type = "checkbox",
          name = gui_names.table_columns.map_view..v_id,
          state = show_on_map,
          enabled = true,
        })
        GCKI.created_msg(element)
      end

      -- Camera
      --~ if not vehicle_list[gui_names.table_columns.camera..v_id] then
      if not check_element("camera", v_id) then
        element = vehicle_list.add({
          type = "checkbox",
          name = gui_names.table_columns.camera..v_id,
          state = show_on_camera,
          enabled = true,
        })
        GCKI.created_msg(element)
      end

      -- Add vehicle to player's list of selected vehicles
      --~ local p_data = global.player_data[player.index]
      p_data.locked_or_owned[v_id] = vehicle
      GCKI.writeDebug("Added p_data.locked_or_owned[%s]!", {v_id})

    --~ -- Must remove invalid vehicle!
    --~ else
--~ GCKI.writeDebug("%s is invalid!", {GCKI.argprint(vehicle)})
--~ GCKI.show("player_data", global.player_data[player.index])
      --~ GCKI_vehicle.remove_vehicle(vehicle)
--~ error("Break!")
    end
  end

  sort_vehicle_rows(vehicle_list, p_data.locked_or_owned)

  ------------------------------------------------------------------------------------
  --         If there are any vehicles on the GUI, unhide the toggle button!        --
  ------------------------------------------------------------------------------------
  if show_toggle_button then
    GCKI.writeDebug("Must show toggle button!")
    player_vehicles.toggle_button_is_visible(player, true)

     --~ -- Activate GUI events?
    if skip_event_check then
      GCKI.writeDebug("Skipping event check!")
    else
      GCKI.writeDebug("Checking whether we need GUI events!")
      GCKI_events.helper.need_gui_events()
    end
  end

  GCKI.entered_function("leave")
end


------------------------------------------------------------------------------------
--                    Remove vehicle from GUI for selected area                   --
-- player: player index, name or entity                                           --
-- id: unit_number                                                    --
------------------------------------------------------------------------------------
player_vehicles.remove_from_gui = function(player, vehicles, flags)
  GCKI.entered_function({player, vehicles, flags})

  player = GCKI.ascertain_player(player)
  if not (player and player.valid) then
    GCKI.arg_err(player, "player specification")
  end
  GCKI.show("player", player.name)

  GCKI.assert(vehicles, "table")
  GCKI.assert(flags, {"table", "nil"})

  local keep_gui_visible = flags and flags.keep_gui_visible
  local skip_event_check = flags and flags.skip_event_check

  --~ local gui = player.valid and player.gui.screen and player.gui.screen[gui_names.frames.main]
  --~ local tab_container = gui and gui[gui_names.scroll_panes.list_container]
  --~ local vehicle_list = tab_container and tab_container[gui_names.tables.vehicle_list]
  local gui = get_gui(player)
  local vehicle_list = player_vehicles.get_gui_table(player)
GCKI.show("vehicle_list", vehicle_list)
  if not vehicle_list then
    GCKI.entered_function({}, "leave", GCKI.argprint(player).." has no vehicle list!")
    return
  end

  local p_data = mod.player_data[player.index]
GCKI.show("p_data", p_data)

  ------------------------------------------------------------------------------------
  --                           Remove vehicles from table                           --
  ------------------------------------------------------------------------------------
  --~ local tab = gui[gui_names.scroll_panes.list_container][gui_names.tables.vehicle_list]
  local id, col_name


  for v, vehicle in pairs(vehicles) do
    id = vehicle.unit_number

    -- Remove vehicle from GUI              --
    for c, column in pairs(columns) do
      col_name = gui_names.table_columns[column]..id
      --~ if tab[col_name] and tab[col_name].valid then
        --~ GCKI.writeDebug("Must remove %s!", {GCKI.argprint(tab[col_name])})
        --~ tab[col_name].destroy()
      --~ end
      if vehicle_list[col_name] and vehicle_list[col_name].valid then
        GCKI.writeDebug("Removing %s!", {GCKI.argprint(vehicle_list[col_name])})
        vehicle_list[col_name].destroy()
      end
    end

    -- Remove from list of vehicles owned/locked by player
    if p_data.locked_or_owned and p_data.locked_or_owned[id] then
      p_data.locked_or_owned[id] = nil
      GCKI.writeDebug("Removed p_data.locked_or_owned[%s]", {id})

      if not next(p_data.locked_or_owned) then
        p_data.locked_or_owned = nil
        GCKI.writeDebug("Removed mod.player_data[%s].locked_or_owned!", {player.index})
      end
    end
  end

  -- Hide GUI and toggle button if there are no vehicles owned/locked by player
GCKI.show("p_data.locked_or_owned", p_data.locked_or_owned)
GCKI.show("keep_gui_visible", keep_gui_visible)
GCKI.show("not (p_data.locked_or_owned or keep_gui_visible)",
          not (p_data.locked_or_owned or keep_gui_visible))

  if not (p_data.locked_or_owned or keep_gui_visible) then
    gui.visible = false
    GCKI.writeDebug("Made GUI of %s invisible!", {GCKI.argprint(player)})

    player_vehicles.toggle_button_is_visible(player, false)
  end
  --~ end

  -- Check whether GUI events are still needed
  if skip_event_check then
    GCKI.writeDebug("Skipping check for GUI events!")
  else
    GCKI.writeDebug("Checking whether we need GUI events!")
    GCKI_events.helper.need_gui_events()
  end

  GCKI.entered_function("leave")
end


------------------------------------------------------------------------------------
--      Update vehicle info on GUI of a players who has selected the vehicle      --
-- player: player index, name or entity                                           --
-- vehicle: unit_number or entity                                                 --
------------------------------------------------------------------------------------
player_vehicles.update_vehicle_entry = function(player, vehicle)
  GCKI.entered_function({player, vehicle})

  player = GCKI.ascertain_player(player)
  if not (player and player.valid) then
    GCKI.arg_err(player, "player specification")
  end
  GCKI.show("player", player.name)

  local p_data = mod.player_data[player.index]

  GCKI.assert(vehicle, {"LuaEntity", "number"})
  local id
  if type(vehicle) == "number" then
    --~ id = p_data.locked_or_owned[vehicle]
    id = vehicle
    vehicle = mod.GCKI_vehicles[id] and mod.GCKI_vehicles[id].entity
  elseif vehicle.valid then
    id = vehicle.unit_number
  end
GCKI.show("id", id)
GCKI.show("vehicle", vehicle)
  --~ if not GCKI_vehicle.is_vehicle(vehicle) then
    --~ GCKI.arg_err(vehicle, "vehicle specification")
  --~ end
--~ GCKI.show("vehicle", GCKI.argprint(vehicle))

  --~ local gui = player.gui.screen[gui_names.frames.main]
  --~ local tab_container = gui and gui[gui_names.scroll_panes.list_container]
  --~ local vehicle_list = tab_container and tab_container[gui_names.tables.vehicle_list]
  --~ local gui = get_gui(player)
  local tab_container = get_gui_tabcontainer(player)
  local vehicle_list = tab_container[gui_names.tables.vehicle_list]
  if not (vehicle_list and vehicle_list.valid) then
    GCKI.entered_function({}, "leave", "No vehicle list on GUI!")
    return
  end

  ------------------------------------------------------------------------------------
  --                               Update vehicle info                              --
  ------------------------------------------------------------------------------------
  --~ local id = vehicle.unit_number
  local v_data = id and mod.GCKI_vehicles[id]
  local v_locker = v_data and v_data.locker
  local v_owner = v_data and v_data.owner
  local player_is_owner_or_locker = (v_owner == player.index) or (v_locker == player.index)
  local show_on_map = (p_data.show_on_map and p_data.show_on_map.id == id) or false
  local show_on_camera = (p_data.show_on_camera and p_data.show_on_camera.id == id) or false

  local custom_name = mod.named_vehicles.by_id[id] and
                      GCKI.enquote(mod.named_vehicles.by_id[id].name)
GCKI.show("custom_name", custom_name)
GCKI.show("mod.named_vehicles.by_id", mod.named_vehicles.by_id)
  --~ args.can_rename_vehicle = AD_vehicle.can_rename_vehicle(vehicle, player, c_name)

  --~ local element, tooltip
  local element

  -- ID/Custom name
  element = vehicle_list[gui_names.table_columns.id..id]
  if element and element.valid then
    GCKI.writeDebug("Updating %s", {GCKI.argprint(element)})

    local args = {
      vehicle = vehicle,
      player = player,
      custom_name = custom_name,
    }
    GCKI_gui.set_textfield(
      element,
      custom_name or tostring(id),
      --~ not (v_owner or v_locker) or player_is_owner_or_locker
      GCKI_vehicle.can_rename_vehicle(args, script.mod_name)
    )
    custom_name = element.text
  end
GCKI.show("custom_name", custom_name)

  -- Surface
  element = vehicle_list[gui_names.table_columns.surface..id]
  if element and element.valid then
    GCKI.writeDebug("Updating %s", {GCKI.argprint(element)})
    element.caption = vehicle.valid and vehicle.surface.name or ""
  end

  -- Toggle ownership
  element = vehicle_list[gui_names.table_columns.toggle_owned..id]
  if element and element.valid then
    GCKI.writeDebug("Updating %s", {GCKI.argprint(element)})
    GCKI_gui.set_checkbox(element, v_owner~= nil, player_is_owner_or_locker)
    element.tooltip = element.enabled and element.state and not v_locker and {
      "GCKI-GUI-vehicle-list-tooltips.unclaim_warning",
      vehicle.localised_name,
      vehicle and vehicle.valid and vehicle.localised_name or "INVALID",
      custom_name
    } or ""
  end

  -- Toggle lock
  element = vehicle_list[gui_names.table_columns.toggle_lock..id]
  if element and element.valid then
    GCKI.writeDebug("Updating %s", {GCKI.argprint(element)})

    GCKI_gui.set_checkbox(element, v_locker ~= nil, player_is_owner_or_locker)
    element.tooltip = element.enabled and element.state and not v_owner and {
      "GCKI-GUI-vehicle-list-tooltips.unlock_warning",
      --~ vehicle.localised_name,
      vehicle and vehicle.valid and vehicle.localised_name or "INVALID",
      custom_name
    } or ""
  end

  -- Toggle state of minimap checkbox
  element = vehicle_list[gui_names.table_columns.map_view..id]
  if element and element.valid then
    GCKI.writeDebug("Updating %s", {GCKI.argprint(element)})

    local enabled = true
    GCKI_gui.set_checkbox(element, show_on_map, enabled)
  end

  -- Toggle state of camera checkbox
  element = vehicle_list[gui_names.table_columns.camera..id]
  if element and element.valid then
    GCKI.writeDebug("Updating %s", {GCKI.argprint(element)})

    local enabled = true
    GCKI_gui.set_checkbox(element, show_on_camera, enabled)
  end

  sort_vehicle_rows(vehicle_list, p_data.locked_or_owned)

  GCKI.entered_function("leave")
end


------------------------------------------------------------------------------------
--    Remove vehicle from GUI of player who selected it or update vehicle info    --
-- player: player index, name or entity                                           --
-- vehicle: entity                                                                --
------------------------------------------------------------------------------------
player_vehicles.update_gui = function(player, vehicle, flags)
  GCKI.entered_function({player, vehicle, flags})

  player = GCKI.ascertain_player(player)
  if not (player and player.valid) then
    GCKI.arg_err(player, "player specification")
  end
  GCKI.show("player", player.name)

  GCKI.assert(vehicle, {"LuaEntity"})
  GCKI.assert(flags, {"table", "nil"})

  -- If keep_gui_visible is set, we won't hide the GUI for vehicles owned/locked
  -- by a player when the last vehicle is removed. (This is important when the
  -- player owns an unlocked vehicle and claims a new one because the GUI would stay
  -- hidden after the last vehicle had been removed and we added the new one.)
  local keep_gui_visible = flags and flags.keep_gui_visible

  local skip_event_check = flags and flags.skip_event_check

  local pass_on_flags = {
    keep_gui_visible = keep_gui_visible,
    skip_event_check = skip_event_check,
  }

  local p_data = mod.player_data[player.index]

  -- Update vehicle info
  if vehicle.valid and p_data.locked_or_owned and
                        p_data.locked_or_owned[vehicle.unit_number] then
    GCKI.writeDebug("Must update info for %s in GUI of %s!",
                    {GCKI.argprint(vehicle), GCKI.argprint(player)})
    --~ GCKI_gui_player_vehicles.update_vehicle_entry(player, vehicle.unit_number)
    player_vehicles.update_vehicle_entry(player, vehicle.unit_number)

  -- Remove from GUI
  else
    GCKI.writeDebug("Must remove %s from GUI of %s!",
                    {GCKI.argprint(vehicle), GCKI.argprint(player)})

    --~ GCKI_gui_player_vehicles.remove_from_gui(player, {vehicle}, {keep_gui_visible = keep_gui_visible})
    player_vehicles.remove_from_gui(player, {vehicle}, pass_on_flags)
  end

  GCKI.entered_function("leave")
end




------------------------------------------------------------------------------------
--              Swap vehicles on GUI if some mod exchanged a vehicle              --
-- player: player index, name or entity                                           --
-- old_id, new_id: unit_number                                                    --
------------------------------------------------------------------------------------
player_vehicles.swap_vehicle_on_gui = function(player, old_id, new_vehicle)
  GCKI.entered_function({player, old_id, new_vehicle})

  player = GCKI.ascertain_player(player)
  if not (player and player.valid) then
    GCKI.arg_err(player, "player specification")
  end
  GCKI.show("player", player.name)

  GCKI.assert(old_id, "number")

  if not GCKI_vehicle.is_vehicle(new_vehicle) then
    GCKI.arg_err(new_vehicle, "vehicle")
  end

  local new_id = new_vehicle.unit_number

  local p_data = mod.player_data[player.index]
  if not (p_data.locked_or_owned and
          p_data.locked_or_owned[old_id] or
          p_data.locked_or_owned[new_id]) then

    GCKI.entered_function({}, "leave", "Player doesn't have this vehicle on the GUI!")
    return
  end

  local gui = player.gui.screen[gui_names.frames.main]
  if not (gui and gui.valid) then
    GCKI.entered_function({}, "leave", GCKI.argprint(player).."has no GUI for selected vehicles!")
    return
  end

  ------------------------------------------------------------------------------------
  --                        Swap elements of vehicle in table                       --
  ------------------------------------------------------------------------------------
  --~ local tab = gui[gui_names.scroll_panes.list_container][gui_names.tables.vehicle_list]
  local tab_container = get_gui_tabcontainer(player)
  local tab = tab_container[gui_names.tables.vehicle_list]

  if (tab and tab.valid) then
    GCKI.writeDebug("Must swap vehicles in table!")
    GCKI_gui.swap_vehicle_in_table({
      gui_table = tab,
      column_names = gui_names.table_columns,
      old_id = old_id,
      new_id = new_id
    })

    --------------------------------------------------------------------------------
    --           Swap vehicle on player's list of selected vehicles               --
    --------------------------------------------------------------------------------
    -- As the old vehicle will be destroyed, it's entry will automagically disappear!
    p_data.locked_or_owned[new_id] = new_vehicle
    GCKI.writeDebug("p_data.locked_or_owned[%s]: %s", {new_id, GCKI.argprint(new_vehicle)})
    sort_vehicle_rows(tab, p_data.locked_or_owned)
  end


  GCKI.entered_function("leave")
end


------------------------------------------------------------------------------------
-- If a checkbox for minimap or camera has been enabled for a vehicle, and if the --
-- checkbox of another vehicle was enabled before, we need to disable that!       --
------------------------------------------------------------------------------------
player_vehicles.check_minimap_camera_boxes = function(event)
  GCKI.entered_function({event})

  GCKI.assert(event, "table", "event data")

  --~ local player = event.player_index and game.players[event.player_index]
  local player = GCKI.ascertain_player(event.player_index)
  if not (player and player.valid) then
    GCKI.arg_err(player, "player specification")
  end
  local p_data = mod.player_data[player.index]
GCKI.show("player", player.name)

  local element = event.element
GCKI.show("element", GCKI.argprint(element))
  if not (GCKI.assert(element, "LuaGuiElement") and element.valid) then
    GCKI.arg_err(element, "LuaGuiElement")
  end
GCKI.show("element.state", element.state)

  -- The player has claimed/locked at least 2 vehicles and the checkbox has been
  -- checked. Uncheck corresponding checkbox of other vehicles!
  if element.state and table_size(p_data.locked_or_owned) > 1 then
    -- Get name of the checkbox's table column and the ID of the vehicle
    GCKI.writeDebug("Must check state of other vehicles' checkboxes!")
    local col_name, v_id = element.name:match("^(.+_)([0-9]+)$")
    v_id = v_id and tonumber(v_id)
GCKI.show("col_name", col_name)
GCKI.show("v_id", v_id)
    local tab = element.parent
    local col

    for v, vehicle in pairs(p_data.locked_or_owned) do
GCKI.show(v.." ~= "..v_id, v ~= v_id)
      if v ~= v_id then
        col = col_name..v
GCKI.show("col", col)
        if tab[col] and tab[col].valid and tab[col].state then
          tab[col].state = false
          GCKI.writeDebug("Unchecked %s!", {GCKI.argprint(tab[col])})
        end
      end
    end
  end

  GCKI.entered_function("leave")
end


------------------------------------------------------------------------------------
--                             Zoom minimap or camera                             --
------------------------------------------------------------------------------------
player_vehicles.zoom_minimap_camera = function(event)
  GCKI.entered_function({event})

  GCKI.assert(event, "table", "event data")

  local element = event.element
GCKI.show("element", GCKI.argprint(element))
  if not (GCKI.assert(element, "LuaGuiElement") and element.valid) then
    GCKI.arg_err(element, "LuaGuiElement")
  end

  local mouse_button = GCKI.mouse_button_names[event.button]
GCKI.show("mouse_button", mouse_button)

  local zoom = element.zoom
  -- Multiply zoom step by 2 (SHIFT or CTRL) or 4 (SHIFT and CTRL)
  local modifier = (event.shift and 2 or 1) * (event.control and 2 or 1)

  -- Get new zoom factor
  zoom =  (mouse_button == "left"   and zoom + GCKI.ZOOM_STEP * modifier) or
          (mouse_button == "right"  and zoom - GCKI.ZOOM_STEP * modifier) or
          (mouse_button == "middle" and GCKI.ZOOM_DEFAULT) or
          zoom

  -- Cap new zoom factor
  if zoom > GCKI.ZOOM_MAX then
    GCKI.writeDebug("Must reduce zoom factor from %s to %s.", {zoom, GCKI.ZOOM_MAX})
    zoom = GCKI.ZOOM_MAX
  elseif zoom < GCKI.ZOOM_MIN then
    GCKI.writeDebug("Must increase zoom factor from %s to %s.", {zoom, GCKI.ZOOM_MIN})
    zoom = GCKI.ZOOM_MIN
  end
GCKI.show("Final zoom factor", zoom)

  -- Apply new zoom factor and show it in the tooltip
  element.zoom = zoom
  element.tooltip = {"GCKI-GUI-tooltips.minimap-or-camera", zoom}
  GCKI.entered_function("leave")
end


------------------------------------------------------------------------------------
--                              GUI-ACTION DETECTED!                              --
------------------------------------------------------------------------------------

-- Button was clicked
player_vehicles.on_gui_click = function(event)
  GCKI.entered_function({event})

  local element = event.element

  if not GCKI.prefixed(element.name, GCKI.gui_player_vehicles_prefix) then
    GCKI.entered_function({}, "leave", GCKI.argprint(element).." does not belong to us!")
    return
  end

  --~ local player = game.players[event.player_index]
  local player = GCKI.ascertain_player(event.player_index)
  --~ local p_data = player and global.player_data and global.player_data[player.index]
  --~ local gui = player.gui.screen[gui_names.frames.main]


  ------------------------------------------------------------------------------------
  -- Toggle GUI
  if element.name == gui_names.buttons.toggle_gui then
    GCKI.writeDebug("Must toggle GUI of %s!", {GCKI.argprint(player)})
    player_vehicles.toggle_gui(player)

  -- Close button of selected area's vehicle list
  elseif element.name == gui_names.buttons.main_frame_close then
    GCKI.writeDebug("Must close the list of vehicles claimed/locked by %s.",
                    {GCKI.argprint(player)})
    player_vehicles.close_gui(player)

  -- Textfield for custom name has been selected
  elseif GCKI.prefixed(element.name, gui_names.table_columns.id) then
    GCKI.writeDebug("%s selected %s for editing!",
                    {GCKI.argprint(player), GCKI.argprint(element)})
    GCKI_gui.check_vehicle_name(event)

  -- Something else from our GUI has been clicked
  else
    GCKI.writeDebug("Nothing to do for %s!", {GCKI.argprint(element)})
  end

  GCKI.entered_function("leave")
end


-- Text entered into text field
player_vehicles.on_gui_text_changed = function(event)
  GCKI.entered_function({event})

  local element = event.element

  ------------------------------------------------------------------------------------
  -- Text field for custom vehicle name has been changed
  if GCKI.prefixed(element.name, gui_names.table_columns.id) then
    GCKI_gui.check_vehicle_name(event)

  -- Some other textfield has been changed (We don't need this yet!)
  else
    GCKI.writeDebug("Nothing to do for %s!", {GCKI.argprint(element)})
  end

  GCKI.entered_function("leave")
end


-- Finished changes to textfield (confirmed with ENTER key)
player_vehicles.on_gui_confirmed = function(event)
  GCKI.entered_function({event})

  local element = event.element

  ------------------------------------------------------------------------------------
  -- Text field for custom vehicle name has been changed
  if GCKI.prefixed(element.name, gui_names.table_columns.id) then
    GCKI_gui.edit_vehicle_name(event)

  -- Some other textfield has been changed (We don't need this yet!)
  else
    GCKI.writeDebug("Nothing to do for %s!", {GCKI.argprint(element)})
  end

  GCKI.entered_function("leave")
end


-- Finished changes to textfield (confirmed with ENTER key)
player_vehicles.on_gui_checked_state_changed = function(event)
  GCKI.entered_function({event})

  local element = event.element

  -- The other checkbox in this row: toggle_owned if player used toggle_lock, and
  --                                 toggle_lock if player used toggle_owned.
  local other_name, other

  ------------------------------------------------------------------------------------
  -- Checkbox for claiming custom vehicles has been toggled
  if GCKI.prefixed(element.name, gui_names.table_columns.toggle_owned) then
    GCKI.writeDebug("Toggled ownership using %s!", {GCKI.argprint(element)})

    --~ other_name = gui_names.table_columns.toggle_lock..element.name:match("^.+_(%d+)$")
    other_name = gui_names.table_columns.toggle_lock..element.name:match("^.-(%d+)$")
    other = element.parent[other_name]
GCKI.show("other", GCKI.argprint(other))
    GCKI_gui.change_vehicle_owner(event, other)

  -- Checkbox for locking custom vehicles has been toggled
  elseif GCKI.prefixed(element.name, gui_names.table_columns.toggle_lock) then
    GCKI.writeDebug("Toggled lock using %s!", {GCKI.argprint(element)})
    --~ other_name = gui_names.table_columns.toggle_owned..element.name:match("^.+_(%d+)$")
    other_name = gui_names.table_columns.toggle_owned..element.name:match("^.-(%d+)$")
    other = element.parent[other_name]
GCKI.show("other", GCKI.argprint(other))
    GCKI_gui.change_vehicle_locker(event, other)

  -- Checkbox for minimap has been toggled
  elseif GCKI.prefixed(element.name, gui_names.table_columns.map_view) then
    GCKI.writeDebug("Toggled minimap using %s!", {GCKI.argprint(element)})
    player_vehicles.check_minimap_camera_boxes(event)
    GCKI_gui_player_vehicles_map.update_map(event)

  -- Checkbox for camera has been toggled
  elseif GCKI.prefixed(element.name, gui_names.table_columns.camera) then
    GCKI.writeDebug("Toggled camera using %s!", {GCKI.argprint(element)})
    player_vehicles.check_minimap_camera_boxes(event)
    GCKI_gui_player_vehicles_camera.update_camera(event)

  -- Some other checkbox has been changed
  else
    GCKI.writeDebug("Nothing to do for %s!", {GCKI.argprint(element)})
  end

  GCKI.entered_function("leave")
end


------------------------------------------------------------------------------------
GCKI.entered_file("leave")
return player_vehicles
