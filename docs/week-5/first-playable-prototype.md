# First Playable Prototype

## Core Loop Diagram
### 1) Main Route Selection
```mermaid
flowchart LR
    A(["Start"]) --> B[/"Player Choose Location"/]
    B --> C{"Choose Area"}
    C --> D{"If arena is unlocked"}
    D -- "Yes" --> E["Arena Flow"]
    D -- "No" --> B
    C --> T["Taurace (Central Town) Flow"]
    C --> BW["Bramblewilds (Overgrown Forest) Flow"]
```

### 2) Taurace (Central Town) Flow
```mermaid
flowchart TD
    T["Taurace (Central Town)"] --> T1{"Town Actions"}
    T1 --> AQ["Accept Quests"]
    AQ --> PH["Player Heals"]
    PH --> T

    T1 --> SQ[/"Submit Quests"/]
    SQ --> RW["Player receives rewards (e.g., gold)"]
    RW --> T

    T1 --> BS[/"Buy in Shop"/]
    BS --> EX["Exchange gold for items"]
    EX --> T1
```

### 3) Bramblewilds (Overgrown Forest) Flow
```mermaid
flowchart TD
    BW["Bramblewilds (Overgrown Forest)"] --> F1{"Forest Progress"}

    F1 --> KM[/"Kill Monsters"/]
    KM --> GG["Get gold"]
    GG --> BW

    F1 --> AC[/"Accomplish Quest"/]
    AC --> QL["Quest list records progress"]
    QL --> F1

    F1 --> SW{"Has special weapon?"}
    SW -- "No" --> ST[/"Interact with statue"/]
    ST --> WG["Weapon is given to the player"]
    WG --> BW
    SW -- "Yes" --> BW
```

### 4) Arena Flow
```mermaid
flowchart TD
    E["Arena"] --> F["Boss Battle Commences"]
    F --> G{"Did player win the boss battle?"}
    G -- "Yes" --> H(["End"])
    G -- "No" --> T["Return to Taurace (Central Town)"]
```

## Control Scheme
### Movement (WASD)
- Use `W`, `A`, `S`, and `D` for basic movement.
- Since Pixel Origins is a 2D game with four-direction movement, this layout is practical and familiar for players.
- This scheme is widely used in popular games, including Minecraft and Oceanhorn (PC).
- With mouse-based interaction on the opposite hand, WASD remains the most ergonomic movement setup.

### Attack (Left Click)
- Use the left mouse button as the primary attack input.
- Left-click attack is a common and intuitive standard across many action games.

### Interaction (`E`)
- Use `E` to interact with NPCs, interactable world objects, and location entrances.
- `E` is close to WASD, making interactions easy to perform while using the mouse at the same time.

## Prototype Learnings
### Working Features During Playtesting
- The player can move and attack.
- Enemies detect the player using a field-of-vision trigger and begin attacking when the player enters that range.

### Features to Rework
- Manual dialogue setup is too tedious; consider using an addon such as Dialogue Manager 3.
- Current player attack presentation only supports left and right facing animations; we still need assets and implementation for up and down facing attacks.

### Technical Surprises
- Player knockback on damage is finicky and requires more precise collision setup and tuning.
- A stage manager is needed to handle player transitions between maps reliably.

## Updated Scope
Based on the prototype, the MVP is now focused on:
- Two weapons
- One town
- One biome
- One enemy type
