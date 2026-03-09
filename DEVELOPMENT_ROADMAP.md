# Village Dominion — Development Roadmap

**Document type:** Execution plan for solo developer  
**References:** MVP_SPECIFICATION.md (authoritative scope)  
**Engine:** Godot 4.x  
**Target:** Playable prototype with clear milestones and testable stages

---

## 1. Development Strategy

### Overall strategy

Build the game in **layers**: data and simulation first, then presentation, then content. The solo developer should never add a new system until the layer it depends on is stable and serialisable. Each milestone ends with a **definition of done** and a quick validation step so the next phase does not rest on untested ground.

**Risk reduction:**  
- **Vertical slice early.** The first playable moment is “place one building → see resources change → advance time.” No diplomacy, no events, no combat until that loop is solid. This proves the core data model and time loop before any AI or UI complexity.  
- **One source of truth.** All game state lives in a small set of managers and data classes. UI only displays and requests changes; it never owns village state, resources, or relationships. This keeps save/load and AI changes predictable.  
- **Content last.** Implement systems with minimal content (e.g. 2 resources, 3 buildings, 1 AI village) until the pipeline works. Then scale to MVP numbers (4–5 resources, 10–14 buildings, 4–6 AI villages) in a dedicated “content fill” phase.

**What to build first:**  
- Data model and IDs (Village, Building, Resource definitions and instances).  
- GameManager + time tick + resource production/consumption.  
- Village view + building placement + resource display.  

**What to delay:**  
- Extra building types, events, and AI personalities until the slice works.  
- Polish (animations, sound, tutorial) until MVP feature-complete.  
- Any system not listed in MVP_SPECIFICATION.md (e.g. espionage, caravans) until after MVP ship.

**Why this order:** Without a working economy and placement, diplomacy and combat have nothing to attach to. Without a working slice, adding more content multiplies debugging. Building in dependency order (data → simulation → UI → content) keeps each step verifiable and avoids big rewrites.

---

## 2. Milestone Roadmap

Milestones are ordered so each one builds on the previous. “Definition of done” is the gate before moving on.

---

### M1: Project bootstrap and data foundations

**Goal:** Godot project runs; folder structure exists; core data types and IDs are defined; no gameplay yet.

**Features included:**  
- New Godot 4.x project with recommended folder structure (see Section 4).  
- Enums or constants for `ResourceType`, `BuildingType`, `PersonalityType` (and optionally `DiplomacyAction`, `BattleType`).  
- Scripts: `ResourceDefinition` (Resource), `BuildingDefinition` (Resource), `BuildingInstance` (class with id, type_id, position, level, assigned_workers).  
- Script: `Village` (class) holding: village_id, display_name, Dictionary of resource_id → amount, array of BuildingInstance, population, max_population, military_strength.  
- No scenes required yet; can test by instantiating Village in a test script and printing state.

**Dependencies:** None.

**Definition of done:**  
- Project opens in Godot; scripts parse; creating a Village and adding a BuildingInstance does not error.  
- Village can be converted to Dictionary (for future save) and back without data loss.

---

### M2: GameManager and time loop

**Goal:** A single autoload owns game state; time advances (turn-based or timer); player village exists and can be ticked.

**Features included:**  
- Autoload: `GameManager`. Holds: current_turn (or game_time), player_village (Village instance), reference to resource/building definitions.  
- Method: `advance_turn()` (or `tick()`). For player village: apply production from buildings (using definitions), apply consumption (e.g. food per population), clamp resources and population to caps.  
- At least 2 resource types and 2 building definitions (e.g. Farm, LumberCamp) with production values. No placement yet; start with a pre-defined list of building instances on the player village for testing.  
- Optional: `EventBus` autoload with signals like `resources_changed`, `turn_advanced`.

**Dependencies:** M1 (Village, BuildingInstance, definitions).

**Definition of done:**  
- Running the game and calling `GameManager.advance_turn()` N times changes resource amounts according to building production and consumption.  
- No crashes; numbers are predictable from definitions.

---

### M3: Village view and building placement

**Goal:** Player sees a grid (TileMap or placeholder); can place and upgrade buildings; costs deduct from village resources; placed buildings appear and are stored in player village.

**Features included:**  
- Scene: Main (root). Scene: VillageView with TileMap (buildable terrain) and a container for building visuals (e.g. ColorRect or simple sprite per building type).  
- Building placement: click or select cell → choose building from a simple list/panel → if cost met and cell valid, deduct cost, add BuildingInstance to Village, show visual.  
- Building upgrade: select existing building → if upgrade cost met and level < max, deduct cost, increment level, refresh visual.  
- UI: ResourceBar (labels or bars showing current resources).  
- GameManager remains source of truth; VillageView and UI read from GameManager and call GameManager to perform build/upgrade.

**Dependencies:** M2 (GameManager, Village, production).

**Definition of done:**  
- Player can place at least 2 building types and upgrade once.  
- Resources decrease on build/upgrade; after advance_turn(), resources increase according to placed buildings.  
- Reloading the scene loses state (save not required yet).

