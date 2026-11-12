-- Vehicle records remain the source of truth, including in existing saves.
-- mod.owners retains one representative per player for legacy presence checks.
local ownership = {}

function ownership.scope(surface)
  if not (surface and surface.valid) or surface.platform then return nil end
  if not script.active_mods["space-age"] then return "global" end
  return surface.planet and ("planet:" .. surface.planet.name) or
                           ("surface:" .. surface.index)
end

function ownership.all(player_index)
  local owned = {}
  for id, data in pairs(mod.GCKI_vehicles or {}) do
    if data.owner and (not player_index or data.owner == player_index) and
        data.entity and data.entity.valid then
      owned[id] = data.owner
    end
  end
  return owned
end

function ownership.find(player_index, surface, exclude)
  local scope = ownership.scope(surface)
  if not scope then return nil end
  local found
  for id in pairs(ownership.all(player_index)) do
    if id ~= exclude and ownership.scope(mod.GCKI_vehicles[id].entity.surface) == scope then
      if not found or id < found then found = id end
    end
  end
  return found
end

function ownership.refresh(player_index, exclude)
  local found
  for id in pairs(ownership.all(player_index)) do
    if id ~= exclude and (not found or id < found) then found = id end
  end
  mod.owners[player_index] = found
end

function ownership.unavailable_reason(player)
  local physical = player.physical_surface or player.surface
  local reason
  if player.surface.platform or physical.platform then
    reason = "keys-on-platform"
  elseif physical ~= player.surface then
    reason = "keys-in-remote-view"
  end
  return reason
end

function ownership.can_use(player, notify)
  local reason = ownership.unavailable_reason(player)
  if reason and notify then GCKI.output(player, {"GCKI-messages." .. reason}) end
  return not reason
end

function ownership.update_shortcut(player)
  local force = mod.force_data and mod.force_data[player.force.name]
  local data = mod.player_data and mod.player_data[player.index]
  local reason = ownership.unavailable_reason(player)
  local unlocked = force and force.show_shortcuts and not (data and data.suspended)
  local available = unlocked and not reason or false
  player.set_shortcut_available(GCKI.shortcut_name, available)
  GCKI_gui.update_key_status(player, unlocked and reason or nil)
  local cursor = player.cursor_stack
  if not available and cursor and cursor.valid_for_read and cursor.name == GCKI.carkey_name then
    cursor.clear()
  end
end

-- Reconcile changes made by other mods or by enabling/disabling Space Age.
-- Keep one claim per scope; releasing a claim preserves its independent lock.
function ownership.reconcile()
  local keep, remove, ids = {}, {}, {}
  for id in pairs(ownership.all()) do ids[#ids + 1] = id end
  table.sort(ids)
  for _, id in ipairs(ids) do
    local data = mod.GCKI_vehicles[id]
    local scope = ownership.scope(data.entity.surface)
    local key = scope and (data.owner .. "/" .. scope)
    if not key or keep[key] then
      remove[#remove + 1] = {id, data.owner}
    else
      keep[key] = id
    end
  end
  for _, entry in ipairs(remove) do
    GCKI_vehicle.remove_vehicle_owner(entry[1], entry[2], {skip_event_check = true})
  end
  local players = {}
  for index in pairs(mod.owners) do players[index] = true end
  for _, owner in pairs(ownership.all()) do players[owner] = true end
  for index in pairs(players) do ownership.refresh(index) end
end

return ownership
