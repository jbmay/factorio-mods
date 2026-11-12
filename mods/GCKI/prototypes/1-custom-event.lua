GCKI.entered_file()
------------------------------------------------------------------------------------
-- Create custom events
local event
for e, e_name in pairs(GCKI.custom_events) do
  event = {
    type = "custom-event",
    name = e_name,
  }
  data:extend({event})
  GCKI.created_msg(event)
end


------------------------------------------------------------------------------------
GCKI.entered_file("leave")
