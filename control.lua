-- Runtime behavior (control stage).
--
-- How the mod works: Factorio 2.0 added "removal plans" to the
-- item-request-proxy entity — the same invisible helper entity the engine
-- uses when you right-click a single stack in a container to have bots
-- take it away. A proxy is spawned on top of a target entity carrying a
-- plan of exactly which stacks (by inventory + slot) bots should remove;
-- construction bots then ferry those items to storage and the proxy
-- deletes itself when the plan is done.
--
-- So "empty this container" is: read every stack in the entity, build one
-- big removal plan covering all of them, and spawn a proxy with that plan.
-- The engine and the bots do the rest.

local TOOL_NAME = "container-emptier"

-- Entity types where flagging items for bot pickup makes no sense or would
-- fight the player (bots taking items out of your own hands/robots).
-- Everything else is allowed: chests, machines, vehicles, turrets, etc.
local SKIP_TYPES = {
  ["character"] = true,
  ["construction-robot"] = true,
  ["logistic-robot"] = true,
  ["item-request-proxy"] = true,
  ["entity-ghost"] = true,
  ["tile-ghost"] = true,
}

-- Build a removal plan covering every stack in every inventory the entity
-- has (trunk, output, fuel, modules, ...).
--
-- Plan format (array of BlueprintInsertPlan):
--   { id = {name, quality}, items = { in_inventory = {positions...} } }
-- The proxy wants ONE entry per distinct item+quality, each listing all the
-- slot positions holding that item — so stacks are grouped via `by_key`.
--
-- Returns nil when there's nothing to remove, so callers can treat
-- "skipped" and "empty" the same way.
local function build_removal_plan(entity)
  if SKIP_TYPES[entity.type] then return nil end

  -- Inventories are addressed by index (defines.inventory.*). Rather than
  -- hardcoding which define applies to which entity type (chest vs
  -- car_trunk vs furnace_result...), just probe every index this entity
  -- supports; get_inventory() returns nil for indexes it doesn't have.
  local max_index = entity.get_max_inventory_index()
  if not max_index or max_index == 0 then return nil end

  local plan = {}
  local by_key = {} -- "name/quality" -> plan entry, for stack grouping
  for inv_index = 1, max_index do
    local inventory = entity.get_inventory(inv_index)
    if inventory and not inventory.is_empty() then
      for i = 1, #inventory do
        local stack = inventory[i]
        -- valid_for_read is false for empty slots; reading .name on one
        -- would error.
        if stack.valid_for_read then
          local key = stack.name .. "/" .. stack.quality.name
          local entry = by_key[key]
          if not entry then
            entry = {
              id = { name = stack.name, quality = stack.quality.name },
              items = { in_inventory = {} },
            }
            by_key[key] = entry
            plan[#plan + 1] = entry
          end
          local positions = entry.items.in_inventory
          positions[#positions + 1] = {
            inventory = inv_index,
            -- InventoryPosition.stack is ZERO-based, unlike Lua's usual
            -- one-based indexing. Off by one here = bots grab wrong slots.
            stack = i - 1,
            count = stack.count,
          }
        end
      end
    end
  end

  if #plan == 0 then return nil end
  return plan
end

-- Find item-request-proxies attached to this entity. There's no direct
-- "entity -> its proxies" API, but a proxy always sits at its target's
-- position, so search there and confirm via proxy_target (the position may
-- be shared, e.g. proxies of a neighboring large entity overlapping).
local function find_proxies_for(entity)
  local proxies = entity.surface.find_entities_filtered({
    name = "item-request-proxy",
    force = entity.force,
    position = entity.position,
  })
  local result = {}
  for _, proxy in pairs(proxies) do
    if proxy.proxy_target == entity then
      result[#result + 1] = proxy
    end
  end
  return result
end

-- Flag one entity: snapshot its contents into a removal plan and spawn the
-- proxy. Returns true if a proxy was created (used for the feedback count).
local function flag_for_removal(entity)
  -- An entity can already have a proxy (from a previous drag, or a vanilla
  -- per-stack request). Destroy and recreate rather than merge, so the plan
  -- always reflects the CURRENT contents — re-dragging is how you refresh.
  for _, proxy in pairs(find_proxies_for(entity)) do
    proxy.destroy()
  end

  local plan = build_removal_plan(entity)
  if not plan then return false end

  entity.surface.create_entity({
    name = "item-request-proxy",
    position = entity.position,
    force = entity.force,
    target = entity,
    modules = {}, -- insertion side of the proxy; empty = removal only
    removal_plan = plan,
    raise_built = true, -- let other mods see the proxy appear
  })
  return true
end

-- Normal drag: flag everything selected.
local function on_selected(event)
  -- Selection events fire for EVERY selection tool (blueprints,
  -- deconstruction planners, other mods' tools), so filter by item name.
  if event.item ~= TOOL_NAME then return end
  local player = game.get_player(event.player_index)
  if not player then return end

  local count = 0
  for _, entity in pairs(event.entities) do
    if entity.valid and flag_for_removal(entity) then
      count = count + 1
    end
  end
  if count > 0 then
    -- Local flying text: visible only to this player, no game-state change.
    player.create_local_flying_text({
      text = { "container-emptier.flagged", count },
      create_at_cursor = true,
    })
  end
end

-- Alt drag: cancel — destroy any pending proxies on the selected entities.
-- Items already in a bot's hands are past cancelling; they'll be delivered.
local function on_alt_selected(event)
  if event.item ~= TOOL_NAME then return end
  local player = game.get_player(event.player_index)
  if not player then return end

  local count = 0
  for _, entity in pairs(event.entities) do
    if entity.valid then
      for _, proxy in pairs(find_proxies_for(entity)) do
        proxy.destroy()
        count = count + 1
      end
    end
  end
  if count > 0 then
    player.create_local_flying_text({
      text = { "container-emptier.cancelled", count },
      create_at_cursor = true,
    })
  end
end

script.on_event(defines.events.on_player_selected_area, on_selected)
script.on_event(defines.events.on_player_alt_selected_area, on_alt_selected)
