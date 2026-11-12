--~ GCKI.entered_file()

--~ ------------------------------------------------------------------------------------
--~ -- Reset technologies so that vehicle keys are available if mod is loaded into an
--~ -- existing game where the unlock technologies have already been researched.
--~ ------------------------------------------------------------------------------------


--~ local technologies = {
  --~ -- Vanilla
  --~ "automobilism",
  --~ -- Cargo Ships
  --~ "water_transport",
--~ }

--~ for _, force in pairs(game.forces) do
  --~ for _, tech in ipairs(technologies) do
    --~ if force.technologies[tech] ~= nil and force.technologies[tech].researched then
      --~ force.technologies[tech].researched = false
      --~ force.technologies[tech].researched = true
      --~ GCKI.writeDebug("Reset technology \"%s\" for force \"%s\"!", {tech, force.name})
    --~ end
  --~ end
--~ end


--~ ------------------------------------------------------------------------------------
--~ GCKI.entered_file("leave")
