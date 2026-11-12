GCKI.entered_file()

-- This file contains everything related to the GUI for vehicles selected by a    --
-- player. The vehicles on these GUIs may be ones that player has named, claimed, --
-- or locked; they also may have been named/claimed/locked by another player, or  --
-- by none at all. A vehicle may be selected by multiple player, so it appears on --
-- several GUIs simultaneously.
------------------------------------------------------------------------------------



local select_area = {}

------------------------------------------------------------------------------------
------------------------------------------------------------------------------------
--                              Names of GUI elements                             --
------------------------------------------------------------------------------------
------------------------------------------------------------------------------------
local gui_names = GCKI_gui_names.select_area
--~ GCKI.show("selector names", gui_names)



------------------------------------------------------------------------------------
------------------------------------------------------------------------------------
--                                Local definitions                                --
------------------------------------------------------------------------------------
------------------------------------------------------------------------------------

-- We'll need these columns for our table:
local columns = {
  "icon", "proto_name", "id",
  "owner",  "toggle_owned",
  "locker", "toggle_lock",
}



local function create_gui(player)
  GCKI.entered_function({player})

  player = GCKI.ascertain_player(player)
  if not (player and player.valid) then
    GCKI.arg_err(player, "player specification")
  end


  ------------------------------------------------------------------------------------
  --           Construct the main frame that will contain the entire GUI            --
  ------------------------------------------------------------------------------------
  local gui = player.gui.screen
  if not (gui[gui_names.frames.main] and gui[gui_names.frames.main].valid) then
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
  local header = gui["header"]
  if not (header and header.valid) then
    header = GCKI_gui.make_flow({
      parent = gui,
      name = "header",
      --~ caption = {"GCKI-GUI.gui-title", {"mod-name.GCKI"}, {"GCKI-GUI.gui-title-vehicles"}},
      caption = {
        "GCKI-GUI.gui-title",
        {"mod-name.GCKI"},
        {"GCKI-GUI.gui-title-selected-vehicles"}
      },
      direction = "horizontal",
      dragspace = true,
      close_button_name = gui_names.buttons.main_frame_close,
    })
    GCKI.created_msg(header)
  end

  -- Inner frame: an inlaid frame, just for style
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

  -- Create table
  if not (vehicle_list and vehicle_list.valid) then
    vehicle_list = tab_container.add({
      type = "table",
      name = gui_names.tables.vehicle_list,
      column_count = #columns,
      draw_horizontal_lines = true,
      draw_horizontal_line_after_headers = true,
    })
    GCKI.writeDebug("Created table for vehicle list!")
  else
    vehicle_list.clear()
    GCKI.writeDebug("Cleared table!")
  end

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

  if not (player.gui.screen[gui_names.frames.main] and
          player.gui.screen[gui_names.frames.main].valid) then
    GCKI.writeDebug("Must initialize GUI!")
    create_gui(player)
  end

  GCKI.entered_function("leave")
  return player.gui.screen[gui_names.frames.main]
end


-- Get the scroll pane that contains the vehicle list from the player's GUI
local function get_gui_tabcontainer(player)
  GCKI.entered_function({player})

  player = GCKI.ascertain_player(player)
  if not (player and player.valid) then
    GCKI.arg_err(player, "player specification")
  end

  local gui = get_gui(player)
  local function container()
    return gui and gui.valid and
            gui["inner-frame"] and gui["inner-frame"].valid and
            gui["inner-frame"][gui_names.scroll_panes.list_container]
  end

  if not container() then
    GCKI.writeDebug("Must initialize GUI!")
    create_gui(player)
  end

  GCKI.entered_function("leave")
  return container()
end

------------------------------------------------------------------------------------
------------------------------------------------------------------------------------
--                                Shared functions                                --
------------------------------------------------------------------------------------
------------------------------------------------------------------------------------


------------------------------------------------------------------------------------
--                  Initialize GUI for vehicles in selected area                  --
-- player: player index, name or entity                                           --
-- vehicles: array of entities                                                    --
------------------------------------------------------------------------------------
--~ select_area.init_gui = function(player, vehicles)
  --~ GCKI.entered_function({player, vehicles})