---

### M4: Worker assignment and population

**Goal:** Population is capped by housing; workers can be assigned to production buildings; production scales with assigned workers (e.g. output = base_rate * min(assigned, slots)).

**Features included:**  
- Housing buildings define max_population contribution; Village recalculates max_population from building list.  
- Population growth: simple rule (e.g. surplus food per turn adds growth; starvation reduces population or triggers loss later).  
- Worker assignment UI: select building → set assigned workers (0 to building’s worker_slots); Village stores assigned_workers per BuildingInstance.  
- Production formula uses assigned_workers (e.g. production = definition.output_per_worker * assigned_workers * level_multiplier).

**Dependencies:** M3 (buildings, Village, definitions).

**Definition of done:**  
- Adding housing increases max population; assigning workers to a production building changes its output; advance_turn() reflects both.  
- Population can grow or shrink based on food (formula is tunable in data).

---

### M5: AI villages and relationship model

**Goal:** Multiple AI villages exist in data; each has personality, resources, military strength, and a relationship value with the player. No UI yet.

**Features included:**  
- Class (or Resource): `AIVillage` extending or composing Village data (id, name, personality_type, relationship_with_player, military_strength, simplified or full stockpile).  
- GameManager holds array of AIVillage; initial relationship values set at game start.  
- `DiplomacyManager` (can be script or part of GameManager): get_relationship(player_id, ai_id), set_relationship(delta or absolute). Relationship in range e.g. -100 to +100 or discrete states.  
- PersonalityDefinition (Resource): personality_type_id, name, modifiers (e.g. trade_accept_bonus, war_tendency). Used later for AI decisions.  
- No AI decisions yet; only data and accessors.

**Dependencies:** M2 (GameManager, Village pattern).

**Definition of done:**  
- GameManager has 2–4 AIVillages; DiplomacyManager returns relationship for each; relationship can be changed in code and persists in GameManager state.  
- All of this is serialisable to Dictionary (no Node-dependent state).

---

### M6: Diplomacy actions and AI response logic

**Goal:** Player can perform a small set of diplomacy actions toward an AI village; AI accepts or refuses based on personality and relationship; relationship and resources update.

**Features included:**  
- Actions: Gift (player gives resources → relationship up), Request Trade (offer resource A for resource B → AI accepts/refuses), Declare War (relationship drop, state = at_war).  
- DiplomacyManager or GameManager: `apply_diplomacy_action(player_village, ai_village, action, params)`. Updates relationship, transfers resources if trade accepted, sets at_war flag.  
- AI response: simple rules (e.g. if relationship < -30 refuse trade; if personality is Mercantile and deal is fair, accept; else roll with relationship modifier). No UI yet; call from code or a simple debug panel.  
- At least 2 personality types with different behaviour (e.g. Mercantile vs Aggressive).

**Dependencies:** M5 (AIVillage, relationship, personality).

**Definition of done:**  
- From code or debug UI: gift to AI → relationship increases; request trade → AI sometimes accepts, sometimes refuses; declare war → relationship drops and at_war is true.  
- No crashes; state consistent in GameManager.

---

### M7: Diplomacy and trade UI

**Goal:** Player can open a diplomacy screen, see all AI villages with relationship and personality, and perform gift, trade, and declare war from the UI.

**Features included:**  
- Scene: DiplomacyScreen (panel or full-screen). List of AI villages: name, relationship value or label (Hostile/Neutral/Friendly etc.), personality name.  
- Buttons or flows: Gift (open sub-panel to choose resource and amount), Trade (offer resource + amount, request resource + amount, submit), Declare War.  
- TradePanel: inputs for give/get amounts; on confirm, call GameManager/DiplomacyManager; show result (accepted/refused).  
- Notifications: short message when AI refuses or when war is declared (e.g. “Northbrook refused the trade” / “You are at war with Northbrook”).  
- Optional: Request Alliance, Offer Peace (can be stubbed or simple for MVP).

**Dependencies:** M6 (diplomacy actions, AI response).

**Definition of done:**  
- Player can open diplomacy, select an AI, send a gift, propose a trade, and declare war.  
- UI reflects updated relationship and resources after each action.  
- One full flow (gift → trade → war) works without errors.

---

### M8: Combat resolution and war consequences

**Goal:** When at war, “battle” can be triggered (by player or AI); outcome is resolved by formula; resources and military strength change for both sides; optional raid vs invasion.

**Features included:**  
- CombatResolver (script, no scene): `resolve_battle(attacker_village, defender_village, battle_type)`. Input: strengths, optional defence modifier. Output: winner, losses for each side (military, optional resource pillage).  
- GameManager or BattleManager: `trigger_battle(attacker_id, defender_id, battle_type)`. Calls CombatResolver; applies losses to both Village/AIVillage; updates military_strength; if defender is player and loses heavily, may set loss condition (village destroyed).  
- At least one battle type (e.g. Raid or Invasion); two types if time allows.  
- When player declares war, either auto-resolve one battle per turn or add “Attack” button that triggers battle.  
- AI can trigger battle when at_war and conditions met (e.g. once per N turns, strength check).

