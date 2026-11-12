GCKI.entered_file()

------------------------------------------------------------------------------------
------------------------------------------------------------------------------------
--                                 LOCAL DEFINITIONS                              --
------------------------------------------------------------------------------------
------------------------------------------------------------------------------------

--~ -- If the distance between owner and vehicle is greater than this value, we will
--~ -- output messages for the owner. (Default: 32 tiles, i.e. 1 chunk)
--~ local message_owner_distance = GCKI.message_owner_distance

local driving_state = {}




------------------------------------------------------------------------------------
------------------------------------------------------------------------------------
--                                  LOCAL FUNCTIONS                               --
------------------------------------------------------------------------------------
------------------------------------------------------------------------------------

-- Vehicle is owned by player
local function player_is_owner(data)
  GCKI.entered_function({data})

  GCKI.assert(data, "table")

  local player          = data.player           -- Player whose driving state changed
  local vehicle         = data.vehicle          -- Vehicle the player entered or left
  local occupants       = data.occupants        -- Optional
  local locker          = data.locker           -- Optional
GCKI.show("player", GCKI.argprint(player))
GCKI.show("vehicle", GCKI.argprint(vehicle))
GCKI.show("occupants", GCKI.argprint(occupants))
GCKI.show("locker", GCKI.argprint(locker))
  -- A lock restricts other players, not its owner.
  if locker then
    GCKI_vehicle.enforce_vehicle_lock(vehicle)
    return
  end

  -- Vehicle is unlocked, somebody is inside.
  if occupants then
    GCKI.argprint("%s has entered a vehicle with occupants!",
                  {GCKI.argprint(player)})
    local driver        = occupants.driver and occupants.driver.entity
    local passenger     = occupants.passenger and occupants.passenger.entity
GCKI.show("driver", GCKI.argprint(driver))
GCKI.show("passenger", GCKI.argprint(passenger))

    -- We couldn't have entered a vehicle that already had driver and passenger, so if
    -- the vehicle already has a driver, we can safely replace him and make him passenger.
    if player == passenger then
      -- Make owner driver
      vehicle.set_driver(player)

      -- Only act for real players, ignore dummy characters!
      if driver and driver.valid then
        GCKI_messages.driving_state.info_role_of_occupant(player, vehicle, "driver")
        GCKI_messages.driving_state.info_role_of_other_occupant(player, driver.name, "passenger")

        -- Make previous driver passenger
        vehicle.set_passenger(driver)
        GCKI_messages.driving_state.info_owner_is_new_driver(driver, vehicle, player.name)
        GCKI_messages.driving_state.info_role_of_occupant(driver, vehicle, "passenger")
      end

    -- Player is owner and driver
    elseif player == driver then
      if passenger then
        GCKI_messages.driving_state.info_owner_is_new_driver(passenger, vehicle, player.name)
      end

    -- Player is owner and has left
    else
      -- Tell owner who is left in the vehicle, and remind him to lock it.
      GCKI_messages.driving_state.info_owner_left_vehicle(player, vehicle, occupants)

      -- Inform the remaining player that owner has left
      GCKI.output(driver or passenger, {"GCKI-messages.occupant-owner_left",
                                        player.name, GCKI.loc_name(vehicle)})
    end

  -- Vehicle is unlocked, nobody is inside (player left vehicle).
  else
    GCKI.writeDebug("%s has left vehicle. It's now unlocked and unoccupied!",
                    {GCKI.argprint(player)})
    -- Tell owner who is left in the vehicle, and remind him to lock it.
    GCKI_messages.driving_state.info_owner_left_vehicle(player, vehicle, occupants)

  end

end


-- Reject unauthorized occupants without removing the owner from either seat.
local function eject_from_locked(data)
  GCKI_vehicle.enforce_vehicle_lock(data.vehicle)
end


-- Vehicle was unlocked but somebody was already inside
local function unlocked_had_occupants(data)
  GCKI.entered_function({data})

  local player          = data.player           -- Player whose driving state changed
  local vehicle         = data.vehicle          -- Vehicle the player entered or left
  local occupants       = data.occupants        -- Optional
  local owner           = data.owner            -- Optional
  --~ local locker          = data.locker           -- Optional

  local driver, passenger
  if occupants then
    driver = occupants.driver and occupants.driver.is_player and occupants.driver.entity
    passenger = occupants.passenger and occupants.passenger.is_player and occupants.passenger.entity
  end
GCKI.show("driver", GCKI.argprint(driver))
GCKI.show("passenger", GCKI.argprint(passenger))

  --~ local msg, print_to

  -- If vehicle has an owner, tell him who's inside it now
  GCKI_messages.driving_state.info_tell_owner_occupant_entered(data)

  -- Player has entered the vehicle and is driver
  if player == driver then
GCKI.writeDebug("Player is driver!")
    -- Inform occupants about players inside the vehicle
    GCKI_messages.driving_state.info_player_entered_vehicle(vehicle, occupants)

    -- Warn new driver that the vehicle may be summoned by its owner
    GCKI_messages.driving_state.info_owner_can_summon_vehicle(data, not not owner)

  -- Player has entered the vehicle and is passenger
  elseif player == passenger then
GCKI.writeDebug("Player is passenger!")
    -- There is a human driver
    if driver then
