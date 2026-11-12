-- Loaded into the installed mod only for native --test-save runs. These tests use
-- the production handlers and real Factorio players, surfaces, entities and saves.
return function(context)
  local results = {}
  local function case(name, run)
    local ok, err = pcall(run)
    results[#results + 1] = {name = name, status = ok and 'passed' or 'failed'}
    helpers.write_file('mod-ci-' .. context.suite .. '-' .. context.mode .. '.json',
                       helpers.table_to_json(results))
    if not ok then error(name .. ': ' .. tostring(err)) end
  end

  local function move(player, surface)
    assert(player.teleport({0, 0}, surface), 'player teleport failed')
  end

  -- Scripted clicks execute in one tick, so reset only the input cooldown between
  -- clicks. Vehicle discovery, reach/collision checks and all mutations stay real.
  local function click(player, position)
    mod.player_data[player.index].last_action_tick = nil
    GCKI_events.used_key.key_on_position(player, position)
  end

  local function prepare_surface(surface)
    surface.request_to_generate_chunks({0, 0}, 1)
    surface.force_generate_chunk_requests()
    for _, entity in pairs(surface.find_entities_filtered{area = {{-12, -12}, {12, 12}}}) do
      if entity.type ~= 'character' then entity.destroy() end
    end
    local tiles = {}
    for x = -12, 12 do for y = -12, 12 do
      tiles[#tiles + 1] = {name = 'grass-1', position = {x, y}}
    end end
    surface.set_tiles(tiles)
  end

  local function spawn(player, surface, position)
    return assert(surface.create_entity{name = 'car', position = position or {3, 0}, force = player.force})
  end

  local function assert_claim(player, car)
    assert(GCKI_vehicle.get_owner(car) == player, 'vehicle owner was not preserved')
    assert(remote.call('gcki-continued', 'owned_by_player', player) == car.unit_number,
           'current vehicle lookup selected another vehicle')
  end

  local function assert_locked(player, car)
    assert(GCKI_vehicle.get_locker(car) == player, 'vehicle locker was not preserved')
    assert(car.disabled_by_script and not car.operable and not car.minable_flag,
           'locked vehicle flags were not preserved')
  end

  local function lock_unlock(player, car)
    click(player, car.position)
    assert_locked(player, car)
    click(player, car.position)
    assert(not GCKI_vehicle.get_locker(car) and not car.disabled_by_script and
           car.operable and car.minable_flag, 'vehicle did not unlock')
    click(player, car.position)
    assert_locked(player, car)
  end

  local function snapshot(state, car, owner, locker)
    state.cars[#state.cars + 1] = {entity = car, id = car.unit_number, surface = car.surface,
      x = car.position.x, y = car.position.y, owner = owner, locker = locker}
  end

  local function base_game(player, state)
    assert(not script.active_mods['space-age'], 'base-game suite must run without Space Age')
    local nauvis = game.surfaces.nauvis
    prepare_surface(nauvis); move(player, nauvis)
    local first = spawn(player, nauvis)
    case('claim, lock and unlock a car without Space Age', function()
      click(player, first.position); assert_claim(player, first); lock_unlock(player, first)
    end)
    local second = spawn(player, nauvis, {7, 0})
    case('replacing the single global claim preserves the old lock', function()
      click(player, second.position)
      assert_claim(player, second)
      assert(not GCKI_vehicle.get_owner(first)); assert_locked(player, first)
      lock_unlock(player, second)
    end)
    case('summon the current global vehicle locally', function()
      click(player, {x = 0, y = 4})
      assert(second.position.x == 0 and second.position.y == 4)
      assert(first.position.x == 3 and first.position.y == 0)
    end)
    local other = game.create_surface('gcki-test-other-surface', {autoplace_controls = {}})
    prepare_surface(other)
    case('base-game global vehicle remains summonable from another surface', function()
      move(player, other)
      click(player, {x = 0, y = 4})
      assert(second.surface == other and second.position.y == 4)
      assert_claim(player, second); assert_locked(player, second)
    end)
    snapshot(state, first, nil, player.index)
    snapshot(state, second, player.index, player.index)
  end

  local function space_age(player, state)
    assert(script.active_mods['space-age'], 'Space Age suite requires Space Age')
    local planets = {'nauvis', 'vulcanus', 'fulgora', 'gleba', 'aquilo'}
    local claimed = {}
    for _, name in ipairs(planets) do
      local planet = game.planets[name]
      local surface = planet.surface or planet.create_surface()
      prepare_surface(surface); move(player, surface)
      case(name .. ': an unclaimed planet cannot summon cars from other planets', function()
        local before = {}
        for _, car in ipairs(claimed) do
          before[car.unit_number] = {surface = car.surface, x = car.position.x, y = car.position.y}
        end
        assert(not GCKI_ownership.find(player.index, surface))
        click(player, {x = 0, y = 4})
        -- Also test the summon handler directly, bypassing the key dispatch guard.
        GCKI_events.used_key.summon(player, {x = 0, y = 4})
        for _, car in ipairs(claimed) do
          local old = before[car.unit_number]
          assert(car.surface == old.surface and car.position.x == old.x and car.position.y == old.y)
        end
      end)
      local car = spawn(player, surface)
      case(name .. ': claim, lock, unlock and summon the local car', function()
        click(player, car.position); assert_claim(player, car); lock_unlock(player, car)
        click(player, {x = 0, y = 4})
        assert(car.surface == surface and car.position.x == 0 and car.position.y == 4)
        assert_locked(player, car)
        for _, previous in ipairs(claimed) do
          assert(GCKI_vehicle.get_owner(previous) == player and previous.surface ~= surface)
          assert_locked(player, previous)
          assert(previous.position.x == 0 and previous.position.y == 4)
        end
      end)
      claimed[#claimed + 1] = car
    end
    local first = claimed[1]
    case('nauvis: removing the local claim never falls back to another planet', function()
      move(player, first.surface)
      GCKI_vehicle.remove_vehicle_owner(first, player, {keep_vehicle = true, keep_color = true})
      assert(not GCKI_ownership.find(player.index, first.surface))
      click(player, {x = 0, y = -4})
      GCKI_events.used_key.summon(player, {x = 0, y = -4})
      for _, car in ipairs(claimed) do
        assert(car.position.x == 0 and car.position.y == 4)
      end
      -- Restore the Nauvis assignment before testing replacement and persistence.
      click(player, first.position); assert_claim(player, first)
    end)
    local replacement
    case('replacing the Nauvis claim preserves all other planet claims and locks', function()
      move(player, first.surface)
      replacement = spawn(player, first.surface, {7, 0})
      click(player, replacement.position); lock_unlock(player, replacement)
      assert(not GCKI_vehicle.get_owner(first)); assert_locked(player, first)
      for i = 2, #claimed do assert(GCKI_vehicle.get_owner(claimed[i]) == player) end
      assert_claim(player, replacement)
    end)
    for i, car in ipairs(claimed) do snapshot(state, car, i > 1 and player.index or nil, player.index) end
    snapshot(state, replacement, player.index, player.index)
    case('platform blocks shortcut, hotkey and key-tool summoning', function()
      local character = player.character
      local platform = assert(player.force.create_space_platform{
        name = 'GCKI-regression', planet = 'nauvis', starter_pack = 'space-platform-starter-pack'})
      platform.apply_starter_pack()
      player.cursor_stack.set_stack{name = GCKI.carkey_name, count = 1}
      player.set_controller{type = defines.controllers.remote, surface = platform.surface, position = {0, 0}}
      GCKI_events.on_player_changed_surface{player_index = player.index}
      assert(not player.is_shortcut_available(GCKI.shortcut_name) and not player.cursor_stack.valid_for_read)
      GCKI_events.on_lua_shortcut{player_index = player.index, prototype_name = GCKI.shortcut_name}
      GCKI_custom_input.spawn_carkey{player_index = player.index}
      click(player, {x = 0, y = 4})
      GCKI_events.used_key.summon(player, {x = 0, y = 4})
      assert(not player.cursor_stack.valid_for_read)
      for _, saved in ipairs(state.cars) do
        assert(saved.entity.surface == saved.surface and saved.entity.position.x == saved.x and
               saved.entity.position.y == saved.y)
      end
      assert(player.teleport(character.position, character.surface))
      player.set_controller{type = defines.controllers.character, character = character}
      GCKI_events.on_player_changed_surface{player_index = player.index}
      assert(player.is_shortcut_available(GCKI.shortcut_name))
    end)
  end

  script.on_nth_tick(1, function()
    local player = assert(game.get_player(1), 'native test player is missing')
    if mod.ci_vehicle_test and mod.ci_vehicle_test.awaiting_reload then
      local state = mod.ci_vehicle_test
      results = state.results
      state.awaiting_reload = nil
      assert(state.mode == context.mode and state.player == player.index)
      for _, saved in ipairs(state.cars) do
        case(saved.surface.name .. ': saved car, ownership and lock survive reload (' .. saved.id .. ')', function()
          local car = saved.entity
          assert(car.valid and car.unit_number == saved.id and car.surface == saved.surface)
          assert(car.position.x == saved.x and car.position.y == saved.y)
          local data = assert(mod.GCKI_vehicles[saved.id])
          assert(data.owner == saved.owner and data.locker == saved.locker)
          if saved.locker then assert_locked(player, car) end
          if saved.owner then
            move(player, car.surface); assert_claim(player, car)
            click(player, {x = -4, y = 0})
            assert(car.surface == saved.surface and car.position.x == -4 and car.position.y == 0)
          end
        end)
      end
      script.finish_test(true)
    else
      if not player.character then
        player.set_controller{type = defines.controllers.god}; player.create_character()
      end
      player.force.technologies.automobilism.researched = true
      GCKI_player.init_player(player)
      local state = {mode = context.mode, player = player.index, cars = {}}
      mod.ci_vehicle_test = state
      if context.mode == 'space-age' then space_age(player, state) else base_game(player, state) end
      state.results = results
      state.awaiting_reload = true
      -- This uses Factorio's real mod save/load lifecycle, preserving LuaEntity
      -- references in storage and running the production on_load handler.
      game.reload_mods()
    end
  end)
end