**Dependencies:** M5 (AIVillage, military_strength), M6 (at_war state).

**Definition of done:**  
- Triggering a battle updates both villages’ military and optionally resources; winner/loser is correct from formula.  
- Player can lose military from defence; if loss condition is “village destroyed,” it triggers when defender (player) strength goes to zero or below threshold.

---

### M9: Events system

**Goal:** Random or condition-based events fire during play; player chooses from 1–3 options; effects apply to resources, relationship, or population.

**Features included:**  
- EventDefinition (Resource or class): event_id, title, description, array of choices (choice_text, effects: resource_deltas, relationship_deltas, population_delta).  
- EventManager (script, can be autoload): register events; each turn or every N turns, optionally roll for event; pick event by weight or condition (e.g. low food, at_war).  
- When event fires: set “pending event” in GameManager; pause or allow UI to open event popup.  
- Scene: EventPopup — title, description, buttons for each choice. On choice, apply effects via GameManager (resource change, relationship change, population change), clear pending event.  
- At least 3 events with 2 choices each; effects validated (no negative population below zero, etc.).

**Dependencies:** M2 (GameManager, advance_turn), M5 (relationship), M3 (resources).

**Definition of done:**  
- After a number of turns, an event fires; player sees popup and selects a choice; effects apply; game continues.  
- No invalid state (e.g. negative population); event history or last event can be inspected for debugging.

---

### M10: Victory and loss conditions

**Goal:** Game checks after turn or after battle; if condition met, game transitions to end screen (victory or defeat).

**Features included:**  
- Victory: e.g. “All AI villages allied or conquered,” or “Reach prestige X.”  
- Loss: e.g. “Player village destroyed (military zero and captured),” “Bankruptcy (zero food + zero gold and population collapse)” or “Population zero.”  
- GameManager: at end of advance_turn() and after resolve_battle(), call `check_victory_loss()`. If true, set game_state = won/lost, reason string.  
- Scene: GameOverScreen — show title (Victory/Defeat), reason, button Restart, button Quit. Main scene or GameManager shows this when game_state is won/lost.

**Dependencies:** M8 (combat, village destroyed), M2 (resources, population), M6 (alliance state).

**Definition of done:**  
- Winning condition can be reached (e.g. ally all villages) and victory screen shows.  
- Losing condition can be reached (e.g. lose all military and be “conquered”) and defeat screen shows.  
- Restart starts a new game (reset GameManager state).

---

### M11: Save and load

**Goal:** Full game state serialised to disk; load restores state exactly; one save slot is enough.

**Features included:**  
- SaveManager (autoload or part of GameManager): `save_game(file_path)`, `load_game(file_path)`.  
- Serialise: current_turn, player_village (buildings, resources, population, military), all AIVillages, relationships, at_war flags, event history or seed, game_state (playing/won/lost).  
- All runtime state in GameManager/DiplomacyManager must be serialisable (no Node paths or RID). Use IDs for villages and building types.  
- Main menu or in-game: Save button, Load button (or “Continue” if save exists).  
- On load: clear current state, deserialise into GameManager, rebuild VillageView from building list (place visuals for each BuildingInstance).

**Dependencies:** M1–M10 (all state must be in serialisable structures).

**Definition of done:**  
- Save to file; quit; load from file. Game continues from same turn, same resources, same relationships and buildings.  
- No missing or corrupted data in one full save/load cycle.

---

### M12: Content fill and balance pass

**Goal:** Scale to MVP numbers; add remaining content; one full playthrough is possible in 30–60 minutes.

**Features included:**  
- Resources: 4–5 (Food, Wood, Stone, Gold, Iron).  
- Buildings: 10–14 (production, military, housing, trade, utility); 2–3 upgrade levels each.  
- AI villages: 4–6; personalities: 4–5; diplomacy actions: 6–8 (add Alliance, Peace, Tribute if not already in).  
- Events: 8–12.  
- Balance: tune production costs, relationship thresholds, combat formula so that early/mid/late game feel achievable and loss/victory are reachable.  
- Optional: second victory path (e.g. economic or prestige) and second loss path (bankruptcy/rebellion).

**Dependencies:** M11 (save/load so balance changes can be tested across sessions).

**Definition of done:**  
- MVP_SPECIFICATION.md “Final MVP Specification” is satisfied: player can do everything listed there.  
- At least one complete playthrough to victory and one to defeat without crashes; save/load works with full content.

---

## 3. Vertical Slice Recommendation

### Smallest meaningful vertical slice

**Scope:** From “start game” to “see my choices affect the world in one loop” without diplomacy or events.

**What must exist:**

