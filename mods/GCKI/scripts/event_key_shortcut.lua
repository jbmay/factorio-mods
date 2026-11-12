GCKI.entered_file()

------------------------------------------------------------------------------------
------------------------------------------------------------------------------------
--                                 LOCAL DEFINITIONS                              --
------------------------------------------------------------------------------------
------------------------------------------------------------------------------------

------------------------------------------------------------------------------------
--            CREATE AN AREA AROUND CLICK-POSITION TO SEARCH FOR VEHICLES         --
------------------------------------------------------------------------------------
local function area_create(position, dx, dy)
  position = position and GCKI.normalize_position(position) or
              --~ GCKI.error("Missing position!")
              GCKI.arg_err(position, "position")
  dx = dx or 0
  dy = dy or dx

  local x, y = position.x, position.y

  --~ return {{x - dx, y - dy}, {x + dx, y + dy}}
  return {left_top = {x - dx, y - dy}, right_bottom = {x + dx, y + dy}}
end


-- This will hold the main functions we want to call from outside
local used_key = {}


------------------------------------------------------------------------------------
------------------------------------------------------------------------------------
--                                 VEHICLE FUNCTIONS                              --
------------------------------------------------------------------------------------
------------------------------------------------------------------------------------
-- Vehicle has been locked. Enforce driver access while retaining passengers!
local function eject_from(owner, vehicle)
GCKI.entered_function({owner, vehicle})

  local occupants = GCKI_vehicle.get_occupants(vehicle)

  -- Remove dummy characters inserted by other mods so they don't spam the surface.
  GCKI_vehicle.remove_dummy(vehicle, occupants)

  -- Color the vehicle with owner's color
  GCKI_vehicle.color_vehicle(vehicle)

  -- Retain the owner and eject only unauthorized players.
  GCKI_vehicle.enforce_vehicle_lock(vehicle)
end


-- You own this vehicle, lock or unlock the doors
used_key.toggle_lock = function(owner, vehicle)
GCKI.entered_function({owner, vehicle})
  -- If the vehicle has just been locked, "locker" will be owner.index!
  local locker = GCKI_vehicle.lock_or_unlock(vehicle, owner)

  -- Eject unauthorized occupants
  if locker then
    eject_from(owner, vehicle)
  end

  GCKI_messages.used_key.info_owner_locked_state(owner, locker, vehicle)

  return locker
end


-- Player can't claim a vehicle with somebody inside!
local function is_player_inside(player, vehicle)
GCKI.entered_function({player, vehicle})
  local occupants = GCKI_vehicle.get_occupants(vehicle)
  local driver = GCKI_events.helper.assert_role(occupants, "driver") and occupants.driver.entity
  local passenger = GCKI_events.helper.assert_role(occupants, "passenger") and occupants.passenger.entity

  local occupied =
                    -- Both seats are taken by a human player
                    (driver and passenger) or
                    -- There's just one player in the vehicle, but another player tries to claim it
                    (driver and driver ~= player) or
                    (passenger and passenger ~= player)

  return occupied and GCKI_messages.used_key.info_cant_claim_occupied(player, vehicle, occupants)
end


-- Player has claimed an unlocked vehicle
local function claim_unlocked_vehicle(player, vehicle)
GCKI.entered_function({player, vehicle})

  player = GCKI.ascertain_player(player)
  GCKI.assert(vehicle, "LuaEntity")

  if not (player and player.valid) then
    GCKI.entered_function({}, "leave", "invalid player")
    return
  elseif not (vehicle and vehicle.valid) then
    GCKI.entered_function({}, "leave", "invalid vehicle")
    return
  end


  -- Player claims vehicle belonging to his own force
  if player.force == vehicle.force then
    GCKI_messages.used_key.info_claimed_unlocked_vehicle(player, vehicle)

  -- Player steals vehicle from another force
  else
    GCKI_messages.used_key.info_claimed_unlocked_vehicle_other_force(player, vehicle)

    GCKI.writeDebug("Raising event!")
    local old_force = vehicle and vehicle.valid and vehicle.force
    local new_force = player and player.valid and player.force
    --~ local raise_id = GCKI.custom_events.on_vehicle_changed_force
    local raise_id = "on_vehicle_changed_force"

    vehicle.force = new_force

    script.raise_event(raise_id, {
      old_force = old_force,
      new_force = new_force,
      player = player,
      vehicles = {vehicle},
      name = raise_id,
    })
  end

  GCKI.writeDebug("Adding owner to %s!", {GCKI.argprint(vehicle)})
  GCKI_vehicle.add_vehicle_owner(vehicle, player)
