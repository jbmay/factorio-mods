GCKI.entered_file()

------------------------------------------------------------------------------------
------------------------------------------------------------------------------------
--                              Names of GUI elements                             --
------------------------------------------------------------------------------------
------------------------------------------------------------------------------------

local names = {}
names.select_area                       = {}
names.player_vehicles                   = {}
names.player_vehicles_mapview           = {}
names.player_vehicles_camera           = {}


local select_area                       = names.select_area
local p_vehicles                        = names.player_vehicles
local p_vehicles_map                    = names.player_vehicles_mapview
local p_vehicles_camera                 = names.player_vehicles_camera


local select_area_prefix                = GCKI.gui_select_area_prefix
local p_vehicles_prefix                 = GCKI.gui_player_vehicles_prefix
local p_vehicles_map_prefix             = GCKI.gui_player_vehicles_map_prefix
local p_vehicles_camera_prefix          = GCKI.gui_player_vehicles_camera_prefix

local col_prefix


------------------------------------------------------------------------------------
--                    GUI for vehicles in player-selected area                    --
------------------------------------------------------------------------------------
select_area.buttons = {
  -- Close button for main frame
  main_frame_close                      = select_area_prefix.."close_window_button",
}

select_area.frames = {
  -- The master frame that contains the entire GUI
  main                                  = select_area_prefix.."main_frame",
}

select_area.scroll_panes = {
  -- Flow (vertical, scrollable) containing table with vehicle list
  list_container                        = select_area_prefix.."container_vehicle_list",
}

select_area.tables = {
  -- Table containing the vehicle list
  vehicle_list                          = select_area_prefix.."vehicle_list",
}
col_prefix = select_area.tables.vehicle_list.."_"

select_area.table_columns = {
  -- Vehicle list
  --~ icon                                  = select_area_prefix.."vehicle_list_icon_",
  --~ proto_name                            = select_area_prefix.."vehicle_list_prototype_name_",
  --~ id                                    = select_area_prefix.."vehicle_list_id_",
  --~ owner                                 = select_area_prefix.."vehicle_list_owner_",
  --~ locker                                = select_area_prefix.."vehicle_list_locker_",
  --~ toggle_lock                           = select_area_prefix.."vehicle_list_toggle_lock_",
  --~ toggle_owned                          = select_area_prefix.."vehicle_list_toggle_owned_",
  icon                                  = col_prefix.."icon_",
  proto_name                            = col_prefix.."prototype_name_",
  id                                    = col_prefix.."id_",
  owner                                 = col_prefix.."owner_",
  locker                                = col_prefix.."locker_",
  toggle_lock                           = col_prefix.."toggle_lock_",
  toggle_owned                          = col_prefix.."toggle_owned_",
}



------------------------------------------------------------------------------------
--             GUI for vehicles claimed, locked, or named by a player             --
------------------------------------------------------------------------------------
p_vehicles.buttons = {
  -- Toggle button for list of available characters (enable/disable)
  toggle_gui                            = p_vehicles_prefix.."toggle_button",
  -- Close button for main frame
  main_frame_close                      = p_vehicles_prefix.."close_window_button",
  mapview                               = p_vehicles_prefix.."mapview_button",
}

p_vehicles.frames = {
  -- The master frame that contains the entire GUI
  main                                  = p_vehicles_prefix.."main_frame",
}

p_vehicles.scroll_panes = {
  -- Flow (vertical, scrollable) containing table with vehicle list
  list_container                        = p_vehicles_prefix.."container_vehicle_list",
}

p_vehicles.tables = {
  -- Table containing the vehicle list
  vehicle_list                          = p_vehicles_prefix.."vehicle_list",
}
col_prefix = p_vehicles.tables.vehicle_list.."_"

p_vehicles.table_columns = {
  -- Vehicle list
  icon                                  = col_prefix.."icon_",
  proto_name                            = col_prefix.."prototype_name_",
  id                                    = col_prefix.."id_",
  surface                               = col_prefix.."surface_",
  position                              = col_prefix.."position_",
  toggle_owned                          = col_prefix.."toggle_owned_",
  toggle_lock                           = col_prefix.."toggle_lock_",
  map_view                              = col_prefix.."toggle_map_",
  camera                                = col_prefix.."toggle_camera_",
}


------------------------------------------------------------------------------------
--        GUI for vehicles claimed, locked, or named by a player (mapview)        --
------------------------------------------------------------------------------------
p_vehicles_map.buttons = {
  -- Close button for main frame
  main_frame_close                      = p_vehicles_map_prefix.."close_window_button",
}

p_vehicles_map.frames = {
  -- The master frame that contains the entire GUI
  main                                  = p_vehicles_map_prefix.."main_frame",
}

p_vehicles_map.flows = {
  -- The flow that adds a second line to the frame header, showing the  names of
  -- vehicle and surface
  vehicle_name                          = p_vehicles_map_prefix.."vehicle_name",

  -- The flow that contains the camera
  cam_container                         = p_vehicles_map_prefix.."container",
}

p_vehicles_map.maps = {
  -- Mapview
  minimap                               = p_vehicles_map_prefix.."map",
}


------------------------------------------------------------------------------------
--         GUI for vehicles claimed, locked, or named by a player (camera)        --
------------------------------------------------------------------------------------
p_vehicles_camera.buttons = {
  -- Close button for main frame
  main_frame_close                      = p_vehicles_camera_prefix.."close_window_button",
}

p_vehicles_camera.frames = {
  -- The master frame that contains the entire GUI
  main                                  = p_vehicles_camera_prefix.."main_frame",
}

p_vehicles_camera.flows = {
  -- The flow that adds a second line to the frame header, showing the vehicle name
  vehicle_name                          = p_vehicles_camera_prefix.."vehicle_name",

  -- The flow that contains the camera
  cam_container                         = p_vehicles_camera_prefix.."container",
}

p_vehicles_camera.cameras = {
  -- Camera
  camera                                = p_vehicles_camera_prefix.."camera",
}

GCKI.show("Names of GUI elements", names)


------------------------------------------------------------------------------------
GCKI.entered_file("leave")
return names
