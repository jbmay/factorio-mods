GCKI.entered_file()

------------------------------------------------------------------------------------
------------------------------------------------------------------------------------
--                                 LOCAL DEFINITIONS                              --
------------------------------------------------------------------------------------
------------------------------------------------------------------------------------

local messages = {}
messages.used_key = {}
messages.driving_state = {}


-- Print info to owner if vehicle is more than one chunk away
local function must_print_to_owner(owner, vehicle)
  GCKI.entered_function({owner, vehicle})

  owner = GCKI.ascertain_player(owner)

  local ret = false

  if owner and owner.valid and GCKI_vehicle.is_vehicle(vehicle) then
    --~ ret = GCKI.distance_exceeds(owner.position, vehicle.position, GCKI.message_owner_distance)
    ret = GCKI_calc.distance_exceeds(owner.position, vehicle.position, GCKI.message_owner_distance)
  end

  return ret
end

------------------------------------------------------------------------------------
------------------------------------------------------------------------------------
--                            SEND MESSAGES TO PLAYERS                            --
------------------------------------------------------------------------------------
------------------------------------------------------------------------------------


------------------------------------------------------------------------------------
--        Player used the key shortcut to claim, lock, or summon a vehicle        --
------------------------------------------------------------------------------------
-- Info: Somebody tried to steal a vehicle!
messages.used_key.info_player_not_owner = function(owner, thief, vehicle)
GCKI.entered_function({owner, thief})
  if GCKI.ascertain_player(owner) and GCKI.ascertain_player(thief) then
    local v_name = GCKI.loc_name(vehicle)
    -- Message to owner: "[Player] has tried to take your [vehicle]!"
    GCKI.hint(owner, {"GCKI-messages.owner-thief", thief.name, v_name})

    -- Message to player: "This [vehicle] is owned by [owner]."
    GCKI.output(thief, {"GCKI-messages.vehicle-owner", v_name, owner.name})
  end
  return true
end


-- Info: Owner locked vehicle, occupants are ejected
messages.used_key.info_eject_occupants_locked = function(owner, occupant, vehicle)
GCKI.entered_function({owner, occupant, vehicle})
  if owner == occupant then
    GCKI.hint(owner, {"GCKI-messages.hints-eject_owner", GCKI.loc_name(vehicle)})
  elseif occupant then
    GCKI.hint(occupant, {"GCKI-messages.occupant-locked_vehicle_eject",
                          owner.name, GCKI.loc_name(vehicle)})
  end
  return true
end


-- Info: Lock state (owner)
messages.used_key.info_owner_locked_state = function(owner, locker, vehicle)
GCKI.entered_function({owner, locker, vehicle})
    local locked = locker and {"GCKI-states.locked"} or {"GCKI-states.unlocked"}
    local how_to = locker and "unlock" or "lock"

    GCKI.output(owner, {"GCKI-messages.owner-vehicle_lock_state", GCKI.loc_name(vehicle), locked})
    GCKI.hint(owner, {"GCKI-messages.hints-how_to_"..how_to, GCKI.loc_name(vehicle)})
  return true
end


-- Info: Can't claim occupied vehicle!
messages.used_key.info_cant_claim_occupied = function(player, vehicle, occupants)
GCKI.entered_function({player, vehicle})
  if player and vehicle then
    GCKI.output(player, {"GCKI-messages.vehicle-occupied",
                          --~ GCKI.loc_name(vehicle), GCKI_vehicle.get_occupant_names(vehicle)})
                          GCKI.loc_name(vehicle), GCKI_vehicle.get_occupant_names(vehicle, occupants)})
    GCKI.hint(player, {"GCKI-messages.player-find_other"})
  end
  return true
end


-- Info: Can't claim vehicle that has been locked by another player
messages.used_key.info_cant_claim_locked = function(player, locker, vehicle)
GCKI.entered_function({player, locker, vehicle})
  GCKI.output(player, {"GCKI-messages.player-vehicle_locked", GCKI.loc_name(vehicle), locker.name})
  return true
end


-- Info: Player has reclaimed a vehicle he previously locked
messages.used_key.info_claimed_locked_vehicle = function(player, vehicle)
GCKI.entered_function({player, vehicle})
  GCKI.output(player, {"",
    {"GCKI-messages.player-new_vehicle", GCKI.loc_name(vehicle)},
    " ",
    {"GCKI-messages.vehicle-lock_state", GCKI.loc_name(vehicle), {"GCKI-states.locked"}}
  })
  GCKI.hint(player, {"GCKI-messages.hints-how_to_unlock", GCKI.loc_name(vehicle)})
  return true
