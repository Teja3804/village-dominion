# Village Dominion — Strategy & Diplomacy Simulator

A turn-based village strategy game built in Godot 4. Build your village, manage resources, train soldiers, and navigate a world of AI leaders with unique personalities through war, diplomacy, trade, and alliances.

## Features

- **Village Building System** — 12 building types with upgrade paths
- **Resource Economy** — Food, Wood, Stone, Gold, Weapons with production/consumption
- **AI Villages** — 5 personality types (Aggressive, Diplomatic, Trader, Opportunist, Isolationist)
- **Diplomacy System** — Alliances, trade routes, gifts, threats, peace proposals
- **War System** — Turn-based combat simulation with loot and morale effects
- **World Events** — 12 random events (famine, plague, bandit attacks, gold rush, festivals, etc.)
- **Save/Load** — 3 save slots using JSON
- **Win/Lose Conditions** — Survive 10 years or conquer all villages

## Controls

| Key | Action |
|-----|--------|
| `Enter` | End Turn |
| `B` | Open Building Panel |
| `D` | Open Diplomacy Panel |
| `T` | Open Trade Panel |
| `F5` | Quick Save (Slot 1) |
| `F9` | Quick Load (Slot 1) |
| `Esc` | Close Panel |

## Project Structure

```
godot-project/
├── project.godot
├── scenes/
│   └── main/Main.tscn          # Main game scene (all UI embedded)
├── scripts/
│   ├── core/
│   │   ├── Main.gd             # Root scene controller
│   │   ├── Village.gd          # Village data + logic
│   │   ├── AIVillage.gd        # AI personality decisions
│   │   └── CombatResolver.gd   # Battle simulation
│   ├── data/
│   │   ├── constants.gd        # All game enums + constants
│   │   ├── building_definition.gd
│   │   └── building_database.gd
│   ├── managers/
│   │   ├── EventBus.gd         # Global signal bus (autoload)
│   │   ├── GameManager.gd      # Turn loop + village management (autoload)
│   │   ├── SaveManager.gd      # Save/load (autoload)
│   │   ├── ai_manager.gd       # AI turn processing
│   │   ├── battle_manager.gd   # Attack execution
│   │   ├── diplomacy_manager.gd
│   │   └── event_manager.gd    # Random world events
│   └── ui/
│       ├── MainUI.gd           # HUD + panel routing
│       ├── TopBarUI.gd         # Resource display
│       ├── BuildingPanel.gd    # Build/upgrade UI
│       ├── DiplomacyPanel.gd   # Diplomacy actions
│       ├── TradePanel.gd       # Trade route management
│       ├── EventPopup.gd       # World event notification
│       ├── BattleResultPopup.gd
│       ├── SaveMenu.gd
│       └── GameOverScreen.gd
├── data/
│   ├── buildings.json          # Building reference data
│   ├── events.json             # Event definitions
│   └── personalities.json      # AI personality data
docs/
├── MVP_SPEC.md
└── DEV_ROADMAP.md
```

## Development Roadmap

### Phase 1 — Core (Done)
- [x] Village building system
- [x] Resource economy
- [x] Building database

### Phase 2 — AI & Combat (Done)
- [x] AI village personalities
- [x] Combat resolver
- [x] Battle manager

### Phase 3 — Diplomacy (Done)
- [x] Relationship scores
- [x] Alliance, peace, war, trade, gift, threat actions
- [x] AI diplomacy decisions

### Phase 4 — Events & Polish (Done)
- [x] 12 world event types
- [x] Notification log
- [x] Save/load system
- [x] Game over screen

### Phase 5 — Visual Polish (TODO)
- [ ] TileMap world map
- [ ] Village sprites and icons
- [ ] Animated transitions
- [ ] Sound effects / music

### Phase 6 — Advanced Features (TODO)
- [ ] Espionage system
- [ ] Reputation system
- [ ] Procedural map generation
- [ ] Tech tree
- [ ] Trade caravan animations

## How to Run

1. Install [Godot 4.2+](https://godotengine.org/)
2. Open `godot-project/project.godot`
3. Press F5 or click the Play button

## Tech Stack

- **Engine**: Godot 4.2
- **Language**: GDScript
- **Architecture**: Signal-driven (EventBus pattern), data-driven buildings
