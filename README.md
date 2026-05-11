# DataStoreHandler-Lua

A simple Roblox server-side data system for handling player progression, inventory, and character saving.

This project was built to practice real backend logic such as data persistence, migration, and game state management.

---

## Features

- saves and loads player data (coins, rebirths, inventory, etc.)
- tracks discovered characters
- supports character attributes like price and passive income
- basic protection against data loss between sessions
- supports data migration between versions

---

## Usage

Place the module in `ServerScriptService` and require it:

```lua
local DataStoreHandler = require(game.ServerScriptService.src.DataStoreHandler)