select_area.init_gui = function(player, vehicles, flags)
  GCKI.entered_function({player, vehicles, flags})

  -- Make sure we have a valid player
  player = GCKI.ascertain_player(player)
  if not (player and player.valid) then
    GCKI.arg_err(player, "player specification")
  end
  local p_data = mod.player_data[player.index]
  GCKI.show("player", player.name)
  GCKI.show("p_data", p_data)

  -- If "vehicles" is passed on, it must be a table
  GCKI.assert(vehicles, {"table", "nil"})
GCKI.show("vehicles", vehicles)
  if type(vehicles) == "table" and not flags then
    local checked = {}
    for v, vehicle in pairs(vehicles) do
      if type(vehicle) == "userdata" and vehicle.object_name == "LuaEntity" then
        table.insert(checked, vehicle)
        vehicles[v] = nil
      end
    end
    if next(checked) then
      vehicles = checked
    else
      flags = util.table.deepcopy(vehicles)
      vehicles = nil
    end
  end
  if not vehicles then
    GCKI.writeDebug("No vehicles passed on. Looking for stored vehicles!")
    vehicles = p_data.selected_vehicles and
                util.table.deepcopy(p_data.selected_vehicles)
    GCKI.show("vehicles", vehicles)
  end

  -- Read flags
  GCKI.assert(flags, {"table", "nil"}, "nil or table or flags")
  --~ local skip_event_check = flags and flags.skip_event_check


  -- The GUI frames/flows will be built the first time this function is called for
  -- a player. The actual table will be cleared when the GUI is closed. It must be
  -- rebuilt when the player uses the keys to select an area.
  --~ local gui = player.gui.screen[gui_names.frames.main]
  local gui = get_gui(player)

  -- Hide existing GUI and return if there are no vehicles to display
  if gui and gui.valid and not vehicles then
    gui.visible = false
    GCKI.entered_function({}, "leave", "No selected vehicles!")
    return
  end

  -- Keep the GUI wherever it was moved by the player if the player has selected a
  -- new area while the GUI was already visible.
  gui.auto_center = not gui.visible
  GCKI.show("Set gui.auto_center", gui.auto_center)

  -- Sort selected vehicles by unit_number and store them with player, so the
  -- order of vehicles won't change when we update the GUI.
  p_data.selected_vehicles = {}
GCKI.show("p_data.selected_vehicles", p_data.selected_vehicles)
GCKI.show("vehicles", vehicles)

  -- Fill the table with currently selected vehicles
  local id
  for v, vehicle in pairs(vehicles or {}) do
    id = vehicle.valid and vehicle.unit_number
    if id then
      p_data.selected_vehicles[id] = vehicle
      GCKI.show("p_data.selected_vehicles["..id.."]",
                GCKI.argprint(p_data.selected_vehicles[id]))
    end
  end

  -- Show GUI if there are any vehicles on it!
  local show_gui = next(p_data.selected_vehicles)
  if show_gui then
    -- Close GUI for vehicles owned/locked by the player!
    GCKI.writeDebug("Closing GUI for vehicles owned/locked by %s!", {GCKI.argprint(player)})
    GCKI_gui_player_vehicles.close_gui(player)

    -- Display GUI
    GCKI.writeDebug("Displaying GUI of %s!", {GCKI.argprint(player)})
    gui.visible = true

    -- Bring it to front!
    GCKI.writeDebug("Moving GUI to front!")
    gui.bring_to_front()

  else
    GCKI.writeDebug("Removing p_data.selected_vehicles!")
    p_data.selected_vehicles = nil

    GCKI.writeDebug("Hiding GUI for vehicles selected by %s!", {GCKI.argprint(player)})
    gui.visible = false
  end



  ----------------------------------------------------------------------------------
  --                         Create table for vehicle list                        --
  ----------------------------------------------------------------------------------
  local vehicle_list = select_area.get_gui_table(player)

  -- Initialize table for vehicle list?
  if vehicle_list.column_count ~= #columns then
    GCKI.writeDebug("Must destroy and rebuild table for vehicle list!")
    local tab_container = get_gui_tabcontainer(player)
    vehicle_list.destroy()
    --~ vehicle_list = create_table(tab_container)
    create_table(tab_container)

  -- Remove everything but the header line
  else
    GCKI_gui.clear_table(vehicle_list, columns, p_data.selected_vehicles)
  end

  ----------------------------------------------------------------------------------
  --                         Fill table with vehicle data                         --
  ----------------------------------------------------------------------------------
  if p_data.selected_vehicles then
    GCKI.writeDebug("Must fill table with vehicle data!")
    select_area.add_to_gui(player, p_data.selected_vehicles)
  end

  GCKI.entered_function("leave")
