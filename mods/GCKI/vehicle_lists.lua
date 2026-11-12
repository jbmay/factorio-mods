GCKI.entered_file()

------------------------------------------------------------------------------------
------------------------------------------------------------------------------------
--                                 LOCAL DEFINITIONS                              --
------------------------------------------------------------------------------------
------------------------------------------------------------------------------------
local protos = {}

------------------------------------------------------------------------------------
--  Blacklist/whitelist patterns for names of vehicle prototypes from other mods  --
------------------------------------------------------------------------------------
local mod_proto_map = {

  -- "Avatars" uses buildings based on the car prototype.
  ["Avatars"] = {
    ["car"] = {
      blacklist = {
        "avatar-control-center",
        "avatar-remote-deployment-unit",
      },
    },
  },

  -- "Companion Drones" are actually spider vehicles.
  ["Companion_Drones"] = {
    ["spider-vehicle"] = {
      blacklist = {"companion"},
    },
  },

  -- "HelicopterRevival" combines different car prototypes to make a helicopter.
  ["HelicopterRevival"] = {
    ["car"] = {
      blacklist = {
        "^heli%-entity%-_%-",
        "^heli%-.+%-entity%-_%-",
        "^rotor%-entity%-_%-",
        "^rotor%-.+%-entity%-_%-",
      },
    },
  },

  -- "Industrial Revolution 2" has some vehicles we should ignore
  ["IndustrialRevolution"] = {
    ["car"] = {
      blacklist = {
        -- Tech is unlocked before electronic circuits are available!
        "monowheel",
        -- Invisible car used to hide players
        "limbo-car",
      },
    },
  },

  -- "King Jo's Warhammer 40K Bunker" has a stationary building based on the car prototype.
  ["kj_40kbunker"] = {
    ["car"] = {
      blacklist = {"kj_40kbunker"},
    },
  },

  -- "Logicarts" (dorfl)
  ["logicarts"] = {
    ["car"] = {
      blacklist = {"logicarts-car", "logicarts-car-electric"},
    },
  },

  -- "Logistic Carts" (fork by SingletonFactory)
  ["logicarts2"] = {
    ["car"] = {
      blacklist = {"logicarts-car", "logicarts-car-electric"},
    },
  },

  -- "Long_Range_Delivery_Drones" (drones are car-prototypes that self-destruct
  -- after use)
  ["Long_Range_Delivery_Drones"] = {
    ["car"] = {
      blacklist = {"long-range-delivery-drone"},
    },
  },

  -- Mod is still deprecated, it's to go public when Factorio 2.0 drops
  -- "Maraxsis" (Cars seem to be used as door to the pressure dome)
  ["maraxsis"] = {
    ["car"] = {
      blacklist = {"h2o-pressure-dome-collision"},
    },
  },

  -- "Renai Transportation" uses cars to store train info/drivers while transporting trains.
  ["RenaiTransportation"] = {
    ["car"] = {
      blacklist = {"RTPropCar"},
    },
  },

  -- "Satisfactorio" uses some fake car prototypes and has a spidertron.
  ["Satisfactorio"] = {
    ["car"] = {
      blacklist = {
        "lookout-tower",
        "jump-pad-car",
        "jump-pad-flying",
        "hyper-tube-entrance-car",
        "zipline-flying",
        "parachute-flying",
        "jetpack-flying",
        "hover-pack-flying",
        "tractor",
        "truck",
        "explorer",
      },
    },
    ["spider-vehicle"] = {
      blacklist = {"drone"},
    }
  },

  -- "Space Exploration" uses cars as obstacles (asteroids, debris) for spaceships
  ["space-exploration"] = {
    ["car"] = {
      blacklist = {"se%-spaceship%-obstacle%-.+%-vehicle"},
    },
  },

  -- "Shield Projector" (required by "Space Exploration") uses cars as dummy for energy walls.
  ["shield-projector"] = {
    ["car"] = {
      blacklist = {"shield-projector-barrier"},
    },
  },

  -- "Spidertron Enhancements" uses spider-vehicle dummies that are teleported on
  -- each tick when the player enters a vehicle directly from a spidertron.
  ["SpidertronEnhancements"] = {
    ["spider-vehicle"] = {
      blacklist = {"spidertron%-enhancements%-dummy%-.+"},
    },
  },
}



