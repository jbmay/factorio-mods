-- This file contains everything the mini GUI we need for the camera view (just a
-- frame with header + close button and the camera inside).
------------------------------------------------------------------------------------
GCKI.entered_file()

local pv_camera = {}

------------------------------------------------------------------------------------
------------------------------------------------------------------------------------
--                              Names of GUI elements                             --
------------------------------------------------------------------------------------
------------------------------------------------------------------------------------
local gui_names = GCKI_gui_names.player_vehicles_camera



------------------------------------------------------------------------------------
------------------------------------------------------------------------------------
--                                Local definitions                                --
------------------------------------------------------------------------------------
------------------------------------------------------------------------------------

local function create_gui(player)
  GCKI.entered_function({player})

  player = GCKI.ascertain_player(player)
  if not (player and player.valid) then
    GCKI.arg_err(player, "player specification")
  end

  --~ local gui, element, e_name

  -- Construct the main frame that will contain the entire GUI
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
GCKI.show("gui", GCKI.argprint(gui))

  -- Header: flow for GUI title and closing button
  local header = gui["header"]
  if not (header and header.valid) then
    header = GCKI_gui.make_flow({
      parent = gui,
      name = "header",
      caption = {"GCKI-GUI.gui-title", {"mod-name.GCKI"}, ""},
      direction = "horizontal",
      vertically_stretchable = true,
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
--                                 Add the camera                                 --
------------------------------------------------------------------------------------
local function get_camera(player)
  GCKI.entered_function({player})

  local container = get_content_flow(player)
  local cam_name = gui_names.cameras.camera
GCKI.show("container", GCKI.argprint(container))

  local camera = container[cam_name]
  if not (camera and camera.valid) then
    camera = container.add({
      type = "camera",
      name = cam_name,
      visible = true,
      chart_player_index = player.index,
      position = player.position,
      surface_index = player.surface.index,
      zoom = GCKI.ZOOM_DEFAULT,
      tooltip = {"GCKI-GUI-tooltips.minimap-or-camera", GCKI.ZOOM_DEFAULT},
    })
    GCKI.created_msg(camera)

    local style = camera.style
    local scale = 1.5
    style.minimal_width = 256 * scale
    style.minimal_height = 256 * scale
    style.maximal_width = style.minimal_width * 2
    style.maximal_height = style.minimal_height * 2
    style.natural_width = style.minimal_width
    style.natural_height = style.minimal_height
    GCKI.modified_msg("style", camera, "Adjusted")
  end

  GCKI.entered_function("leave")
  return camera
end


------------------------------------------------------------------------------------
------------------------------------------------------------------------------------
--                                Shared functions                                --
------------------------------------------------------------------------------------
------------------------------------------------------------------------------------


------------------------------------------------------------------------------------
--                           Initialize GUI for camera                           --
-- player: player index, name or entity                                           --
------------------------------------------------------------------------------------
--~ pv_camera.init_gui = function(player)
  --~ GCKI.entered_function({player})
pv_camera.init_gui = function(player, flags)
  GCKI.entered_function({player, flags})

  -- Make sure we have a valid player
  player = GCKI.ascertain_player(player)
  if not (player and player.valid) then
    GCKI.arg_err(player, "player specification")
  end
  GCKI.show("player", player.name)

  local p_data = mod.player_data[player.index]
  GCKI.show("p_data", p_data)

  local show_on_camera = p_data and p_data.show_on_camera or false

  -- Read flags
  GCKI.assert(flags, {"table", "nil"}, "nil or table or flags")
  --~ local skip_event_check = flags and flags.skip_event_check

  -- The GUI frames/flows will be built the first time this function is called for
  -- a player.
  local gui = get_gui(player)

  -- Update GUI?
  if show_on_camera then
    GCKI.writeDebug("Updating map GUI!")
    pv_camera.update_gui(player)
  end

  -- Hide existing GUI if player didn't activate camera for a vehicle
  GCKI.writeDebug("Must %s camera!", {show_on_camera and "show" or "hide"})
  gui.visible = show_on_camera and true or false

  GCKI.entered_function("leave")
end



------------------------------------------------------------------------------------
--                                   Update GUI                                   --
-- This updates the information shown in the GUI header (surface and custom name) --
------------------------------------------------------------------------------------
pv_camera.update_gui = function(player, flags)
  GCKI.entered_function({player})

  -- Make sure we have a valid player
  player = GCKI.ascertain_player(player)
  if not (player and player.valid) then
    GCKI.arg_err(player, "player specification")
  end
GCKI.show("player", player.name)

  GCKI.assert(flags, {"table", "nil"}, "nil or table of flags")
  local skip_event_check = flags and flags.skip_event_check

  local p_data = mod.player_data[player.index]
  local v_data = p_data.show_on_camera

  local gui = get_gui(player)

  -- Player must have a GUI!
  if gui and gui.valid then
    local vehicle

    -- Close GUI if we have no data
    if not v_data then
      GCKI.writeDebug("Must close GUI because player doesn't have camera data!")
      pv_camera.close_gui(player, {skip_event_check = skip_event_check})

    -- We have data
    elseif v_data.entity and v_data.entity.valid then
      vehicle = v_data.entity
GCKI.show("vehicle", GCKI.argprint(vehicle))


      -- Close GUI if force of vehicle or player has been changed
      if vehicle.force ~= player.force then
GCKI.show("player.force", player.force)
GCKI.show("vehicle.force", vehicle.force)
        GCKI.writeDebug("Must close GUI because player force and vehicle force are different!")
        pv_camera.close_gui(player)

      -- Update camera
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
          {"GCKI-GUI.gui-title-player-vehicles-camera", v_surface.name},
        }
        inner_header.title.caption = v_name

        -- Update camera view
        local camera = get_camera(player)
        camera.surface_index = v_surface.index
        camera.entity = vehicle
        camera.position = v_data.position
        GCKI.writeDebug("Updated GUI")

      end
    end
  end

  GCKI.entered_function("leave")
end


------------------------------------------------------------------------------------
--                                  Update camera                                 --
-- We can enter this function because the player has changed a GUI element, but   --
-- also because on_entity_died has been triggered for the vehicle. If the GUI has --
-- been changed, the camera should follow the vehicle entity, and we must get the --
-- entity from the GUI element. If the vehicle is about to die, we want to focus  --
-- the camera on the last vehicle position instead, so players can see the death  --
-- message rendered on the ground.                                                --
------------------------------------------------------------------------------------
pv_camera.update_camera = function(event_data)
  GCKI.entered_function({event_data})

  GCKI.assert(event_data, "table")

  -- Make sure we have a valid player
  --~ local player = game.players[event_data.player_index]
  local player = GCKI.ascertain_player(event_data.player_index)
  if not (player and player.valid) then
    GCKI.arg_err(player, "player specification")
  end
  GCKI.show("player", player.name)

  local gui = get_gui(player)
  local p_data = mod.player_data[player.index]

  -- GUI has been used: Derive info from the element
  local element = event_data.element
  -- Entity is about to die: Derive info from the vehicle
  local vehicle = event_data.vehicle

GCKI.show("gui", GCKI.argprint(gui))
GCKI.show("element", GCKI.argprint(element))
GCKI.show("vehicle", GCKI.argprint(vehicle))

  local show_camera, entity, position, surface, v_name

  -- Player used GUI to show camera
  if element then
    local v_id  = tonumber(element.name:match("^.+_([0-9]+)"))
    show_camera = element.state
    entity      = v_id and p_data.locked_or_owned and p_data.locked_or_owned[v_id]
    surface     = entity and entity.valid and entity.surface
    v_name      = GCKI.loc_name(entity)

  -- Vehicle is about to die
  elseif vehicle then
    show_camera = true
    position    = vehicle.position
    surface     = vehicle.valid and vehicle.surface
    v_name      = GCKI.loc_name(vehicle)

  -- Something went wrong!
  else
    GCKI.arg_err(event_data, "GUI element or vehicle specification")
  end

  --~ surface = GCKI.ascertain_surface(surface) or
            --~ GCKI.ascertain_surface(p_data.show_on_camera and p_data.show_on_camera.surface_index) or
            --~ GCKI.arg_err(surface, "surface specification")

  -- Camera has been turned on for the vehicle
  if show_camera then
GCKI.writeDebug("Must show camera!")

    -- Update player data
    p_data.show_on_camera = {
      entity          = entity or vehicle,
      id              = (entity and entity.unit_number) or
                        (vehicle and vehicle.unit_number),
      name            = v_name,
      position        = position or entity.position,
      surface_index   = surface.index,
    }

    local camera = get_camera(player)
GCKI.show("camera", GCKI.argprint(camera))

    --~ p_data.show_on_camera = p_data.show_on_camera or {}

    -- Update camera
    camera.surface_index = surface.index
    if entity then
      camera.entity = entity
    else
      camera.position = position
    end
    GCKI.writeDebug("Updated camera")

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
      {"GCKI-GUI.gui-title-player-vehicles-camera", surface.name},
    }
    inner_header.title.caption = v_name
    GCKI.writeDebug("Updated GUI")

  -- Camera has been turned off
  else