end



-- Get the vehicle list from the player's GUI
select_area.get_gui_table = function(player)
  GCKI.entered_function({player})

  player = GCKI.ascertain_player(player)
  if not (player and player.valid) then
    GCKI.arg_err(player, "player specification")
  end

  local tab_name = gui_names.tables.vehicle_list

  local container = get_gui_tabcontainer(player)
  --~ local tab = container and container.valid and container[tab_name]
  local tab = container[tab_name]

  if not (tab and tab.valid) then
    tab = create_table(container, tab_name)
  end
  --~ return container and container.valid and container[gui_names.tables.vehicle_list]
  return tab
end


------------------------------------------------------------------------------------
--                     Close GUI for vehicles in selected area                    --
------------------------------------------------------------------------------------
select_area.close_gui = function(player, flags)
  GCKI.entered_function({player, flags})

  -- Make sure we have a valid player
  player = GCKI.ascertain_player(player)
  if not (player and player.valid) then
    GCKI.arg_err(player, "player specification")
  end
  GCKI.show("player", player.name)

  GCKI.assert(flags, {"table", "nil"}, "nil or table of flags")

  --~ local gui = player.gui.screen[gui_names.frames.main]
  local gui = get_gui(player)

  -- Hide GUI
  gui.visible = false
  GCKI.writeDebug("Closed the list of vehicles selected by %s.", {GCKI.argprint(player)})

  -- In the GUI, remove children of table for vehicle list
  local vehicle_list = select_area.get_gui_table(player)

  if vehicle_list and vehicle_list.valid then
    GCKI_gui.clear_table(vehicle_list, columns)
    GCKI.writeDebug("Cleared vehicle list!")
  end

  -- Remove list of selected vehicles
  mod.player_data[player.index].selected_vehicles = nil
  GCKI.writeDebug("Removed mod.player_data[%s].selected_vehicles!", {player.index})

  -- Check whether we still need GUI events!
  GCKI.writeDebug("Checking whether we need GUI events!")
  if not (flags and flags.skip_event_check) then
    GCKI_events.helper.need_gui_events()
  else
    GCKI.writeDebug("Skipping check for GUI events!")
  end

  GCKI.entered_function("leave")
end


------------------------------------------------------------------------------------
--     Remove our GUI from all players on a force, or all players in the game     --
------------------------------------------------------------------------------------
select_area.remove_guis = function(force)
  GCKI.entered_function({force})

  local gui_name = gui_names.frames.main
  GCKI_gui.remove_guis(force, gui_name, "selected_vehicles")

  GCKI.entered_function("leave")
end


------------------------------------------------------------------------------------
--      Hide our GUI from all players on a force, or all players in the game      --
------------------------------------------------------------------------------------
select_area.hide_guis = function(force, flags)
  GCKI.entered_function({force, flags})

  local gui_name = gui_names.frames.main
  GCKI_gui.hide_guis(force, gui_name, flags)

  GCKI.entered_function("leave")
end


