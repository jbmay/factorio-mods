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
    assert(not car.disabled_by_script and car.operable and not car.minable_flag,
           'locked vehicle flags were not preserved')
  end

  local function owner_access(player, car)
    for _, role in ipairs({'driver', 'passenger'}) do
      car['set_' .. role](player)
      mod.player_data[player.index].last_action_tick = game.tick
      mod.player_data[player.index].skip_state_change = 2
      GCKI_events.on_player_driving_changed_state{player_index = player.index, entity = car, tick = game.tick}
      assert(player.vehicle == car and GCKI_vehicle.get_occupants(car)[role].entity == player,
             'lock ejected the owner from ' .. role .. ' seat')
      assert_locked(player, car)
      player.opened = car
      GCKI_events.on_gui_opened{player_index = player.index, entity = car}
      assert(player.opened == car, 'owner could not open locked inventory')
      player.opened = nil
      car['set_' .. role](nil)
    end
    mod.player_data[player.index].skip_state_change = nil
  end

  local function lock_unlock(player, car)
    click(player, car.position)
    assert_locked(player, car)
    click(player, car.position)
    assert(not GCKI_vehicle.get_locker(car) and not car.disabled_by_script and
           car.operable and car.minable_flag, 'vehicle did not unlock')
    click(player, car.position)
    assert_locked(player, car)
    owner_access(player, car)
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
      assert(mod_gui.get_button_flow(player).GCKI_key_status.tooltip[1] == 'GCKI-messages.keys-on-platform')
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
      local nauvis = game.surfaces.nauvis
      prepare_surface(nauvis); move(player, nauvis)
      case('distant claiming and locking work in character and remote views; summons stay near the character', function()
        local car = spawn(player, nauvis, {11, 11})
        local character = player.character
        for _, remote_view in ipairs({false, true}) do
          if remote_view then
            player.set_controller{type = defines.controllers.remote, surface = nauvis, position = {10, 10}}
          end
          assert(not GCKI_player.is_in_reach(player, car.position))
          click(player, car.position); assert_claim(player, car)
          click(player, car.position); assert_locked(player, car)
          click(player, car.position); assert(not GCKI_vehicle.get_locker(car))
          click(player, {x = 10, y = -10})
          assert(car.position.x == 11 and car.position.y == 11, 'out-of-reach summon moved the car')
          click(player, {x = 0, y = 4})
          assert(car.position.x == 0 and car.position.y == 4, 'nearby summon failed')
          assert(car.teleport({11, 11}))
          GCKI_vehicle.remove_vehicle_owner(car, player, {skip_event_check = true})
          GCKI_vehicle.unlock_vehicle(car)
        end
        player.set_controller{type = defines.controllers.character, character = character}
        car.destroy()
      end)
      case('riding in a claimed car cannot extend summon range by moving the remote camera', function()
        local car = spawn(player, nauvis)
        click(player, car.position); assert_claim(player, car)
        car.set_driver(player)
        local character = player.character
        local x, y = player.physical_position.x, player.physical_position.y
        player.set_controller{type = defines.controllers.remote, surface = nauvis, position = {100, 100}}
        click(player, {x = 100, y = 104})
        assert(car.position.x == 3 and car.position.y == 0)
        assert(player.physical_position.x == x and player.physical_position.y == y,
               'remote-view summon teleported the seated character')
        click(player, {x = 0, y = 4})
        assert(car.position.x == 0 and car.position.y == 4)
        player.set_controller{type = defines.controllers.character, character = character}
        car.set_driver(nil); car.destroy(); move(player, nauvis)
      end)
      case('disabled shortcut exposes the viewed-surface reason and clears it on return', function()
        local character = player.character
        local other = game.create_surface('gcki-remote-key-check')
        player.set_controller{type = defines.controllers.remote, surface = other, position = {0, 0}}
        GCKI_events.on_player_changed_surface{player_index = player.index}
        local flow = mod_gui.get_button_flow(player)
        assert(not player.is_shortcut_available(GCKI.shortcut_name))
        assert(flow.GCKI_key_status and flow.GCKI_key_status.tooltip[1] == 'GCKI-messages.keys-in-remote-view')
        assert(player.teleport(character.position, character.surface))
        player.set_controller{type = defines.controllers.character, character = character}
        GCKI_events.on_player_changed_surface{player_index = player.index}
        assert(player.is_shortcut_available(GCKI.shortcut_name) and not flow.GCKI_key_status)
        game.delete_surface(other)
      end)
      case('selected Spidertron body claims the spider instead of summoning the previous car', function()
        local car = spawn(player, nauvis)
        click(player, car.position); assert_claim(player, car)
        local spider = assert(nauvis.create_entity{name = 'spidertron', position = {7, 7}, force = player.force})
        local position = {x = 7, y = 2}
        assert(not GCKI_events.used_key.find_vehicle(nauvis, position), 'fixture must miss the ground footprint')
        mod.player_data[player.index].last_action_tick = nil
        GCKI_events.on_player_selected_area{
          player_index = player.index, item = GCKI.carkey_name, surface = nauvis,
          area = {left_top = position, right_bottom = position}, entities = {spider},
        }
        assert_claim(player, spider)
        assert(car.position.x == 3 and car.position.y == 0, 'previous car was summoned beneath the spider')
        assert(spider.position.x == 7 and spider.position.y == 7)
        car.destroy(); spider.destroy()
      end)
      if context.mode == 'space-age' then space_age(player, state) else base_game(player, state) end
      case('Your vehicles groups planets alphabetically and preserves row controls when reordering', function()
        local expected = context.mode == 'space-age' and
          {'aquilo', 'fulgora', 'gleba', 'nauvis', 'nauvis', 'vulcanus'} or
          {'nauvis', 'gcki-test-other-surface'}
        -- Discard vehicles destroyed by earlier scripted cases before inspecting the GUI.
        GCKI_events.on_configuration_changed{name = 'on_configuration_changed'}
        local names = GCKI_gui_names.player_vehicles.table_columns
        GCKI_gui_player_vehicles.init_gui(player)
        local tab = GCKI_gui_player_vehicles.get_gui_table(player)
        local function check_order()
          local children = tab.children
          assert(#children == (#expected + 1) * 8, 'unexpected vehicle cell count: ' .. #children)
          local previous
          for row, surface in ipairs(expected) do
            local label = children[row * 8 + 4]
            assert(label.caption == surface, 'unexpected planet/surface at row ' .. row)
            local id = tonumber(label.name:sub(#names.surface + 1))
            if row > 1 and expected[row - 1] == surface then
              assert(previous < id, 'same-surface vehicles must have stable ID order')
            end
            previous = id
          end
        end
        check_order()
        local car = state.cars[1].entity
        local map_cell = tab[names.map_view .. car.unit_number]
        local name_cell = tab[names.id .. car.unit_number]
        local old_text = name_cell.text
        map_cell.state, name_cell.text = true, 'Unsubmitted vehicle name'
        -- Scramble the first/last rows to exercise sorting of existing controls.
        for column = 1, 8 do tab.swap_children(8 + column, #expected * 8 + column) end
        GCKI_gui_player_vehicles.add_to_gui(player, {car})
        check_order()
        assert(tab[names.map_view .. car.unit_number] == map_cell and map_cell.state)
        assert(tab[names.id .. car.unit_number] == name_cell and name_cell.text == 'Unsubmitted vehicle name')
        map_cell.state, name_cell.text = false, old_text
        GCKI_gui_player_vehicles.init_gui(player)
        check_order()
      end)
      case('existing disabled locks become usable by their owner on upgrade', function()
        for _, saved in ipairs(state.cars) do
          saved.entity.disabled_by_script = true
          saved.entity.operable = false
        end
        GCKI_events.on_configuration_changed{name = 'on_configuration_changed'}
        for _, saved in ipairs(state.cars) do
          move(player, saved.entity.surface)
          assert_locked(player, saved.entity)
          owner_access(player, saved.entity)
        end
      end)
      case('locking while the owner is driving keeps the owner in the vehicle', function()
        local car = state.cars[#state.cars].entity
        move(player, car.surface)
        car.set_driver(player)
        click(player, car.position) -- unlock
        click(player, car.position) -- lock again while driving
        assert(player.vehicle == car); assert_locked(player, car)
        car.set_driver(nil)
      end)
      case('locked driver seat and inventory reject non-owners while passenger seats remain available', function()
        local car = state.cars[#state.cars].entity
        local data = mod.GCKI_vehicles[car.unit_number]
        local owner, locker = data.owner, data.locker
        -- Native tests supply one real player. A different lock-holder ID makes
        -- that real player unauthorized; Lua regressions also test two players
        -- occupying the driver/passenger seats simultaneously.
        data.owner, data.locker = nil, player.index + 1000
        for _, role in ipairs({'driver', 'passenger'}) do
          car['set_' .. role](player)
          mod.player_data[player.index].last_action_tick = game.tick
          mod.player_data[player.index].skip_state_change = 2
          GCKI_events.on_player_driving_changed_state{player_index = player.index, entity = car, tick = game.tick}
          if role == 'driver' then
            assert(not car.get_driver() and player.vehicle == car, 'driver was not redirected to a passenger seat')
          else
            assert(player.vehicle == car, 'locked vehicle rejected a passenger')
          end
          car.set_driver(nil); car.set_passenger(nil)
        end
        car.set_passenger(player)
        player.opened = car
        GCKI_events.on_gui_opened{player_index = player.index, entity = car}
        assert(not player.opened, 'unauthorized passenger inventory stayed open')
        car.set_passenger(nil); car.set_driver(player)
        GCKI_events.on_player_driving_changed_state{player_index = player.index, entity = car, tick = game.tick}
        assert(not car.get_driver() and player.vehicle == car, 'passenger bypassed the driver lock by switching seats')
        car.set_passenger(nil)
        data.owner, data.locker = owner, locker
        mod.player_data[player.index].skip_state_change = nil
      end)
      case('admin recovery is explicit and preserves the recovered vehicle and its contents', function()
        local saved = state.cars[#state.cars]
        local car = saved.entity
        move(player, car.surface)
        local was_admin = player.admin
        local trunk = car.get_inventory(defines.inventory.car_trunk)
        assert(trunk.insert{name = 'iron-plate', count = 12} == 12)
        GCKI_vehicle.edit_vehicle_name{player = player, vehicle = car, new_name = 'GCKI recovery test'}
        local color = car.color
        player.admin = false
        GCKI_commands.clear_owner{player_index = player.index, parameter = 'vehicle ' .. car.unit_number}
        assert_claim(player, car); assert_locked(player, car)
        player.admin = true
        car.set_driver(player)
        GCKI_commands.clear_owner{player_index = player.index, parameter = 'vehicle invalid'}
        assert_claim(player, car); assert_locked(player, car)
        GCKI_commands.clear_owner{player_index = player.index, parameter = 'vehicle ' .. car.unit_number}
        assert(car.valid and car.unit_number == saved.id and not mod.GCKI_vehicles[car.unit_number])
        assert(car.operable and car.minable_flag and not car.disabled_by_script)
        assert(not car.get_driver() and not car.get_passenger() and not player.vehicle)
        assert(trunk.get_item_count('iron-plate') == 12)
        assert(mod.named_vehicles.by_id[car.unit_number].name == 'GCKI recovery test')
        assert(car.color.r == color.r and car.color.g == color.g and car.color.b == color.b)
        -- Restore the fixture's ordinary assignment for its later save/load checks.
        click(player, car.position); click(player, car.position)
        assert_claim(player, car); assert_locked(player, car)
        player.admin = was_admin
      end)
      case('server-console recovery clears a removed players stale lock and claim', function()
        local car = spawn(player, player.surface, {10, -10})
        local id, missing = car.unit_number, player.index + 1000
        mod.GCKI_vehicles[id] = {entity = car, owner = missing, locker = missing}
        mod.owners[missing] = id
        mod.lockers[missing] = {[id] = id}
        car.disabled_by_script, car.operable, car.minable_flag = true, false, false
        GCKI_commands.clear_owner{parameter = 'vehicle ' .. id}
        assert(not mod.GCKI_vehicles[id] and not mod.owners[missing] and not mod.lockers[missing])
        assert(car.valid and car.operable and car.minable_flag and not car.disabled_by_script)
      end)
      state.results = results
      state.awaiting_reload = true
      -- This uses Factorio's real mod save/load lifecycle, preserving LuaEntity
      -- references in storage and running the production on_load handler.
      game.reload_mods()
    end
  end)
end
