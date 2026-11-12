log("Entered file control.lua!")

------------------------------------------------------------------------------------
------------------------------------------------------------------------------------
--                                  REQUIRE FILES                                 --
------------------------------------------------------------------------------------
------------------------------------------------------------------------------------
require("util")

-- Support for "Global variable viewer"
if script.active_mods["gvv"] then
  require("__gvv__.gvv")()
  log("Enabled support for gvv!")
end

mod = storage

AUTODRIVE_NAME = "autodrive"
GCKI_NAME = script.mod_name
local path = "__gcki-continued__."
-- Some common functions used by the other scripts
GCKI                                    = require(path..'common')
GCKI_string                             = GCKI.string_functions


-- Add vehicle entities from other mods to blacklist/whitelist
-- (Must be loaded after common.lua!)
GCKI_prototypes                         = require(path..'.vehicle_lists')

GCKI_ownership = require(path..'scripts.ownership')

-- Event handlers
GCKI_events                             = require(path..'scripts.event_handlers')
-- The car keys (as of 1.1.2: a shortcut) have been used used
GCKI_events.used_key                    = require(path..'scripts.event_key_shortcut')
-- Player driving state changed
GCKI_events.driving                     = require(path..'scripts.event_driving')


-- Event handlers for events triggered by custom inputs
GCKI_custom_input                       = require(path..'scripts.custom_inputs')


-- Functions
GCKI_calc                               = require(path..'libs.math_functions')
GCKI_messages                           = require(path..'scripts.messages')
GCKI_mods                               = require(path..'scripts.compatibility_functions')
GCKI_player                             = require(path..'scripts.player_functions')
GCKI_force                              = require(path..'scripts.force_functions')
GCKI_vehicle                            = require(path..'scripts.vehicle_functions')
GCKI_gui                                = require(path..'scripts.gui')
GCKI_gui_select_area                    = require(path..'scripts.gui_stuff.gui_selected_area')
GCKI_gui_player_vehicles                = require(path..'scripts.gui_stuff.gui_player_vehicles')
GCKI_gui_player_vehicles_map            = require(path..'scripts.gui_stuff.gui_player_vehicles_map')
GCKI_gui_player_vehicles_camera         = require(path..'scripts.gui_stuff.gui_player_vehicles_camera')
GCKI_commands                           = require(path..'scripts.commands')
GCKI_remote                             = require(path..'scripts.remote_functions')
GCKI_cleanup                            = require(path..'scripts.cleanup_lists')




-- Check whether Autodrive is active
AUTODRIVE = remote.interfaces[AUTODRIVE_NAME] and true or false
GCKI.show("AUTODRIVE", AUTODRIVE)

-- Check whether Blueprint Sandboxes is active
BP_SANDBOXES = script.active_mods["blueprint-sandboxes"] and true or false

------------------------------------------------------------------------------------
------------------------------------------------------------------------------------
--                                LOCAL DEFINITIONS                               --
------------------------------------------------------------------------------------
------------------------------------------------------------------------------------


local function registered_msg(event)
  GCKI.writeDebug("Registered event \"%s\".", {event})
end

------------------------------------------------------------------------------------
------------------------------------------------------------------------------------
--                                  EVENT SCRIPTS                                 --
------------------------------------------------------------------------------------
------------------------------------------------------------------------------------