------------------------------------------------------------------------------------
--                               Add vehicle to GUI                               --
-- vehicle_list:        Our GUI table of selected vehicles                        --
-- vehicles:            An entity or an array of entities                         --
------------------------------------------------------------------------------------
select_area.add_to_gui = function(player, vehicles, flags)
  GCKI.entered_function({player, vehicles, flags})

  player = GCKI.ascertain_player(player)
  if not (player and player.valid) then
    GCKI.arg_err(player, "player specification")
  end
  GCKI.show("player", player.name)

  GCKI.assert(vehicles, "table", "table of vehicles")

  -- Read flags
  GCKI.assert(flags, {"table", "nil"}, "nil or table or flags")
  local skip_event_check = flags and flags.skip_event_check
  --~ GCKI.assert(vehicles, {"table", "nil"})

  --~ local gui = player.valid and player.gui.screen[gui_names.frames.main]
  --~ local vehicle_list = gui[gui_names.scroll_panes.list_container][gui_names.tables.vehicle_list]
  --~ local gui = get_gui(player)
  local vehicle_list = select_area.get_gui_table(player)

  ----------------------------------------------------------------------------------
  --                               Get vehicle info                               --
  ----------------------------------------------------------------------------------
  local element, id, text
  local v_data, v_locker, v_owner, named_by
  local player_is_owner_or_locker, player_named_vehicle

  local o, l
  for v, vehicle in pairs(vehicles) do
  --~ for v, vehicle in pairs(vehicles or {}) do
    id = vehicle.unit_number
    v_data = mod.GCKI_vehicles[id]
    --~ v_locker = (v_data and v_data.locker and game.players[v_data.locker] and
                --~ game.players[v_data.locker].name) or ""
    --~ v_owner = (v_data and v_data.owner and game.players[v_data.owner] and
                --~ game.players[v_data.owner].name) or ""
    --~ named_by = (v_owner ~= "" and v_owner) or (v_locker ~= "" and v_locker) or
                --~ (global.named_vehicles.by_id[id] and global.named_vehicles.by_id[id].named_by)
    --~ player_is_owner_or_locker = (v_owner == player.name) or (v_locker == player.name)
    --~ if v_data then
    do
      l = v_data and v_data.locker and game.get_player(v_data.locker)
      o = v_data and v_data.owner and game.get_player(v_data.owner)
      v_locker = (l and l.valid and l.name) or ""
      v_owner = (o and o.valid and o.name) or ""
      named_by = (v_owner ~= "" and v_owner) or (v_locker ~= "" and v_locker) or
                  (mod.named_vehicles.by_id[id] and
                    mod.named_vehicles.by_id[id].named_by)
      player_is_owner_or_locker = (v_owner == player.name) or
                                  (v_locker == player.name)
      player_named_vehicle = (named_by == player.index)
    end
    --~ if type(named_by) == "number" then
      --~ named_by = game.players[named_by] and game.players[named_by].name
    --~ end
    if type(named_by) == "number" then
      local p = game.get_player(named_by)
      named_by = p and p.valid and p.name
    end
GCKI.show("named_by", named_by)


    --------------------------------------------------------------------------------
    --                              Add GUI elements                              --
    --------------------------------------------------------------------------------
    local tab_cols = gui_names.table_columns

    -- Icon
    if not vehicle_list[tab_cols.icon..id] then
      element = vehicle_list.add({
        type = "sprite",
        name = tab_cols.icon..id,
        --~ sprite = "item/"..global.vehicle_prototypes_map[vehicle.type][vehicle.name].placeable_by,
        sprite = "item/"..mod.vehicle_prototypes.map[vehicle.type][vehicle.name].placeable_by,
      })
      GCKI.created_msg(element)
    end

    -- Prototype name
    if not vehicle_list[tab_cols.proto_name..id] then
      local pass_on_flags = { ignore_custom_name = true, ignore_unit_number = true }
      element = vehicle_list.add({
        type = "label",
        name = tab_cols.proto_name..id,
        caption = GCKI.loc_name(vehicle, pass_on_flags),
      })
      GCKI.created_msg(element)
    end

    -- ID/Name
    if not vehicle_list[tab_cols.id..id] then
      text = mod.named_vehicles.by_id[id] and
              GCKI.enquote(mod.named_vehicles.by_id[id].name)
      element = vehicle_list.add({
        type = "textfield",
        name = tab_cols.id..id,
        text = text or id,
        lose_focus_on_confirm = true,
        clear_and_focus_on_right_click = true,
        enabled = (v_owner == "" and v_locker == "") or
                  player_is_owner_or_locker or
                  player_named_vehicle,
        style = "GCKI_stretchable_textfield",
      })