GCKI.writeDebug("Must hide camera!")
    pv_camera.close_gui(player)
  end

  -- Show or hide the GUI?
  if gui and gui.valid and gui.visible ~= show_camera then
    gui.visible = show_camera
    GCKI.writeDebug("Turned camera %s!", {show_camera and "on" or "off"})
  end

  GCKI.entered_function("leave")
end


------------------------------------------------------------------------------------
--                          Close GUI for player's camera                         --
------------------------------------------------------------------------------------
pv_camera.close_gui = function(player, flags)
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

  --~ local gui = player.gui.screen[gui_names.frames.main]
  local gui = get_gui(player)
GCKI.show("Player's camera", GCKI.argprint(gui))

  -- Hide GUI
  if gui and gui.valid and gui.visible then
    gui.visible = false
    GCKI.writeDebug("Closed the list of vehicles selected by %s.", {GCKI.argprint(player)})
  end

  -- Clean up!
  if p_data.show_on_camera then
    -- Remove from global table
    local v_id = p_data.show_on_camera.id
    p_data.show_on_camera = nil
    GCKI.writeDebug("Removed mod.player_data[%s].show_on_camera!", {player.index})

    -- Uncheck camera button in GUI of players' locked vehicles
    if p_data.locked_or_owned and p_data.locked_or_owned[v_id] then
      GCKI.writeDebug("Must uncheck camera button!")
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


