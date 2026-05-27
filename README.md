# DataStoreHandler-Lua

A simple Roblox server-side data system for handling player progression, inventory, and character saving.

This project was built to practice real backend logic such as data persistence, migration, and game state management.

---

## Features

- persistent player data (coins, rebirths, time played)
- inventory & storage system with slot-based placement
- character serialization (attributes, mesh, decals, metadata)
- discovered and seen character tracking
- base/plateau reconstruction from saved state
- data versioning and migration support (v8 → v9)
- autosave + safe shutdown handling
- session tracking system

---

## Usage

Place the module in `ServerScriptService` and require it:

```lua
local DataStoreHandler = require(game.ServerScriptService.src.DataStoreHandler)
