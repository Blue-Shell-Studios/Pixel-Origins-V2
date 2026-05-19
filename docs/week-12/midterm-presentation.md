# Midterm Presentation

## Systems Documentation
### Enemy AI (FSMs, pathfinding)
- Goblin AI uses a finite state machine with four states: `IDLE`, `WALKING`, `RUNNING`, and `ATTACK`.
- Camp-level behavior is managed by `EnemyCamp`:
  - `Vision` area alerts the camp and assigns the player as target.
  - Goblins chase while aggroed and retreat to camp when disengaged.
- Movement is direct steering (`direction_to`) and not tile/navmesh pathfinding in this snapshot.
- Combat transition logic:
  - Goblins enter attack state when within `attack_range`.
  - Attack hitboxes are enabled during a specific animation window.

### Combat/interaction system
- Player combat is state-driven (`IDLE`, `WALKING`, `RUNNING`, `ATTACK`, `ACTION`).
- Sword damage is handled via `Area2D` overlap with target `Hitbox` checks.
- Directional combat includes left/right/up/down facing and hitbox repositioning by look direction.
- Interaction uses an `ActionableFinder` area in front of the player:
  - Pressing `E` triggers `interact()` on actionable owners (e.g., Village Mayor).
  - NPC dialogue is handled through Dialogue Manager balloon UI.
- HUD reflects combat and interaction outcomes:
  - Health updates, gold updates, tracked quest status, and bottom text notifications.

### Progression systems (leveling, unlocks, etc.)
- No leveling/stat tree system is implemented yet in this commit.
- Current progression is quest-and-resource driven:
  - Repeatable quest: `Goblin Cleanup` (defeat 1 goblin).
  - Quest states: active, progress tracked, ready to turn in, completed via mayor.
  - Reward loop: quest completion grants gold (`gold_reward`).
- Player loop progression is currently stage traversal + quest completion + gold accumulation.

### Save/load architecture (if applicable)
- `SaveManager` persists data to `user://savegame.json`.
- Saved payload includes:
  - Save version
  - Current stage name
  - Player position (`x`, `y`)
  - Player health
  - Total gold
- Save triggers:
  - Stage switches for non-UI stages (handled by `StageManager`).
- Load triggers:
  - `Continue` on start screen
  - Death recovery flow in HUD (load last save; fallback to start screen on failure).
- `StageManager` restores stage, position, health, and gold when loading progress.

## Asset Pipeline
### Where assets come from (free, commissioned, self-made, AI-generated)
- Third-party plugin:
  - Dialogue system uses bundled `addons/dialogue_manager`.
- Imported pixel-art assets:
  - Player, goblin, tileset, and object sprites are present under `assets/`.
  - Sources for many of these files are not yet documented in-project.
- Dialogue content:
  - Quest dialogue (`dialogues/village_mayor.dialogue`) appears to be project-authored.
- Background image files include stock-like naming (`stockcake`, `meadow-landscape...`), but explicit provenance is not documented in this snapshot.

### Asset credits and licenses
- Explicitly documented in this commit:
  - `addons/dialogue_manager/LICENSE` uses MIT License.
  - `assets/tileset/Dreamy Land Tileset/Readme_AutoTile.txt` references AutoTile technique source (`michagamedev.wordpress.com`).
- Missing documentation gap:
  - There is no centralized credits file yet for player sprites, goblin sprites, object packs, fonts, and background images.

### Placeholder vs. final art plan
- Current state (alpha/midterm-level):
  - Functional in-game sprites and maps are in place.
  - UI is primarily utilitarian and readability-focused.
- Remaining placeholder/provisional elements:
  - Some visual polish assets (effects, refined UI treatments, transition presentation) are still minimal.
  - Asset attribution metadata is incomplete and should be finalized before release.

## Playtesting Feedback

### What did playtesters struggle with?
- Losing progress after death
- Quest clarity and objective tracking were likely unclear, inferred from tracked quest HUD and quest modal additions.
- Dialogue-driven task flow needs structure
- Enemy readability in encounters needed improvement

### What changes are you making based on feedback?
- Added persistent save/load and start screen continue flow.
- Added quest tracking UI and quest list modal with tracked toggle.
- Added clearer quest dialogue flow and completion messaging.
- Added enemy health feedback for combat readability.

## Beta Roadmap
### What gets finished Weeks 13-15?
- Stabilize current vertical slice systems:
  - Quest lifecycle reliability (accept, track, objective, turn-in, repeat).
  - Save/load robustness across stage switches and death recovery.
  - Combat-state consistency for player and goblin AI.
- Content completion goals:
  - Expand quest content beyond single-goblin cleanup.
  - Add more interactables/NPC exchanges in existing maps.
- Documentation and release readiness:
  - Add a full credits/attribution document for all external assets.

### What's getting cut for time?
- Full RPG progression systems (leveling, skills/stat trees) remain out of scope for beta.
- Advanced enemy navigation/pathfinding is deferred (current direct chase remains).
- Large-scale content expansion (many new maps/biomes) is likely deferred in favor of stability.

### Polish priorities
- UI/UX polish:
  - Improve readability and consistency of HUD, quest modal, and message timing.
- Combat feel polish:
  - Tune hit windows, feedback, and pacing.
- Traversal polish:
  - Reduce edge-case spawn/transition issues.
- Production polish:
  - Clean temporary/backup artifacts and finalize asset provenance + licensing notes.