GCKI.writeDebug("Setting tooltip of ID column:")

      element.tooltip = element.enabled and {
          "GCKI-GUI-vehicle-list-tooltips.id",
          vehicle.localised_name,
          element.text
      } or {
        "GCKI-GUI-vehicle-list-tooltips.id_disabled",
        named_by,
        vehicle.localised_name,
        element.text
      }
      GCKI.created_msg(element)
    end

    -- Owner name
    if not vehicle_list[tab_cols.owner..id] then
      element = vehicle_list.add({
        type = "label",
        name = tab_cols.owner..id,
        caption = v_owner,
      })
      GCKI.created_msg(element)
    end

    -- Toggle ownership
    if not vehicle_list[tab_cols.toggle_owned..id] then
      element = vehicle_list.add({
        type = "checkbox",
        name = tab_cols.toggle_owned..id,
        state = (v_owner ~= ""),
        enabled = player_is_owner_or_locker
      })
GCKI.writeDebug("Setting tooltip of toggle-ownership column:")
GCKI.show("element.enabled", element.enabled)
GCKI.show("element.state", element.state)
GCKI.show("locker", GCKI.argprint(v_locker))
      element.tooltip = element.enabled and element.state and v_locker == "" and {
        "GCKI-GUI-vehicle-list-tooltips.unclaim_warning",
        vehicle.localised_name,
        mod.named_vehicles.by_id[id] and GCKI.enquote(mod.named_vehicles.by_id[id].name) or id
      } or ""
      GCKI.created_msg(element)
    end

    -- Locker name
    if not vehicle_list[tab_cols.locker..id] then
      element = vehicle_list.add({
        type = "label",
        name = tab_cols.locker..id,
        caption = v_locker,
      })
      GCKI.created_msg(element)
    end

    -- Toggle lock
    if not vehicle_list[tab_cols.toggle_lock..id] then
      element = vehicle_list.add({
        type = "checkbox",
        name = tab_cols.toggle_lock..id,
        state = (v_locker ~= ""),
        enabled = player_is_owner_or_locker,
      })
GCKI.writeDebug("Setting tooltip of toggle-ownership column:")
GCKI.show("element.enabled", element.enabled)
GCKI.show("owner", GCKI.argprint(v_owner))
      element.tooltip = element.enabled and element.state and v_owner == "" and {
        "GCKI-GUI-vehicle-list-tooltips.unlock_warning",
        vehicle.localised_name,
        mod.named_vehicles.by_id[id] and GCKI.enquote(mod.named_vehicles.by_id[id].name) or id
      } or ""
      GCKI.created_msg(element)
    end

    -- Add vehicle to player's list of selected vehicles
    local p_data = mod.player_data[player.index]
    p_data.selected_vehicles[id] = vehicle
    GCKI.writeDebug("Added p_data.selected_vehicles[%s]!", {id})
  end

  -- Check whether we still need GUI events?
    if skip_event_check then
      GCKI.writeDebug("Skipping event check!")
    else
      GCKI.writeDebug("Checking whether we need GUI events!")
      GCKI_events.helper.need_gui_events()
    end
  --~ GCKI.writeDebug("Checking whether we need GUI events!")
  --~ GCKI_events.helper.need_gui_events()


  GCKI.entered_function("leave")
end