end


-- Player has claimed a locked vehicle
local function claim_locked_vehicle(player, vehicle)
GCKI.entered_function({player, vehicle})
  GCKI_messages.used_key.info_claimed_locked_vehicle(player, vehicle)
  GCKI_vehicle.add_vehicle_owner(vehicle, player)
end


------------------------------------------------------------------------------------
-- Player tried to claim or lock/unlock a vehicle!
------------------------------------------------------------------------------------
used_key.claim_or_toggle_lock = function(player, vehicle)
GCKI.entered_function({player, vehicle})

  if not GCKI_ownership.can_use(player, true) or
      GCKI_ownership.scope(player.surface) ~= GCKI_ownership.scope(vehicle.surface) then
    return
  end

  -- Claiming and changing locks do not require character reach.
  local v_data = GCKI_vehicle.get_vehicle_data(vehicle)
  --~ local owner = v_data and v_data.owner and game.players[v_data.owner]
  local owner = v_data and v_data.owner and game.get_player(v_data.owner)


GCKI.show("owner", GCKI.argprint(owner))

  -- Player tried to steal a vehicle
  if owner and player ~= owner then
GCKI.writeDebug("Vehicle belongs to %s!", {GCKI.argprint(owner)})
    GCKI_messages.used_key.info_player_not_owner(owner, player, vehicle)

  -- Vehicle belongs to player, player wants to lock/unlock it
  elseif player == owner then
GCKI.writeDebug("Vehicle belongs to player!")
    used_key.toggle_lock(owner, vehicle)

  -- Vehicle has no owner, but may be locked because the last owner claimed another one
  else
    GCKI.writeDebug("%s has no owner. Check whether it's locked!",
                    {GCKI.argprint(vehicle)})
    --~ local locker = v_data and v_data.locker and game.players[v_data.locker]
    local locker = v_data and v_data.locker and game.get_player(v_data.locker)
GCKI.show("locker", locker)

    -- Vehicle is unlocked
    if not locker then
GCKI.writeDebug("Vehicle is unlocked!")
      -- Player can only claim empty vehicles!
      if not is_player_inside(player, vehicle) then
GCKI.writeDebug("Nobody is inside, can claim unlocked vehicle!")
        claim_unlocked_vehicle(player, vehicle)

        -- Use entity_label as custom name if this is a "spider-vehicle" prototype
        if vehicle.type == "spider-vehicle" and vehicle.entity_label and
            not mod.named_vehicles.by_id[vehicle.unit_number] then

          --~ GCKI_vehicle.edit_vehicle_name(player, vehicle, vehicle.entity_label)
          local args = {
            player = player,
            vehicle = vehicle,
            new_name = vehicle.entity_label
          }
          GCKI_vehicle.edit_vehicle_name(args, script.mod_name)
          GCKI.writeDebug("Added %s to vehicle names!", {GCKI.argprint(vehicle.entity_label)})
        end

      end

    -- Vehicle was locked by player, but player claimed another vehicle meanwhile
    elseif player == locker then
GCKI.writeDebug("Vehicle has been locked by player. Claiming it again!")
        claim_locked_vehicle(player, vehicle)

    -- Vehicle has been locked by somebody else
    else
GCKI.writeDebug("Vehicle has been locked by somebody else!")
      GCKI_messages.used_key.info_cant_claim_locked(player, locker, vehicle)
    end
  end
end
------------------------------------------------------------------------------------



