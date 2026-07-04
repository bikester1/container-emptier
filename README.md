# Container Emptier

A Factorio mod that lets you flag an **entire container** — or anything else with an inventory — to be emptied by the logistics network in one drag, instead of right-clicking every stack individually.

![Mod icon](container_emptier_tool.png)

## What it does

Vanilla Factorio (2.0+) lets you right-click a single stack in a container to have construction bots haul it off to storage. That's great for one stack, and tedious for a full steel chest.

This mod adds a **selection tool** to the shortcut bar:

- **Drag** over entities → every stack inside is flagged for pickup. Bots from the covering logistic network carry the contents off to storage chests.
- **Alt-drag** → cancel pending pickups on the selected entities.
- Re-dragging over an entity refreshes its plan to match the current contents.

It works on anything with an inventory, not just chests: assembler inputs/outputs, furnace contents and fuel, module slots, cars, tanks, spidertrons, cargo wagons, roboports, turret ammo, and so on. Your own character and robots in flight are deliberately excluded.

## Requirements

- Factorio **2.1** (base game only — no Space Age required)
- The entities you empty must be inside a logistic network with construction bot coverage and available storage, same as the vanilla per-stack feature.

## Installation

**From source (this repo):**

1. Clone or download this repository.
2. Copy the mod folder into your Factorio mods directory as `container-emptier_1.0.0`:
   - Windows: `%APPDATA%\Factorio\mods\`
   - Linux: `~/.factorio/mods/`
   - macOS: `~/Library/Application Support/factorio/mods/`

3. Launch Factorio and make sure the mod is enabled under **Mods**.

## Usage

1. Click the **Container emptier** button in the shortcut bar (bottom right), or bind a hotkey under **Settings → Controls → Mods**.
2. Drag a selection box over the entities you want emptied.
3. Watch the bots do the work. Alt-drag to cancel if you change your mind (items already in a bot's hands will still be delivered).

## How it works

The mod uses the same engine mechanism as vanilla's per-stack right-click: an
[`item-request-proxy`](https://lua-api.factorio.com/latest/classes/LuaEntity.html) entity with a **removal plan** (added in Factorio 2.0). On selection, [`control.lua`](control.lua) walks every inventory of each selected entity, groups the stacks by item and quality into a single removal plan, and spawns one proxy per entity. The engine then dispatches construction bots to fulfill it, and the proxy cleans itself up when done.

There is no per-tick logic and no persistent state — everything happens at selection time, so the mod has zero UPS impact while idle and is safe to add to or remove from existing saves.

## Notes and caveats

- Flagging a machine that's actively being fed (e.g. an assembler with inserters supplying it) means bots and inserters will fight over the contents. That's inherent to "empty everything" — alt-drag to cancel.
- The removal plan is a snapshot: items produced *after* you drag aren't included. Drag again to re-flag with fresh contents.

## License

[MIT](LICENSE)