------------------------------------------------------------------------------------
--                    Remove vehicle from GUI for selected area                   --
-- player: player index, name or entity                                           --
-- id: unit_number                                                    --
------------------------------------------------------------------------------------
select_area.remove_from_gui = function(player, vehicles, flags)
  GCKI.entered_function({player, vehicles, flags})

  player = GCKI.ascertain_player(player)
  if not (player and player.valid) then
    GCKI.arg_err(player, "player specification")
  end
  GCKI.show("player", player.name)

  GCKI.assert(vehicles, "table")
  if not next(vehicles) then
    GCKI.entered_function({}, "leave", "No vehicles!")
    return
  end

  GCKI.assert(flags, {"table", "nil"}, "nil or table of flags")
  local skip_event_check = flags and flags.skip_event_check

  --~ local gui = player.valid and player.gui.screen and player.gui.screen[gui_names.frames.main]
  --~ local tab_container = gui and gui[gui_names.scroll_panes.list_container]
  --~ local vehicle_list = tab_container and tab_container[gui_names.tables.vehicle_list]
  local gui = get_gui(player)
  local tab_container = get_gui_tabcontainer(player)
  local vehicle_list = tab_container[gui_names.tables.vehicle_list]

  --~ if not vehicle_list then
  if not (vehicle_list and vehicle_list.valid) then
    GCKI.entered_function({}, "leave", GCKI.argprint(player).." has no vehicle list!")
    return
  end

  local p_data = mod.player_data[player.index]
  if not (p_data.selected_vehicles and next(p_data.selected_vehicles)) then
        GCKI.entered_function({}, "leave", "No selected vehicles!")
    return
  end


  ----------------------------------------------------------------------------------
  --                          Remove vehicles from table                          --
  ----------------------------------------------------------------------------------
  --~ local tab = gui[gui_names.scroll_panes.list_container][gui_names.tables.vehicle_list]
  local id, col_name
  local tab = vehicle_list

  for v, vehicle in pairs(vehicles) do
    id = vehicle.unit_number

    -- Remove vehicle from GUI              --
    for c, column in pairs(columns) do
      col_name = gui_names.table_columns[column]..id
      if tab[col_name] and tab[col_name].valid then
        GCKI.writeDebug("Removing %s.", {GCKI.argprint(tab[col_name])})
        tab[col_name].destroy()
      end
    end

    -- Remove vehicle from player's list of selected vehicles              --
    if p_data.selected_vehicles[id] then
          p_data.selected_vehicles[id] = nil
      GCKI.writeDebug("Removed p_data.selected_vehicles[%s].", {id})

      if not next(p_data.selected_vehicles) then
        p_data.selected_vehicles = nil
        GCKI.writeDebug("Removed mod.p_data[%s].selected_vehicles!", {player.index})

        gui.visible = false
        GCKI.writeDebug("Removed GUI of %s!", {GCKI.argprint(player)})
        break
      end
    end
  end

  -- Check whether we need GUI events?
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
select_area.update_vehicle_entry = function(player, vehicle)
  GCKI.entered_function({player, vehicle})

  player = GCKI.ascertain_player(player)
  if not (player and player.valid) then
    GCKI.arg_err(player, "player specification")
  end
  GCKI.show("player", player.name)

  GCKI.assert(vehicle, {"LuaEntity", "number"})
  if type(vehicle) == "number" then
    vehicle = mod.player_data[player.index].selected_vehicles[vehicle]
    if not GCKI_vehicle.is_vehicle(vehicle) then
      GCKI.arg_err(vehicle, "vehicle specification")
    end
  end
GCKI.show("vehicle", GCKI.argprint(vehicle))

  --~ local gui = player.gui.screen[gui_names.frames.main]
  --~ local tab_container = gui and gui[gui_names.scroll_panes.list_container]
  --~ local vehicle_list = tab_container and tab_container[gui_names.tables.vehicle_list]
  local tab_container = get_gui_tabcontainer(player)
  local vehicle_list = tab_container[gui_names.tables.vehicle_list]
  if not (vehicle_list and vehicle_list.valid) then
    GCKI.entered_function({}, "leave", "No vehicle list on GUI!")
    return
  end

  ----------------------------------------------------------------------------------
  --                              Update vehicle info                             --
  ----------------------------------------------------------------------------------
  local id = vehicle.unit_number
  local v_data = mod.GCKI_vehicles[id]
  --~ local v_locker = (v_data and v_data.locker and game.players[v_data.locker] and
                    --~ game.players[v_data.locker].name) or ""
  --~ local v_owner = (v_data and v_data.owner and game.players[v_data.owner] and
                    --~ game.players[v_data.owner].name) or ""
  --~ local player_is_owner_or_locker = (v_owner == player.name) or (v_locker == player.name)
GCKI.show("v_data", v_data)
  local v_locker, v_owner, player_is_owner_or_locker
  --~ if v_data then
--~ GCKI.writeDebug("v_data exists!")
  do
    local l = v_data and v_data.locker and game.get_player(v_data.locker)
    local o = v_data and v_data.owner and game.get_player(v_data.owner)
    v_locker = (l and l.valid and l.name) or ""
    v_owner = (o and o.valid and o.name) or ""
    player_is_owner_or_locker = (v_locker == player.name) or
                                (v_owner == player.name)
  end
