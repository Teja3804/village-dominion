# Village Dominion — Project Scaffolding

**Document type:** Project structure and data contracts  
**References:** MVP_SPECIFICATION.md, DEVELOPMENT_ROADMAP.md  
**Engine:** Godot 4.x | **Language:** GDScript  
**Goal:** Structured, maintainable codebase for solo + AI-assisted development.

---

## 1. Final Project Folder Structure

### Folder responsibilities

| Folder | Responsibility |
|--------|----------------|
| **scenes/** | All `.tscn` files. Subfolders group by feature: main, village, ui, menu. |
| **scripts/autoload/** | Singletons (GameManager, EventBus, SaveManager). Registered in project.godot. |
| **scripts/core/** | Game logic and data classes: Village, AIVillage, BuildingInstance, managers (Diplomacy, Combat, Event). No UI. |
| **scripts/ui/** | UI controllers that display state and call into GameManager/EventBus. No game state ownership. |
| **data/** | Static config and IDs: constants.gd (enums), optional JSON definitions. Loaded at runtime. |
| **resources/** | Godot Resource (`.tres`) definitions: BuildingDefinition, ResourceDefinition, PersonalityDefinition, EventDefinition. |
| **assets/** | Art, fonts, audio. Subfolders: art (tiles, buildings, ui), fonts, audio. |
| **saves/** | Default directory for save files. Gitignored. |
| **tests/** | Optional: unit or integration test scenes/scripts. |

### Full directory tree

```
Village Dominion (Strategy & Diplomacy Simulator)/
├── project.godot
├── MVP_SPECIFICATION.md
├── DEVELOPMENT_ROADMAP.md
├── PROJECT_SCAFFOLDING.md
├── .gitignore
│
├── scenes/
│   ├── main/
│   │   └── Main.tscn
│   ├── village/
│   │   ├── VillageView.tscn
│   │   └── BuildingVisual.tscn
│   ├── ui/
│   │   ├── TopBarUI.tscn
│   │   ├── BuildingPanel.tscn
│   │   ├── DiplomacyPanel.tscn
│   │   ├── TradePanel.tscn
│   │   ├── EventPopup.tscn
│   │   ├── BattleResultPopup.tscn
│   │   └── GameOverScreen.tscn
│   └── menu/
│       └── MainMenu.tscn
│
├── scripts/
│   ├── main/
│   │   └── Main.gd
│   ├── autoload/
│   │   ├── GameManager.gd
│   │   ├── EventBus.gd
│   │   └── SaveManager.gd
│   ├── core/
│   │   ├── Village.gd
│   │   ├── AIVillage.gd
│   │   ├── BuildingInstance.gd
│   │   ├── DiplomacyManager.gd
│   │   ├── CombatResolver.gd
│   │   └── EventManager.gd
│   └── ui/
│       ├── TopBarUI.gd
│       ├── BuildingPanel.gd
│       ├── DiplomacyPanel.gd
│       ├── TradePanel.gd
│       ├── EventPopup.gd
│       ├── BattleResultPopup.gd
│       └── GameOverScreen.gd
│
├── data/
│   └── constants.gd
│
├── resources/
│   ├── building_definitions/
│   ├── resource_definitions/
│   ├── personality_definitions/
│   └── event_definitions/
│
├── assets/
│   ├── art/
│   │   ├── tiles/
│   │   ├── buildings/
│   │   └── ui/
│   ├── fonts/
│   └── audio/
│
├── saves/
│   └── .gitkeep
│
└── tests/
    └── .gitkeep
```

---

## 2. Scene Tree Architecture

### Main scenes

| Scene | Root node type | Child nodes | Responsibility |
|-------|----------------|-------------|----------------|
| **Main** | Control or Node2D | VillageView (instance), CanvasLayer (UI), optional Camera2D | Root of gameplay. Holds VillageView and UI layer; does not own game state. On ready, ensures GameManager exists and can wire UI. |
| **VillageView** | Node2D | TileMapLayer (terrain), Node2D (building container) | Displays grid and building visuals. Reads building list from GameManager; requests place/upgrade via GameManager. |
| **BuildingVisual** | Node2D or Control | Sprite/ColorRect/TextureRect, optional Label | One visual per BuildingInstance. Positioned by VillageView; no logic. |
| **TopBarUI** | Control | HBoxContainer (resource labels/bars), Next Turn button | Shows current resources and turn; emits or calls advance_turn. |
| **BuildingPanel** | Control | List/buttons (building types), cost labels, Upgrade/Assign workers | Build/upgrade and worker assignment; calls GameManager.place_building, upgrade_building, assign_workers. |
| **DiplomacyPanel** | Control | List of AI villages (name, relationship, personality), action buttons | Shows AI list and diplomacy actions; calls GameManager/DiplomacyManager. |
| **TradePanel** | Control | LineEdits/spinboxes (give/get amounts), Confirm/Cancel | Proposes trade; calls GameManager or DiplomacyManager.apply_trade. |
| **EventPopup** | Control | Label (title, description), Buttons (choices) | Shows one event; on choice, notifies GameManager/EventManager. |
| **BattleResultPopup** | Control | Label (result text), OK button | Shows battle outcome; closes on OK. |
| **GameOverScreen** | Control | Label (Victory/Defeat + reason), Restart, Quit | Shown when game_state is won/lost; Restart calls GameManager.new_game. |
| **MainMenu** | Control | New Game, Continue, Quit | Entry point; New Game loads Main, Continue loads Main and then SaveManager.load_game. |

### How scenes communicate

- **No scene holds game state.** All state lives in GameManager (and managers it owns).
- **UI → GameManager:** Direct method calls (e.g. `GameManager.place_building(cell, type_id)`, `GameManager.advance_turn()`).
- **GameManager / EventBus → UI:** Signals. EventBus emits `resources_changed`, `turn_advanced`, `event_triggered`, `game_over`, etc. UI scenes connect to these and refresh their display.
- **VillageView:** Gets building list from `GameManager.get_player_buildings()` (or similar) on demand or when `buildings_changed` fires; calls `GameManager.place_building()` / `upgrade_building()` when the player acts.
- **Popups:** EventPopup and BattleResultPopup are shown by a central UI controller or Main when EventBus fires `event_triggered` / `battle_resolved`; they call back into GameManager/EventManager to submit the chosen option.

---

## 3. Game State Architecture

### Global state (lives in GameManager or its managers)

| State | Owner | Description |
|-------|--------|-------------|
| **current_turn** | GameManager | Integer; incremented each advance_turn(). |
| **game_state** | GameManager | Enum: PLAYING, VICTORY, DEFEAT. Drives GameOverScreen. |
| **player_village** | GameManager | Single Village instance: buildings, resources, population, military. |
| **ai_villages** | GameManager | Array of AIVillage. Each has own resources, military, personality, relationship to player. |
| **relationships** | DiplomacyManager (or GameManager) | Per (player, ai) or per ai_id: relationship value, at_war, alliance. |
| **pending_event** | EventManager (or GameManager) | Current event + choices, if an event is being shown. |
| **rng_seed** | GameManager or EventManager | Optional; for reproducible events. |

### Local state (no global ownership)

- **UI display cache:** What a panel last showed (e.g. selected building). Can be re-built from GameManager; not persisted.
- **Selection:** Currently selected cell or building instance id. Can live in VillageView or BuildingPanel; not saved.

### Where things live (summary)

- **Player village state:** `GameManager.player_village` (Village).
- **AI village states:** `GameManager.ai_villages` (Array of AIVillage).
- **Resource totals:** Inside `player_village.resources` (Dict). AI villages have their own `.resources` or abstract wealth.
- **Diplomacy relationships:** `DiplomacyManager` (or GameManager) holds a map keyed by ai_id (or pair) → relationship value and flags.
- **Event state:** `EventManager` (or GameManager): pending_event, optional event history.
- **Game time / tick:** `GameManager.current_turn`; `advance_turn()` drives production, consumption, AI, events, victory/loss check.

### State flow

1. **Player action** (build, diplomacy, attack) → UI calls GameManager → GameManager updates its state (Village, relationships, etc.).
2. **GameManager** emits or EventBus emits (e.g. resources_changed, buildings_changed) → UI refreshes.
3. **advance_turn():** GameManager updates production/consumption, then calls EventManager.roll_for_event(), then AI decisions (DiplomacyManager / AIVillage), then CombatResolver if battles occur, then check_victory_loss(); after each logical step, emit signals so UI can update.

---

## 4. Core Scripts / Classes

| Script | Responsibility | Key data stored | Important methods |
|--------|----------------|-----------------|--------------------|
| **GameManager** | Central game state; time advance; orchestration; victory/loss. | current_turn, game_state, player_village, ai_villages, refs to DiplomacyManager, EventManager. | new_game(), advance_turn(), place_building(cell, type_id), upgrade_building(instance_id), assign_workers(instance_id, count), get_player_resources(), get_player_buildings(), check_victory_loss(), save_game(), load_game() |
| **Village** | One village's state: buildings, resources, population, military. | village_id, display_name, building_instances[], resources{}, population, max_population, military_strength | add_building(inst), remove_building(instance_id), get_production_per_turn(), apply_production(), get_consumption(), recalculate_max_population(), to_dict(), from_dict() |
| **AIVillage** | AI village + personality + relationship to player. | Extends or composes Village; personality_type_id, relationship_with_player, at_war | get_relationship(), set_relationship(delta), decide_response(action, params), to_dict(), from_dict() |
| **BuildingInstance** | One placed building (runtime). | instance_id, building_type_id, grid_x, grid_y, level, assigned_workers | to_dict(), from_dict() |
| **DiplomacyManager** | Relationship storage; apply diplomacy actions. | relationship_map (ai_id → value or struct), at_war flags | get_relationship(ai_id), set_relationship(ai_id, value), apply_action(player_village, ai_village, action_type, params) |
| **CombatResolver** | Stateless battle resolution. | None | resolve_battle(attacker_strength, defender_strength, battle_type, modifiers) → result dict |
| **EventManager** | When to fire events; apply choice effects. | event_definitions[], pending_event, optional seed | roll_for_event(turn, conditions), get_pending_event(), apply_choice(choice_index), clear_pending() |
| **SaveManager** | Serialise/deserialise full state to disk. | last_save_path (optional) | save(path), load(path), has_save() |
| **EventBus** | Global signals for loose coupling. | None | Signals: resources_changed, turn_advanced, buildings_changed, event_triggered, battle_resolved, diplomacy_updated, game_over |
| **TopBarUI** | Display resources and turn; Next Turn button. | None (reads from GameManager) | _ready(): connect EventBus; _on_resources_changed(), _on_turn_advanced(); _on_next_turn_pressed() → GameManager.advance_turn() |
| **BuildingPanel** | Build/upgrade and worker UI. | selected_instance_id (local) | refresh_from_game_state(), _on_build_requested(type_id), _on_upgrade_requested(), _on_assign_workers(instance_id, count) |
| **DiplomacyPanel** | List AI villages and actions. | selected_ai_id (local) | refresh_from_game_state(), _on_gift(), _on_trade(), _on_declare_war() |
| **EventPopup** | Show event and choices. | event_data (passed when shown) | show_event(data), _on_choice_selected(index) |

---

## 5. Data Models

Structures that represent core game objects. Support both player and AI villages where applicable.

### Village

- **village_id:** String or int (unique)
- **display_name:** String
- **building_instances:** Array of BuildingInstance
- **resources:** Dictionary (resource_id → int amount)
- **population:** int
- **max_population:** int (derived from housing buildings)
- **military_strength:** int

### BuildingInstance (runtime)

- **instance_id:** String or int (unique per instance)
- **building_type_id:** String or int (references BuildingDefinition)
- **grid_x, grid_y:** int
- **level:** int (1..max_level)
- **assigned_workers:** int (0..building_definition.worker_slots)

### BuildingDefinition (static Resource)

- **building_type_id:** String or int
- **name:** String
- **description:** String
- **cost:** Dictionary (resource_id → int)
- **worker_slots:** int
- **production:** Dictionary (resource_id → float rate per worker per level) or equivalent
- **max_level:** int
- **unlock_village_level:** int (optional)
- **building_category:** String (e.g. "production", "housing", "military")

### Resource (definition only; no runtime "Resource" entity)

- **resource_id:** String or int
- **name:** String
- **icon_path:** String (optional)
- **can_go_negative:** bool

Stockpiles are Village.resources (Dict resource_id → amount).

### LeaderPersonality (static Resource)

- **personality_type_id:** String or int
- **name:** String
- **trade_accept_modifier:** float or int (relationship threshold modifier)
- **war_tendency:** float (0..1)
- **alliance_tendency:** float
- **reaction_to_gift:** int (relationship delta)
- **reaction_to_insult:** int (optional)

### DiplomacyRelation (runtime, per player–AI pair)

- **ai_village_id:** String or int
- **relationship_value:** int (-100 to 100 or similar)
- **at_war:** bool
- **allied:** bool (optional)
- **truce_until_turn:** int (optional)

### BattleResult (ephemeral or for history)

- **attacker_village_id:** String or int
- **defender_village_id:** String or int
- **battle_type:** String (e.g. "raid", "invasion")
- **winner_id:** String or int
- **attacker_losses:** int (military)
- **defender_losses:** int
- **pillage:** Dictionary (resource_id → int) optional
- **turn:** int

### WorldEvent (template = static; instance = when fired)

**EventDefinition (template):**

- **event_id:** String or int
- **title:** String
- **description:** String
- **choices:** Array of { "text": String, "effects": Dictionary (resource_deltas, relationship_deltas, population_delta) }

**EventInstance (when shown):**

- **event_definition_id:** String or int
- **chosen_choice_index:** int (-1 until chosen)

---

## 6. Static Game Data

Data that does not change during a run. Used for balance and content.

| Data type | Recommended storage | Why |
|-----------|---------------------|-----|
| **Building definitions** | Godot Resources (`.tres`) in resources/building_definitions/ | Editor-friendly; type-safe; easy to add fields. |
| **Resource type definitions** | Godot Resources or data/constants.gd (enum + name table) | Small set; enum in code keeps IDs consistent. |
| **Leader personalities** | Godot Resources in resources/personality_definitions/ | Tunable modifiers; same pattern as buildings. |
| **Event definitions** | Godot Resources or JSON in resources/event_definitions/ | Resources if you want per-event editor; JSON if you prefer bulk edit. |
| **Diplomacy action effects** | In code (DiplomacyManager) or small Resource (action_id → relationship delta, etc.) | Few actions; constants or one small config. |

**Recommendation:**

- **Godot Resources** for: BuildingDefinition, PersonalityDefinition, ResourceDefinition (if you want icon path etc. in editor). Good for AI-assisted work: "add a new building" = add a new .tres and reference it.
- **Script constants / enums** for: ResourceType, BuildingType, PersonalityType, DiplomacyAction, BattleType. Single source of IDs; no typos.
- **JSON** for: Event definitions if you prefer one events.json; or use Resource for each event. Optional.

**Do not** put runtime state (current resources, relationships, turn) in static data.

---

## 7. Autoload / Singleton Design

| Autoload name | Purpose | Data stored | Example responsibilities |
|---------------|---------|-------------|---------------------------|
| **GameManager** | Single source of truth for game state; orchestration. | current_turn, game_state, player_village, ai_villages, references to DiplomacyManager, EventManager. | new_game(), advance_turn(), place_building(), upgrade_building(), check_victory_loss(), get_player_resources(), save/load delegation. |
| **EventBus** | Decouple systems via signals. | None. | Emit resources_changed, turn_advanced, buildings_changed, event_triggered, battle_resolved, game_over. |
| **SaveManager** | Persist and restore game state. | Optional: last_save_path. | save(path), load(path), has_save(); reads state from GameManager, writes to JSON. |

**What should NOT be in singletons:**

- UI node references (panels, buttons). Keep in scenes.
- Asset loading (use ResourceLoader or scene tree).
- Village or BuildingInstance data duplicated outside GameManager.
- Game logic that belongs in Village or CombatResolver (keep in core scripts, called by GameManager).

---

## 8. Communication Between Systems

- **Signals (EventBus):** GameManager (or managers) emit after state changes. UI and other systems connect and refresh. Use for: resources_changed, turn_advanced, buildings_changed, event_triggered, battle_resolved, game_over. Keeps GameManager from depending on UI.
- **Direct method calls (UI → GameManager):** UI calls GameManager.place_building(), advance_turn(), etc. One-way; UI does not expose state.
- **Direct method calls (GameManager → managers):** GameManager calls DiplomacyManager.apply_action(), EventManager.roll_for_event(), CombatResolver.resolve_battle(). Managers can be owned by GameManager (not autoloads).
- **Return values:** CombatResolver returns a result dict; EventManager returns pending event; DiplomacyManager returns accept/refuse. No long call chains.

**Example flows:**

- **Village → resources:** Village.apply_production() updates Village.resources; GameManager then emits EventBus.resources_changed. (Village does not touch EventBus; GameManager does.)
- **AIManager → DiplomacyManager:** GameManager.advance_turn() calls each AIVillage.decide_action(); if action is "declare_war", GameManager calls DiplomacyManager.set_relationship(ai_id, ...) and sets at_war; then emits diplomacy_updated.
- **EventManager → GameManager:** EventManager.roll_for_event() may set pending_event; GameManager emits event_triggered; UI shows EventPopup; on choice, UI calls EventManager.apply_choice(index); EventManager applies effects via GameManager (resource/relationship deltas) and clears pending.
- **BattleManager / CombatResolver → UI:** GameManager triggers battle, calls CombatResolver.resolve_battle(); applies losses to Village/AIVillage; emits battle_resolved with result; UI (or Main) shows BattleResultPopup with result text.

---

## 9. Initial Stub Files

Create these files with minimal content so the project parses and runs.

### data/constants.gd

- Enums or const for: ResourceType, BuildingType, PersonalityType.
- Optional: DiplomacyAction, BattleType, GameState.
- No logic; only IDs and names.

### scripts/autoload/GameManager.gd

- Extends Node.
- Variables: current_turn (int), game_state (enum), player_village (Village), ai_villages (Array).
- Stub methods: new_game(), advance_turn(), place_building(), upgrade_building(), get_player_resources(), check_victory_loss() — empty or print/log.
- No scene required; autoload.

### scripts/autoload/EventBus.gd

- Extends Node.
- Declare signals: resources_changed, turn_advanced, buildings_changed, event_triggered, battle_resolved, game_over.
- No logic.

### scripts/autoload/SaveManager.gd

- Extends Node.
- Stub methods: save(path), load(path), has_save() → false.
- No state yet.

### scripts/core/Village.gd

- Class or inner class: Village. Variables: village_id, display_name, building_instances (Array), resources (Dict), population, max_population, military_strength.
- Stub: to_dict() → {}, from_dict() → void.

### scripts/core/AIVillage.gd

- Extends or wraps Village (or duplicate structure). Add: personality_type_id, relationship_with_player, at_war.
- Stub: decide_response() → null or false.

### scripts/core/BuildingInstance.gd

- Class or Resource: instance_id, building_type_id, grid_x, grid_y, level, assigned_workers.
- Stub: to_dict(), from_dict().

### scripts/core/DiplomacyManager.gd

- Extends RefCounted or Node. Stub: get_relationship(ai_id), set_relationship(ai_id, value), apply_action(...) — empty or print.

### scripts/core/CombatResolver.gd

- Extends RefCounted or Node. Static or stateless. Stub: resolve_battle(attacker_strength, defender_strength, battle_type) → {}.

### scripts/core/EventManager.gd

- Extends RefCounted or Node. Stub: roll_for_event(turn), get_pending_event() → null, apply_choice(index).

### scripts/ui/*.gd

- Each: extends Control (or appropriate node). _ready() with optional connect to EventBus. Stub _on_* handlers. No game state.

### Minimal contents rule

- Every script must parse (no syntax errors).
- Autoloads must not depend on scenes that are not always loaded.
- Core scripts (Village, BuildingInstance, etc.) must not depend on Node or scene tree unless required; prefer RefCounted or static for data-only classes.

---

## 10. Data Flow Diagram (Conceptual)

**Game tick loop (advance_turn):**

1. **Game tick** — Player or timer calls GameManager.advance_turn().
2. **Resource production** — GameManager asks player_village.get_production_per_turn() and applies to player_village.resources; same for AI villages if simulated.
3. **Consumption** — Apply food (and other) consumption; update population (growth/starvation).
4. **AI decisions** — For each AIVillage, optionally decide_action() (trade, war, etc.); update relationships and at_war via DiplomacyManager.
5. **Diplomacy updates** — Apply any pending deals or truce expiry.
6. **Events** — EventManager.roll_for_event(turn); if event fires, set pending_event and emit event_triggered; wait for player choice (next frame or later); when choice made, apply_choice() → resource/relationship deltas.
7. **Battles** — If at_war and battle triggered this turn, CombatResolver.resolve_battle(); apply losses; emit battle_resolved.
8. **Victory/loss check** — GameManager.check_victory_loss(); if won/lost, set game_state and emit game_over.
9. **UI update** — EventBus signals (resources_changed, turn_advanced, etc.) already emitted at appropriate steps; UI refreshes.

**Player actions (between ticks):**

- Build / upgrade / assign workers → GameManager updates player_village → emit buildings_changed, resources_changed.
- Diplomacy (gift, trade, war) → GameManager or DiplomacyManager updates relationships and resources → emit diplomacy_updated, resources_changed.
- Next Turn button → advance_turn() as above.

---

## 11. First Coding Targets

Implement in this order so each step has a working base.

| Order | System | Why this order |
|-------|--------|----------------|
| 1 | **Data models + constants** (Village, BuildingInstance, BuildingDefinition, constants.gd) | Everything else depends on IDs and structures. Must be serialisable (to_dict/from_dict). |
| 2 | **GameManager + tick** (new_game(), advance_turn(), player_village creation, apply production/consumption) | Central state and time loop; no UI yet. Validate with print or a simple test. |
| 3 | **Resource display + Next Turn** (TopBarUI or minimal bar, EventBus.resources_changed / turn_advanced) | Proves UI can read from GameManager and that advance_turn() runs. |
| 4 | **VillageView + building placement** (grid, place_building, deduct cost, show building visual) | First player action that changes state; proves full build loop. |
| 5 | **BuildingPanel + upgrade + worker assignment** (assign_workers, production scaling) | Completes vertical slice: place → assign → turn → see resources change. |

After 5: you have the vertical slice. Then add AI villages (M5), diplomacy (M6–M7), combat (M8), events (M9), victory/loss (M10), save/load (M11), content (M12).

---

## 12. Developer Setup Instructions

### Create the project

1. Open Godot 4.x.
2. New Project → choose **Empty** (or Minimal).
3. Set project path to: `.../Village Dominion (Strategy & Diplomacy Simulator)` (or create that folder and select it).
4. Renderer: Canvas (2D) or compatibility; no 3D required.
5. Create Folder.

### Place folders

1. In FileSystem, create the folders from Section 1 (scenes, scripts, data, resources, assets, saves, tests).
2. Create subfolders: scenes/main, scenes/village, scenes/ui, scenes/menu; scripts/autoload, scripts/core, scripts/ui; resources/building_definitions, etc.; assets/art/tiles, assets/art/buildings, assets/art/ui, assets/fonts, assets/audio.
3. Add saves/.gitkeep and tests/.gitkeep so empty folders are versioned (optional).

### Register autoloads

1. Project → Project Settings → Autoload.
2. Add:
   - **EventBus** → path: `res://scripts/autoload/EventBus.gd` (enable).
   - **GameManager** → path: `res://scripts/autoload/GameManager.gd` (enable).
   - **SaveManager** → path: `res://scripts/autoload/SaveManager.gd` (enable).
3. Order: EventBus first (no dependencies), then GameManager, then SaveManager.

### Create the main scene

1. Create scene: Scene → New Scene → Other Node → Node (or Control for 2D UI root). Save as `scenes/main/Main.tscn`.
2. Add child: Instance scene or add Node2D named VillageView (placeholder); add CanvasLayer, add child Control for UI (e.g. TopBarUI placeholder).
3. Attach script to root if desired (e.g. `scripts/main/Main.gd` or leave unscripted).
4. Project → Project Settings → Application → Run → Main Scene: set to `res://scenes/main/Main.tscn`.

### Run the game

1. Press F5 or Project → Run. Main scene runs; GameManager and EventBus exist (no error if stubs are empty).
2. To test: In GameManager._ready() or new_game(), create a Village and print its to_dict(); or call advance_turn() and print resources.

### Optional: MainMenu as entry

1. Create `scenes/menu/MainMenu.tscn` with New Game / Quit.
2. New Game → change scene to Main.tscn and call GameManager.new_game().
3. Set MainMenu as main scene in Project Settings so game starts at menu.

---

*End of Project Scaffolding. Use with MVP_SPECIFICATION.md and DEVELOPMENT_ROADMAP.md.*
