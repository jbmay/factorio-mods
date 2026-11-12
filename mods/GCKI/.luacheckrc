return {
  globals = {
    -- Math functions
    "abs", "ceil", "floor", "max", "min", "random", "sqrt",

    -- Factorio
    "mods", "settings", "data", "game", "script",
    "defines", "log", "math", "pairs", "remote", "rendering",
    "serpent", "string", "table", "table_size", "next",  "type", "util",
    "commands", "mod_gui",
    --~ "global",         -- Used in Factorio <=1.1.110
    "storage",        -- Used to be 'global' in Factorio <= 1.1.110
    "prototypes", "helpers",

    -- GCKI
    "GCKI", "GCKI_NAME", "AUTODRIVE", "AUTODRIVE_NAME",
    "GCKI_prototypes", "GCKI_events", "GCKI_event_lists", "GCKI_custom_input",
    "GCKI_calc", "GCKI_string", "GCKI_messages", "GCKI_mods", "GCKI_player", "GCKI_force",
    "GCKI_vehicle", "GCKI_gui", "GCKI_gui_select_area", "GCKI_gui_player_vehicles",
    "GCKI_gui_player_vehicles_map", "GCKI_gui_player_vehicles_camera",
    "GCKI_commands", "GCKI_remote", "GCKI_cleanup", "GCKI_custom_input_lists",
    "GCKI_lib", "GCKI_gui_names",

    "common", "mod",

    -- Data stage
    -- ~ "autodrive_global", "AD_lib",
    --~ "AUTODRIVE_ICONPATH", "AUTODRIVE_EQUIPMENT_CATEGORY",
    --~ "AUTODRIVE_CREATES_SUBGROUP", "AUTODRIVE_SUBGROUP", "AUTODRIVE_TECHS",
    --~  "AUTODRIVE_SENSOR_CNT", "AUTODRIVE_SENSORS", "AUTODRIVE_SENSOR_GROUPS",





    -- GCKI constants
    "GCKI_event_lists",


    -- Other mods
    "AUTODRIVE", "NULLIUS", "BP_SANDBOXES",
  },

  ignore = {
    "213",  -- Unused loop variable
  },
  cache = true,
}