------------------------------------------------------------------------------------
--    Add new pattern to list (do nothing if it already contained the pattern)    --
------------------------------------------------------------------------------------
local function add_to_prototype_list(list, pattern)
  GCKI.entered_function({list, pattern})
  local add_it = true
  for l, l_pattern in pairs(list) do
    if l_pattern == pattern then
      GCKI.writeDebug("Pattern \"%s\" is already in list!", {pattern})
      add_it = false
      break
    end
  end

  if add_it then
    table.insert(list, pattern)
  end

  GCKI.entered_function("leave")
  return add_it
end



------------------------------------------------------------------------------------
--          Store patterns for black- or whitelisting vehicle prototypes          --
------------------------------------------------------------------------------------
local function make_blacklist_whitelist(mod_data, target)
  GCKI.entered_function({mod_data, target})

  GCKI.assert(mod_data, "table")
  GCKI.assert(target, "table")

  for mod_name, proto_data in pairs(mod_data) do
  GCKI.show("Data for "..mod_name, proto_data)
    if GCKI.check_mods(mod_name) then
      GCKI.writeDebug("Adding prototypes on account of mod \"%s\":", {mod_name})

      for proto_type, lists in pairs(proto_data) do
        GCKI.writeDebug("Looking for \"%s\" prototypes.", {proto_type})

        for list_name, patterns in pairs(lists) do
          for p, pattern in pairs(patterns) do
            if add_to_prototype_list(target[list_name.."_vehicles"][proto_type], pattern) then
              GCKI.writeDebug("Added \"%s\" to %s (\"%s\").", {pattern, list_name, proto_type})
            end
          end
        end
      end
    end
  end
  GCKI.show("target", target)

  GCKI.entered_function("leave")
end


------------------------------------------------------------------------------------
--                          Update black- and whitelists!                         --
--       (Used when a mod has called our functions to add/remove prototypes)      --
------------------------------------------------------------------------------------
local function update_black_and_white_list()
  GCKI.entered_function()

  local source, target

  if data then
    GCKI.mod_patterns = GCKI.mod_patterns or {}
    source = GCKI.mod_patterns
  else
    mod.vehicle_prototypes.mod_patterns = mod.vehicle_prototypes.mod_patterns or {}
    source = mod.vehicle_prototypes.mod_patterns
  end
  target= GCKI.patterns


  -- We completely rebuild the black- and whitelists!
  target.blacklist_vehicles = {}
  target.whitelist_vehicles = {}

  for p, p_type in ipairs(GCKI.vehicle_types) do
    target.blacklist_vehicles[p_type] = {}
    target.whitelist_vehicles[p_type] = {}
  end

  -- Create black-/whitelist for patterns in mod.vehicle_prototypes.mod_patterns!
  make_blacklist_whitelist(source, target)

  GCKI.entered_function("leave")
end


------------------------------------------------------------------------------------
-- Add patterns to mod prototypes' black- or whitelist
------------------------------------------------------------------------------------
local function add_mod_patterns(patterns, mod_name, list)
  GCKI.entered_function({patterns, mod_name, list})

  GCKI.assert(mod_name, "string")
  GCKI.assert(patterns, "table")
  GCKI.assert(list, "string")

  local target
  GCKI.mod_patterns = GCKI.mod_patterns or {}
  GCKI.mod_patterns[mod_name] = GCKI.mod_patterns[mod_name] or {}
  target = GCKI.mod_patterns[mod_name]

  local list_changed

  for proto_type, proto_names in pairs(patterns) do
    target[proto_type] = target[proto_type] or {}
    target[proto_type][list] = target[proto_type][list] or {}

    for p, proto_name in pairs(proto_names) do
      if add_to_prototype_list(target[proto_type][list], proto_name) then
        list_changed = true
        GCKI.writeDebug("Added %s to mod_patterns[\"%s\"][\"%s\"][\"%s\"]",
                        {proto_name, mod_name, proto_type, list})
      end
    end
  end
GCKI.show("mod_patterns", data and GCKI.mod_patterns or mod.vehicle_prototypes.mod_patterns)
GCKI.show("list_changed", list_changed)

  GCKI.entered_function("leave")
  return list_changed
end