end


-- Info: Player has claimed an unlocked vehicle
--~ messages.used_key.info_claimed_unlocked_vehicle = function(player, vehicle)
--~ GCKI.entered_function({player, vehicle})
  --~ GCKI.output(player, {"GCKI-messages.player-new_vehicle", GCKI.loc_name(vehicle)})
  --~ GCKI.hint(player, {"GCKI-messages.hints-new_vehicle", GCKI.loc_name(vehicle)})
  --~ GCKI.hint(player, {"GCKI-messages.hints-how_to_lock", GCKI.loc_name(vehicle)})
  --~ return true
--~ end
messages.used_key.info_claimed_unlocked_vehicle = function(player, vehicle, stolen)
GCKI.entered_function({player, vehicle, stolen})
  if vehicle and vehicle.valid and stolen then
    GCKI.output(player, {
      "GCKI-messages.player-steals_vehicle",
      GCKI.loc_name(vehicle),
      vehicle.force.name,
    })
  else
    GCKI.output(player, {"GCKI-messages.player-new_vehicle", GCKI.loc_name(vehicle)})
  end
  GCKI.hint(player, {"GCKI-messages.hints-new_vehicle", GCKI.loc_name(vehicle)})
  GCKI.hint(player, {"GCKI-messages.hints-how_to_lock", GCKI.loc_name(vehicle)})
  return true
end


-- Info: Player has claimed an unlocked vehicle from another force
messages.used_key.info_claimed_unlocked_vehicle_other_force = function(player, vehicle)
GCKI.entered_function({player, vehicle})
  local stolen = true
  messages.used_key.info_claimed_unlocked_vehicle(player, vehicle, stolen)
  --~ vehicle.force = player.force
  return true
end


-- Info: Teleported on same surface
messages.used_key.info_teleport_player_same_surface = function(owner, player, vehicle)
GCKI.entered_function({owner, player, vehicle})
  GCKI.output(player, {"GCKI-messages.occupant-summoned_by", GCKI.loc_name(vehicle), owner.name})
  return true
end


-- Info: Teleport occupants to other surface
messages.used_key.info_teleport_player_other_surface = function(owner, player, vehicle)
GCKI.entered_function({owner, player, vehicle})
  GCKI.output(player, {"GCKI-messages.occupant-summoned_to_surface",
    owner.name, GCKI.loc_name(vehicle), owner.surface.name, owner.position})
  GCKI.output(player, {"GCKI-messages.occupant-summoned_moved", GCKI.loc_name(vehicle)})
  GCKI.hint(player, {"GCKI-messages.hints-check_surface_setting",
                      {"mod-setting-name.GCKI-teleport_to_other_surface"} })
  return true
end


-- Info: Eject occupants before teleporting vehicle to other surface
messages.used_key.info_eject_occupants_teleport = function(owner, player, vehicle)
GCKI.entered_function({owner, player, vehicle})
  GCKI.output(player, {"GCKI-messages.occupant-summoned_to_surface",
    owner.name, GCKI.loc_name(vehicle), owner.surface.name, owner.position})
  GCKI.output(player, {"GCKI-messages.occupant-summoned_eject",
    GCKI.loc_name(vehicle), vehicle.surface.name, vehicle.position})
  GCKI.hint(player, {"GCKI-messages.hints-check_surface_setting",
                      {"mod-setting-name.GCKI-teleport_to_other_surface"} })
  return true
end


-- Info: Summoned vehicle has arrived
messages.used_key.info_summoned_vehicle_arrived = function(player, vehicle)
GCKI.entered_function({player, vehicle})
  GCKI.output(player, {"GCKI-messages.hints-arrived", GCKI.loc_name(vehicle)})
  return true
end


-- Info: Can't summon vehicle to a position that's not within the owner's reach
messages.used_key.info_summoned_error_out_of_reach = function(owner, vehicle)
GCKI.entered_function({owner, vehicle})
  GCKI.output(owner, {"GCKI-messages.owner-far_place", GCKI.loc_name(vehicle)})
  GCKI.hint(owner, {"GCKI-messages.hints-far_place", GCKI.loc_name(vehicle)})
  return false