------------------------------------------------------------------------------------
--      Check whether the key has been used on a vehicle (claim, lock/unlock)     --
------------------------------------------------------------------------------------
used_key.find_vehicle = function(surface, position, selection)
  GCKI.entered_function({surface, position})

  surface = GCKI.ascertain_surface(surface)
  if not (surface and surface.valid) then
    GCKI.arg_err(surface, "surface specification")
  end
  position = GCKI.normalize_position(position)

  local function supported(entity)
    local types = mod.vehicle_prototypes.map
    return entity and entity.valid and entity.surface == surface and
           types[entity.type] and types[entity.type][entity.name]
  end
  -- Use Factorio's visual selection before searching ground collision boxes.
  -- Spidertron's elevated, animated body may be outside its ground footprint.
  if selection then
    if supported(selection.selected) then return selection.selected end
    for _, entity in ipairs(selection.entities or {}) do
      if supported(entity) then return entity end
    end
  end

  --~ local vehicles = surface.find_entities_filtered({
    --~ -- area = area_create(position, 1),
    --~ area = area_create(position, .25),
    --~ type = GCKI.vehicle_types,
  --~ })
  local filters = {
    area = area_create(position, .25),
    type = GCKI.vehicle_types,
  }
GCKI.show("position", position)
GCKI.show("Search filters", filters)
  local vehicles = surface.find_entities_filtered(filters)
GCKI.show("Found vehicles", vehicles)

  local vehicle
  for v, v_entity in pairs(vehicles) do
GCKI.writeDebug("%s:\t%s", {v, GCKI.argprint(v_entity)})
    --~ if global.vehicle_prototypes_map[v_entity.type][v_entity.name] then
    if supported(v_entity) then
      vehicle = v_entity
      break
    end
  end
GCKI.show("vehicle", vehicle)

  GCKI.entered_function("leave")
  return vehicle
end
------------------------------------------------------------------------------------



-- Look for entities colliding with area on surface
--~ local function find_entities_in_area(vehicle, args)
  --~ GCKI.entered_function({vehicle, args})

  --~ -- We only get proto if vehicle is valid!
  --~ local proto = GCKI_vehicle.is_vehicle(vehicle)
  --~ if not proto then
    --~ GCKI.arg_err(vehicle, "not a valid vehicle")
  --~ end
local function find_entities_in_area(args)
  GCKI.entered_function({args})

  GCKI.assert(args, {"table"}, "table of arguments")
  local vehicle     = args.vehicle

  -- We only get proto if vehicle is valid!
  local proto = GCKI_vehicle.is_vehicle(vehicle)
  if not proto then
    GCKI.arg_err(vehicle, "not a valid vehicle")
  end
GCKI.show("proto", proto)

  local surface     = args.surface
  local pos         = args.position
  local orientation = args.orientation

  local area = area_create(pos, proto.half_width, proto.half_length)
  area.orientation = orientation
GCKI.show("area", area)
GCKI.show("angle", orientation * 360)

GCKI.show("proto.collision_mask", proto.collision_mask)

  local found = surface.find_entities_filtered({
    area = area,
    --~ collision_mask = proto.collision_mask,
    collision_mask = proto.collision_mask.layers,
  })