------------------------------------------------------------------------------------
--                                   EVENT LISTS                                  --
------------------------------------------------------------------------------------
GCKI_event_lists = {
  player_events = {
    "on_player_created",
    "on_player_joined_game",
    "on_pre_player_left_game",
    "on_pre_player_removed",
    "on_player_removed",
    "on_player_driving_changed_state",
    "on_player_changed_force",
    "on_gui_opened",
    "on_player_changed_surface",
    "on_player_controller_changed",
    "on_forces_merging",
  },
  filterable_vehicle_events = {
    "script_raised_teleported",
    "script_raised_built",
    "script_raised_revive",
    "on_robot_built_entity",
    "on_built_entity",
    "on_entity_cloned",
    "script_raised_destroy",
    "on_pre_player_mined_item",
    "on_robot_pre_mined",
    "on_entity_died",
  },
  unfilterable_vehicle_events = {
    "on_entity_renamed",
    "on_entity_color_changed",
    "on_object_destroyed",
  },
  tech_events = {
    "on_research_finished",
    "on_research_reversed",
    "on_force_reset",
  },
  gui_events = {
    "on_gui_click",
    "on_gui_confirmed",
    "on_gui_text_changed",
    "on_gui_checked_state_changed",
  },
  shortcut_events = {
    "on_player_selected_area",
    "on_player_alt_selected_area",
    "on_player_reverse_selected_area",
    "on_lua_shortcut"
  },
  custom_events_other_mods = {
    -- Spidertron Weapon Switcher
    script.active_mods["SpidertronWeaponSwitcher"] and
      "on_spidertron_switched" or nil,
    -- Custom Color:
    script.active_mods["CustomColor"] and
      table.unpack({
        "car_saved", "car_removed", "car_paint_player", "car_return_color",
      }) or nil,
  },


}



------------------------------------------------------------------------------------
--                                  CUSTOM INPUTS                                 --
------------------------------------------------------------------------------------
GCKI_custom_input_lists = {
  -- Always active (for custom inputs we may add in the future )
  regular = {},
  -- Enable if a condition is met
  optional = {
    --~ -- Must be enabled if at least one vehicle is on a GUI
    --~ need_state = {
      --~ [GCKI.custominput_name_cancel_path] = "player_cancelled_path",
    --~ },
    -- Must be enabled if at least one vehicle based on a supported prototype exists
    need_vehicle = {
      [GCKI.custominput_spawn_carkey] = "spawn_carkey",
    }
  },
}

-- Add names of regular custom-input events to event list
for e_name, e in pairs(GCKI_custom_input_lists.regular or GCKI.EMPTY_TAB) do
  GCKI.writeDebug("Adding regular custom-input %s to GCKI.event_names!",
                {GCKI.enquote(e_name)})
  GCKI.event_names[e_name] = e_name
end

-- Add names of optional custom-input events to event list
for l, list in pairs(GCKI_custom_input_lists.optional or GCKI.EMPTY_TAB) do
  for e_name, e in pairs(list) do
    GCKI.writeDebug("Adding optional custom-input %s to GCKI.event_names (%s)!",
                  {GCKI.enquote(e_name), l})
    GCKI.event_names[e_name] = e_name
  end
end



------------------------------------------------------------------------------------
--                                     TIMERS                                     --
------------------------------------------------------------------------------------
-- Timers for on_nth_tick
local tick_list = {
  -- Remove invalid vehicles from tables
  GCKI.CLEANUP_VEHICLES_INTERVAL,
  -- Remove invalid vehicles from player data
  GCKI.CLEANUP_PLAYERDATA_INTERVAL,
  -- Remove expired renderings from tables
  GCKI.CLEANUP_RENDERINGS_INTERVAL,
}
script.on_nth_tick(tick_list, function(event)
  event.name = "on_nth_tick"
  GCKI_events.on_nth_tick(event)
end)


------------------------------------------------------------------------------------
--                               GAME INITIALIZATION                              --
------------------------------------------------------------------------------------
-- These events have no data, so we must pass on the event name for debugging mode!
script.on_init(function() GCKI_events.on_init({name = "on_init"}) end)
script.on_load(function() GCKI_events.on_load({name = "on_load"}) end)

-- This event has data, but not event.name, so we must add it for debugging mode!
script.on_configuration_changed(function(event)
  event.name = "on_configuration_changed"
  GCKI_events.on_configuration_changed(event)
end)

local events = defines.events

script.on_event(events.on_runtime_mod_setting_changed,
                GCKI_events.on_runtime_mod_setting_changed)


------------------------------------------------------------------------------------
--                                  PLAYER EVENTS                                 --
------------------------------------------------------------------------------------
for p, player_event in pairs(GCKI_event_lists.player_events) do
  script.on_event(events[player_event], GCKI_events[player_event])
  registered_msg(player_event)
