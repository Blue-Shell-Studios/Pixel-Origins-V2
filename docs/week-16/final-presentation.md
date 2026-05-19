# Final Presentation

## Postmortem
### What went well?
- The team successfully shipped a playable end-to-end build with a complete route:
  - Start screen -> Overworld -> Tauracre -> Bramble Wilds -> Ancient Ruins boss encounter.
- The v3 migration consolidated interaction and stage flow through dedicated managers (`StageManager`, `InteractionManager`, `DialogueService`, `SoundManager`, `DeathManager`).
- Combat and progression loops became clearer by final week:
  - sword + bow loadout,
  - coin economy,
  - NPC quest loop,
  - death recovery,
  - and encounter escalation with a multi-phase boss.
- Audio integration and UI feedback improved overall player readability and polish.

### What would we change?
- Start system/data architecture planning earlier to avoid late migration pressure.
- Break very large scripts into smaller components earlier (especially player and boss logic).
- Add explicit in-repo documentation for every new asset at the time it is imported (source + license + allowed use).
- Add lightweight automated checks for scene health and merge conflict markers before final integration.

### Key learnings
- Vertical-slice-first development works, but only if refactors are scheduled before content expansion.
- Manager-based modularization helps shipping speed, but too many global autoload dependencies can increase coupling.
- Encounter design quality depends as much on feedback systems (audio/visual/status text) as on raw mechanics.
- Credits and licensing should be treated as production tasks, not end-of-project cleanup.

## Architecture Reflection
### Which design patterns saved us?
- Manager/Service pattern (autoload singletons):
  - Stage, interaction, dialogue, sound, quests, death flow, and save snapshots are centralized.
- Template/base-class reuse:
  - `BaseEnemy` and `BaseNPC` reduced repeated logic for aggro/contact damage and interaction handling.
- Event-driven signaling:
  - Signals between managers/entities kept many systems decoupled enough for quick iteration.
- Snapshot/Memento-like state capture:
  - Save/death recovery workflows rely on session state snapshots and restore points.

### Where did our architecture break down?
- Manager sprawl and global coupling:
  - Many systems depend on each other through autoload globals, making behavior harder to trace.
- Monolithic gameplay scripts:
  - `entities/enemies/ancient_ruins_boss.gd` and `entities/player/player.gd` grew large and multi-responsibility.
- Mixed persistence strategy:
  - Session snapshot recovery works, but persistent long-term save intent evolved over time and created scope churn.
- Data is still partly hard-coded (stage IDs, mappings, quest values), which limits scalability.

### How would we architect it differently?
- Keep autoloads thinner and move game logic into scene-local components with clear interfaces.
- Convert large entity scripts into explicit state modules (movement/combat/animation/loot/AI separated).
- Move stage, quest, and audio routing to data-driven resources instead of hard-coded dictionaries.
- Formalize save layers:
  - runtime session state,
  - checkpoint state,
  - persistent profile state.
- Add CI/editor tooling for scene validation and conflict-marker detection.

## Code Statistics
### Lines of code
- Project gameplay/content code (excluding `addons/`):
  - `.gd`: 36 files, ~4,839 lines
  - `.tscn`: 21 files, ~24,800 lines
  - Total project script+scene lines: ~29,639
- Including third-party addon code/scenes:
  - `.gd` + `.cs` + `.tscn`: 117 files, ~42,709 lines

### Number of commits
- Total commits: **38**

### Refactors performed
- Commits with subjects that start with `refactor:`: **6**
- Key refactors visible in history:
  - entities split and collision flow cleanup,
  - landmark/stage transition rework,
  - v3 migration,
  - stage scene repair,
  - y-ordering fixes.

## Complete Credits
### All asset attributions
From the `README.md` asset table in this snapshot:
- [Little Dreamyland Asset Pack](https://starmixu.itch.io/little-dreamyland-asset-pack) by Starmixu and Utaskuas
- [Dan's RPG Set](https://danieruart.itch.io/16x16-rpg-fantasy-character-and-tileset) by DanieruArt
- [Sunny side asset pack](https://danieldiggle.itch.io/sunnyside) by daniellediggle
- [Pixel Poem Dungeon](https://pixel-poem.itch.io/dungeon-assetpuck) by Pixel_Poem (support MiniPainter)
- [Monopixel Monsters](https://monopixelart.itch.io/) by MonoPixel
- [Broken Sword Asset Pack](https://from-chris.itch.io/broken-sword-asset-pack) by Chris
- [Pixel Crawler](https://anokolisa.itch.io/free-pixel-art-asset-pack-topdown-tileset-rpg-16x16-sprites) by Anokolisa
- [Super Retro World Character pack](https://gif-superretroworld.itch.io/character-pack) by Gif
- [RPG Dungeon Pack](https://gif-superretroworld.itch.io/dungeon-pack) by Gif (@gif_not_jif), Noiracide (@Noiracide), and Romi (@DessRomaric)
- [RPG Interior Pack](https://gif-superretroworld.itch.io/interior-pack) by The low-res arist (@Pixelart_asset)
- [Necomancer Boss Sheet](https://creativekind.itch.io/necromancer-free) by CreativeKind
- [Start Screen Background](https://stockcake.com/i/pixel-meadow-sunset_2513211_1497930) from StockCake
- Royalty Free Musics and SFXs from [Pixabay](https://pixabay.com/) and [mixkit](https://mixkit.co/)

### Third-party code/plugins
- Dialogue Manager plugin (`addons/dialogue_manager`) by Nathan Hoad and contributors.
- License in repository: MIT (`addons/dialogue_manager/LICENSE`).

### Playtester acknowledgments
- Empty