--~ ------------------------------------------------------------------------------------
--~ --     Remove our GUI from all players on a force, or all players in the game     --
--~ ------------------------------------------------------------------------------------
--~ pv_camera.remove_guis = function(force)
  --~ GCKI.entered_function({force})

  --~ local gui_name = gui_names.frames.main
  --~ GCKI_gui.remove_guis(force, gui_name, "show_on_camera")

  --~ GCKI.entered_function("leave")
--~ end


------------------------------------------------------------------------------------
--      Hide our GUI from all players on a force, or all players in the game      --
------------------------------------------------------------------------------------
pv_camera.hide_guis = function(force, flags)
  GCKI.entered_function({force})

  force = GCKI.ascertain_force(force, flags)
  if not (force and force.valid) then
    GCKI.arg_err(force, "force specification")
  end

  local gui_name = gui_names.frames.main
  GCKI_gui.hide_guis(force, gui_name, flags)


  GCKI.entered_function("leave")
end


------------------------------------------------------------------------------------
--              Swap vehicles on GUI if some mod exchanged a vehicle              --
-- player: player index, name or entity                                           --
-- old_id, new_id: unit_number                                                    --
------------------------------------------------------------------------------------
pv_camera.swap_vehicle_on_gui = function(player, old_id, new_vehicle)
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
  if not p_data.show_on_camera then
    GCKI.entered_function({}, "leave", "No camera for player!")
    return
  end

  --~ local gui = player.gui.screen[gui_names.frames.main]
  --~ local gui = get_gui(player)
  --~ if not (gui and gui.valid) then
    --~ GCKI.entered_function({}, "leave", GCKI.argprint(player).."has no GUI for the camera!")
    --~ return
  --~ end

  ------------------------------------------------------------------------------------
  --                             Swap vehicles on camera                            --
  ------------------------------------------------------------------------------------
  --~ local camera = gui[gui_names.cameras.camera]
  local camera = get_camera(player)
  camera.entity = new_vehicle
  camera.position = new_vehicle.position

  local inner_header = get_inner_header(player)
  --~ gui.header.caption = GCKI.loc_name(vehicle)
  inner_header.title.caption = GCKI.loc_name(new_vehicle)

  ------------------------------------------------------------------------------------
  --                      Swap entry for vehicle in player data                     --
  ------------------------------------------------------------------------------------
  -- As the old vehicle will be destroyed, it's entry will automagically disappear!
  p_data.show_on_camera.entity = new_vehicle
  p_data.show_on_camera.id = new_vehicle.unit_number
  p_data.show_on_camera.name = GCKI.loc_name(new_vehicle)
  p_data.show_on_camera.position = new_vehicle.position
  p_data.show_on_camera.surface_index = new_vehicle.surface.index
  GCKI.show("p_data.show_on_camera", p_data.show_on_camera)

  GCKI.entered_function("leave")
end


------------------------------------------------------------------------------------
--                              GUI-ACTION DETECTED!                              --
------------------------------------------------------------------------------------

-- Button was clicked
pv_camera.on_gui_click = function(event)
  GCKI.entered_function({event})

  local element = event.element

  if not GCKI.prefixed(element.name, GCKI.gui_player_vehicles_camera_prefix) then
    GCKI.entered_function({}, "leave", "Nothing to do for \""..GCKI.argprint(element).."\"!")
    return
  end

  --~ local player = game.players[event.player_index]
  local player = GCKI.ascertain_player(event.player_index)
  --~ local p_data = player and global.player_data and global.player_data[player.index]
  --~ local gui = player.gui.screen[gui_names.frames.main]


  ------------------------------------------------------------------------------------
  -- Close button of camera GUI
  if element.name == gui_names.buttons.main_frame_close then
    GCKI.writeDebug("Must close the camera of %s.", {GCKI.argprint(player)})
    pv_camera.close_gui(player)

  -- Camera has been clicked: change zoom
  elseif element.name == gui_names.cameras.camera then
    GCKI.writeDebug("Must change camera zoom.")
    GCKI_gui_player_vehicles.zoom_minimap_camera(event)

  -- Something else from our GUI has been clicked
  else
    GCKI.writeDebug("Nothing to do for %s!", {GCKI.argprint(element)})
  end

  GCKI.entered_function("leave")
end

------------------------------------------------------------------------------------
GCKI.entered_file("leave")
return pv_camera
