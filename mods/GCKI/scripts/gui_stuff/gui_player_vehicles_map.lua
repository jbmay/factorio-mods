-- This file contains everything the mini GUI we need for the map preview (just a
-- frame with header + close button and the minimap inside).
------------------------------------------------------------------------------------
GCKI.entered_file()

local pv_mapview = {}

------------------------------------------------------------------------------------
------------------------------------------------------------------------------------
--                              Names of GUI elements                             --
------------------------------------------------------------------------------------
------------------------------------------------------------------------------------
local gui_names = GCKI_gui_names.player_vehicles_mapview
--~ GCKI.show("player vehicles (minimap)", gui_names)



------------------------------------------------------------------------------------
------------------------------------------------------------------------------------
--                                Local definitions                                --
------------------------------------------------------------------------------------
------------------------------------------------------------------------------------

--~ local function create_gui(player)
  --~ GCKI.entered_function({player})

  --~ player = GCKI.ascertain_player(player)
  --~ if not (player and player.valid) then
    --~ GCKI.arg_err(player, "player specification")
  --~ end

  --~ local gui, element, e_name

  --~ ------------------------------------------------------------------------------------
  --~ --           Construct the main frame that will contain the entire GUI            --
  --~ ------------------------------------------------------------------------------------
  --~ gui = player.gui.screen
  --~ if not gui[gui_names.frames.main] then
    --~ gui = gui.add({
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

    --~ -- Header: flow for GUI title and closing button
    --~ local header = GCKI_gui.make_flow({
      --~ parent = gui,
      --~ name = "header",
      --~ caption = {
        --~ "GCKI-GUI.gui-title",
        --~ {"mod-name.GCKI"},
        --~ {"GCKI-GUI.gui-title-player-vehicles-map", ""},
      --~ },
      --~ direction = "horizontal"
    --~ })
    --~ GCKI.created_msg(header)
    --~ header.style.vertically_stretchable = false
    --~ header.title.drag_target = gui

    --~ -- Spacer to push closing button to the right (can be used to drag GUI)
    --~ local dragspace = header.add({
      --~ type = "empty-widget",
      --~ name = "dragspace",
      --~ style = "draggable_space_header",
    --~ })
    --~ dragspace.drag_target = gui
    --~ dragspace.style.horizontally_stretchable = true
    --~ dragspace.style.vertically_stretchable = true
    --~ GCKI.created_msg(dragspace)

    --~ -- Closing button
    --~ local close = header.add({
      --~ type = "sprite-button",
      --~ name = gui_names.buttons.main_frame_close,
      --~ visible = true,
      --~ style = "frame_action_button",
      --~ sprite = "utility/close_white",
      --~ mouse_button_filter = {"left"},
    --~ })
    --~ GCKI.created_msg(close)


    --~ ------------------------------------------------------------------------------------
    --~ --                                 Add the minimap                                --
    --~ ------------------------------------------------------------------------------------
    --~ local minimap = gui.add({
      --~ type = "minimap",
      --~ name = gui_names.maps.minimap,
      --~ visible = true,
      --~ chart_player_index = player.index,
      --~ position = player.position,
      --~ surface_index = player.surface.index,
      --~ zoom = GCKI.ZOOM_DEFAULT,
      --~ tooltip = {"GCKI-GUI-tooltips.minimap-or-camera", GCKI.ZOOM_DEFAULT},
    --~ })
    --~ GCKI.created_msg(minimap)

    --~ local style = minimap.style
    --~ local scale = 1.5
    --~ style.minimal_width = 256 * scale
    --~ style.minimal_height = 256 * scale
    --~ style.maximal_width = style.minimal_width * 2
    --~ style.maximal_height = style.minimal_height * 2
    --~ style.natural_width = style.minimal_width
    --~ style.natural_height = style.minimal_height
  --~ end

  --~ GCKI.entered_function("leave")
  --~ return gui
--~ end


local function create_gui(player)
  GCKI.entered_function({player})

  player = GCKI.ascertain_player(player)
  if not (player and player.valid) then
    GCKI.arg_err(player, "player specification")
  end

  --~ local gui, element, e_name
  local gui

  ------------------------------------------------------------------------------------
  --           Construct the main frame that will contain the entire GUI            --
  ------------------------------------------------------------------------------------
  gui = player.gui.screen
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
GCKI.show("gui", GCKI.argprint(gui))

  -- Header: flow for GUI title and closing button
  local header = gui["header"]
  if not (header and header.valid) then
    header = GCKI_gui.make_flow({
      parent = gui,
      name = "header",
      caption = {"GCKI-GUI.gui-title", {"mod-name.GCKI"}, ""},
      direction = "horizontal",
      vertically_stretchable = false,
      dragspace = true,
      close_button_name = gui_names.buttons.main_frame_close,
    })
    GCKI.created_msg(header)
  end

  -- We can't have linebreaks in the header, so we need a second flow just for the
  -- caption with the names of vehicle and surface.
  local content_header = gui[gui_names.flows.vehicle_name]
  if not (content_header and content_header.valid) then
    content_header = GCKI_gui.make_flow({
      parent = gui,
      name = gui_names.flows.vehicle_name,
      --~ caption = {"GCKI-GUI.gui-title-vehicles-map", "", ""},
      caption = "",
      direction = "horizontal",
    })
    GCKI.created_msg(content_header)
for c, child in pairs(content_header.children) do
  GCKI.show("Element "..tostring(c), GCKI.argprint(child))
end
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

  GCKI.entered_function("leave")
  return gui
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

  return gui
end



-- Get the inner header with names of vehicle and surface
local function get_inner_header(player)
  GCKI.entered_function({player})

  player = GCKI.ascertain_player(player)
  if not (player and player.valid) then
    GCKI.arg_err(player, "player specification")
  end


  local gui = get_gui(player)
  local inner_header = gui and gui.valid and gui[gui_names.flows.vehicle_name]
  if not (inner_header and inner_header.valid) then
    GCKI.writeDebug("Must initialize GUI!")
    gui = create_gui(player)
  end
GCKI.show("gui", GCKI.argprint(gui))

  GCKI.entered_function("leave")
  return gui and gui.valid and gui[gui_names.flows.vehicle_name]
end



-- Get the flow containing the map
local function get_content_flow(player)
  GCKI.entered_function({player})

  player = GCKI.ascertain_player(player)
  if not (player and player.valid) then
    GCKI.arg_err(player, "player specification")
  end

  local gui = get_gui(player)
  local inner_frame = gui and gui.valid and gui["inner-frame"]
  if not (inner_frame and inner_frame.valid) then
    GCKI.writeDebug("Must initialize GUI!")
    gui = create_gui(player)
  end


  GCKI.entered_function("leave")
  return gui and gui.valid and gui["inner-frame"] or nil
end

------------------------------------------------------------------------------------
--                                 Add the minimap                                --
------------------------------------------------------------------------------------
local function get_map(player)
  GCKI.entered_function({player})

  local container = get_content_flow(player)
  local map_name = gui_names.maps.minimap
GCKI.show("container", GCKI.argprint(container))
  local minimap = container and container.valid and container[map_name]
  if not (minimap and minimap.valid) then
    minimap = container.add({
      type = "minimap",
      name = map_name,
      visible = true,
      chart_player_index = player.index,
      position = player.position,
      surface_index = player.surface.index,
      zoom = GCKI.ZOOM_DEFAULT,
      tooltip = {"GCKI-GUI-tooltips.minimap-or-camera", GCKI.ZOOM_DEFAULT},
    })
    GCKI.created_msg(minimap)
  --~ end

    local style = minimap.style
    local scale = 1.5
    style.minimal_width = 256 * scale
    style.minimal_height = 256 * scale
    style.maximal_width = style.minimal_width * 2
    style.maximal_height = style.minimal_height * 2
    style.natural_width = style.minimal_width
    style.natural_height = style.minimal_height
    GCKI.modified_msg("style", minimap, "Adjusted")
  end

  GCKI.entered_function("leave")
  return minimap
end

------------------------------------------------------------------------------------
------------------------------------------------------------------------------------
--                                Shared functions                                --
------------------------------------------------------------------------------------
------------------------------------------------------------------------------------


------------------------------------------------------------------------------------
--                           Initialize GUI for minimap                           --
-- player: player index, name or entity                                           --
------------------------------------------------------------------------------------
pv_mapview.init_gui = function(player)
  GCKI.entered_function({player})

  -- Make sure we have a valid player
  player = GCKI.ascertain_player(player)
  if not (player and player.valid) then
    GCKI.arg_err(player, "player specification")
  end
  GCKI.show("player", player.name)

  local p_data = mod.player_data[player.index]
  GCKI.show("p_data", p_data)

  local show_on_map = p_data and p_data.show_on_map or false

  -- The GUI frames/flows will be built the first time this function is called for
  -- a player.
  --~ local gui = player.gui.screen[gui_names.frames.main]
  local gui = get_gui(player)

  -- Update GUI?
  if show_on_map then
    GCKI.writeDebug("Updating map GUI!")
    pv_mapview.update_gui(player)
  end


  -- Hide existing GUI if player didn't activate mapview for a vehicle
  --~ if gui and gui.valid then
    GCKI.writeDebug("Must %s minimap!", {show_on_map and "show" or "hide"})
    gui.visible = show_on_map and true or false


  --~ -- Initialize GUI if it doesn't exist yet.
  --~ else
    --~ GCKI.writeDebug("Must initialize GUI!")
    --~ gui = create_gui(player)
  --~ end

  GCKI.entered_function("leave")
end

------------------------------------------------------------------------------------
--                                   Update GUI                                   --
-- This updates the information shown in the GUI header (surface and custom name) --
------------------------------------------------------------------------------------
pv_mapview.update_gui = function(player, flags)
  GCKI.entered_function({player, flags})

  -- Make sure we have a valid player
  player = GCKI.ascertain_player(player)
  if not (player and player.valid) then
    GCKI.arg_err(player, "player specification")
  end
  GCKI.show("player", player.name)

  GCKI.assert(flags, {"table", "nil"}, "nil or table of flags")
  local skip_event_check = flags and flags.skip_event_check

  local p_data = mod.player_data[player.index]
  local v_data = p_data.show_on_map

  --~ local gui = get_gui(player)

  -- Player must have a GUI!
  --~ if gui and gui.valid then
    local vehicle
    local pass_on_flags = {skip_event_check = skip_event_check, }

    -- Close GUI if we have no data
    if not v_data then
      GCKI.writeDebug("Must close GUI because player doesn't have minimap data!")
      pass_on_flags = {skip_event_check = skip_event_check, }
      pv_mapview.close_gui(player, pass_on_flags)

    -- We have data
    else
      local gui = get_gui(player)

      -- Stored vehicle still exists
      if v_data.entity and v_data.entity.valid then
        vehicle = v_data.entity
        GCKI.show("vehicle", GCKI.argprint(vehicle))

        -- Close GUI if player hasn't claimed/locked the vehicle any longer
        if not (p_data.locked_or_owned and p_data.locked_or_owned[vehicle.unit_number]) then
          GCKI.writeDebug("Closing GUI because vehicle does not belong to player!")
          pv_mapview.close_gui(player, pass_on_flags)

        -- Close GUI if force of vehicle or player has been changed
        elseif vehicle.force ~= player.force then
          GCKI.show("player.force", player.force)
          GCKI.show("vehicle.force", vehicle.force)
          GCKI.writeDebug("Closing GUI because player force and vehicle force are different!")
          pv_mapview.close_gui(player, pass_on_flags)

        -- Update map
        else
          local v_surface = vehicle and vehicle.surface or
                            GCKI.ascertain_surface(v_data.surface_index) or
                            GCKI.arg_err(v_data.surface_index, "surface specification")
  GCKI.show("v_surface", GCKI.argprint(v_surface))
          local v_name    = v_data.name
  GCKI.show("v_name", GCKI.argprint(v_name))

          -- Update GUI title
          local header = gui.header
          if not (header and header.valid) then
            GCKI.writeDebug("Missing header or inner header -- must rebuild GUI!")
            gui = create_gui(player)
            header = gui.header
          end

          local inner_header = get_inner_header(player)

GCKI.show("header", GCKI.argprint(header))
GCKI.show("inner_header", GCKI.argprint(inner_header))
          header.title.caption = {
            "GCKI-GUI.gui-title",
            {"mod-name.GCKI"},
            {"GCKI-GUI.gui-title-player-vehicles-map", v_surface.name},
          }
          inner_header.title.caption = v_name
          --~ inner_header.title.caption = v_data.name

          -- Update map view
          local map = get_map(player)
          map.surface_index = v_surface.index
          map.entity = vehicle
          map.position = v_data.position


          GCKI.writeDebug("Updated GUI")
        end

      -- Vehicle isn't valid anymore!
      elseif v_data.id and
              not (p_data.locked_or_owned and p_data.locked_or_owned[v_data.id]) then
          GCKI.writeDebug("Must close GUI because vehicle does not belong to player!")
          pv_mapview.close_gui(player, pass_on_flags)
      end
    end
  --~ end

  GCKI.entered_function("leave")
end


------------------------------------------------------------------------------------
--                                 Update minimap                                 --
------------------------------------------------------------------------------------
--~ pv_mapview.update_map = function(event_data)
  --~ GCKI.entered_function({event_data})

  --~ GCKI.assert(event_data, "table")

  --~ -- Make sure we have a valid player
  --~ local player = GCKI.ascertain_player(event_data.player_index)
  --~ if not (player and player.valid) then
    --~ GCKI.arg_err(player, "player specification")
  --~ end
  --~ local p_data = global.player_data[player.index]
  --~ GCKI.show("player", player.name)

  --~ -- Get the vehicle ID from the GUI element
  --~ local element = event_data.element
--~ GCKI.show("element", GCKI.argprint(element))
--~ GCKI.show("element.state", GCKI.argprint(element.state))

  --~ local gui = get_gui(player)
--~ GCKI.show("gui", GCKI.argprint(gui))
--~ for e, element in pairs(gui.header.children) do
  --~ GCKI.show(e, GCKI.argprint(element))
--~ end



  --~ -- Minimap has been turned on for the vehicle
  --~ if element.state then
--~ GCKI.writeDebug("Must show minimap!")
    --~ local map = get_map(player)

    --~ local v_id = element and element.valid and element.name:match("^.+_([0-9]+)")
    --~ v_id = v_id and tonumber(v_id)

    --~ local vehicle = v_id and p_data.locked_or_owned and p_data.locked_or_owned[v_id]
    --~ local v_name = vehicle and GCKI.loc_name(vehicle)
    --~ p_data.show_on_map = p_data.show_on_map or {}

    --~ if vehicle and vehicle.valid then

      --~ local surface = vehicle.surface

      --~ -- Update player data
      --~ p_data.show_on_map = {
        --~ entity          = vehicle,
        --~ id              = vehicle.unit_number,
        --~ name            = v_name,
        --~ position        = vehicle.position,
        --~ surface_index   = surface.index,
      --~ }
--~ GCKI.show("p_data.show_on_map", p_data.show_on_map)

      --~ -- Update map
      --~ map.surface_index = surface.index
      --~ map.entity = vehicle
      --~ map.position = vehicle.position
      --~ GCKI.writeDebug("Updated map")

      --~ local header = gui.header
      --~ if not (header and header.valid) then
        --~ GCKI.writeDebug("Missing header or inner header -- must rebuild GUI!")
        --~ gui = create_gui(player)
        --~ header = gui.header
      --~ end

      --~ local inner_header = get_inner_header(player)
  --~ GCKI.show("header", GCKI.argprint(header))
  --~ GCKI.show("inner_header", GCKI.argprint(inner_header))
      --~ header.title.caption = {
        --~ "GCKI-GUI.gui-title",
        --~ {"mod-name.GCKI"},
        --~ {"GCKI-GUI.gui-title-player-vehicles-map", surface.name},
      --~ }
      --~ inner_header.title.caption = v_name

      --~ GCKI.writeDebug("Updated GUI")
    --~ end

  --~ -- Minimap has been turned off
  --~ else
--~ GCKI.writeDebug("Must hide minimap!")
    --~ pv_mapview.close_gui(player)
  --~ end

  --~ -- Show or hide the GUI?
--~ GCKI.show("gui.visible", gui.visible)
--~ GCKI.show("checkbox state", element.state)
--~ GCKI.show(tostring(gui.visible).." ~= "..tostring(element.state), gui.visible == element.state)

  --~ if gui and gui.valid and gui.visible ~= element.state then
    --~ gui.visible = element.state
    --~ GCKI.writeDebug("Turned minimap %s!", {element.state and "on" or "off"})
  --~ end

  --~ GCKI.entered_function("leave")
--~ end
pv_mapview.update_map = function(event_data)
  GCKI.entered_function({event_data})

  GCKI.assert(event_data, "table")

  -- Make sure we have a valid player
  local player = GCKI.ascertain_player(event_data.player_index)
  if not (player and player.valid) then
    GCKI.arg_err(player, "player specification")
  end
  local p_data = mod.player_data[player.index]
  GCKI.show("player", player.name)

  -- Get the vehicle ID from the GUI element
  local element = event_data.element
GCKI.show("element", GCKI.argprint(element))
GCKI.show("element.state", GCKI.argprint(element.state))

  local gui = get_gui(player)
GCKI.show("gui", GCKI.argprint(gui))
for e, elem in pairs(gui.header.children) do
  GCKI.show(e, GCKI.argprint(elem))
end



  -- Minimap has been turned on for the vehicle
  if element.state then
GCKI.writeDebug("Must show minimap!")
    local map = get_map(player)

    local v_id = element and element.valid and element.name:match("^.+_([0-9]+)")
    v_id = v_id and tonumber(v_id)

    local vehicle = v_id and p_data.locked_or_owned and p_data.locked_or_owned[v_id]
    local v_name = vehicle and GCKI.loc_name(vehicle)
    p_data.show_on_map = p_data.show_on_map or {}

    if vehicle and vehicle.valid then

      local surface = vehicle.surface

      -- Update player data
      p_data.show_on_map = {
        entity          = vehicle,
        id              = vehicle.unit_number,
        name            = v_name,
        position        = vehicle.position,
        surface_index   = surface.index,
      }
GCKI.show("p_data.show_on_map", p_data.show_on_map)

      -- Update map
      map.surface_index = surface.index
      map.entity = vehicle
      map.position = vehicle.position
      GCKI.writeDebug("Updated map")

      local header = gui.header
      if not (header and header.valid) then
        GCKI.writeDebug("Missing header or inner header -- must rebuild GUI!")
        gui = create_gui(player)
        header = gui.header
      end

      local inner_header = get_inner_header(player)
  GCKI.show("header", GCKI.argprint(header))
  GCKI.show("inner_header", GCKI.argprint(inner_header))
      header.title.caption = {
        "GCKI-GUI.gui-title",
        {"mod-name.GCKI"},
        {"GCKI-GUI.gui-title-player-vehicles-map", surface.name},
      }
      inner_header.title.caption = v_name

      GCKI.writeDebug("Updated GUI")
    end

  -- Minimap has been turned off
  else
GCKI.writeDebug("Must hide minimap!")
    pv_mapview.close_gui(player)
  end

  -- Show or hide the GUI?
GCKI.show("gui.visible", gui.visible)
GCKI.show("checkbox state", element.state)
GCKI.show(tostring(gui.visible).." ~= "..tostring(element.state), gui.visible == element.state)

  if gui and gui.valid and gui.visible ~= element.state then
    gui.visible = element.state
    GCKI.writeDebug("Turned minimap %s!", {element.state and "on" or "off"})
  end

  GCKI.entered_function("leave")
end



------------------------------------------------------------------------------------
--                         Close GUI for player's minimap                         --
------------------------------------------------------------------------------------
pv_mapview.close_gui = function(player, flags)
  GCKI.entered_function({player, flags})

  -- Make sure we have a valid player
  player = GCKI.ascertain_player(player)
  if not (player and player.valid) then
    GCKI.arg_err(player, "player specification")
  end
  GCKI.show("player", player.name)

  local p_data = mod.player_data[player.index]

  -- Read flags
  GCKI.assert(flags, {"table", "nil"}, "nil or table or flags")
  local skip_event_check = flags and flags.skip_event_check


  --~ local gui = player.gui.screen[gui_names.frames.main]
  local gui = get_gui(player)
GCKI.show("Player's minimap", GCKI.argprint(gui))

  -- Hide GUI
  if gui and gui.valid and gui.visible then
    gui.visible = false
    GCKI.writeDebug("Closed the list of vehicles selected by %s.", {GCKI.argprint(player)})
  end

  -- Clean up!
  if p_data.show_on_map then
    -- Remove from global table
    local v_id = p_data.show_on_map.id
    p_data.show_on_map = nil
    GCKI.writeDebug("Removed mod.player_data[%s].show_on_map!", {player.index})

    -- Uncheck minimap button in GUI of players' locked vehicles
    if p_data.locked_or_owned and p_data.locked_or_owned[v_id] then
      GCKI.writeDebug("Must uncheck minimap button!")
      GCKI_gui_player_vehicles.update_vehicle_entry(player, v_id)
    end
  end

  -- Do we still need GUI events?
  if skip_event_check then
    GCKI.writeDebug("Skipping check for GUI events!")
  else
    GCKI.writeDebug("Checking whether we need GUI events!")
    GCKI_events.helper.need_gui_events()
  end

  GCKI.entered_function("leave")
end


------------------------------------------------------------------------------------
--     Remove our GUI from all players on a force, or all players in the game     --
------------------------------------------------------------------------------------
pv_mapview.remove_guis = function(force)
  GCKI.entered_function({force})

  local gui_name = gui_names.frames.main
  GCKI_gui.remove_guis(force, gui_name, "show_on_map")

  GCKI.entered_function("leave")
end


------------------------------------------------------------------------------------
--      Hide our GUI from all players on a force, or all players in the game      --
------------------------------------------------------------------------------------
pv_mapview.hide_guis = function(force, flags)
  GCKI.entered_function({force, flags})

  local gui_name = gui_names.frames.main
  GCKI_gui.hide_guis(force, gui_name, flags)

  GCKI.entered_function("leave")
end


------------------------------------------------------------------------------------
--              Swap vehicles on GUI if some mod exchanged a vehicle              --
-- player: player index, name or entity                                           --
-- old_id, new_id: unit_number                                                    --
------------------------------------------------------------------------------------
pv_mapview.swap_vehicle_on_gui = function(player, old_id, new_vehicle)
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

  --~ local new_id = new_vehicle.unit_number

  local p_data = mod.player_data[player.index]
  if not p_data.show_on_map then
    GCKI.entered_function({}, "leave", "No minimap for player!")
    return
  end

  --~ local gui = player.gui.screen[gui_names.frames.main]
  --~ if not (gui and gui.valid) then
    --~ GCKI.entered_function({}, "leave", GCKI.argprint(player).."has no GUI for the minimap!")
    --~ return
  --~ end

  ------------------------------------------------------------------------------------
  --                            Swap vehicles on minimap                            --
  ------------------------------------------------------------------------------------
  --~ local map = gui[gui_names.maps.minimap]
  local map = get_map(player)
  map.entity = new_vehicle
  map.position = new_vehicle.position

  local inner_header = get_inner_header(player)
  --~ gui.header.caption = GCKI.loc_name(vehicle)
  inner_header.title.caption = GCKI.loc_name(new_vehicle )

  ------------------------------------------------------------------------------------
  --                      Swap entry for vehicle in player data                     --
  ------------------------------------------------------------------------------------
  -- As the old vehicle will be destroyed, it's entry will automagically disappear!
  p_data.show_on_map.entity = new_vehicle
  p_data.show_on_map.id = new_vehicle.unit_number
  p_data.show_on_map.name = GCKI.loc_name(new_vehicle)
  p_data.show_on_map.position = new_vehicle.position
  p_data.show_on_map.surface_index = new_vehicle.surface.index
  GCKI.show("p_data.show_on_map", p_data.show_on_map)


  GCKI.entered_function("leave")
end


------------------------------------------------------------------------------------
--                              GUI-ACTION DETECTED!                              --
------------------------------------------------------------------------------------

-- Button was clicked
pv_mapview.on_gui_click = function(event)
  GCKI.entered_function({event})

  local element = event.element

  if not GCKI.prefixed(element.name, GCKI.gui_player_vehicles_map_prefix) then
    GCKI.entered_function({}, "leave", "Nothing to do for \""..GCKI.argprint(element).."\"!")
    return
  end

  --~ local player = game.players[event.player_index]
  local player = GCKI.ascertain_player(event.player_index)
  --~ local p_data = player and global.player_data and global.player_data[player.index]
  --~ local gui = player.gui.screen[gui_names.frames.main]


GCKI.show("gui_names.buttons.main_frame_close", gui_names.buttons.main_frame_close)
GCKI.show("element.name", element.name)
GCKI.show(element.name.." == "..gui_names.buttons.main_frame_close,
          element.name == gui_names.buttons.main_frame_close)
  ------------------------------------------------------------------------------------
  -- Close button of minimap GUI
  if element.name == gui_names.buttons.main_frame_close then
    GCKI.writeDebug("Must close the minimap of %s.", {GCKI.argprint(player)})
    pv_mapview.close_gui(player)

  -- Minimap has been clicked: change zoom
  elseif element.name == gui_names.maps.minimap then
    GCKI.writeDebug("Must change minimap zoom.")
    GCKI_gui_player_vehicles.zoom_minimap_camera(event)

  -- Something else from our GUI has been clicked
  else
    GCKI.writeDebug("Nothing to do for %s!", {GCKI.argprint(element)})
  end

  GCKI.entered_function("leave")
end

------------------------------------------------------------------------------------
GCKI.entered_file("leave")
return pv_mapview