1. **Game start:** GameManager creates player village with starting resources (e.g. 100 Food, 100 Wood) and 0 buildings.  
2. **Village view:** Grid (e.g. 10x10 or 16x16) with buildable cells; empty at start.  
3. **Place one building:** Player selects “Farm,” clicks cell; 50 Wood deducted; Farm appears at cell; BuildingInstance added to Village.  
4. **Assign workers:** Player assigns 2 workers to Farm (max 2 for Farm).  
5. **Advance time:** Player clicks “Next Turn” (or time advances automatically every few seconds). GameManager.advance_turn() runs: Farm produces e.g. 10 Food per worker → +20 Food; population consumes e.g. 1 Food per pop → net change. Resource bar updates.  
6. **Upgrade (optional in slice):** Player upgrades Farm to level 2; cost deducted; next turn Farm produces more.  
7. **Repeat:** Player can place another building (e.g. Lumber Camp), assign workers, advance turns, and see Wood and Food change.

**What is explicitly out of this slice:**  
- No AI villages.  
- No diplomacy, trade, or war.  
- No events.  
- No victory/loss.  
- No save/load.  
- Only 2 resources and 2–3 building types.

### Success criteria for the vertical slice

- **Functional:** Place building → assign workers → advance turn → resources change correctly. No crashes.  
- **Readable:** Resource bar and building visuals make it obvious what changed.  
- **Data-driven:** Changing production values in BuildingDefinition (or JSON) changes in-game numbers without code change.  
- **Extensible:** Adding a third building type is a matter of adding a definition and a visual; no refactor of core logic.

**When to expand:** Only after the slice is stable and you have run 5+ “sessions” of place → assign → turn → observe. Then add M5 (AI villages and relationship) and wire one diplomacy action (e.g. gift) to complete a second slice: “build → produce → gift to AI → relationship up.”

---

## 4. Godot Project Structure

Use a flat, explicit structure so that AI-generated code and future you know where files live. Avoid deep nesting.

```
project/
├── project.godot
├── MVP_SPECIFICATION.md
├── DEVELOPMENT_ROADMAP.md
│
├── scenes/
│   ├── main/
│   │   └── Main.tscn
│   ├── village/
│   │   ├── VillageView.tscn
│   │   └── BuildingVisual.tscn
│   ├── ui/
│   │   ├── ResourceBar.tscn
│   │   ├── BuildingPanel.tscn
│   │   ├── DiplomacyScreen.tscn
│   │   ├── TradePanel.tscn
│   │   ├── EventPopup.tscn
│   │   └── GameOverScreen.tscn
│   └── menu/
│       └── MainMenu.tscn          # optional for MVP; can be minimal
│
├── scripts/
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
│       ├── ResourceBar.gd
│       ├── BuildingPanel.gd
│       ├── DiplomacyScreen.gd
│       ├── TradePanel.gd
│       ├── EventPopup.gd
│       └── GameOverScreen.gd
│
├── data/
│   ├── definitions/              # Resource (.tres) or JSON
│   │   ├── resources/
│   │   ├── buildings/
│   │   ├── personalities/
│   │   └── events/
│   └── constants.gd               # or enums: ResourceType, BuildingType, etc.
│
├── resources/                     # Godot Resource files if using .tres
│   ├── resource_definitions/
│   ├── building_definitions/
│   ├── personality_definitions/
│   └── event_definitions/
│
├── assets/
│   ├── art/                       # sprites, tilesets, icons
│   │   ├── tiles/
│   │   ├── buildings/
│   │   └── ui/
│   ├── fonts/
│   └── audio/                     # optional for MVP
│
└── saves/                         # default directory for save files (gitignore)
```

**Notes:**  
- `data/definitions` and `resources/` can be merged if you use only `.tres` for definitions; keep one place for “static config” so AI and humans know where to add new buildings/events.  
- `saves/` in project root keeps save path simple; add `saves/` to `.gitignore`.  
- Scripts next to scenes are optional; grouping by `scripts/core` and `scripts/ui` keeps responsibilities clear and scales well for AI-generated files.

---

## 5. Scene Architecture

| Scene | Purpose | Owns | Does not own |
|-------|--------|------|--------------|
| **Main** | Root of gameplay. Orchestrates view and UI; holds reference to VillageView and overlay containers. | CanvasLayer or root layout; container for VillageView instance; container for UI panels (or references to them). | Game state (lives in GameManager). Building definitions (loaded by GameManager or data layer). |
| **VillageView** | Displays the village grid and building visuals. | TileMap (terrain); Node2D or Control container for building sprites/placeholders; camera if pannable/zoomable. | Village data (reads from GameManager). Logic for production or costs (those are in GameManager). |
| **ResourceBar** | Shows current player resources. | Labels or ProgressBars per resource; layout. | Resource amounts (reads from GameManager on update; does not store). |
| **BuildingPanel** | Build and upgrade interface. | List or buttons of building types; cost labels; upgrade button when building selected. | Building definitions (receives from GameManager or EventBus). Placement logic (requests placement via GameManager). |
| **DiplomacyScreen** | List of AI villages and diplomacy actions. | List/buttons per AI (name, relationship, personality); buttons for Gift, Trade, Declare War, etc. | AI village data (reads from GameManager). Action execution (calls GameManager/DiplomacyManager). |
| **TradePanel** | Propose trade to selected AI. | Inputs for “give resource/amount” and “get resource/amount”; Confirm/Cancel. | Validation (GameManager checks cost and executes). |
| **EventPopup** | Shows one event and choices. | Title, description, 1–3 choice buttons. | Event content (received via signal or GameManager.get_pending_event()). Effect application (sends choice to GameManager). |
| **GameOverScreen** | Victory or defeat. | Title (Victory/Defeat), reason text, Restart, Quit. | Game state (only displayed; restart calls GameManager.new_game() or equivalent). |