end


-- Info: Can't summon vehicle to a position where it can't be placed
messages.used_key.info_summoned_error_cant_place = function(owner, vehicle)
GCKI.entered_function({owner, vehicle})
  GCKI.output(owner, {"GCKI-messages.owner-wrong_place", GCKI.loc_name(vehicle)})
  GCKI.hint(owner, {"GCKI-messages.hints-wrong_place", GCKI.loc_name(vehicle)})
  return false
end


-- Info: Player must first claim a vehicle
messages.used_key.info_error_no_vehicle_yet = function(player)
GCKI.entered_function({player})
  GCKI.output(player, {"GCKI-messages.player-vehicle_not_yet"})
  GCKI.hint(player, {"GCKI-messages.hints-use_key"})
  return true
end



------------------------------------------------------------------------------------
--                        Player entered or left a vehicle                        --
------------------------------------------------------------------------------------
-- Info: Inform other occupant that player entered vehicle
messages.driving_state.info_player_entered_vehicle = function(vehicle, occupants)
  GCKI.entered_function({vehicle, occupants})
GCKI.show("occupants", occupants)
GCKI.show("table_size(occupants)", table_size(occupants))

  local ret = false

  -- We only need to output something if another player is in the vehicle!
  if occupants and table_size(occupants) > 1 then
    local msg = {
      "GCKI-messages.vehicle-occupied",
      GCKI.loc_name(vehicle),
      GCKI_vehicle.get_occupant_names(vehicle, occupants)
    }

    -- Will change "role" to real role of occupant when printing!
    local hint = {"GCKI-messages.occupant-role", "role", GCKI.loc_name(vehicle)}

    -- Inform occupants
    for role, occupant in pairs(occupants) do
      -- Tell player who is in the vehicle
      GCKI.output(occupant.entity, msg)

      -- Tell player his new role
      hint[2] = {"GCKI-words."..role}
      GCKI.hint(occupant.entity, hint)
    end
    ret = true
  end

  return ret
end


-- Info: Inform remaining occupant that player left vehicle
messages.driving_state.info_player_left_vehicle = function(player, vehicle, occupants)
GCKI.entered_function({player, vehicle, occupants})

  local driver    = occupants and occupants.driver and occupants.driver.is_player and
                      occupants.driver.entity
  local passenger = occupants and occupants.passenger and occupants.passenger.is_player and
                      occupants.passenger.entity
  local ret = false
  local print_to, role

  -- Driver has left
  if passenger and player ~= passenger then
    print_to, role = passenger, "driver"
  -- Passenger has left
  elseif driver and player ~= driver then
    print_to, role = driver, "passenger"
  end
GCKI.show("print_to", print_to)
GCKI.show("role", role)
  if print_to and print_to.valid then
    GCKI.output(print_to, {"GCKI-messages.occupant-player_left",
                            player.name, GCKI.loc_name(vehicle), {"GCKI-words."..role}})
    ret = true
  end

  return ret
end


-- Info: Tell owner if there's still anyone in the vehicle he just left, and remind
-- him to lock the vehicle.
messages.driving_state.info_owner_left_vehicle = function(print_to, vehicle, occupants)
GCKI.entered_function({print_to, vehicle, occupants})

  local driver    = occupants and occupants.driver and occupants.driver.is_player and
                      occupants.driver.entity
  local passenger = occupants and occupants.passenger and occupants.passenger.is_player and
                      occupants.passenger.entity

  -- Inform owner
  if print_to and print_to.valid and vehicle and vehicle.valid then
    GCKI.output(print_to, {"GCKI-messages.owner_left_own", GCKI.loc_name(vehicle)})
    if driver or passenger then
        GCKI.output(print_to, {"GCKI-messages.vehicle-occupied", GCKI.loc_name(vehicle),
                            GCKI_vehicle.get_occupant_names(vehicle, occupants)})
    end
    GCKI.hint(print_to, {"GCKI-messages.hints-lock_vehicle", GCKI.loc_name(vehicle)})
    return true
  end
end


-- Info: Tell occupant whether he's driver or passenger in this vehicle
messages.driving_state.info_role_of_occupant = function(print_to, vehicle, role)
GCKI.entered_function({print_to, vehicle, role})

  local ret = false
  if print_to and print_to.valid and vehicle.valid then
    local msg = {"GCKI-messages.occupant-role", {"GCKI-words."..role}, GCKI.loc_name(vehicle)}
    GCKI.hint(print_to, msg)
    ret = true
  end
  return ret
