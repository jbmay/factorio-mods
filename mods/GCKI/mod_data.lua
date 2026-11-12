-- Settings for calling Pi-C_lib
return {
  mod_name = "gcki-continued",
  mod_shortname = "GCKI",
  debug_log_setting = "GCKI-debug_in_log",
  debug_log_setting_type = "startup",
  debug_game_setting = "GCKI-debug_in_game",
  debug_game_setting_type = "runtime-per-user",
  -- We only want to include this in the control stage, so 'include' is added to the
  -- mod arguments in common.lua!
  --~ include = "string_functions"
}