------------------------------------------------------------------------------------
-- Remove patterns from mod prototypes' black- or whitelist
------------------------------------------------------------------------------------
local function remove_mod_patterns(patterns, mod_name, list)
  GCKI.entered_function({patterns, mod_name, list})

  GCKI.assert(mod_name, "string")
  GCKI.assert(patterns, "table")
  GCKI.assert(list, "string")

  local target
  GCKI.mod_patterns = GCKI.mod_patterns or {}
  GCKI.mod_patterns[mod_name] = GCKI.mod_patterns[mod_name] or {}
  target = GCKI.mod_patterns[mod_name]
GCKI.show("target", target)

  local list_changed

  if target then
    local stored_patterns

    for proto_type, proto_names in pairs(patterns) do
  GCKI.show(proto_type, proto_names)

      if target[proto_type] and target[proto_type][list] then
        stored_patterns = target[proto_type][list]
        for p_index, proto_name in pairs(proto_names) do
          for p, pattern in pairs(stored_patterns) do
            if pattern == proto_name then
              table.remove(stored_patterns, p)
              list_changed = true
              GCKI.writeDebug("Removed mod_patterns[\"%s\"][\"%s\"][\"%s\"][%s]",
                              {mod_name, proto_type, list, p})
            end
          end
          if not next(stored_patterns) then
            target[proto_type][list] = nil
            GCKI.writeDebug("Removed mod_patterns[\"%s\"][\"%s\"][\"%s\"]",
                            {mod_name, proto_type, list})
          end
        end
      end

      if target[proto_type] and not next(target[proto_type]) then
        target[proto_type] = nil
        GCKI.writeDebug("Removed mod_patterns[\"%s\"][\"%s\"]", {mod_name, proto_type})
      end
    end

GCKI.show("target", target)
    if not next(target) then
      GCKI.mod_patterns[mod_name] = nil
      GCKI.writeDebug("Removed mod_patterns[\"%s\"]", {mod_name})
    end
GCKI.show("mod_patterns", data and GCKI.mod_patterns or mod.vehicle_prototypes.mod_patterns)

  -- Nothing to do
  else
    GCKI.writeDebug("No pattern stored for mod \"%s\"!", {mod_name})
  end

  GCKI.entered_function("leave")
  return list_changed
end


------------------------------------------------------------------------------------
--                       Remove patterns from inactive mods                       --
------------------------------------------------------------------------------------
local function clean_pattern_list(target)
  GCKI.entered_function({target})

  local removed_mod

  for mod_name, proto_data in pairs(target) do
    if GCKI.check_mods(mod_name) then
      GCKI.writeDebug("Keeping patterns of mod \"%s\".", {mod_name})
    else
      target[mod_name] = nil
      removed_mod = true
      GCKI.writeDebug("Removed patterns of mod \"%s\".", {mod_name})
    end
  end

  GCKI.entered_function("leave")
  return removed_mod
end


------------------------------------------------------------------------------------
-- Allow other mods to add/remove patterns of vehicle prototype names to/from our --
-- black- and whitelists!                                                         --
------------------------------------------------------------------------------------
-- Add patterns to black- or whitelist
local function add_patterns_to_list(patterns, mod_name, list)
  GCKI.entered_function({patterns, mod_name, list})

  -- Add new patterns to the mod's patternlist. Will only return true if at least
  -- one new pattern has been added!
  GCKI.writeDebug("Trying to add new patterns to mod's list.")
  local new_patterns = add_mod_patterns(patterns, mod_name, list)

  -- Clean up behind inactive mods. Will only return true if we removed patterns
  -- from at least one mod!
  GCKI.writeDebug("Removing data of inactive mods from mod_patterns!")
  local stored = GCKI.mod_patterns
  local removed = clean_pattern_list(stored)

  if new_patterns or removed then
    GCKI.writeDebug("Must update black- and whitelists!")
    update_black_and_white_list()

    GCKI.writeDebug("Rebuilding vehicle prototype map!")
    GCKI.vehicle_prototypes_map = protos.get_vehicle_prototypes_map()
GCKI.show("GCKI.vehicle_prototypes_map", GCKI.vehicle_prototypes_map)
  end

  GCKI.entered_function("leave")
end


-- Remove patterns from black- or whitelist
local function remove_patterns_from_list(patterns, mod_name, list)
  GCKI.entered_function({patterns, mod_name, list})

  -- Add new patterns to the mod's patternlist. Will only return true if at least
  -- one new pattern has been added!
  GCKI.writeDebug("Trying to remove patterns from mod's list.")
  local removed = remove_mod_patterns(patterns, mod_name, list)