GCKI.show("player_is_owner_or_locker", player_is_owner_or_locker)

  local custom_name = mod.named_vehicles.by_id[id] and
                      GCKI.enquote(mod.named_vehicles.by_id[id].name)
  --~ local element, tooltip
  local element

  local tab_cols = gui_names.table_columns

  -- ID/Name
  element = vehicle_list[tab_cols.id..id]
  if element and element.valid then
    GCKI.writeDebug("Updating %s", {GCKI.argprint(element)})

    GCKI_gui.set_textfield(
      element,
      custom_name or tostring(id),
      (v_owner == "" and v_locker == "") or player_is_owner_or_locker
    )
    custom_name = element.text
GCKI.show("custom_name", custom_name)
  end

  -- Owner name
  element = vehicle_list[tab_cols.owner..id]
  if element and element.valid then
    GCKI.writeDebug("Updating %s", {GCKI.argprint(element)})
    GCKI_gui.set_label(element, v_owner)
  end

  -- Toggle ownership
  element = vehicle_list[tab_cols.toggle_owned..id]
  if element and element.valid then
    GCKI.writeDebug("Updating %s", {GCKI.argprint(element)})
    GCKI_gui.set_checkbox(element, (v_owner ~= ""), player_is_owner_or_locker)
    element.tooltip = element.enabled and element.state and v_locker == "" and {
      "GCKI-GUI-vehicle-list-tooltips.unclaim_warning",
      vehicle.localised_name,
      custom_name
    } or ""
  end

  -- Locker name
  element = vehicle_list[tab_cols.locker..id]
  if element and element.valid then
    GCKI.writeDebug("Updating %s", {GCKI.argprint(element)})
    GCKI_gui.set_label(element, v_locker)
  end

  -- Toggle lock
  element = vehicle_list[tab_cols.toggle_lock..id]
  if element and element.valid then
    GCKI.writeDebug("Updating %s", {GCKI.argprint(element)})

    GCKI_gui.set_checkbox(element, (v_locker ~= ""), player_is_owner_or_locker)
    element.tooltip = element.enabled and element.state and v_owner == "" and {
      "GCKI-GUI-vehicle-list-tooltips.unlock_warning",
      vehicle.localised_name,
      custom_name
    } or ""
  end

  GCKI.entered_function("leave")
end


------------------------------------------------------------------------------------
--    Remove vehicle from GUI of player who selected it or update vehicle info    --
-- player: player index, name or entity                                           --
-- vehicle: entity                                                 --
------------------------------------------------------------------------------------
select_area.update_gui = function(player, vehicle, flags)
  GCKI.entered_function({player, vehicle, flags})

  player = GCKI.ascertain_player(player)
  if not (player and player.valid) then
    GCKI.arg_err(player, "player specification")
  end
  local p_data = mod.player_data[player.index]
  GCKI.show("player", player.name)

  GCKI.assert(vehicle, {"LuaEntity"})

  GCKI.assert(flags, {"table", "nil"}, "nil or table of flags")
  local skip_event_check = flags and flags.skip_event_check

  --~ -- Update vehicle info
  if vehicle.valid and p_data.selected_vehicles and
                        p_data.selected_vehicles[vehicle.unit_number] then
  --~ if vehicle.valid and p_data.selected_vehicles and
                        --~ p_data.selected_vehicles[vehicle.unit_number] and
                        --~ vehicle.surface == player.surface then
    GCKI.writeDebug("Must update info for %s in GUI of %s!", {GCKI.argprint(vehicle), GCKI.argprint(player)})
    GCKI_gui_select_area.update_vehicle_entry(player, vehicle.unit_number)

  -- Remove from GUI
  else
    local pass_on_flags = { skip_event_check = skip_event_check, }
    GCKI_gui_select_area.remove_from_gui(player, {vehicle}, pass_on_flags)
  end

  GCKI.entered_function("leave")
end




