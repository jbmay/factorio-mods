GCKI.entered_file()

------------------------------------------------------------------------------------
------------------------------------------------------------------------------------
-- We already have set type filters for the selection tool. All mods should have  --
-- created their prototype, so we can add name filters for all the prototypes we  --
-- care about!                                                                    --
------------------------------------------------------------------------------------
------------------------------------------------------------------------------------


------------------------------------------------------------------------------------
--                             ADD NAMES TO FILTERLIST                            --
------------------------------------------------------------------------------------
-- Get list of all "car"/"spider-vehicle" prototypes we care about
local name_filters = {}
local vehicles = GCKI.vehicle_prototypes_map
GCKI.show("vehicles", vehicles)

for proto_type, proto_names in pairs(vehicles) do
  for proto_name, p in pairs(proto_names) do
    table.insert(name_filters, proto_name)
  end
end
GCKI.show("name_filters", name_filters)

------------------------------------------------------------------------------------
--                       APPLY NAMEFILTERS TO SELECTION-TOOL                      --
------------------------------------------------------------------------------------
local keys = data.raw["selection-tool"][GCKI.carkey_name]

local m_name
for m, mode in pairs({"", "alt_", "reverse_", "super_forced_"}) do
  m_name = mode.."select"
GCKI.show("m_name", m_name)

  if keys[m_name] then
    keys[m_name].entity_filters = name_filters
    GCKI.modified_msg(m_name..".entity_filters", keys)
  end
end
GCKI.show("keys", keys)


------------------------------------------------------------------------------------
GCKI.entered_file("leave")