**Rule:** Scenes display and dispatch. They do not own authoritative state. They call GameManager (or EventBus) and refresh when signals fire.

---

## 6. Script / Class Architecture

| Script/Class | Responsibility | Main data | Key methods / behaviour |
|--------------|----------------|-----------|---------------------------|
| **GameManager** | Central game state; time advance; orchestration of village, AI, diplomacy, combat, events; victory/loss check. | current_turn, player_village (Village), ai_villages (Array of AIVillage), reference to DiplomacyManager, EventManager; game_state (playing/won/lost). | `advance_turn()`, `place_building(cell, type_id)`, `upgrade_building(instance_id)`, `get_player_resources()`, `check_victory_loss()`, `new_game()`, `save_game()` / `load_game()` or delegate to SaveManager. |
| **Village** | One village’s state: buildings, resources, population, military. | village_id, display_name, building_instances (Array), resources (Dict), population, max_population, military_strength. | `add_building(instance)`, `remove_building(instance_id)`, `get_production_per_turn()`, `apply_production()`, `get_consumption()`, `to_dict()` / `from_dict()` for save. |
| **AIVillage** | AI village state and personality; can extend or wrap Village. | Same as Village plus: personality_type_id, relationship_with_player, at_war, last_actions (optional). | `get_relationship()`, `set_relationship(delta)`, `decide_response(action, params)` (returns accept/refuse and optional counter); `to_dict()` / `from_dict()`. |
| **BuildingInstance** | One placed building at runtime. | instance_id, building_type_id, grid_x, grid_y, level, assigned_workers. | No heavy logic; data only. `to_dict()` / `from_dict()`. |
| **BuildingDefinition** | Static config for a building type. (Resource) | type_id, name, description, cost (Dict resource_id → amount), worker_slots, production (e.g. resource_id → rate per worker per level), max_level, unlock_level. | N/A; read by GameManager and Village. |
| **ResourceDefinition** | Static config for a resource. (Resource) | resource_id, name, icon_path, can_go_negative. | N/A. |
| **DiplomacyManager** | Relationship storage and action application. | relationship_map (e.g. Dict of (player_id, ai_id) → value); or stored per AIVillage. | `get_relationship(ai_id)`, `apply_action(player_village, ai_village, action_type, params)`, `set_relationship(ai_id, value)`. May live inside GameManager or be separate. |
| **CombatResolver** | Pure function: resolve one battle. | None (stateless). | `resolve_battle(attacker_strength, defender_strength, battle_type, modifiers) → { winner, attacker_losses, defender_losses, pillage }`. |
| **EventManager** | When to fire events; what event to pick; apply choice effects. | event_definitions (Array or loaded Resources); pending_event (current event + choices); optional RNG seed. | `roll_for_event(turn, conditions)`, `get_pending_event()`, `apply_choice(choice_index)`, `clear_pending()`. |
| **EventDefinition** | (Resource or class) One event template. | event_id, title, description, choices (Array of { text, effects }). | N/A. |
| **SaveManager** | Serialise/deserialise full game state to disk. | Current save path; optionally last save path for “Continue.” | `save(path)`, `load(path)`; both call GameManager to get state and then restore. |
| **EventBus** | Decouple UI from logic with signals. | No state. | Signals: `resources_changed`, `turn_advanced`, `building_placed`, `diplomacy_action_result`, `event_triggered`, `war_declared`, `game_over`. |
| **UIController** (optional) | Central place to show/hide panels and route high-level UI. | References to panels (or they connect to EventBus). | `show_diplomacy()`, `show_building_panel()`, `show_event_popup(event_data)`, `show_game_over(won, reason)`. Can be a node in Main or separate. |

---

## 7. Autoload / Singleton Plan

| Autoload | Why global | State it stores | What should NOT be in it |
|----------|------------|------------------|---------------------------|
| **GameManager** | Single source of truth for game state; every system (UI, save, events, combat) needs to read or mutate it. | current_turn, player_village, ai_villages, game_state, references to definitions. | Raw UI nodes (panels, buttons). Asset loading (use ResourceLoader or scene tree). |
| **EventBus** | Many scripts need to react to “resources changed” or “event fired” without holding references to GameManager or each other. | None (signals only). | Game state. Business logic. |
| **SaveManager** | Save/load must be available from anywhere (e.g. menu, in-game). | Optional: last_save_path. | Game state (it reads/writes via GameManager). |

