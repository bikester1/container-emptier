-- Prototype definitions (data stage).
--
-- This mod adds three prototypes that work together:
--   1. A selection-tool item — the draggable green/red selection cursor.
--   2. A shortcut — the button in the shortcut bar (next to blueprints etc.)
--      that puts the tool in the player's cursor.
--   3. A custom-input — an (unbound by default) hotkey that does the same.
--
-- The actual "empty this container" behavior lives in control.lua; the
-- prototypes here only define what can be selected and how the tool looks.

local tool = {
  type = "selection-tool",
  name = "container-emptier",
  icon = "__container-emptier__/container_emptier_tool.png",
  -- The file is 120x64: a 64px icon plus 32/16/8px mip levels packed to the
  -- right. Factorio infers the mip count from the file width, so only the
  -- base size is declared here.
  icon_size = 64,

  -- "only-in-cursor": the tool exists only while held; it never sits in the
  -- inventory, so there's nothing to craft or clean up.
  -- "spawnable": required for the shortcut/custom-input "spawn-item" action
  -- to be allowed to conjure it into the cursor.
  flags = { "only-in-cursor", "spawnable", "not-stackable" },
  hidden = true, -- keep it out of filter/search lists; the shortcut is the only entry point
  subgroup = "tool",
  order = "z[container-emptier]",
  stack_size = 1,

  -- Normal drag: flag entities to be emptied.
  -- No entity type filter here — anything on our force is selectable, and
  -- control.lua decides what actually has an inventory worth emptying.
  select = {
    border_color = { r = 1, g = 0.6, b = 0 },
    cursor_box_type = "entity",
    mode = { "any-entity", "same-force" },
  },
  -- Alt drag (shift on some layouts): cancel pending pickups instead.
  alt_select = {
    border_color = { r = 1, g = 0, b = 0 },
    cursor_box_type = "not-allowed",
    mode = { "any-entity", "same-force" },
  },
}

-- Shortcut bar button. "spawn-item" needs no script support: the engine
-- itself puts the tool in the cursor when clicked.
local shortcut = {
  type = "shortcut",
  name = "container-emptier",
  action = "spawn-item",
  item_to_spawn = "container-emptier",
  -- Ties the shortcut to the hotkey below so the keybind shows in its tooltip.
  associated_control_input = "container-emptier",
  icon = "__container-emptier__/container_emptier_tool.png",
  icon_size = 64,
  small_icon = "__container-emptier__/container_emptier_tool.png",
  small_icon_size = 64,
  style = "default",
}

-- Optional hotkey, unbound by default ("" = player assigns one in
-- Settings > Controls > Mods if they want it).
local hotkey = {
  type = "custom-input",
  name = "container-emptier",
  key_sequence = "",
  action = "spawn-item",
  item_to_spawn = "container-emptier",
  consuming = "none",
}

data:extend({ tool, shortcut, hotkey })
