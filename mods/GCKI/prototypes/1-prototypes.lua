GCKI.entered_file()

local icon = GCKI.car_key_icon
local protos = {}

------------------------------------------------------------------------------------
--            Keys (Prototype/ItemWithLabel-->Prototype/SelectionTool)            --
------------------------------------------------------------------------------------
--~ local type_filters = {"car", "spider-vehicle"}
local box_type = "entity"
local sel_mode = {"entity-with-owner", "same-force", "avoid-rolling-stock"}
local filter_mode = "whitelist"

protos.tool = {
  type                                  = "selection-tool",
  name                                  = GCKI.carkey_name,
  icon                                  = icon,
  icon_size                             = 64,
  --~ icon_mipmaps                          = 1,
  order                                 = "b[personal-transport]-z[car-key]",
  --~ flags                                 = {"only-in-cursor", "hidden", "spawnable", "not-stackable"},
  flags                                 = {"only-in-cursor", "spawnable", "not-stackable"},
  stack_size                            = 1,

  --~ entity_filter_mode                    = filter_mode,
  --~ -- entity_type_filters                   = type_filters,
  --~ selection_mode                        = sel_mode,
  --~ selection_color                       = {g = 1},
  --~ selection_cursor_box_type             = box_type,

  --~ alt_entity_filter_mode                = filter_mode,
  --~ -- alt_entity_type_filters               = type_filters,
  --~ alt_selection_mode                    = sel_mode,
  --~ alt_selection_color                   = {b = 1},
  --~ alt_selection_cursor_box_type         = box_type,

  --~ reverse_entity_filter_mode            = filter_mode,
  --~ -- reverse_entity_type_filters           = type_filters,
  --~ reverse_selection_mode                = sel_mode,
  --~ reverse_selection_color               = {r = 1},
  --~ reverse_selection_cursor_box_type     = box_type,
}
protos.tool.select = {
  entity_filter_mode = filter_mode,
  mode = sel_mode,
  --~ border_color = {r = 0.3, g = 0.9, b = 0.3},
  border_color = {g = 1},
  cursor_box_type = box_type,
}
protos.tool.alt_select = {
  entity_filter_mode = filter_mode,
  mode = sel_mode,
  border_color = {b = 1},
  cursor_box_type = box_type,
}
protos.tool.reverse_select = {
  entity_filter_mode = filter_mode,
  mode = sel_mode,
  border_color = {r = 1},
  cursor_box_type = box_type,
}
protos.tool.super_forced_select = table.deepcopy(protos.tool.select)


------------------------------------------------------------------------------------
--                            Keys (Prototype/Shortcut)                           --
------------------------------------------------------------------------------------
-- The action must be "lua" because we want to enable the shortcut depending on the
-- current state of our unlock tech. We can't use technology_to_unlock because that
-- will unlock the shortcut forever (in all save files) if the tech has been enabled
-- once!
protos.shortcut = {
  type                  = "shortcut",
  name                  = GCKI.shortcut_name,
  localised_name        = {"shortcut-name.GCKI_car-key-shortcut"},
  localised_description = {"shortcut-description.GCKI_car-key-shortcut"},
  action                = "lua",
  --~ icon = {
    --~ filename            = icon,
    --~ size                = 64,
    --~ mipmap_count        = 1,
  --~ },
  icon                  = icon,
  small_icon            = icon,
  associated_control_input = GCKI.custominput_spawn_carkey,
  order                 = "b[personal-transport]-z[car-key]",
  -- We'll set this in prototypes/3-add-unlock-tech-to-shortcut.lua (called from
  -- data-final-fixes) now, when we know whether any of the eligible techs will be
  -- available and not hidden.
  --~ technology_to_unlock  = "automobilism",
  unavailable_until_unlocked = true,

}


------------------------------------------------------------------------------------
--                      Custom input to put keys into cursor                      --
------------------------------------------------------------------------------------
protos.keys_to_cursor = {
    type = "custom-input",
    name = GCKI.custominput_spawn_carkey,
    --~ localised_name = {"controls.player-cancelled-path"},
    --~ localised_description = {"controls-description.player-cancelled-path"},
    localised_name = {"controls.keys-to-cursor"},
    localised_description = {"controls-description.keys-to-cursor"},
    order = "a",
    key_sequence = "",
    consuming = "none",
    --~ action = "spawn-item",
    --~ item_to_spawn = GCKI.carkey_name,
    action = "lua",
    enabled = true,
}


------------------------------------------------------------------------------------
--                              Create custom events                              --
------------------------------------------------------------------------------------
for e, e_name in pairs(GCKI.custom_events) do
  protos[e_name] = {
    type = "custom-event",
    name = e_name,
  }
  --~ data:extend({event})
  --~ minime.created_msg(event)
end


------------------------------------------------------------------------------------
protos.keys_to_cursor = {
    type = "custom-input",
    name = GCKI.custominput_spawn_carkey,
    localised_name = {"controls.keys-to-cursor"},
    localised_description = {"controls-description.keys-to-cursor"},
    order = "a",
    key_sequence = "",
    consuming = "none",
    action = "lua",
    enabled = true,
}


------------------------------------------------------------------------------------
--                   Icon for locked vehicles (Prototype/Sprite)                  --
------------------------------------------------------------------------------------
protos.locked_icon = {
  type                  = "sprite",
  name                  = "GCKI_locked-icon",
  filename              = GCKI.locked_symbol,
  size                  = 64,
  scale                 = .5
}


------------------------------------------------------------------------------------
--                          GUI styles (Prototype/Sprite)                         --
------------------------------------------------------------------------------------
local styles = {}
styles.highlighted_value_textfield = {
  type                  = "textbox_style",
  parent                = "highlighted_value_textfield",
  --~ disabled_font         = "default-bold",
  --~ disabled_font_color   = {1, 1, 1, 1},
  font                  = "default",
  font_color            = {},
}
styles.stretchable_textfield = {
  type                  = "textbox_style",
  parent                = "stretchable_textfield",
  disabled_font         = "default-bold",
  disabled_font_color   = {1, 1, 1, 1},
}
styles.toggle_button = {
  type                  = "button_style",
  parent                = "mod_gui_button",
  padding               = 4,
}
styles.inner_frame = {
    type = "frame_style",
    parent = "inside_shallow_frame_with_padding",
    vertically_stretchable = "on",
    horizontal_align = "center",
    vertical_align = "center",
}


------------------------------------------------------------------------------------
--                              Create the new stuff!                             --
------------------------------------------------------------------------------------
-- Prototypes
for p_name, proto in pairs(protos) do
  data:extend({proto})
  GCKI.created_msg(proto)
end



-- Styles
local name
for s_name, style in pairs(styles) do
  name = "GCKI_"..s_name
  data.raw["gui-style"]["default"][name] = style
  GCKI.writeDebug("Created new style \"%s\"!", {name})
end


------------------------------------------------------------------------------------
GCKI.entered_file("leave")