GCKI.show("removed", removed)

  if removed then
    GCKI.writeDebug("Must update black- and whitelists!")
    update_black_and_white_list()

    GCKI.writeDebug("Rebuilding vehicle prototype map!")
    GCKI.vehicle_prototypes_map = protos.get_vehicle_prototypes_map()
  end

  GCKI.entered_function("leave")
end


--~ ------------------------------------------------------------------------------------
--~ --                       Remove patterns from inactive mods                       --
--~ ------------------------------------------------------------------------------------
--~ local function clean_pattern_list(target)
  --~ GCKI.entered_function({target})

  --~ local removed_mod

  --~ for mod_name, proto_data in pairs(target) do
    --~ if GCKI.check_mods(mod_name) then
      --~ GCKI.writeDebug("Keeping patterns of mod \"%s\".", {mod_name})
    --~ else
      --~ target[mod_name] = nil
      --~ removed_mod = true
      --~ GCKI.writeDebug("Removed patterns of mod \"%s\".", {mod_name})
    --~ end
  --~ end

  --~ GCKI.entered_function("leave")
  --~ return removed_mod
--~ end


------------------------------------------------------------------------------------
--             Function to get a list of all valid vehicle prototypes.            --
------------------------------------------------------------------------------------
local function get_vehicles_from_patterns()
  GCKI.entered_function()

  local ret = {}
  local vehicles

  local pattern_lists = GCKI.patterns
  local add_it
GCKI.show("pattern_lists", pattern_lists)

  for p, proto_type in ipairs(GCKI.vehicle_types) do
    ret[proto_type] = {}
    -- Get all prototypes
    vehicles = data.raw[proto_type]
GCKI.show("vehicles", type(vehicles))

    -- Filter out prototypes that are blacklisted or not selectable in game
    for name, proto in pairs(vehicles) do
GCKI.show("prototype name", name)
      -- Must be nil, we don't want to spam the list with "false" entries!
      add_it = nil
      -- Always add whitelisted prototypes, even if they are not selectable in game!
      for w, w_pattern in pairs(pattern_lists.whitelist_vehicles[proto.type]) do
GCKI.show("Whitelist pattern "..w, w_pattern)
        -- Check for literal strings first, then for regular expressions
        if name:find(w_pattern, 1, true) or name:find(w_pattern) then
          GCKI.writeDebug("Found whitelisted pattern \"%s\"!", {w_pattern})
          add_it = true
          break
        end
      end
GCKI.show("add_it after checking whitelist patterns", add_it)
      -- Prototype is not whitelisted -- is it blacklisted?
      if not add_it then
GCKI.show("proto.selectable_in_game", proto.selectable_in_game)
        -- Consider prototypes that are selectable_in_game and allow_passengers.
        -- If allow_passengers is false, the vehicle may have neither a driver nor a
        -- passenger!
        -- (Allow for "nil" during data stage, it will default to "true" eventually!)
        if proto.selectable_in_game ~= false and
            proto.allow_passengers ~= false then
GCKI.writeDebug("Must check blacklist patterns!")
          add_it = true
          for b, b_pattern in pairs(pattern_lists.blacklist_vehicles[proto.type]) do
            -- Check for literal strings first, then for regular expressions
            if name:find(b_pattern, 1, true) or name:find(b_pattern) then
              GCKI.writeDebug("Blacklisted pattern \"%s\" found!", {b_pattern})
              add_it = nil
              break
            end
          end
        else
          GCKI.writeDebug("Not selectable in game!")
        end
      end
      GCKI.writeDebug("%s %s \"%s\"", {add_it and "Adding" or "Ignoring", proto_type, name})
      if add_it then
        table.insert(ret[proto_type], name)
      end
    end
  end

  GCKI.writeDebug("Made list of suitable vehicles: %s", {ret})

  GCKI.entered_function("leave")
  return ret
end

------------------------------------------------------------------------------------
--         CONTROL STAGE: Build prototype map from selection tool filters         --
------------------------------------------------------------------------------------
local function get_vehicles_from_selection_tool()
  GCKI.entered_function()

  local ret = {}

  --~ local selection_tool = game.item_prototypes[GCKI.carkey_name]
  local selection_tool = prototypes.item[GCKI.carkey_name]