end


-- Info: Inform somebody else whether an occupant is driver or passenger
messages.driving_state.info_role_of_other_occupant = function(print_to, other, role)
GCKI.entered_function({print_to, other, role})

  local ret = false
  if print_to and print_to.valid then
    local msg = {"GCKI-messages.occupant-role_other", other, {"GCKI-words."..role}}
    GCKI.hint(print_to, msg)
    ret = true
  end
  return ret
end


-- Info: Inform other occupant that owner is now driver of the vehicle
messages.driving_state.info_owner_is_new_driver = function(print_to, vehicle, owner)
GCKI.entered_function({print_to, vehicle, owner})

  local ret = false
  if print_to and print_to.valid and vehicle.valid then
    local msg = {"GCKI-messages.occupant-owner_is_driver", GCKI.loc_name(vehicle), owner}
    GCKI.hint(print_to, msg)
    ret = true
  end
  return ret
end


-- Info: Tell occupant who's the owner of the vehicle, and warn him that owner can
-- summon the vehicle
messages.driving_state.info_owner_can_summon_vehicle = function(data, condition)
GCKI.entered_function({data, condition})

  local ret = false

  if condition then

    local print_to = GCKI.ascertain_player(data.player)
    local owner_name = data.owner and data.owner.valid and data.owner.name
    local vehicle_name = data.vehicle and GCKI.loc_name(data.vehicle)
GCKI.show("print_to", print_to)
GCKI.show("owner_name", owner_name)
GCKI.show("vehicle_name", vehicle_name)
    if not (print_to and print_to.valid) then
      GCKI.arg_err(print_to, "player specification")
    elseif not (owner_name) then
      GCKI.arg_err(data.owner, "player specification")
    end

    GCKI.output(print_to, {"GCKI-messages.vehicle-owner", vehicle_name, owner_name})
    GCKI.hint(print_to, {"GCKI-messages.hints-warn_guest", vehicle_name, owner_name})
    ret = true
  end

  return ret
end


-- Info: Tell owner that somebody entered his vehicle
messages.driving_state.info_tell_owner_occupant_entered = function(data)
GCKI.entered_function({data})

  GCKI.assert(data, "table")
  local owner = data.owner
  local player = data.player
  local vehicle = data.vehicle
  local occupants = data.occupants

  local ret = false
  if must_print_to_owner(owner, vehicle) then
    local v_name = GCKI.loc_name(vehicle)
    -- Who entered the vehicle?
    GCKI.output(owner, {"GCKI-messages.owner-enter_other", player.name, v_name})
    -- Who else is in the vehicle?
    GCKI.output(owner, {"GCKI-messages.vehicle-occupied", v_name,
                        GCKI_vehicle.get_occupant_names(vehicle, occupants)})
    ret = true
  end

  return ret
end


-- Info: Tell owner that occupant left his vehicle
messages.driving_state.info_tell_owner_occupant_left = function(data)
GCKI.entered_function({data})

  GCKI.assert(data, "table")
  local owner = data.owner
  local player = data.player
  local vehicle = data.vehicle

  local ret = false

  if must_print_to_owner(owner, vehicle) then
    GCKI.output(owner, {"GCKI-messages.owner-occupant_left",
                        player.name, GCKI.loc_name(vehicle)})
    ret = true
  end

  return ret
end


-- Tell player who left an unlocked owned vehicle that he can steal it
messages.driving_state.info_player_can_steal_vehicle = function(data)
GCKI.entered_function({data})

  GCKI.assert(data, "table")
  local owner = data.owner
  local player = data.player
  local vehicle = data.vehicle
  local occupants = data.occupants
  local driver, passenger

  if occupants then
    driver = occupants.driver and occupants.driver.is_player and occupants.driver.entity
    passenger = occupants.passenger and occupants.passenger.is_player and occupants.passenger.entity
  end

  local ret = false

  if vehicle and vehicle.valid and vehicle.minable and owner and not (driver or passenger) then
    GCKI.output(player, {"GCKI-messages.player-steal_vehicle", GCKI.loc_name(vehicle), owner.name})
    ret = true
  end

  return ret
end


------------------------------------------------------------------------------------
return messages