**Do not make autoloads:**  
- Village, AIVillage, BuildingInstance (they are data owned by GameManager).  
- DiplomacyManager, CombatResolver, EventManager (can be owned by GameManager or Main scene; only make autoload if you find yourself passing them everywhere).  
- Any UI controller (lives in scene tree under Main).  
- Resource or Building definitions (load from `data/` or `resources/` when needed or at startup).

**Rule of thumb:** If more than two unrelated systems need to call it or listen to it, consider autoload. If it only holds data that one system owns, keep it as a child or property of that system.

---

## 8. Data Organization Strategy

| Data kind | Where / format | Rationale |
|-----------|----------------|------------|
| **Static definitions** (building types, resource types, personalities, event templates) | **Resources** (`.tres`) in `resources/` or JSON in `data/definitions/`. Load at game start or on demand. | Editable in editor or external tools; no logic; same for every run. |
| **Runtime game state** (current resources, building instances, relationships, turn) | **Custom classes** (Village, AIVillage, BuildingInstance) and **Dictionary** for simple key-value (e.g. resource_id → amount). Stored inside GameManager. | Typed and clear; easy to add `to_dict()` / `from_dict()` for save. |
| **Save file** | **JSON** (preferred) or Godot’s native serialisation. One file per save. Structure: one root object with current_turn, player_village (dict), ai_villages (array of dict), relationships, game_state. | Human-readable for debugging; language-agnostic; easy to version if format changes. |
| **IDs and enums** | **Constants** or **enums** in `data/constants.gd` (or similar): ResourceType, BuildingType, PersonalityType, DiplomacyAction, BattleType. | Avoid typos; refactor-friendly; same IDs in definitions and runtime. |
| **Event choice effects** | **Structured dict** or small class: e.g. `{ "resource": { "food": -10 }, "relationship": { "ai_1": 5 }, "population": 0 }`. Stored in EventDefinition. | Flexible; easy to add new effect types; validate in EventManager when applying. |

**Static vs runtime:**  
- **Static:** Never changes during a run. Definitions, constants, event templates.  
- **Runtime:** Changes every turn or on player action. Village data, relationships, turn count, pending event. Always in GameManager (or owned by it) and always serialisable.

**Avoid:**  
- Storing runtime state only in Node properties (e.g. Label.text) without a backing data structure.  
- One giant untyped Dictionary for “everything.” Prefer small classes per entity.

---

## 9. Implementation Order

Same order as milestones M1–M12; below is the “why” and “what to test” per step.

| Step | What | Why at this point | Unlocks | Test before moving on |
|------|------|--------------------|---------|------------------------|
| 1 | Data foundations (M1) | Nothing else can be built without Village, BuildingInstance, definitions, IDs. | All later systems. | Create Village, add BuildingInstance, convert to_dict/from_dict. |
| 2 | GameManager + time loop (M2) | Economy is the backbone; everything else consumes or produces resources. | Village view can show “live” data. | advance_turn() changes resources; production matches definitions. |
| 3 | Village view + placement (M3) | Player must be able to affect the world (place/upgrade); otherwise game is passive. | Worker assignment, full loop. | Place 2 building types, upgrade one, see resources change after turn. |
| 4 | Workers + population (M4) | Makes production and housing meaningful; required for balance. | Full economy. | Assign workers → output changes; housing caps population. |
| 5 | AI villages + relationship (M5) | Diplomacy needs entities and a relationship number. | Diplomacy actions. | Get/set relationship per AI; serialisable. |
| 6 | Diplomacy actions + AI response (M6) | Defines “what the player can do” with AI. | Diplomacy UI. | Gift/trade/war from code; relationship and resources update; AI accepts/refuses. |
| 7 | Diplomacy UI (M7) | Player must be able to use diplomacy without debug. | Full player loop. | Open diplomacy, gift, trade, declare war from UI; feedback visible. |
| 8 | Combat (M8) | War must have consequences; loss condition “village destroyed” needs combat. | Victory/loss. | Battle resolves; strengths and resources update; loss triggers when appropriate. |
| 9 | Events (M9) | Adds variety and narrative; can affect balance. | Richer runs. | Event fires; choice applies effects; no invalid state. |
| 10 | Victory/loss (M10) | Game needs an end state. | Save/load, content pass. | Win and lose conditions trigger; GameOverScreen shows. |
| 11 | Save/load (M11) | Required for MVP; forces serialisation discipline. | Content fill. | Save, quit, load; state identical. |
| 12 | Content fill + balance (M12) | MVP scale and fun. | Ship. | Full playthrough to victory and defeat; all MVP features present. |

---

## 10. Testing and Validation Plan

