------------------------------------------------------------------------------------
------------------------------------------------------------------------------------
--                        Updating settings from other mods                       --
------------------------------------------------------------------------------------
------------------------------------------------------------------------------------

local mod_name, setting_name

------------------------------------------------------------------------------------
--                            SpidertronWeaponSwitcher                            --
------------------------------------------------------------------------------------
mod_name = "SpidertronWeaponSwitcher"
if mods[mod_name] then

  -- Force this setting to be on, or no items will be created for the new vehicle
  -- prototypes, making it impossible to find the item that places the entity.
  setting_name = "sws-show-alternate-items"
  local setting = data.raw["bool-setting"][setting_name]

  if setting then
    setting.hidden = true
    setting.allowed_values = {true}
    setting.forced_value = true
    setting.default_value = true
    log(string.format("Changed setting %s of mod %s: %s",
                      setting_name, mod_name, serpent.block(setting)))
  end
end