end


------------------------------------------------------------------------------------
--                                 VEHICLE EVENTS                                 --
------------------------------------------------------------------------------------
-- We will add filters to these events once we have the list of vehicle prototypes
-- (either in on_init or in on_load)
for ve, vehicle_event in pairs(GCKI_event_lists.filterable_vehicle_events) do
  script.on_event(events[vehicle_event], GCKI_events[vehicle_event])
  registered_msg(vehicle_event)
end


-- These events can't be filtered!
for ve, vehicle_event in pairs(GCKI_event_lists.unfilterable_vehicle_events) do
  script.on_event(events[vehicle_event], GCKI_events[vehicle_event])
  registered_msg(vehicle_event)
end


------------------------------------------------------------------------------------
--                            TECHNOLOGY-RELATED EVENTS                           --
------------------------------------------------------------------------------------
for te, tech_event in pairs(GCKI_event_lists.tech_events) do
  script.on_event(events[tech_event], GCKI_events[tech_event])
  registered_msg(tech_event)
end


------------------------------------------------------------------------------------
--                        EVENTS TRIGGERED BY CUSTOM INPUT                        --
------------------------------------------------------------------------------------
for event_name, event_handler_name in pairs(GCKI_custom_input_lists.regular) do
  --~ script.on_event(AD. , AD_player.player_cancelled_path)
  script.on_event(event_name, GCKI_custom_input[event_handler_name])
  registered_msg(event_name)
end


------------------------------------------------------------------------------------
------------------------------------------------------------------------------------
--                                  ADD COMMANDS                                  --
------------------------------------------------------------------------------------
------------------------------------------------------------------------------------
do
  -- Create commands to set/toggle settings with Boolean values
  --~ local name, status
  local name
  for s, setting in ipairs({
    "flying_text",
    "show_hints",
    "debug_in_game",
    "teleport_to_other_surface",
    "render_text"
  }) do
    name = "GCKI-"..setting
    GCKI.show("name", name)

    commands.add_command(
      name,
      {"GCKI-commands.command-help", name, {"mod-setting-name."..name}},
      GCKI_commands.create_command(name))
  end


  -- Create commands to unlock/reset all (the player's) vehicles
  local c_name
  for c, command in pairs({
    "unlock",                   -- Unlock all or selected vehicles
    "unlock_player",            -- Unlock all vehicles of a specific player
    "reset",                    -- Reset all or selected vehicles (reset will remove
                                -- owner/locker, custom name, color)
    "reset_player",             -- Reset all vehicles of a specific player
  }) do

    c_name = "GCKI-"..command
    commands.add_command(
      c_name,
      {"GCKI-commands.command-"..command.."-help", c_name},
      GCKI_commands[command]
    )
    GCKI.writeDebug("Added command %s.", {GCKI.enquote("/"..c_name)})
  end
end

------------------------------------------------------------------------------------
------------------------------------------------------------------------------------
--                             ADD REMOTE INTERFACES                              --
------------------------------------------------------------------------------------
------------------------------------------------------------------------------------

-- This has been moved to scripts.remote_functions!



------------------------------------------------------------------------------------
------------------------------------------------------------------------------------
--                    FIND LOCAL VARIABLES THAT ARE USED GLOBALLY                 --
--                              (Thanks to eradicator!)                           --
------------------------------------------------------------------------------------
------------------------------------------------------------------------------------
setmetatable(_ENV, {

  -- luacheck: no unused

  __newindex = function (self, key, value) --locked_global_write
    error('\n\n[ER Global Lock] Forbidden global *write*:\n'..
          serpent.line{key = key or '<nil>', value = value or '<nil>'}..'\n', 2)
    end,
  __index   = function (self, key) --locked_global_read
    if key ~= "game" and key ~= "mods" and key ~= "data" then
      error('\n\n[ER Global Lock] Forbidden global *read*:\n'..
            serpent.line{key = key or '<nil>'}..'\n', 2)
    end
  end,
})


------------------------------------------------------------------------------------
GCKI.entered_file("leave")
