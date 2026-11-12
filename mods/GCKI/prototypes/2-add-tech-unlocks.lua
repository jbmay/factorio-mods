GCKI.entered_file()

------------------------------------------------------------------------------------
--          Add unlock for the key shortcut to all eligible technologies          --
------------------------------------------------------------------------------------
local icon = GCKI.car_key_icon

-- Unlock the Car Key
local tech
local techs = data.raw.technology
local unlock = {
  type = "nothing",
  icon = icon,
  icon_size = 64,
  --~ icon_mipmaps = 1,
  effect_description = {"techeffect-description.technology-effect"},
}

GCKI.writeDebug("Adding unlocks for car-keys!")
for tech_name, t in pairs(GCKI.unlock_tech_map) do
  tech = techs[tech_name]
GCKI.show(tech_name, tech)
  if tech then
    tech.effects = tech.effects or {}
    table.insert(tech.effects, unlock)
    GCKI.writeDebug("Added unlock for car-keys to %s" , {GCKI.argprint(tech)})
  end
end




------------------------------------------------------------------------------------
GCKI.entered_file("leave")