| Stage | What to verify | How |
|-------|----------------|-----|
| **Resource production** | Production per turn matches (building output × workers × level). Consumption (e.g. food per pop) correct. Caps (max pop, non-negative resources where defined) enforced. | After M2/M4: advance_turn() N times with fixed buildings; compare to hand calculation. Unit test or in-editor script that creates Village, adds buildings, ticks, asserts numbers. |
| **Building placement / effects** | Cost deducted; building appears in Village list and on map; upgrade cost and level increase correct. | After M3: place building, check GameManager.player_village resources and building_instances; upgrade, check level and cost. |
| **AI decision sanity** | AI refuses when relationship too low; accepts when conditions met; personality changes outcome. | After M6: run 10 gift/trade attempts with two personalities; log accept/refuse; check relationship thresholds. |
| **Diplomacy state transitions** | Relationship updates after gift/trade/war; at_war set and cleared; no duplicate or stuck state. | After M7: perform gift → trade → war in sequence; read relationship and at_war from GameManager; repeat with different AI. |
| **Battle outcome** | Winner/loser correct from strengths; losses applied to both sides; pillage (if any) correct. | After M8: call CombatResolver with known strengths; assert winner and loss numbers; trigger battle in game and check village military before/after. |
| **Event effects** | Choice effects apply (resource delta, relationship delta, population); no negative population; event clears after choice. | After M9: fire event, pick each choice, check GameManager state; trigger event that would set population negative and validate clamp or block. |
| **Victory/loss** | Conditions trigger at correct moment; correct reason string; restart resets state. | After M10: force win condition (e.g. ally all); force loss (e.g. lose all military); check game_state and GameOverScreen. |
| **Save/load integrity** | All relevant state present after load: turn, resources, buildings, positions, AI state, relationships, at_war, game_state. | After M11: play to mid-game, save, change something in memory, load; compare state to pre-save. Optionally checksum or hash critical dicts. |

Manual playtest: after M12, run one full game to victory and one to defeat; note any crash, stuck state, or nonsensical number. Fix before considering MVP complete.

---

## 11. Risk Register

| Risk | Why it’s risky | Likely symptom | How to reduce early |
|------|----------------|----------------|---------------------|
| **Feature creep** | Adding “one more” system (espionage, caravans, extra victory) delays ship and complicates save/load. | Never reaching MVP; constant refactors. | Stick to MVP_SPECIFICATION.md; maintain a “post-MVP” list; do not implement anything not in the roadmap until M12 is done. |
| **Tightly coupled systems** | UI or EventManager directly reading/writing Village or AI state in multiple places. | Changing one system breaks others; save/load misses fields. | Single source of truth (GameManager); UI only calls GameManager and subscribes to EventBus; no duplicate state in scenes. |
| **Unreadable AI logic** | Complex nested conditions or opaque weights. | AI feels random or broken; tuning is guesswork. | Use simple rules and named constants (e.g. REFUSE_TRADE_IF_RELATIONSHIP_BELOW = -30); log “AI refused trade: relationship too low” in debug. |
| **Too much UI complexity** | Fancy layouts, many panels, custom controls. | UI takes longer than simulation; hard to maintain. | Start with buttons and labels; one panel per purpose; polish only after MVP content complete. |
| **Unstable save/load design** | State scattered in nodes; serialisation added late and incomplete. | Load fails or restores wrong state; new features “forget” to save. | Design to_dict/from_dict in M1; add SaveManager in M11 and ensure every new state field is in the serialised payload. |
| **Weak gameplay loop** | Economy or diplomacy not impactful; victory/loss too easy or impossible. | Playtests feel boring or frustrating. | Vertical slice first; playtest after M4 and M7; tune numbers in data; run full playthrough by M12 and iterate balance before adding more content. |
| **AI-generated code drift** | Inconsistent naming, duplicate logic, or wrong placement of files. | Hard to navigate; merge conflicts; behaviour duplicated. | Enforce folder structure and “one class per file”; give AI this roadmap and MVP spec as context; review each PR for “does this belong in GameManager or Village?” |

---

## 12. First 2 Weeks Plan

**Goal:** Reach the vertical slice (place building → assign workers → advance turn → see resources change) and have a stable base for M5+.

### Week 1

| Day/Session | Goal | Deliverable |
|-------------|------|-------------|
| **Day 1** | Project + structure + data foundations | Godot project created; folders from Section 4; constants.gd with ResourceType, BuildingType; Village.gd, BuildingInstance.gd, BuildingDefinition (Resource); 2 resource defs, 2 building defs. Create Village in script, add one BuildingInstance, print to_dict(). |
| **Day 2** | GameManager + tick | GameManager autoload; holds player_village; loads 2 building definitions; advance_turn() applies production (from pre-placed building list) and consumption; EventBus with resources_changed, turn_advanced. Test: 5 turns, resources change. |
| **Day 3** | Main + VillageView (grid only) | Main.tscn with placeholder or TileMap (empty grass); VillageView with TileMap; no placement yet. GameManager created on ready; maybe “Next Turn” button that calls advance_turn() and prints resources. |
| **Day 4** | Building placement | BuildingPanel (simple list of 2 building types + cost); click cell in VillageView → if valid and cost met, GameManager.place_building(cell, type_id); add BuildingVisual (ColorRect or icon) at cell. ResourceBar (labels) shows current resources; updates on resources_changed. |
| **Day 5** | Upgrade + worker assignment | Select placed building (click or list); upgrade button (cost + level check); assign workers (slider or buttons 0..worker_slots). Production in advance_turn() uses assigned_workers. Test: place Farm, assign 2, turn → Food increases; upgrade Farm, turn → more Food. |

