-- Runs the production ownership, claiming, locking, and shortcut handlers with
-- small Factorio API substitutes. Engine smoke tests separately check real APIs.
local noop = function() end
local function stub() return setmetatable({}, {__index = function() return noop end}) end
GCKI = stub()
GCKI.argprint = tostring
GCKI.enquote = tostring
GCKI.normalize_position = function(p) return p end
GCKI.prefixed = function(s, prefix) return s:sub(1, #prefix) == prefix end
GCKI.ascertain_player = function(p) return type(p) == 'number' and game.get_player(p) or p end
GCKI.shortcut_name = 'GCKI_carkey'
GCKI.carkey_name = 'GCKI_car-key'
GCKI.ACTION_DELAY = 0
GCKI.EMPTY_TAB = {}
script = {active_mods = {}, raise_event = noop}
if arg[2] ~= 'base-game' then script.active_mods['space-age'] = '2.1.24' end
defines = {events = {script_raised_teleported = 1}, build_check_type = {manual = 1}}
mod = {GCKI_vehicles = {}, owners = {}, lockers = {}, player_data = {}, force_data = {},
       named_vehicles = {by_id = {}, by_name = {}}, vehicles_orig_color = {}}
GCKI_gui = stub()
GCKI_gui_player_vehicles = stub()
GCKI_mods = stub()
GCKI_messages = {used_key = stub()}
local function surface(index, planet, platform)
  return {index = index, name = planet or tostring(index), valid = true,
          planet = planet and {name = planet}, platform = platform,
          is_chunk_generated = function() return true end,
          can_place_entity = function() return true end,
          find_entities_filtered = function() return {} end}
end
local nauvis, vulcanus = surface(1, 'nauvis'), surface(2, 'vulcanus')
local platform = surface(3, nil, {})
local player = {valid = true, index = 1, name = 'one', surface = nauvis,
                physical_surface = nauvis, force = {name = 'player'},
                character = {valid = true, orientation = 0},
                cursor_stack = {valid_for_read = false}}
local other_player = {valid = true, index = 2, name = 'two', surface = nauvis,
                      character = {valid = true}, force = player.force}
local players = {[1] = player, [2] = other_player}
game = {tick = 100, players = players, get_player = function(id) return players[id] end}
player.cursor_stack.set_stack = function(stack)
  player.cursor_stack.name = stack.name
  player.cursor_stack.valid_for_read = true
end
player.cursor_stack.clear = function() player.cursor_stack.valid_for_read = false end
player.set_shortcut_available = function(_, available) player.available = available end
player.clear_cursor = function() player.cursor_stack.clear(); return true end
mod.player_data[1] = {settings = {}}
mod.player_data[2] = {settings = {}}
mod.force_data.player = {show_shortcuts = true}
GCKI_ownership = dofile('mods/GCKI/scripts/ownership.lua')
GCKI_vehicle = dofile('mods/GCKI/scripts/vehicle_functions.lua')
-- Mock entity type checking and visual/UI effects, keeping ownership and lock
-- operations themselves intact.
GCKI_vehicle.is_vehicle = function(v) return type(v) == 'table' and v.valid and v.prototype end
GCKI_vehicle.color_vehicle = noop
GCKI_vehicle.store_orig_color = noop
GCKI_vehicle.can_store_orig_color = function() return true end
GCKI_vehicle.get_occupants = function(car)
  local result = {}
  for role, occupant in pairs(car.seats or {}) do
    result[role] = {entity = occupant, index = occupant.index, is_player = true}
  end
  return next(result) and result or nil
end
GCKI_vehicle.remove_dummy = noop
GCKI_vehicle.locked_icon = noop
GCKI_vehicle.must_remove_vehicle = function() return false end
GCKI_events = dofile('mods/GCKI/scripts/event_handlers.lua')
GCKI_events.helper.need_gui_events = noop
GCKI_events.helper.check_optional_events = noop
GCKI_events.driving = dofile('mods/GCKI/scripts/event_driving.lua')
GCKI_events.used_key = dofile('mods/GCKI/scripts/event_key_shortcut.lua')
GCKI_player = dofile('mods/GCKI/scripts/player_functions.lua')
GCKI_player.is_in_reach = function() return true end
GCKI_custom_input = dofile('mods/GCKI/scripts/custom_inputs.lua')

local function vehicle(id, where, owner)
  local entity = {unit_number = id, valid = true, surface = where, position = {x = 0, y = 0},
                  force = player.force, name = 'car', type = 'car', orientation = 0,
                  prototype = {half_width = 1, half_length = 1, collision_mask = {layers = {}}}}
  entity.seats = {}
  for _, role in ipairs({'driver', 'passenger'}) do
    entity['set_' .. role] = function(occupant)
      local old = entity.seats[role]
      if old and old.vehicle == entity then old.vehicle = nil end
      entity.seats[role] = occupant
      if occupant then occupant.vehicle = entity end
    end
  end
  entity.teleport = function(position, destination)
    entity.position = position
    entity.surface = destination or entity.surface
    return true
  end
  mod.GCKI_vehicles[id] = {entity = entity, owner = owner}
  return entity
end
local function move(where)
  player.surface, player.physical_surface = where, where
  GCKI_events.on_player_changed_surface({player_index = 1})
end
local function claim(v)
  GCKI_vehicle.add_vehicle_owner(v, player, {keep_color = true, keep_gui = true,
                                         keep_owner_on_gui = true, dont_tell_CustomColor = true})
end
local cases = {}
function cases.claims_are_independent_per_planet()
  local a, b = vehicle(11, nauvis), vehicle(22, vulcanus)
  claim(a); claim(b)
  assert(mod.GCKI_vehicles[11].owner == 1 and mod.GCKI_vehicles[22].owner == 1)
  assert(GCKI_ownership.find(1, nauvis) == 11 and GCKI_ownership.find(1, vulcanus) == 22)
end
function cases.reclaim_replaces_only_same_planet_and_preserves_locks()
  local a, b, c = vehicle(11, nauvis), vehicle(22, vulcanus), vehicle(33, nauvis)
  claim(a); claim(b)
  mod.GCKI_vehicles[11].locker = 1
  claim(c)
  assert(not mod.GCKI_vehicles[11].owner and mod.GCKI_vehicles[11].locker == 1)
  assert(mod.GCKI_vehicles[22].owner == 1 and mod.GCKI_vehicles[33].owner == 1)
end
function cases.old_save_claim_needs_no_migration()
  vehicle(11, nauvis, 1); mod.owners[1] = 11
  assert(GCKI_ownership.find(1, nauvis) == 11)
  assert(not GCKI_ownership.find(1, vulcanus))
  claim(vehicle(22, vulcanus))
  assert(mod.GCKI_vehicles[11].owner == 1)
end
function cases.base_game_claim_lock_unlock_and_summon()
  assert(not script.active_mods['space-age'])
  local car = vehicle(11, nauvis)
  claim(car)
  GCKI_events.used_key.claim_or_toggle_lock(player, car)
  assert(not car.disabled_by_script and car.operable and mod.GCKI_vehicles[11].locker == 1)
  GCKI_events.used_key.claim_or_toggle_lock(player, car)
  assert(not car.disabled_by_script and not mod.GCKI_vehicles[11].locker)
  GCKI_events.used_key.summon(player, {x = 5, y = 2})
  assert(car.position.x == 5 and car.surface == nauvis and mod.GCKI_vehicles[11].owner == 1)
end
function cases.base_game_replacing_claim_preserves_old_lock()
  assert(not script.active_mods['space-age'])
  local first, second = vehicle(11, nauvis), vehicle(22, nauvis)
  claim(first)
  GCKI_events.used_key.claim_or_toggle_lock(player, first)
  claim(second)
  assert(not mod.GCKI_vehicles[11].owner and mod.GCKI_vehicles[11].locker == 1)
  assert(not first.disabled_by_script and first.operable and mod.GCKI_vehicles[22].owner == 1)
end
function cases.base_game_keeps_single_global_claim()
  script.active_mods['space-age'] = nil
  local a, b = vehicle(11, nauvis), vehicle(22, vulcanus)
  claim(a); claim(b)
  assert(not mod.GCKI_vehicles[11].owner and mod.GCKI_vehicles[22].owner == 1)
  assert(GCKI_ownership.find(1, nauvis) == 22)
end
function cases.summon_uses_current_planet_without_moving_other_vehicle()
  local a, b = vehicle(11, nauvis), vehicle(22, vulcanus)
  claim(a); claim(b)
  GCKI_events.used_key.summon(player, {x = 5, y = 2})
  assert(a.position.x == 5 and b.position.x == 0 and b.surface == vulcanus)
  move(vulcanus)
  GCKI_events.used_key.summon(player, {x = 7, y = 2})
  assert(a.position.x == 5 and b.position.x == 7 and a.surface == nauvis)
end
function cases.unclaimed_planet_does_not_summon_another_planets_vehicle()
  local a = vehicle(11, nauvis); claim(a); move(vulcanus)
  GCKI_events.used_key.summon(player, {x = 5, y = 2})
  assert(a.surface == nauvis and a.position.x == 0)
end
function cases.platform_blocks_shortcut_hotkey_and_existing_keys()
  local a = vehicle(11, nauvis); claim(a)
  player.cursor_stack.set_stack({name = GCKI.carkey_name})
  move(platform)
  assert(player.available == false and not player.cursor_stack.valid_for_read)
  GCKI_events.on_lua_shortcut({player_index = 1, prototype_name = GCKI.shortcut_name})
  GCKI_custom_input.spawn_carkey({player_index = 1})
  GCKI_events.used_key.key_on_position(player, {x = 5, y = 2})
  GCKI_events.used_key.summon(player, {x = 5, y = 2})
  assert(not player.cursor_stack.valid_for_read and a.position.x == 0 and a.surface == nauvis)
  assert(not mod.player_data[1].last_action_tick)
  move(nauvis)
  assert(player.available == true)
end
function cases.remote_view_from_platform_cannot_bypass_guard()
  player.physical_surface, player.surface = platform, nauvis
  assert(not GCKI_ownership.can_use(player))
  player.physical_surface, player.surface = nauvis, vulcanus
  assert(not GCKI_ownership.can_use(player))
end
function cases.removing_one_claim_preserves_other_planets()
  local a, b = vehicle(11, nauvis), vehicle(22, vulcanus)
  claim(a); claim(b)
  GCKI_vehicle.remove_vehicle_owner(b, player, {keep_vehicle = true, keep_color = true, keep_gui = true})
  assert(mod.GCKI_vehicles[11].owner == 1 and not mod.GCKI_vehicles[22].owner)
  assert(mod.owners[1] == 11 and GCKI_ownership.find(1, nauvis) == 11)
end
function cases.reset_player_removes_all_planet_claims()
  claim(vehicle(11, nauvis)); claim(vehicle(22, vulcanus)); vehicle(33, nauvis, 2)
  local reset = {}
  GCKI_vehicle.reset_vehicle = function(id) reset[id] = true end
  GCKI_vehicle.reset_player_vehicles(player)
  assert(reset[11] and reset[22] and not reset[33])
end
function cases.claims_stay_separate_between_players()
  vehicle(11, nauvis, 2)
  claim(vehicle(22, nauvis))
  assert(mod.GCKI_vehicles[11].owner == 2 and mod.GCKI_vehicles[22].owner == 1)
end
function cases.locking_and_unlocking_are_independent_per_planet()
  local a, b = vehicle(11, nauvis), vehicle(22, vulcanus)
  claim(a); claim(b)
  GCKI_events.used_key.claim_or_toggle_lock(player, a)
  assert(not a.disabled_by_script and a.operable and mod.GCKI_vehicles[11].locker == 1)
  assert(not b.disabled_by_script and not mod.GCKI_vehicles[22].locker)
  move(vulcanus)
  GCKI_events.used_key.claim_or_toggle_lock(player, b)
  assert(mod.GCKI_vehicles[11].locker == 1 and mod.GCKI_vehicles[22].locker == 1)
  move(nauvis)
  GCKI_events.used_key.claim_or_toggle_lock(player, a)
  assert(not mod.GCKI_vehicles[11].locker and mod.GCKI_vehicles[22].locker == 1)
  assert(mod.GCKI_vehicles[11].owner == 1 and mod.GCKI_vehicles[22].owner == 1)
end
function cases.reset_all_visits_all_planets_and_players()
  claim(vehicle(11, nauvis)); claim(vehicle(22, vulcanus)); vehicle(33, nauvis, 2)
  local reset = {}
  GCKI_vehicle.reset_vehicle = function(id) reset[id] = true end
  GCKI_vehicle.reset_all_vehicles()
  assert(reset[11] and reset[22] and reset[33])
end
function cases.invalid_vehicles_and_deleted_surfaces_are_ignored()
  local a = vehicle(11, nauvis, 1)
  a.valid = false
  assert(not GCKI_ownership.find(1, nauvis))
  a.valid = true; nauvis.valid = false
  assert(not GCKI_ownership.find(1, nauvis))
end
function cases.custom_planets_and_nonplanet_surfaces_have_separate_claims()
  local custom = surface(4, 'modded-planet')
  local other = surface(5)
  claim(vehicle(11, custom)); claim(vehicle(22, other))
  assert(GCKI_ownership.find(1, custom) == 11 and GCKI_ownership.find(1, other) == 22)
end
function cases.disabling_space_age_reconciles_to_one_global_claim()
  claim(vehicle(11, nauvis)); claim(vehicle(22, vulcanus))
  script.active_mods['space-age'] = nil
  GCKI_ownership.reconcile()
  assert(mod.GCKI_vehicles[11].owner == 1 and not mod.GCKI_vehicles[22].owner)
end
function cases.moved_vehicle_cannot_create_two_claims_on_one_planet()
  local a, b = vehicle(11, nauvis), vehicle(22, vulcanus)
  claim(a); claim(b); b.surface = nauvis
  GCKI_ownership.reconcile()
  assert(mod.GCKI_vehicles[11].owner == 1 and not mod.GCKI_vehicles[22].owner)
end
function cases.lock_owner_can_enter_drive_and_open_inventory_without_unlocking()
  local car = vehicle(11, nauvis); claim(car)
  GCKI_events.used_key.toggle_lock(player, car)
  car.set_driver(player)
  mod.player_data[1].last_action_tick = game.tick
  mod.player_data[1].skip_state_change = 2
  GCKI_events.on_player_driving_changed_state{player_index = 1, entity = car, tick = game.tick}
  assert(car.seats.driver == player and player.vehicle == car)
  assert(not car.disabled_by_script and car.operable and not car.minable_flag)
  assert(mod.GCKI_vehicles[11].locker == 1)
  player.opened = car
  GCKI_events.on_gui_opened{player_index = 1, entity = car}
  assert(player.opened == car and mod.GCKI_vehicles[11].locker == 1)
end
function cases.lock_allows_other_passengers_but_rejects_other_drivers()
  local car = vehicle(11, nauvis); claim(car)
  GCKI_events.used_key.toggle_lock(player, car)
  for _, role in ipairs({'driver', 'passenger'}) do
    car.set_driver(nil); car.set_passenger(nil)
    car['set_' .. (role == 'driver' and 'passenger' or 'driver')](player)
    car['set_' .. role](other_player)
    mod.player_data[2].last_action_tick = game.tick
    mod.player_data[2].skip_state_change = 2
    GCKI_events.on_player_driving_changed_state{player_index = 2, entity = car, tick = game.tick}
    if role == 'driver' then
      assert(not car.seats.driver and not other_player.vehicle)
    else
      assert(car.seats.passenger == other_player and other_player.vehicle == car)
    end
    assert(player.vehicle == car and mod.GCKI_vehicles[11].locker == 1)
  end
end
function cases.locking_occupied_vehicle_keeps_owner_and_closes_other_inventory()
  local car = vehicle(11, nauvis); claim(car)
  car.set_driver(player); car.set_passenger(other_player)
  player.opened = car; other_player.opened = car
  GCKI_events.used_key.toggle_lock(player, car)
  assert(car.seats.driver == player and car.seats.passenger == other_player)
  assert(player.opened == car and not other_player.opened)
end
function cases.lock_redirects_other_driver_to_an_available_passenger_seat()
  local car = vehicle(11, nauvis); claim(car)
  GCKI_events.used_key.toggle_lock(player, car)
  car.set_driver(other_player)
  GCKI_events.on_player_driving_changed_state{player_index = 2, entity = car, tick = game.tick}
  assert(not car.seats.driver and car.seats.passenger == other_player)
  assert(other_player.vehicle == car and mod.GCKI_vehicles[11].locker == 1)
end
function cases.lock_allows_unattended_passenger_but_rejects_switching_to_driver()
  local car = vehicle(11, nauvis); claim(car)
  GCKI_events.used_key.toggle_lock(player, car)
  car.set_passenger(other_player)
  GCKI_events.on_player_driving_changed_state{player_index = 2, entity = car, tick = game.tick}
  assert(car.seats.passenger == other_player and other_player.vehicle == car)
  car.set_passenger(nil); car.set_driver(other_player)
  mod.player_data[2].last_action_tick = game.tick
  mod.player_data[2].skip_state_change = 2
  GCKI_events.on_player_driving_changed_state{player_index = 2, entity = car, tick = game.tick}
  assert(not car.seats.driver and car.seats.passenger == other_player and other_player.vehicle == car)
  assert(mod.GCKI_vehicles[11].locker == 1 and not car.minable_flag)
end
function cases.lock_rejects_other_inventory_but_unlock_restores_public_access()
  local car = vehicle(11, nauvis); claim(car)
  GCKI_events.used_key.toggle_lock(player, car)
  other_player.opened = car
  GCKI_events.on_gui_opened{player_index = 2, entity = car}
  assert(not other_player.opened)
  GCKI_events.used_key.toggle_lock(player, car)
  other_player.opened = car
  GCKI_events.on_gui_opened{player_index = 2, entity = car}
  assert(other_player.opened == car and GCKI_vehicle.can_access_vehicle(car, other_player))
  assert(car.minable_flag and not car.disabled_by_script and car.operable)
end
function cases.lock_holder_keeps_access_after_claiming_a_replacement()
  local first, second = vehicle(11, nauvis), vehicle(22, nauvis)
  claim(first); GCKI_events.used_key.toggle_lock(player, first); claim(second)
  assert(not mod.GCKI_vehicles[11].owner and mod.GCKI_vehicles[11].locker == 1)
  first.set_driver(player)
  GCKI_vehicle.enforce_vehicle_lock(first)
  assert(first.seats.driver == player and GCKI_vehicle.can_access_vehicle(first, player))
  assert(not GCKI_vehicle.can_access_vehicle(first, other_player))
end
assert(cases[arg[1]], 'Unknown runtime case: ' .. tostring(arg[1]))()
print('[PASS] GCKI: ' .. arg[1]:gsub('_', ' '))