------------------------------------------------------------------------------------
--              Swap vehicles on GUI if some mod exchanged a vehicle              --
-- player: player index, name or entity                                           --
-- old_id, new_id: unit_number                                                    --
------------------------------------------------------------------------------------
select_area.swap_vehicle_on_gui = function(player, old_id, new_vehicle)
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
  if not (p_data.selected_vehicles and
          p_data.selected_vehicles[old_id] or
          p_data.selected_vehicles[new_id]) then

    GCKI.entered_function({}, "leave", "Player doesn't have this vehicle on the GUI!")
    return
  end

  --~ local gui = player.gui.screen[gui_names.frames.main]
  --~ if not (gui and gui.valid) then
    --~ GCKI.entered_function({}, "leave", GCKI.argprint(player).."has no GUI for selected vehicles!")
    --~ return
  --~ end
  --~ local gui = get_gui(player)

  ----------------------------------------------------------------------------------
  --                       Swap elements of vehicle in table                      --
  ----------------------------------------------------------------------------------
  --~ local old_name, new_name, col_name

  --~ local tab = gui[gui_names.scroll_panes.list_container][gui_names.tables.vehicle_list]
  local tab = select_area.get_gui_table (player)

  GCKI_gui.swap_vehicle_in_table({
    gui_table = tab,
    column_names = gui_names.table_columns,
    old_id = old_id,
    new_id = new_id
  })

  ----------------------------------------------------------------------------------
  --              Swap vehicle on player's list of selected vehicles              --
  ----------------------------------------------------------------------------------
  p_data.selected_vehicles[new_id] = new_vehicle
  GCKI.show("p_data.selected_vehicles["..new_id.."]", GCKI.argprint(new_vehicle))


  GCKI.entered_function("leave")
end


------------------------------------------------------------------------------------
--                              GUI-ACTION DETECTED!                              --
------------------------------------------------------------------------------------

-- Button was clicked
select_area.on_gui_click = function(event)
  GCKI.entered_function({event})

  local element = event.element

  if not GCKI.prefixed(element.name, GCKI.gui_select_area_prefix) then
    GCKI.entered_function({}, "leave", "Nothing to do for \""..GCKI.argprint(element).."\"!")
    return
  end

  --~ local player = game.players[event.player_index]
  local player = GCKI.ascertain_player(event.player_index)
  --~ local p_data = player and global.player_data and global.player_data[player.index]
  --~ local gui = player.gui.screen[gui_names.frames.main]


  ----------------------------------------------------------------------------------
  -- Close button of selected area's vehicle list, and remove temporary list
  if element.name == gui_names.buttons.main_frame_close then
    GCKI.writeDebug("Must close GUI for vehicles selected by %s!", {GCKI.argprint(player)})
    select_area.close_gui(player)

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
select_area.on_gui_text_changed = function(event)
  GCKI.entered_function({event})

  local element = event.element

  ----------------------------------------------------------------------------------
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
select_area.on_gui_confirmed = function(event)
  GCKI.entered_function({event})

  local element = event.element

  ----------------------------------------------------------------------------------
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
select_area.on_gui_checked_state_changed = function(event)
  GCKI.entered_function({event})

  local element = event.element

  -- The other checkbox in this row: toggle_owned if player used toggle_lock, and
  --                                 toggle_lock if player used toggle_owned.
  local other_name, other

  local tab_cols = gui_names.table_columns

  ----------------------------------------------------------------------------------
  -- Checkbox for claiming custom vehicles has been toggled
  if GCKI.prefixed(element.name, tab_cols.toggle_owned) then
    GCKI.writeDebug("Toggled ownership using %s!", {GCKI.argprint(element)})

    other_name = tab_cols.toggle_lock..element.name:match("^.+_(%d+)$")
    other = element.parent[other_name]
GCKI.show("other", GCKI.argprint(other))
    GCKI_gui.change_vehicle_owner(event, other)

  -- Checkbox for locking custom vehicles has been toggled
  elseif GCKI.prefixed(element.name, tab_cols.toggle_lock) then
    GCKI.writeDebug("Toggled lock using %s!", {GCKI.argprint(element)})
    other_name = tab_cols.toggle_owned..element.name:match("^.+_(%d+)$")
    other = element.parent[other_name]
GCKI.show("other", GCKI.argprint(other))
    GCKI_gui.change_vehicle_locker(event, other)

  -- Some other checkbox has been changed
  else
    GCKI.writeDebug("Nothing to do for %s!", {GCKI.argprint(element)})
  end

  GCKI.entered_function("leave")
end


------------------------------------------------------------------------------------
GCKI.entered_file("leave")
return select_area