GCKI.writeDebug("There is a driver!")
      -- Message to driver (unless the owner is driving)
      if driver ~= owner then
        GCKI_messages.driving_state.info_role_of_other_occupant(driver, player.name, "passenger")
      end

      -- Messages to passenger:
      -- Owner is driver
      if driver == owner then
        GCKI_messages.driving_state.info_owner_is_new_driver(player, vehicle, owner.name)

      -- Another player is driver
      elseif occupants.driver.is_player then
        GCKI_messages.driving_state.info_role_of_other_occupant(player, driver.name, "driver")
      end
    end

    -- Tell player that he is the passenger
    GCKI.output(player, {"GCKI-messages.occupant-role",
                          {"GCKI-words.passenger"}, GCKI.loc_name(vehicle)})
    -- Warn player that vehicle may be summoned by owner (unless owner is the driver)
    GCKI_messages.driving_state.info_owner_can_summon_vehicle(data, not (driver and driver == owner))

  -- Player has left the vehicle
  else
    -- Inform vehicle owner if he's more than a chunk away from the vehicle
    GCKI_messages.driving_state.info_tell_owner_occupant_left(data)

    -- If the vehicle can be mined and nobody is inside, the player can steal it!
    if not GCKI_messages.driving_state.info_player_can_steal_vehicle(data) and
        -- After player left, one of driver or passenger could still be inside.
        (passenger and passenger ~= player) or
        (driver and driver ~= player and driver ~= owner) then

      GCKI_messages.driving_state.info_player_left_vehicle(player, vehicle, occupants)
    end
  end
  GCKI.entered_function("leave")
end


-- Vehicle is owned by another player or has no owner
local function no_or_other_owner(data)
  GCKI.entered_function({data})

  GCKI.assert(data, "table")

  local player          = data.player           -- Player whose driving state changed
  local vehicle         = data.vehicle          -- Vehicle the player entered or left
  local occupants       = data.occupants        -- Optional
  local owner           = data.owner            -- Optional
  local locker          = data.locker           -- Optional

  local driver, passenger
  if occupants then
    driver = occupants.driver and occupants.driver.is_player and occupants.driver.entity
    passenger = occupants.passenger and occupants.passenger.is_player and occupants.passenger.entity
  end

  --~ local msg

  GCKI.writeDebug("This %s belongs to %s!",
                  {GCKI.loc_name(vehicle), owner and owner.name or "nobody"}, "line")
  -- If vehicle is locked, only its owner or locker may enter it!
  if locker then
    eject_from_locked(data)

  -- Vehicle is not locked, but somebody else could be the owner!
  -- The player should be aware that the vehicle can be summoned by the owner.
  -- The owner should know that somebody else is using his vehicle.
  else
    -- Vehicle has driver and/or passenger and is unlocked
    if driver or passenger then
      unlocked_had_occupants(data)

    -- Vehicle has an owner and is unlocked; player has left the vehicle
    else
      -- Tell owner that player has left the vehicle
      GCKI_messages.driving_state.info_tell_owner_occupant_left(data)

      -- If vehicle can be mined and nobody is inside, the player can steal it
      if not GCKI_messages.driving_state.info_player_can_steal_vehicle(data) and (
        -- If there's still somebody inside, tell them that player left
        (passenger and passenger ~= player) or
        (driver and driver ~= player and driver ~= owner)
      ) then
        GCKI_messages.driving_state.info_player_left_vehicle(player, vehicle, occupants)
      end
    end
  end

end




------------------------------------------------------------------------------------
------------------------------------------------------------------------------------
--                         DRIVING STATE OF A PLAYER CHANGED                      --
------------------------------------------------------------------------------------
------------------------------------------------------------------------------------
driving_state.locked_or_owned_vehicle = function(data)
  GCKI.entered_function({data})

  GCKI.assert(data, "table")

  local player          = data.player           -- Player whose driving state changed
  local vehicle         = data.vehicle          -- Vehicle the player entered or left
  local owner           = data.owner            -- Player who owns a vehicle (optional)

GCKI.show("Owner", owner and owner.name or "no owner")

  -- Vehicle is owned by player
  if player == owner then
    GCKI.writeDebug("This is your own %s!", {GCKI.loc_name(vehicle)}, "line")
    player_is_owner(data)

  -- Vehicle is owned by another player or has no owner
  else
    GCKI.writeDebug("This %s belongs to %s!", {GCKI.loc_name(vehicle), owner and owner.name or "nobody"}, "line")
    no_or_other_owner(data)
  end

  GCKI.entered_function("leave")
end


-- Vehicle is unlocked and has no owner
driving_state.unlocked_no_owner = function(data)
  GCKI.entered_function({data})

  GCKI.assert(data, "table")

  local player          = data.player           -- Player whose driving state changed
  local vehicle         = data.vehicle          -- Vehicle the player entered or left
  local occupants       = data.occupants        -- Players who drive in a vehicle

  local driver, passenger
  if occupants then
    driver = occupants.driver and occupants.driver.is_player and
                                  occupants.driver.entity
    passenger = occupants.passenger and occupants.passenger.is_player and
                                        occupants.passenger.entity
  end

  --~ local msg

  -- Player has entered the vehicle, both driver and passenger are present
  if driver and passenger then
    GCKI_messages.driving_state.info_player_entered_vehicle(vehicle, occupants)

  -- Either driver or passenger are present
  elseif driver or passenger then
    -- Player entered an empty vehicle
    --~ if (player == driver) or (passenger == driver) then
    if (player == driver) or (player == passenger) then
GCKI.writeDebug("%s has entered %s!", {GCKI.argprint(player), GCKI.argprint(vehicle)})
    -- Player left vehicle, but there's still somebody inside
    else
      GCKI_messages.driving_state.info_player_left_vehicle(player, vehicle, occupants)
    end
  -- Nobody is in the vehicle
  else
    GCKI.hint(player, {"GCKI-messages.hints-claim_vehicle", GCKI.loc_name(vehicle)})
  end

  GCKI.entered_function("leave")
end


------------------------------------------------------------------------------------
GCKI.entered_file("leave")
return driving_state