### Week 2

| Day/Session | Goal | Deliverable |
|-------------|------|-------------|
| **Day 6** | Population + housing | Housing building type; max_population from buildings; population growth (e.g. surplus food → +1 pop per N turns). ResourceBar shows population and max. Test: build housing, population grows when food surplus. |
| **Day 7** | Polish slice + playtest | Fix any bugs; ensure one full flow: start → place Farm + LumberCamp → assign workers → 10 turns → upgrade one building → 5 more turns. Document any missing from data model (e.g. unlock_level). |
| **Day 8** | AIVillage + relationship (M5) | AIVillage class; GameManager has 2 AIVillages; DiplomacyManager get/set relationship. No UI. Test: set_relationship in code; save/load test: add to_dict/from_dict for AIVillage and relationship map. |
| **Day 9** | Diplomacy actions (M6) | apply_diplomacy_action: Gift, Trade, Declare War. AI response rules (relationship + personality). Debug panel or hotkey to call gift/trade. Test: gift increases relationship; trade sometimes accepted; war sets at_war. |
| **Day 10** | Diplomacy UI (M7) start | DiplomacyScreen scene: list 2 AI villages, relationship, Gift button. TradePanel: give/get inputs, confirm. Wire to GameManager; show “accepted/refused.” Goal: one full diplomacy flow from UI. |

By end of week 2 you have: playable economy slice + first diplomacy loop. From here continue with M8 (combat) and M9 (events) in the next 1–2 weeks.

---

## 13. Final Build Order Summary

- **Build first:** Data model (Village, Building, definitions, IDs) → GameManager and time loop → Village view and building placement → worker assignment and population. **Outcome:** Vertical slice playable (build, assign, turn, see resources).
- **Build second:** AI villages and relationship → diplomacy actions and AI response → diplomacy and trade UI → combat resolution and war consequences → events → victory/loss → save/load. **Outcome:** Full MVP loop (economy + diplomacy + war + events + end state + persist).
- **Build third (content):** Scale to 4–5 resources, 10–14 buildings, 4–6 AI villages, 4–5 personalities, 8–12 events; second victory/loss; balance pass. **Outcome:** MVP content-complete and presentable.
- **Leave for later (polish only):** Tutorial, full localisation, extra maps, meta-progression, animation and audio polish, and any feature not in MVP_SPECIFICATION.md.

---

## AI-Assisted Development Rules

1. **Always provide scope.** When asking AI to implement a feature, attach the relevant part of MVP_SPECIFICATION.md or this roadmap (e.g. “Implement M3: Village view and building placement”). Say “follow our project structure: scripts under scripts/core, scenes under scenes/village.”

2. **One feature per request.** Do not ask for “diplomacy, combat, and events” in one go. Ask for “DiplomacyManager.get_relationship and set_relationship” first, then “apply_diplomacy_action for Gift,” then UI. Smaller chunks keep output consistent and reviewable.

3. **State the data contract.** Before having AI write a new script, specify: “Village has building_instances: Array of BuildingInstance; BuildingInstance has instance_id, building_type_id, grid_x, grid_y, level, assigned_workers.” AI then generates code that matches the contract.

4. **Prefer “implement from spec” over “come up with something.”** Give the AI the exact method names and data structures from this doc (e.g. “CombatResolver.resolve_battle(attacker_strength, defender_strength, battle_type) returns Dictionary with winner, attacker_losses, defender_losses”). Reduces drift and rework.

5. **Review where state lives.** After any AI-generated code, check: “Does this store game state in a Node or in GameManager/Village?” If state is in a UI node or a new singleton not in this roadmap, move it to the approved place.

6. **Keep one vocabulary.** Use the same terms as the roadmap: Village, AIVillage, BuildingInstance, BuildingDefinition, advance_turn, relationship, DiplomacyManager, EventBus. If AI uses different names (e.g. “Town” instead of “Village”), rename to match so the codebase stays consistent.

7. **File placement is non-negotiable.** Tell AI: “New scripts go in scripts/core or scripts/ui; new scenes go in scenes/village or scenes/ui; definitions go in resources/ or data/definitions.” Reject generated code that puts core logic in `scripts/misc` or duplicates Manager logic in a scene script.

8. **Signals and autoloads by design.** If AI adds a new autoload, verify it’s in Section 7. If it adds a new signal, ensure it’s on EventBus (or an agreed place) and documented. Avoid one-off signals on random nodes.

9. **Serialisation for every new state.** When adding a new field to Village, AIVillage, or GameManager, ask AI to “add this to to_dict() and from_dict() and to the save format in SaveManager.” Make this part of the prompt for any state-changing feature after M11.

10. **Test instruction in the prompt.** End complex requests with: “Add a short comment or print in _ready() that demonstrates the feature (e.g. create Village, add building, call advance_turn(), print resources).” Ensures the generated code is runnable and verifiable.

---

*End of Development Roadmap. Use with MVP_SPECIFICATION.md as the single source of scope and this document as the single source of execution order and structure.*
