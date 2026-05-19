# Pixel Origins

A 2D top-down action RPG prototype built in Godot 4.6.

## What the game can do so far

- Playable character with state-driven movement and combat
- Walk and run movement states with directional facing
- Melee attack system with active hit window and enemy hit detection
- Player health system with HUD health bar + label updates
- Gold system with HUD gold display
- Tracked quest display in HUD (with progress / turn-in state)
- Quest modal UI (top-right button) showing active quests and tracked quest toggle
- Player death now reloads the last save (fallback to start screen if no valid save exists)
- Goblin enemy AI with camp behavior:
  - Idle while unalerted
  - Aggro when player enters vision
  - Chase player, attack in range, and retreat back to camp when disengaged
- Goblin health bar that appears only when goblin is damaged (hidden at full health)
- Damage feedback flash effect for player and enemies
- Multi-stage world flow with stage transitions via landmarks and warp zones
- Spawn point-based stage entry so player appears at correct entrance
- On-screen contextual bottom text when interacting with landmarks
- Start screen flow:
  - `New Game`
  - `Continue` (loads last save)
  - `Quit`
  - Overwrite confirmation when starting a new game with an existing save
- Save/load system:
  - Saves on stage switch for non-UI stages
  - Persists stage, position, player health, and total gold
  - Continue and death-reload restore saved values

## Current playable map flow

- `Start Screen`
- `Overworld` (hub)
- `Tauracre` (connected to Overworld)
- `Bramblewilds` (connected to Overworld, includes goblin camp encounters)

## Quest and dialogue flow

- Village Mayor interaction via actionable helper + player interaction finder
- Dialogue choice flow (Yes/No) to accept quest
- Repeatable mayor quest: `Goblin Cleanup` (defeat 1 goblin)
- Quest remains active after objective completion until you return to mayor
- Quest turn-in through mayor dialogue grants gold reward

## Controls

- Move: `W A S D` or arrow keys
- Run: `Shift` (hold while moving)
- Attack: `Left Mouse Button`
- Interact / enter landmark: `E`

## Tech notes

- Engine: Godot `4.6` (`gl_compatibility` renderer)
- Main scene: `core/main.tscn`
- Core singletons:
  - `StageManager` for stage loading/switching
  - `SaveManager` for save/load persistence
  - `QuestManager` for quest state, progress, and rewards
  - `SignalBus` for UI/gameplay events

## Run locally

1. Open the project folder in Godot 4.6.
2. Run the project (`F5`) from the editor.

## Assets Information

The table below lists the assets used for **Pixel Origins**, sourced primarily from **itch.io**. These assets were selected based on their **consistent art style** (pixel dimensions and color schemes) and their **animations** for combat and movement. All assets are **free for non-commercial use**, though some creators appreciate or require credit.

| Asset Link | Description | Credits / License |
| :--- | :--- | :--- |
| [Little Dreamyland Asset Pack](https://starmixu.itch.io/little-dreamyland-asset-pack) | An asset pack used for landscape, building and objects throughout the map | By Starmixu and Utaskuas |
| [Dan's RPG Set](https://danieruart.itch.io/16x16-rpg-fantasy-character-and-tileset) | Contains the player character with partially complete animations | By DanieruArt |
| [Sunny side asset pack](https://danieldiggle.itch.io/sunnyside) | An asset pack used for the landscape / tileset and 1 enemy | By daniellediggle |
| [Pixel Poem Dungeon](https://pixel-poem.itch.io/dungeon-assetpuck) | Asset pack for dungeons and enemies | By Pixel_Poem, support MiniPainter |
| [Monopixel Monsters](https://monopixelart.itch.io/) | Monster Assetpack | By MonoPixel |
| [Broken Sword Asset Pack](https://from-chris.itch.io/broken-sword-asset-pack) | Forest themed tileset and knight animated sprites | By Chris |
| [Pixel Crawler](https://anokolisa.itch.io/free-pixel-art-asset-pack-topdown-tileset-rpg-16x16-sprites) | NPC and Decorator with basic tileset | By Anokolisa |
| [Super Retro World Character pack](https://gif-superretroworld.itch.io/character-pack) | Basic NPC sprites | By Gif |
| [RPG Dungeon Pack](https://gif-superretroworld.itch.io/dungeon-pack) | Dungeon / Arena tileset | By Gif (@gif_not_jif), Noiracide (@Noiracide), and Romi (@DessRomaric) |
| [RPG Interior Pack](https://gif-superretroworld.itch.io/interior-pack) | House interior and walls | By The low-res arist (Twitter @Pixelart_asset) |
