GCKI.entered_file()

-- Custom inputs raise events identified by input_name (a string) instead of name (a
-- number)! They are triggered before the regular events (where on_tick will be
-- triggered first because its name is '0').



------------------------------------------------------------------------------------
------------------------------------------------------------------------------------
--                                LOCAL DEFINITIONS                               --
------------------------------------------------------------------------------------
------------------------------------------------------------------------------------

local custom_inputs = {}
custom_inputs.helper = {}

local helper = custom_inputs.helper



------------------------------------------------------------------------------------
------------------------------------------------------------------------------------
--                        MANAGE HANDLERS FOR CUSTOM-INPUTS                       --
------------------------------------------------------------------------------------
------------------------------------------------------------------------------------

------------------------------------------------------------------------------------
-- Register handlers for optional custom inputs
helper.register_optional_custom_input_events = function()
  GCKI.entered_function()

  local event_list = mod.enable_optional_custom_inputs or GCKI.EMPTY_TAB
  for event_name, event_handler_name in pairs(event_list) do
    GCKI.writeDebug("Registering handler for custom-input event %s!",
                  {GCKI.enquote(event_name)})
    script.on_event(event_name, custom_inputs[event_handler_name])
  end

  GCKI.entered_function("leave")
end



------------------------------------------------------------------------------------
-- Enable handlers for multiple optional custom inputs
helper.enable_optional_custom_inputs = function(event_or_list)
  GCKI.entered_function({event_or_list})

  local event_list

  -- We've already got a list of event names and handlers
  if type(event_or_list) == "table" then
    event_list = event_or_list
  -- We've got the name of a single event, look for that name in all event lists to
  -- get the name of the event handler!
  else
    for list_name, list in pairs(GCKI_custom_input_lists.optional or GCKI.EMPTY_TAB) do
GCKI.show(list_name, list)
      for e_name, e_handler_name in pairs(list) do
GCKI.show(e_name, e_handler_name)
        if e_name == event_or_list then
          GCKI.writeDebug("Found handler for event of custom input %s!",
                        {GCKI.enquote(e_name)})
          event_list = { [e_name] = e_handler_name }
          break
        end
      end
    end
  end
GCKI.show("event_list", event_list)

  mod.enable_optional_custom_inputs = mod.enable_optional_custom_inputs or {}
  for e_name, e_handler_name in pairs(event_list or GCKI.EMPTY_TAB) do
    script.on_event(e_name, custom_inputs[e_handler_name])

    mod.enable_optional_custom_inputs[e_name] = e_handler_name
    GCKI.writeDebug("Enabled event %s.", {e_name})
  end

  GCKI.entered_function("leave")
end



------------------------------------------------------------------------------------
-- Disable handlers for optional custom inputs
-- event_list: {ID1, ID2, …}
helper.disable_optional_custom_inputs = function(event_or_list)
  GCKI.entered_function({event_or_list})

  GCKI.assert(event_or_list, {"table", "string"}, "custom input or list of custom inputs")

  local event_list

  -- We've got a list of event_names and handlers!
  if type(event_or_list) == "table" then
    event_list = event_or_list
  -- When disabling events, we don't need the handler name, so we don't need to look
  -- for it in the lists below GCKI_custom_input_lists.optional but set it to 'true'!
  else
    event_list = { [event_or_list] = true }
  end

  --~ for e_name, e in pairs(event_list) do
    --~ script.on_event(e_name, nil)
    --~ global.enable_optional_custom_inputs[e_name] = nil
    --~ GCKI.writeDebug("Disabled handler for event \"%s\"", {e_name})
  --~ end
  for e_name, e in pairs(event_list) do
    script.on_event(e_name, nil)
    if mod.enable_optional_custom_inputs then
      mod.enable_optional_custom_inputs[e_name] = nil
    end
    GCKI.writeDebug("Disabled handler for event \"%s\"", {e_name})
  end
  if not next(mod.enable_optional_custom_inputs or GCKI.EMPTY_TAB) then
    GCKI.writeDebug("Removing mod.enable_optional_custom_inputs!")
    mod.enable_optional_custom_inputs = nil
  end

  GCKI.entered_function("leave")
end



------------------------------------------------------------------------------------
-- Check whether we must enable optional events
helper.check_optional_events = function()
  GCKI.entered_function()

GCKI.show("mod.enable_optional_custom_inputs", mod.enable_optional_custom_inputs)

  local have_vehicles = mod.vehicles_orig_color and
                          next(mod.vehicles_orig_color) and true
GCKI.show("have_vehicles", have_vehicles)

  local optional_inputs = GCKI_custom_input_lists.optional


  GCKI.writeDebugNewBlock("Enable handlers for custom inputs that need any vehicle?")
  if have_vehicles then
    GCKI.writeDebug("Yes!")
    helper.enable_optional_custom_inputs(optional_inputs.need_vehicle)
  else
    GCKI.writeDebug("No!")
    helper.disable_optional_custom_inputs(optional_inputs.need_vehicle)
  end

  GCKI.entered_function("leave")
end



------------------------------------------------------------------------------------
------------------------------------------------------------------------------------
--                                 EVENT HANDLERS                                 --
------------------------------------------------------------------------------------
------------------------------------------------------------------------------------

-- Check whether driver of a vehicle we control cancelled its path!
custom_inputs.spawn_carkey = function(event)
  GCKI.entered_event(event)
  local player = GCKI.ascertain_player(event.player_index)
  local f_data = player and player.valid and mod.force_data[player.force.name]
GCKI.show("f_data", f_data)

  if not (f_data and f_data.show_shortcuts) then
    GCKI.entered_event(event, "leave", "force doesn't have shortcuts enabled")
    return
  end

  local cursor_stack = player.cursor_stack

  -- Cursor stack is not empty
  GCKI.writeDebugNewBlock("Remove items from cursor stack?")
  if cursor_stack.valid_for_read and cursor_stack.name ~= GCKI.carkey_name then
    GCKI.writeDebug("Yes: must get rid of %s!", {GCKI.argprint(cursor_stack)})
    player.clear_cursor()

  -- Nothing to do: cursor stack is empty
  else
    GCKI.writeDebug("No: already empty!")
  end

  -- Insert car keys into cursor stack
  GCKI.writeDebugNewBlock("Handing keys to player!")
  cursor_stack.set_stack({name = GCKI.carkey_name, count = 1})

  GCKI.entered_event(event, "leave")
end


------------------------------------------------------------------------------------
GCKI.entered_file("leave")
return custom_inputs