GCKI.show("selection_tool", GCKI.argprint(selection_tool))
  --~ local filters = selection_tool and selection_tool.entity_filters
  --~ local filters = selection_tool and
                  --~ selection_tool.get_entity_filters(defines.selection_mode.select)
  local filters = {}
  if selection_tool then
    local mode = defines.selection_mode.select
    for f, filter in pairs(selection_tool.get_entity_filters(mode)) do
      filters[filter. name] = filter
    end
  end
GCKI.show("filters", filters)

  -- Get list of all vehicle prototypes
  --~ local proto_names = game.get_filtered_entity_prototypes({
  local proto_names = prototypes.get_entity_filtered({
    { filter = "type", type = GCKI.vehicle_types },
  })
  local proto

  -- Add prototype to list of filter name really matches a vehicle name.
  for f_name, f_proto in pairs(filters) do
    proto = proto_names[f_name]
    if proto then
      ret[proto.type] = ret[proto.type] or {}
      table.insert(ret[proto.type], f_name)
      GCKI.writeDebug("Added %s to vehicle prototype list!", {GCKI.argprint(proto)})
    else
      GCKI.writeDebug("Ignoring %s!", GCKI.argprint(f_proto))
    end
  end
  GCKI.show("ret", ret)

  GCKI.entered_function("leave")
  return ret
end


------------------------------------------------------------------------------------
--             Function to get the item prototype placing a vehicle.              --
------------------------------------------------------------------------------------
local function vehicle_is_placed_by(vehicle)
  GCKI.entered_function({vehicle})

  --~ vehicle = type(vehicle) == "table" and vehicle.type and vehicle.name and vehicle or
            --~ GCKI.arg_err(vehicle, "vehicle specification")
  GCKI.assert(vehicle, {"LuaEntity", "table"}, "vehicle specification")

  -- Most vehicles can be placed by an item:
  --~ local items = game and game.get_filtered_item_prototypes({
  --~ local items = prototypes and prototypes.get_item_filtered({
  local items = prototypes.get_item_filtered({
    {filter = "place-result", elem_filters = {
      --~ {filter = "type", type = vehicle.type},
      --~ {filter = "name", name = vehicle.name, mode = "and"}
      {filter = "name", name = vehicle.name},
    }}
  })

  -- Some vehicles may be variants of real ones that are used internally by mods
  -- and are not meant to be placed by players directly (e.g. AAI vehicles). If
  -- we've found no item for the vehicle, we'll try to find the base name of the
  -- placeable vehicle:
  if GCKI.is_custom_table_empty(items) then
    items = GCKI_mods.vehicle_is_placed_by_AAI(vehicle)
  end

  local item
  -- As "items" is a LuaCustomTable, next(items) will return garbage, so we use
  -- pairs and break after the first iteration!
  -- We want luacheck to ignore "loop is executed at most once"
  do
    -- luacheck: ignore
    for name, data in pairs(items or {}) do
      item = name
      break
    end
  end
GCKI.show("Vehicle is placed by", item)

  GCKI.entered_function({vehicle}, "leave")
  return item
end

------------------------------------------------------------------------------------
--                 Initialize list of patterns for modded vehicles                --
------------------------------------------------------------------------------------
local function init_pattern_list()
  GCKI.entered_function()

  local target = GCKI.mod_patterns

  -- Add patterns for directly supported mods. (Control stage: There may already be
  -- data added by other mods via the remote interface. Ignore these for now.)
GCKI.writeDebug("Adding mod patterns!")
  for mod_name, mod_data in pairs(mod_proto_map) do
    if GCKI.check_mods(mod_name) then
GCKI.show("target["..mod_name.."]", target[mod_name])
      target[mod_name] = table.deepcopy(mod_data)
      GCKI.writeDebug("Added patterns for mod \"%s\"!", {mod_name})
GCKI.show("target["..mod_name.."] after table.deepcopy", target[mod_name])
    end
  end

  -- Remove patterns for inactive mods.
GCKI.writeDebug("Pruning list of mod_patterns!")
  clean_pattern_list(target)

  GCKI.entered_function("leave")
end


------------------------------------------------------------------------------------
------------------------------------------------------------------------------------
--                                SHARED FUNCTIONS                                --
------------------------------------------------------------------------------------
------------------------------------------------------------------------------------


------------------------------------------------------------------------------------
--    Initialize blacklist and whitelist with data for directly supported mods    --
------------------------------------------------------------------------------------
protos.init_black_and_white_list = function()
  GCKI.entered_function()

  GCKI.mod_patterns = GCKI.mod_patterns or {}
  local source = GCKI.mod_patterns

  GCKI.patterns = GCKI.patterns or {}
  local target = GCKI.patterns
GCKI.show("target", target)
  target.blacklist_vehicles = target.blacklist_vehicles or {}
  target.whitelist_vehicles = target.whitelist_vehicles or {}

  for p, p_type in ipairs(GCKI.vehicle_types) do
    target.blacklist_vehicles[p_type] = target.blacklist_vehicles[p_type] or {}
    target.whitelist_vehicles[p_type] = target.whitelist_vehicles[p_type] or {}
  end

  -- Initialize list of patterns for black- or whitelisting other mods' prototypes.
  GCKI.writeDebug("Initializing list of mod_patterns!")
  init_pattern_list()

  -- Add patterns for directly supported mods. (Control stage: There may already be
  -- data added by other mods via the remote interface. Ignore these for now.)
  make_blacklist_whitelist(source, target)

  GCKI.entered_function("leave")
end


------------------------------------------------------------------------------------
-- Function to get a map of all valid vehicle prototypes for quick look-up
protos.get_vehicle_prototypes_map = function()
  GCKI.entered_function()

  local ret = {}

  -- Look for entities of a valid type!
  local proto_list = data and get_vehicles_from_patterns() or
                              get_vehicles_from_selection_tool()
GCKI.show("proto_list", proto_list)
  local proto

  for proto_type, proto_names in pairs(proto_list or {}) do
    ret[proto_type] = {}

    for p, p_name in ipairs(proto_names) do
      -- During the data stage, we can just set this to true
      if data then
        ret[proto_type][p_name] = true

      --~ -- During the game, we must know what item will place a vehicle, so we can
      --~ -- use its name when calling player.add_custom_alert()!
      --~ else
        --~ ret[proto_type][p_name] = {
          --~ -- Name of first item that places this prototype
          --~ placeable_by = vehicle_is_placed_by({type = proto_type, name = p_name})
        --~ }
      -- During the game, we must know wha titem will place a vehicle, so we can use
      -- its name when calling player.add_custom_alert()!
      else
        --~ proto = game.entity_prototypes[p_name]
        proto = prototypes.entity[p_name]
        ret[proto_type][p_name] = {
          -- Get item that will place a vehicle, so we can use its name when calling
          -- player.add_custom_alert(). The function returns the name of the first
          -- item that places this prototype.
          placeable_by    = vehicle_is_placed_by({type = proto_type, name = p_name}),
          -- We need these values when checking an area for colliding entities.
          half_length     = proto and GCKI_calc.box_size(proto.collision_box)/2,
          half_width      = proto and GCKI_calc.box_width(proto.collision_box)/2,
          collision_mask  = proto and proto.collision_mask
        }
      end
    end
  end

  GCKI.show("Return", ret)

  GCKI.entered_function("leave")
  return ret
end



------------------------------------------------------------------------------------
-- Add patterns for vehicle prototype names to blacklist
protos.add_blacklist_patterns = function(patterns, mod_name)
  GCKI.entered_function({patterns, mod_name})

  add_patterns_to_list(patterns, mod_name, "blacklist")

  GCKI.entered_function("leave")
end


------------------------------------------------------------------------------------
-- Remove patterns for vehicle prototype names from blacklist
protos.remove_blacklist_patterns = function(patterns, mod_name)
  GCKI.entered_function({patterns, mod_name})

  remove_patterns_from_list(patterns, mod_name, "blacklist")

  GCKI.entered_function("leave")
end


------------------------------------------------------------------------------------
-- Add patterns for vehicle prototype names to whitelist
protos.add_whitelist_patterns = function(patterns, mod_name)
  GCKI.entered_function({patterns, mod_name})

  add_patterns_to_list(patterns, mod_name, "whitelist")

  GCKI.entered_function("leave")
end


------------------------------------------------------------------------------------
-- Remove patterns for vehicle prototype names to blacklist
protos.remove_whitelist_patterns = function(patterns, mod_name)
  GCKI.entered_function({patterns, mod_name})

  remove_patterns_from_list(patterns, mod_name, "whitelist")

  GCKI.entered_function("leave")
end



------------------------------------------------------------------------------------
GCKI.entered_file("leave")

return protos