GCKI.show("Found entities", #found)

  local ret = {}

  for e, entity in pairs(found) do
GCKI.show(e, GCKI.argprint(entity))
GCKI.show("entity ~= vehicle", entity ~= vehicle)
    if entity ~= vehicle then
      table.insert(ret, entity)
    end
  end
GCKI.show("ret", ret)

  GCKI.entered_function("leave")
  return next(ret) and ret
end


-- Can the vehicle be placed at the selected location?
--~ local function can_place_vehicle(owner, new_position, vehicle, orientation)
--~ GCKI.entered_function({owner, new_position, vehicle})
local function can_place_vehicle(args)
GCKI.entered_function({args})

  GCKI.assert(args, "table", "no arguments")
  local owner         = args.owner
  local new_position  = GCKI.normalize_position(args.position)
  local vehicle       = args.vehicle
  local orientation   = args.orientation
  --~ local occupants     = args.occupants

  local success = true

  -- Arguments for the different checks
  local new_chunk_pos = {new_position.x/32, new_position.y/32}
  local place_args = {
    name              = vehicle.name,
    position          = new_position,
    force             = owner.force,
    build_check_type  = defines.build_check_type.manual,
    forced            = false
  }
  local check_area_args = {
    vehicle           = vehicle,
    surface           = owner.surface,
    position          = new_position,
    orientation       = orientation,
  }
GCKI.show("vehicle", GCKI.argprint(vehicle))
GCKI.show("collision_mask", vehicle.prototype.collision_mask)
  -- Check whether selected position is in owner's reach
  if not GCKI_player.is_in_reach(owner, new_position) then
    GCKI.writeDebug("Position is not within owner's reach!")
    success = GCKI_messages.used_key.info_summoned_error_out_of_reach(owner, vehicle)

  -- Check whether chunk is valid
  elseif not owner.surface.is_chunk_generated(new_chunk_pos) then
    GCKI.writeDebug("Position is not in a generated chunk!")
    success = GCKI_messages.used_key.info_summoned_error_cant_place(owner, vehicle)

  -- Check whether vehicle can be placed at the new position! This makes sure that
  -- the position is valid (e.g. that a car isn't places on water), but will always
  -- assume that the vehicle is pointing north.
  elseif not owner.surface.can_place_entity(place_args) then
    GCKI.writeDebug("LuaSurface::can_place_entity() failed!")
    success = GCKI_messages.used_key.info_summoned_error_cant_place(owner, vehicle)

  -- Make sure that the vehicle doesn't collide with other entities when it is
  -- rotated by 'orientation' around its center (i.e. vehicle.position).
  elseif find_entities_in_area(check_area_args) then
    GCKI.writeDebug("Function find_entities_in_area() failed!")
    success = GCKI_messages.used_key.info_summoned_error_cant_place(owner, vehicle)
  end

  return success
end


-- Actually teleport the vehicle
local function teleport(vehicle, position, surface)
GCKI.entered_function({vehicle, position, surface})
  return vehicle and vehicle.valid and
                      vehicle.teleport(position, surface or vehicle.surface)
end


-- Tell owner we successfully teleported the vehicle
local function teleport_success(owner, vehicle)
GCKI.entered_function({owner, vehicle})
  GCKI_messages.used_key.info_summoned_vehicle_arrived(owner, vehicle)

  if GCKI_vehicle.get_locker(vehicle) then
GCKI.writeDebug("Restoring locked_icon")
    GCKI_vehicle.locked_icon(vehicle)
  end
end


-- ERROR! Couldn't teleport
local function teleport_error(owner, position, vehicle)
GCKI.entered_function({owner, position, vehicle})
  error(string.format("Couldn't teleport %s summoned by %s from % (%s) to %s (%s)!",
        vehicle and GCKI.argprint(vehicle) or "nil",
        owner and GCKI.argprint(owner) or "nil",
        vehicle and vehicle.position or "nil",
        (vehicle and vehicle.surface and vehicle.surface.name) or "nil",
        position,
        (owner and owner.surface and owner.surface.name) or "nil"))
end


-- Teleport vehicle on the same surface
--~ local function teleport_same_surface(owner, position, vehicle, orientation)
--~ GCKI.entered_function({owner, position, vehicle, orientation})
local function teleport_same_surface(args)
GCKI.entered_function({args})

  GCKI.assert(args, "table", "no arguments")
  local owner       = args.owner
  local position    = args.position
  local vehicle     = args.vehicle
  local orientation = args.orientation
  local occupants   = args.occupants

  --~ local old_surface = vehicle and vehicle.valid and vehicle.surface
  --~ local old_position = vehicle and vehicle.valid and vehicle.position
  --~ local v_id = vehicle and vehicle.valid and vehicle.unit_number

  local old_surface, old_position, v_id
  if vehicle and vehicle.valid then
    old_surface =  vehicle.surface
    old_position = vehicle.position
    v_id = vehicle.unit_number
  end

  GCKI.writeDebugNewBlock("Trying to teleport %s!", GCKI.argprint(vehicle))
  if teleport(vehicle, position) then
    GCKI.writeDebug("Teleported vehicle! Change orientation?")
GCKI.show("orientation", orientation * 360)
GCKI.show("vehicle.orientation", vehicle.orientation * 360)
GCKI.show("orientation == vehicle.orientation", orientation == vehicle.orientation)
    if orientation == vehicle.orientation then
      GCKI.writeDebug("No!")
    else
      GCKI.writeDebug("Yes!")
      vehicle.orientation = orientation
    end

    -- Inform occupants that owner summoned them together with the vehicle
    --~ local occupants = GCKI_vehicle.get_occupants(vehicle)
    for o, occupant in pairs(occupants or {}) do
      -- Only inform other human players, not the owner!
      if occupant.is_player and owner ~= occupant.entity then
        GCKI_messages.used_key.info_teleport_player_same_surface(owner, occupant.entity, vehicle)
      end
    end

    -- Inform owner, restore icon
    teleport_success(owner, vehicle)

    -- Does the vehicle have a custom name?
    local named = mod.named_vehicles.by_id[v_id]

    -- Raise event
    GCKI.writeDebug("Manually raising event script_raised_teleported!")
    local data = {
          entity              = vehicle,
          old_surface_index   = old_surface.index,
          old_position        = old_position,
          name_render_text_id = named and named.render_text_id,
    }
    script.raise_event(defines.events.script_raised_teleported, data)
  else
    GCKI.writeDebug("Failed to teleport %s!", {GCKI.argprint(vehicle)})
    teleport_error(owner, position, vehicle)
  end

  return true
end


-- If we can get a player, check the player's setting "teleport_to_other_surface"
local function can_move_player_to_other_surface(object)
GCKI.entered_function({object})

  local player = GCKI.ascertain_player(object)
GCKI.show("player", player)
  if not player then
    GCKI.assert(object, "LuaEntity")
    player = (object.type == "character") and object.player or
                                              object.associated_player
GCKI.show("player from character", player)
  end
  return player and player.valid and mod.player_data[player.index].settings and
          mod.player_data[player.index].settings.teleport_to_other_surface
end


-- Teleport vehicle to another surface, optionally eject occupants
--~ local function teleport_other_surface(owner, position, vehicle)
--~ GCKI.entered_function({owner, position, vehicle})
local function teleport_other_surface(args)
GCKI.entered_function({args})

  GCKI.assert(args, "table", "no arguments")
  local owner       = args.owner
  local position    = args.position
  local vehicle     = args.vehicle
  local orientation = args.orientation
  local occupants   = args.occupants

  local old_surface = vehicle and vehicle.valid and vehicle.surface
  local old_position = vehicle and vehicle.valid and vehicle.position

  -- Check whether occupants want to be moved to other surfaces. No need to check
  -- for owner (can't summon himself to another surface)!
  --~ for role, occupant in pairs(GCKI_vehicle.get_occupants(vehicle) or {}) do
  for role, occupant in pairs(occupants or {}) do
GCKI.show(role, occupant)
    -- Player allows summoning to another surface
    if can_move_player_to_other_surface(occupant.entity) then
      GCKI_messages.used_key.info_teleport_player_other_surface(owner, occupant.entity, vehicle)

    -- Player will be ejected
    elseif occupant.is_player then
      GCKI_messages.used_key.info_eject_occupants_teleport(owner, occupant.entity, vehicle)
      vehicle["set_"..role](nil)

    -- Dummies will be removed
    elseif occupant.entity and occupant.entity.valid then
      GCKI.writeDebug("Destroying dummy %s!", {GCKI.argprint(occupant.entity)})
      occupant.entity.destroy({raise_destroy = true})
    end
  end

  -- Everybody who shouldn't be inside is out now, so teleport the vehicle!
  if teleport(vehicle, position, owner.surface) then
    GCKI.writeDebug("Teleported vehicle! Change orientation?")
GCKI.show("orientation", orientation * 360)
GCKI.show("vehicle.orientation", vehicle.orientation * 360)
GCKI.show("orientation == vehicle.orientation", orientation == vehicle.orientation)
    if orientation == vehicle.orientation then
      GCKI.writeDebug("No!")
    else
      GCKI.writeDebug("Yes!")
      vehicle.orientation = orientation
    end

    teleport_success(owner, vehicle)

    local v_id = vehicle.unit_number
--~ GCKI.show("v_id", v_id)
--~ GCKI.show("global.named_vehicles.by_id["..v_id.."]", global.named_vehicles.by_id[v_id])
    --~ if global.named_vehicles.by_id[v_id] then
      --~ local name = global.named_vehicles.by_id[v_id].name
      --~ local args = {player = owner, vehicle = vehicle, new_name = name}
--~ GCKI.show("args", args)
      --~ -- GCKI_vehicle.edit_vehicle_name(args, script.mod_name)
      --~ GCKI_vehicle.add_vehicle_name_rendering(owner, vehicle, name)
    --~ end
    GCKI_vehicle.restore_renderings(vehicle)

    -- Update surface index for show_on_camera and show_on_map
    local p_data
    for p, player in pairs(game.players) do
      p_data = mod.player_data[p]
      if p_data.show_on_camera and p_data.show_on_camera.id == v_id then
        p_data.show_on_camera.surface_index = vehicle.surface.index
        GCKI.writeDebug("Updated show_on_camera.surface_index!")
      end

      if p_data.show_on_map and p_data.show_on_map.id == v_id then
        p_data.show_on_map.surface_index = vehicle.surface.index
        GCKI.writeDebug("Updated show_on_map.surface_index!")
      end
    end


    -- Raise event
    GCKI.writeDebug("Manually raising event script_raised_teleported!")

    --~ local v_id = vehicle.unit_number
    local data = {
      entity              = vehicle,
      old_surface_index   = old_surface.index,
      old_position        = old_position,
      name_render_text_id = mod.named_vehicles.by_id[v_id] and
                            mod.named_vehicles.by_id[v_id].render_text_id,
    }
    script.raise_event(defines.events.script_raised_teleported, data)

    -- Update surface name in GUIs
    GCKI.writeDebug("Updating %s on GUIs!", {GCKI.argprint(vehicle)})
    GCKI_gui.update_guis(vehicle)

  else
    teleport_error(owner, position, vehicle)
  end

  return true
end


-- Look up the vehicle via the owner and make sure it's valid
local function get_vehicle(owner)
GCKI.entered_function({owner})

  local vehicle = owner and GCKI_ownership.find(owner.index, owner.surface)
GCKI.show("vehicle", vehicle)

  if vehicle and GCKI_vehicle.must_remove_vehicle(vehicle) then
    GCKI_vehicle.remove_vehicle(vehicle)
  elseif GCKI_events.helper.assert_vehicle(vehicle) then
    return mod.GCKI_vehicles[vehicle].entity
  end
end

--~ -- Determine the new orientation of the teleported vehicle
--~ local function get_orientation(owner, vehicle)
  --~ GCKI.entered_function({owner})

  --~ owner = GCKI.ascertain_player(owner)
  --~ if not (vehicle and vehicle.valid) then
    --~ GCKI.arg_err(vehicle, "valid vehicle")
  --~ end




  --~ GCKI.entered_function("leave")
--~ end

------------------------------------------------------------------------------------
-- Summon vehicle
------------------------------------------------------------------------------------
--~ used_key.summon = function(owner, position)
  --~ GCKI.entered_function({owner, position})
used_key.summon = function(owner, position, mode)
  GCKI.entered_function({owner, position, mode})
GCKI.writeDebug("Player summoned vehicle")

  if not GCKI_ownership.can_use(owner, true) then return end

  -- Get the vehicle via the owner
  local vehicle = get_vehicle(owner)
GCKI.show("vehicle", GCKI.argprint(vehicle))
  -- Player is always on the surface where the keys have been used, so
  -- owner.surface == key.surface!
  --~ if vehicle and can_place_vehicle(owner, position, vehicle) then
    --~ -- Teleport on same surface
    --~ if owner.surface == vehicle.surface then
      --~ GCKI.writeDebug("Teleporting on same surface!")
      --~ teleport_same_surface(owner, position, vehicle)

    --~ -- Teleport to another surface
    --~ else
      --~ GCKI.writeDebug("Teleporting to another surface!")
      --~ teleport_other_surface(owner, position, vehicle)
    --~ end
  --~ end
  if vehicle then
    GCKI.writeDebug("Got a vehicle!")

    -- Use orientation of player.character or vehicle?
    local orientation
GCKI.show("owner", GCKI.argprint(owner))
GCKI.show("owner.vehicle", GCKI.argprint(owner.vehicle))
GCKI.show("owner.vehicle ~= vehicle", owner.vehicle ~= vehicle)
GCKI.show("owner.character", GCKI.argprint(owner.character))
GCKI.show("mode", mode)
    GCKI.writeDebugNewBlock("Use orientation of vehicle or player's character?")
    if mode == "use_player_orientation" then
      -- We only use the character's orientation if the player has a character and
      -- is not inside any vehicle!
      if owner.character and owner.character.valid and not owner.vehicle then
        GCKI.writeDebug("Using orientation of character!")
        orientation = owner.character.orientation

      -- If the owner is inside another vehicle based on one of our prototypes, we
      -- use the direction of that vehicle.
      elseif GCKI_vehicle.is_vehicle(owner.vehicle) then
        GCKI.writeDebug("Using orientation of vehicle the player is riding in!")
        orientation = owner.vehicle.orientation
      end
    end
    if not orientation then
      GCKI.writeDebug("Using vehicle orientation!")
      orientation = vehicle.orientation
    end
GCKI.show("orientation", orientation * 360)
--~ error("Break!")

    local args = {
      owner       = owner,
      position    = position,
      vehicle     = vehicle,
      orientation = orientation,
      occupants   = GCKI_vehicle.get_occupants(vehicle),
    }

    --~ if can_place_vehicle(owner, position, vehicle) then
    --~ if can_place_vehicle(owner, position, vehicle, orientation) then
    if can_place_vehicle(args) then
      -- Teleport on same surface
      if owner.surface == vehicle.surface then
        GCKI.writeDebug("Teleporting on same surface!")
        --~ teleport_same_surface(owner, position, vehicle)
        --~ teleport_same_surface(owner, position, vehicle, orientation)
        teleport_same_surface(args)

      -- Teleport to another surface
      else
        GCKI.writeDebug("Teleporting to another surface!")
        --~ teleport_other_surface(owner, position, vehicle)
        --~ teleport_other_surface(owner, position, vehicle, orientation)
        teleport_other_surface(args)
      end
    end
  end
end



------------------------------------------------------------------------------------
--                             KEY SELECTED A POSITION                            --
------------------------------------------------------------------------------------
used_key.key_on_position = function(player, position, mode, selection)
  GCKI.entered_function({player, position, mode})

  player = GCKI.ascertain_player(player)
  if not (player and player.valid) then
    GCKI.arg_err(player, "player specification")
  end
  if not GCKI_ownership.can_use(player, true) then return end
  position = GCKI.normalize_position(position)
  GCKI.assert(mode, {"string", "nil"}, "string or nil")
GCKI.show("mode", mode)

  local index = player.index
  local p_data = mod.player_data[index]


  -- Make sure player holds a key in the hands
  if not player.cursor_stack.valid_for_read then
    player.cursor_stack.set_stack({name = GCKI.carkey_name, count = 1})
  end

  if p_data.last_action_tick and
      (game.tick - p_data.last_action_tick) < GCKI.ACTION_DELAY then
    GCKI.entered_function(
      {},
      "leave",
      --~ string.format("ticks since last action: %s < %s",
                    --~ game.tick - p_data.last_action_tick, GCKI.ACTION_DELAY)
      string.format("ticks since last action: %s < %s",
                    game.tick - p_data.last_action_tick, GCKI.ACTION_DELAY)
    )
    return
  end


  ------------------------------------------------------------------------------------
  ------------------------------------------------------------------------------------
  --                         The real function starts here!                         --
  ------------------------------------------------------------------------------------
  ------------------------------------------------------------------------------------

  p_data.last_action_tick = game.tick
  local owned_by_player = GCKI_ownership.find(player.index, player.surface)

  -- Look for vehicles at the position the key was used at. If we find one, it will
  -- be valid!
  GCKI.writeDebugNewBlock("Looking for vehicle at click position!")
  local vehicle = GCKI_events.used_key.find_vehicle(player.surface, position, selection)
GCKI.show("Found vehicle", GCKI.argprint(vehicle))
GCKI.show("vehicle force", GCKI.argprint(vehicle and vehicle.force))
GCKI.show("player force", GCKI.argprint(player and player.force))

  -- Found vehicle
  if vehicle then
    GCKI.writeDebug("Player clicked on a vehicle!")
    GCKI_events.used_key.claim_or_toggle_lock(player, vehicle)

  -- Key was used, but not on a vehicle -- player tried to summon his vehicle
  elseif owned_by_player then
    GCKI.writeDebug("Player summoned vehicle!")
    --~ GCKI_events.used_key.summon(player, position)
    GCKI_events.used_key.summon(player, position, mode)

  -- Player doesn't own a vehicle yet
  else
    GCKI.writeDebug("Player has no vehicle yet to lock or summon!")
    GCKI_messages.used_key.info_error_no_vehicle_yet(player)
  end

  GCKI.entered_function("leave")
end


------------------------------------------------------------------------------------
GCKI.entered_file("leave")
return used_key
