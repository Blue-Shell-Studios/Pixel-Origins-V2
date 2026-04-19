# Pixel Origins

A 2D top-down action RPG prototype built in Godot 4.6.

## What the game can do so far

- Playable character with state-driven movement and combat
- Walk and run movement states with directional facing
- Melee attack system with active hit window and enemy hit detection
- Player health system with HUD health bar + label updates
- Player death + game over overlay with restart (press Enter)
- Goblin enemy AI with camp behavior:
  - Idle while unalerted
  - Aggro when player enters vision
  - Chase player, attack in range, and retreat back to camp when disengaged
- Damage feedback flash effect for player and enemies
- Multi-stage world flow with stage transitions via landmarks and warp zones
- Spawn point-based stage entry so player appears at correct entrance
- On-screen contextual bottom text when interacting with landmarks

## Current playable map flow

- `Overworld` (hub)
- `Tauracre` (connected to Overworld)
- `Bramblewilds` (connected to Overworld, includes goblin camp encounters)

## Controls

- Move: `W A S D` or arrow keys
- Run: `Shift` (hold while moving)
- Attack: `Left Mouse Button`
- Interact / enter landmark: `E`
- Restart after death: `Enter`

## Tech notes

- Engine: Godot `4.6` (`gl_compatibility` renderer)
- Main scene: `core/main.tscn`
- Core singletons:
  - `StageManager` for stage loading/switching
  - `SignalBus` for UI/gameplay events

## Run locally

1. Open the project folder in Godot 4.6.
2. Run the project (`F5`) from the editor.