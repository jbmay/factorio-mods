log("Entered file " .. debug.getinfo(1).source)

data:extend({
------------------------------------------------------------------------------------
--                               STARTUP SETTINGS                                 --
------------------------------------------------------------------------------------
  {  -- Write debugging output to log file?
    type = "bool-setting",
    name = "GCKI-debug_in_log",
    setting_type = "startup",
    default_value = false,
    order = "a-a"
  },
  {  -- Use the key-icon from zahnfeechen's mod
    type = "bool-setting",
    name = "GCKI-zahnfeechen_icons",
    setting_type = "startup",
    default_value = false,
    order = "a-b"
  },

------------------------------------------------------------------------------------
--                              GLOBAL RUNTIME SETTINGS                           --
------------------------------------------------------------------------------------
  {   -- Long reach
    type = "bool-setting",
    name = "GCKI-long_reach",
    setting_type = "runtime-global",
    default_value = false,
    order = "a-a"
  },

  {   -- Changing force: claimed/locked vehicles stay with old force or with player?
      type = "bool-setting",
      name = "GCKI-change-force_player-keeps-vehicles",
      setting_type = "runtime-global",
      default_value = true,
      order = "b-a"
  },
  {   -- Changing force: eject occupants from other forces
      type = "bool-setting",
      name = "GCKI-change-force_eject",
      setting_type = "runtime-global",
      default_value = true,
      order = "b-b"
  },

  {   -- Forget/unlock all force vehicles on force reset?
      type = "bool-setting",
      name = "GCKI-lose-vehicles-on-force-reset",
      setting_type = "runtime-global",
      default_value = true,
      order = "b-b"
  },

  {   -- Forget/unlock all force vehicles when last unlock tech is unresearched?
      type = "bool-setting",
      name = "GCKI-lose-vehicles-on-research-reverted",
      setting_type = "runtime-global",
      default_value = true,
      order = "b-b"
  },


------------------------------------------------------------------------------------
--                             PER-USER RUNTIME SETTINGS                          --
------------------------------------------------------------------------------------
  {   -- Show debugging output in game?
    type = "bool-setting",
    name = "GCKI-debug_in_game",
    setting_type = "runtime-per-user",
    default_value = false,
    order = "a-a"
  },
  {   -- Show messages as flying text?
    type = "bool-setting",
    name = "GCKI-flying_text",
    setting_type = "runtime-per-user",
    default_value = false,
    order = "a-b"
  },
  {   -- Show optional hints in game?
    type = "bool-setting",
    name = "GCKI-show_hints",
    setting_type = "runtime-per-user",
    default_value = true,
    order = "a-c"
  },

  {   -- Teleport to other surfaces?
    type = "bool-setting",
    name = "GCKI-teleport_to_other_surface",
    setting_type = "runtime-per-user",
    default_value = true,
    order = "b-a"
  },

  {   -- Show GUI when owned vehicle is lost but player still has locked vehicles?
    type = "bool-setting",
    name = "GCKI-guiclaim_locked_vehicle",
    setting_type = "runtime-per-user",
    default_value = false,
    order = "c-a"
  },
  {   -- Automatically claim locked vehicle if player loses claimed vehicle and the
      -- player has only one locked vehicle left?
    type = "bool-setting",
    name = "GCKI-autoclaim_locked_vehicle",
    setting_type = "runtime-per-user",
    default_value = false,
    order = "c-b"
  },

  {   -- Render text on ground where a claimed vehicle has been removed/destroyed?
    type = "bool-setting",
    name = "GCKI-render_text",
    setting_type = "runtime-per-user",
    default_value = true,
    order = "d-a"
  },
  {   -- Time the rendering will be visible
    type = "int-setting",
    name = "GCKI-render_time",
    setting_type = "runtime-per-user",
    default_value =  5 * 60,                -- 5 minutes
    minimum_value =  1 *  1,                -- 1 second
    maximum_value = 60 * 60,                -- 1 hour
    order = "d-b"
  },
  --~ {   -- Render color
    --~ type = "string-setting",
    --~ name = "GCKI-render_color",
    --~ setting_type = "runtime-per-user",
    --~ default_value =  "default",
    --~ allowed_values = {
     --~ "default",
     --~ "acid",
     --~ "black",
     --~ "blue",
     --~ "brown",
     --~ "cyan",
     --~ "gray",
     --~ "green",
     --~ "orange",
     --~ "pink",
     --~ "purple",
     --~ "red",
     --~ "white",
     --~ "yellow",
    --~ },
    --~ order = "d-c"
  --~ }
  {   -- Render color
    type = "color-setting",
    name = "GCKI-render_color",
    setting_type = "runtime-per-user",
    default_value =  {r = 1.000, g = 0.630, b = 0.259, a = 1},
    --~ allowed_values = {
     --~ "default",
     --~ "acid",
     --~ "black",
     --~ "blue",
     --~ "brown",
     --~ "cyan",
     --~ "gray",
     --~ "green",
     --~ "orange",
     --~ "pink",
     --~ "purple",
     --~ "red",
     --~ "white",
     --~ "yellow",
    --~ },
    order = "d-c"
  },

  {   -- Use orientation of vehicle or player when placing summoned vehicles?
    type = "string-setting",
    name = "GCKI-select_orientation_from",
    setting_type = "runtime-per-user",
    default_value =  "vehicle",
    allowed_values = {
     "player",
     "vehicle",
    },
    order = "e-a"
  }

})


------------------------------------------------------------------------------------
log("Leaving file " .. debug.getinfo(1).source)
