GCKI.entered_file()

------------------------------------------------------------------------------------
------------------------------------------------------------------------------------
-- Now that other mods have had their chance to hide techs, we can set the unlock --
-- technology for our shortcut!
------------------------------------------------------------------------------------
------------------------------------------------------------------------------------

local shortcut = data.raw.shortcut[GCKI.shortcut_name]
local techs = data.raw.technology
local tech

for tech_name, t in pairs(GCKI.unlock_tech_map) do
  tech = techs[tech_name]
  -- We won't break after the first valid tech, if there are more techs in the
  -- list, the last one will win!
  if tech and not tech.hidden then
    GCKI.writeDebug("Setting %s as technology_to_unlock!", {tech_name})
    shortcut.technology_to_unlock = tech_name
  end
end


------------------------------------------------------------------------------------
GCKI.entered_file("leave")
