# Village Dominion — MVP Specification & Technical Scope

**Document type:** Pre-production design document  
**Engine:** Godot  
**Target:** Playable prototype (solo developer)  
**Tone:** Strategy + diplomacy simulator — simplified Clash of Clans meets Civilization diplomacy meets management sim.

---

## 1. Game Vision

**Village Dominion** is a single-player village strategy and diplomacy simulator in which the player founds and grows a settlement, manages resources and population, and navigates a world of AI-controlled villages. The core experience is the tension between building at home and engaging abroad: you must invest in economy and defence, while simultaneously reading other leaders, forming alliances, trading, and—when necessary—going to war. The game is not about micromanaging individual units in real-time battles; it is about strategic decisions at the village and diplomatic level, with combat resolved through a clear, system-driven model (e.g. strength vs. strength, modifiers, outcomes). The player fantasy is “I am the leader who built this village and shaped the fate of the region through choices, not reflexes.”

What makes it interesting is the interplay of systems: your reputation with one village affects how others see you; your military posture deters or provokes; your trade deals create dependency or leverage; random events and leader personalities create emergent stories. The MVP should deliver a loop where each session feels like a run of a strategy game—with a defined beginning, meaningful mid-game, and clear victory or loss—while remaining realistic for a solo developer in Godot.

---

## 2. MVP Goal

**“Finished MVP”** means: a single playable build that can be shown as a real game prototype. A player can start a new game, build and manage their village, interact with a small set of AI villages (diplomacy, trade, war), experience a handful of events, and reach a concrete win or lose state. The prototype does not need extensive art, sound, or tutorial; it must feel complete in terms of systems—i.e. the simulation is coherent, decisions matter, and the loop is replayable.

**Success criteria for the MVP:**
- One full playthrough (early → mid → victory or defeat) is possible in 30–60 minutes.
- The player can meaningfully differentiate runs (e.g. pacifist vs. warmonger, trader vs. isolationist).
- At least two distinct victory paths and one loss condition are implemented and reachable.
- Save/load works; the player can continue a run across sessions.
- The build is presentable: UI is functional and readable, even if not polished.

---

## 3. Core Gameplay Loop

**Minute-to-minute:** The player spends time on a combination of (1) placing/upgrading buildings and assigning workers, (2) managing resources (checking stockpiles, balancing production vs. consumption), (3) opening the diplomacy/trade screen to propose deals or declare actions, (4) responding to events and notifications, and (5) advancing time (e.g. turn or speed-controlled tick) to see the results of decisions. There is no real-time pressure; the pace is “think and click.”

**Session-level:** Each run has a clear arc. **Early game:** Establish basic economy (food, wood, perhaps one other resource), build a few key structures, meet the first AI villages, and secure at least one trade or non-aggression to avoid early elimination. **Mid game:** Scale production, specialise (e.g. military buildings vs. trade posts), deepen one or two alliances, manage threats, and work toward a chosen victory condition (e.g. dominance, alliance network, economic supremacy). **Late game:** Execute the final push—military conquest, diplomatic victory, or economic milestone—or suffer defeat (e.g. village destroyed, bankruptcy, rebellion).

Progression is driven by buildings unlocking capabilities, resources enabling upgrades and deals, and diplomacy/war changing the political map. The loop is “plan → execute (build/trade/war) → see consequences → adapt.”

---

## 4. Core Systems Included in MVP

### Village building
- **Included:** A fixed or semi-fixed map (e.g. grid or predefined zones) where the player places a defined set of building types (see Recommended Scale). Each building has a clear function (production, military, housing, trade, defence). Placement rules are simple (e.g. must be on buildable terrain, no overlapping). Upgrades (e.g. 2–3 levels per building) improve output or unlock abilities. No procedural world; one or two hand-crafted village layouts or a small grid are enough.
- **Why:** Building is the primary “home base” engagement. Without it, the game has no anchor. Keeping placement rules simple keeps scope manageable while still offering meaningful choices.

### Resources and economy
- **Included:** A small set of resources (see Scale) that are produced by buildings and consumed by population, upgrades, and diplomacy (gifts, trade). Stockpiles are tracked globally for the player village. Basic economy loop: produce → store → spend on buildings, upgrades, troops, and deals. No complex supply chains; direct “building X produces resource Y” is enough.
- **Why:** Resources create meaningful tradeoffs and tie building, population, and diplomacy together. A minimal set keeps balance and UI manageable.

### Population / workers
- **Included:** A single “population” or “workers” pool (optionally split into “villagers” and “soldiers” if military is separate). Population is capped by housing. Workers can be assigned to production buildings (e.g. “3 workers at the lumber camp”) or left as “idle.” Population grows over time (e.g. with surplus food and housing) or via events. No individual citizen simulation.
- **Why:** Assigning workers gives the player direct control over prioritisation and makes housing and food matter. One pool (or two: civilian/military) is enough for the MVP.

### AI villages
- **Included:** A fixed number of AI villages (see Scale), each with a name, leader personality, resources, military strength, and relationship with the player. They produce resources, make simple decisions (trade, war, peace) based on personality and relationship, and send offers or threats. No full “AI village building” simulation; they have abstracted strength and resources that change over time via simple rules or scripts.
- **Why:** AI villages are the source of diplomacy and conflict. They must exist and react; they do not need to “play the full game” internally.

### Diplomacy
- **Included:** A diplomacy model with relationship value (e.g. -100 to +100 or discrete states: hostile, unfriendly, neutral, friendly, allied). Actions: propose trade (resource for resource or gold), send gift, request alliance, declare war, offer peace, demand tribute (or refuse). AI responds based on personality and current relationship. A small set of diplomacy actions (see Scale) is enough. History of recent actions (last 5–10) visible to the player.
- **Why:** Diplomacy is the differentiator. The MVP must support at least two “styles” (e.g. friendly trader vs. aggressive expander) with visible consequences.

### War / combat
- **Included:** Abstract combat, not RTS. When the player (or AI) declares war, “battles” are resolved via a formula: attacker strength vs. defender strength, with modifiers (defences, terrain if simple). Outcome: win/lose, with consequences (e.g. loser loses troops and maybe resources; winner may pillage or force peace terms). Optionally 1–2 “phases” (e.g. raid vs. full invasion) with different costs and outcomes. No unit movement on a tactical map; no real-time battles.
- **Why:** War must be possible and consequential so that military buildings and diplomacy matter. Abstract resolution keeps scope small and keeps focus on strategy, not tactics.

### Events
- **Included:** A small pool of random or scripted events (see Scale) that fire during play. Examples: “Neighbour requests aid,” “Bandits raid,” “Harvest boom,” “Plague.” Each event has 1–3 choices with clear effects (resources, relationship, population). Events can be time-based or triggered by conditions (e.g. low food, war). Simple modal or side panel; no complex branching narrative.
- **Why:** Events add unpredictability and narrative flavour and create memorable moments without requiring a full story.

### Progression
- **Included:** Unlock progression: e.g. starting with a subset of buildings and unlocking more as the village “level” or “prestige” increases (based on buildings built, population, or milestones). One or two victory conditions (e.g. “Conquer all villages” or “Alliance with all”) and one or two loss conditions (village destroyed, bankruptcy, rebellion). Optional: a simple “prestige” or “score” that persists only for the session (no meta-progression required for MVP).
- **Why:** Progression gives structure; victory/loss gives closure and replayability.

### UI/UX
- **Included:** Main view (village or map), resource bar, building placement/upgrade UI, population/worker assignment, diplomacy screen (list of villages, relationship, actions), trade panel, event popup, simple notifications (e.g. “Village X declared war”), and game-over/victory screen. No full tutorial; tooltips or short descriptions for key actions are enough.
- **Why:** The player must be able to perform all core actions without confusion. Clarity over beauty for MVP.

### Save / load
- **Included:** Save current game state to disk (village state, resources, AI state, relationships, events, time). Load restores exactly that state. One save slot is acceptable; multiple slots are nice-to-have. No cloud, no cross-platform sync.
- **Why:** Essential for a strategy game; players expect to continue later. Serialising the data model (see below) is the main task.

---

## 5. Systems Explicitly Excluded From MVP

| Excluded feature | Reason to postpone |
|------------------|--------------------|
| **Multiplayer (PvP or co-op)** | Networking, sync, and balance multiply scope and risk. Single-player proves the design first. |
| **Full RTS battles** | Real-time tactical combat requires pathfinding, unit AI, and balance; contradicts “strategy over reflexes” and is a large subsystem. |
| **Procedural world generation** | Hand-crafted or fixed layout is sufficient for MVP; proc-gen adds complexity and testing burden. |
| **Deep animation systems** | Idle animations, combat cinematics, and character animation are polish. MVP is systems-driven; minimal or placeholder art is fine. |
| **Tech tree bloat** | A small number of buildings and 1–2 upgrade levels per building is enough. Large tech trees complicate balance and UI. |
| **Espionage / intrigue** | Spying, secrets, and intel add another subsystem and UI surface. Diplomacy and events can create surprise without it. |
| **Complex pathfinding caravans** | If trade is abstract (e.g. “send 50 wood to Village A”), no caravan movement is needed. Simpler and sufficient for MVP. |
| **Religion / culture / happiness** | Additional “currencies” or meters increase complexity. Population and resources are enough for MVP; these can layer on later. |
| **Multiple maps / campaigns** | One map and one “mode” (sandbox or single scenario) is enough to prove the loop. |
| **Full localisation** | English-only for MVP; localisation can follow once text is stable. |
| **Achievements / meta-progression** | No unlockable content between runs for MVP; focus on one-session depth. |

---

## 6. Recommended MVP Scale

Keep these numbers ambitious but achievable; they define “substantial but not bloated.”

| Category | Recommended MVP count | Notes |
|----------|------------------------|--------|
| **Resources** | 4–5 | e.g. Food, Wood, Stone, Gold, and optionally one “special” (e.g. Iron for military). |
| **Buildings** | 10–14 | Mix: 3–4 production, 2–3 military/defence, 2 housing, 1–2 trade/diplomacy, 1–2 utility (e.g. storage, town hall). |
| **Building upgrade levels** | 2–3 per building | Level 1 (basic), Level 2 (improved), optional Level 3 (advanced). |
| **AI villages** | 4–6 | Enough for 2–3 potential allies and 2–3 rivals; distinct personalities matter. |
| **Leader personalities** | 4–5 types | e.g. Aggressive, Cautious, Mercantile, Proud, Pragmatic. Each affects willingness to trade, ally, or war. |
| **Diplomacy actions** | 6–8 | e.g. Trade, Gift, Request Alliance, Declare War, Offer Peace, Demand Tribute, Refuse, Cancel Deal. |
| **Random / scripted events** | 8–12 | Mix of positive, negative, and choice-driven; some tied to relationship or resources. |
| **Victory conditions** | 2 | e.g. “Conquer all AI villages” and “Form alliance with all surviving villages” (or “Reach X prestige”). |
| **Loss conditions** | 2 | e.g. “Village destroyed (captured/razed)” and “Bankruptcy / collapse (e.g. zero food + rebellion).” |
| **Combat resolution types** | 1–2 | e.g. “Raid” (quick, limited gains) and “Invasion” (full commitment, larger outcome). |

---

## 7. Data Model Planning

Define these entities and their stored data so that save/load and game logic stay consistent.

### Player village
- **Data:** Village ID, display name; list of building instances (type, position, current level, assigned workers); resource stockpiles (resource type → amount); total population, max population (from housing); current military strength (if separate from population); current “prestige” or “level” if used for unlocks; game timestamp or turn number.

### AI village
- **Data:** Village ID, display name; leader personality type; resource stockpiles (or abstract “wealth”); military strength; current relationship with player (numeric or state); list of active deals with player (e.g. trade agreement); “cooldown” or state flags (e.g. at war, in truce); last few actions toward player (for AI and display).

### Building
- **Data (template):** Building type ID, name, description; base cost (resources); production or effect per level (e.g. food/hour, defence points); worker slots; unlock condition (e.g. village level).  
- **Data (instance):** Reference to template; position (x, y or grid index); current level; assigned worker count; build/upgrade completion time if using time-delayed construction.

### Resource
- **Data (definition):** Resource type ID, name, icon reference; whether it can go negative (e.g. food can, gold cannot).  
- **Data (stockpile):** Stored as part of village (resource ID → amount).

### Leader personality
- **Data:** Personality ID, name; numeric or weighted modifiers: e.g. tendency to accept trade, to declare war, to accept alliance, to hold grudges; preferred resources; reaction modifiers to player actions (e.g. gift +5, insult -20).

### Diplomacy relationship
- **Data:** Player village ID, AI village ID; relationship value (e.g. -100 to +100) or discrete state; optional: history of last N actions (action type, turn, result). Stored per player–AI pair.

### Battle result
- **Data:** Attacker village ID, defender village ID; battle type (raid vs. invasion); attacker strength, defender strength; outcome (win/lose); losses (e.g. military units or resource pillage); timestamp/turn. Optional: used for flavour text and AI memory.

### World event
- **Data (template):** Event ID, title, description; list of choices (choice text, effects: resource deltas, relationship deltas, population delta, flags).  
- **Data (instance when fired):** Event template ID; chosen option (if any); turn fired. Optionally store for history.

### Global game state (for save)
- **Data:** Current turn or game time; random seed if events use RNG; list of all villages (player + AI); list of all building instances; diplomacy matrix (relationships); event history or last N events; victory/loss state (none, won, lost, reason).

Use **unique IDs** (e.g. integer or string) for villages, buildings, and events so references survive save/load.

---

## 8. Technical Scope for Godot

### Presentation approach
- **Recommendation:** **2D, map- or village-view heavy.** Top-down or isometric-style village/map as the main play space. No need for 3D; 2D keeps art and performance scope manageable. UI can be overlay panels (dialogue-style or side panels) for building, diplomacy, trade, and events. Suits “systems over spectacle.”

### Map / village representation
- **Option A (simplest):** **TileMap** for terrain (e.g. grass, water); building placement as cells or fixed slots. Good for grid-based building and clear rules.  
- **Option B:** **Node-based “zones”** or **TextureRect/Sprite** placeholders for buildings on a single background image. Slightly more flexible visually, same data model.  
- **Recommendation:** Start with **TileMap + grid-based building** for clear placement rules and easy serialisation of (x, y) or (grid_x, grid_y).

### Suggested scenes
- `Main.tscn` — Root; holds GameManager (autoload), main view, and UI layer.
- `VillageView.tscn` or `MapView.tscn` — TileMap + container for building sprites/nodes; camera if pannable.
- `BuildingTemplate.tscn` — Single scene per building type (or one parameterised scene) for visual representation; can be minimal (coloured rect + icon).
- `UI/ResourceBar.tscn` — Displays current resources.
- `UI/BuildingPanel.tscn` — List/buttons for build/upgrade; shows cost and effect.
- `UI/DiplomacyScreen.tscn` — List of AI villages, relationship, buttons for actions.
- `UI/TradePanel.tscn` — Offer resources, request resources; confirm/cancel.
- `UI/EventPopup.tscn` — Event title, description, choice buttons.
- `UI/GameOverScreen.tscn` — Victory/loss message and reason; restart/quit.

### Suggested scripts / classes
- `GameManager` (autoload) — Current game state (villages, resources, relationships, turn); advance time; save/load; victory/loss check.
- `Village` — Data class or Resource: buildings, stockpiles, population, military. Methods: add/remove building, apply production per tick, check caps.
- `AIVillage` — Extends or composes Village; personality, relationship with player; method `decide_action()` or similar that returns next diplomatic/military action.
- `BuildingDefinition` (Resource) — Static data: type, name, costs, effects per level, worker slots.
- `BuildingInstance` — Runtime: definition ref, position, level, assigned workers; optionally build timer.
- `DiplomacyManager` — Holds relationship map; methods: apply_action(player, ai, action), get_relationship(player, ai).
- `CombatResolver` — Input: attacker strength, defender strength, modifiers; output: win/lose, losses. No scene needed if purely data.
- `EventDatabase` — Array or Dictionary of event definitions (Resource or script).
- `EventManager` — Picks and fires events (time-based or condition-based); applies choice effects via GameManager.
- `SaveLoadManager` (can live in GameManager or separate autoload) — Serialise game state to JSON or binary; deserialise and restore.

### Singleton / autoload recommendations
- `GameManager` — Central state and tick.  
- `EventBus` or `SignalManager` (optional) — Decouple UI from logic (e.g. “resource_changed”, “event_fired”, “war_declared”).  
- `SaveLoadManager` — If not folded into GameManager.

### Data representation in Godot
- **Definitions (building types, resources, personalities, event templates):** Use **Resources** (`.tres`) or script classes loaded from JSON. Easy to edit in editor or via external data.  
- **Runtime state (current stockpiles, building instances, relationships):** Use **custom classes** (GDScript or C#) or **Dictionaries** that mirror the data model above. Prefer **typed structures** (classes with named properties) for clarity and refactoring; serialize to Dictionary/JSON for save.  
- **Avoid:** Storing critical game state only in scene tree nodes (hard to save); large untyped Dictionaries for everything (hard to maintain).

---

## 9. Production Scope Assessment

### Difficulty (solo developer)
- **Overall:** Medium–high. The scope is substantial: multiple systems (economy, diplomacy, combat, events) must interact correctly. The risk is not any single system being impossible, but integration and balance. Estimate: **3–6 months** part-time (or 1.5–3 months full-time) for a disciplined MVP, depending on experience with Godot and strategy games.

### High-risk systems
- **Diplomacy and AI behaviour:** Making AI villages feel coherent (trade when it makes sense, war when plausible) without bugs or deadlocks. Mitigation: start with simple rules (e.g. if relationship < X, refuse trade; if personality is Aggressive and strength > player, consider war); iterate with playtesting.
- **Save/load:** Forgetting to serialize a new field or restoring references (e.g. village ID) incorrectly can cause subtle bugs. Mitigation: define the data model first (Section 7); serialize in one place; test save/load after every major feature.
- **Balance:** Economy or combat can trivialise or block progress. Mitigation: tune numbers in data (Resources/JSON), not in code; playtest short runs early.

### Medium-risk systems
- **Event system:** Trigger conditions and effect application must not break state (e.g. negative population). Mitigation: small effect set (resource delta, relationship delta); validate before apply.
- **UI flow:** Many screens (village, build, diplomacy, trade, event) can feel disjointed. Mitigation: vertical slice early—one loop (build one building, one trade, one event) before expanding.

### Low-risk systems
- **Resource production and consumption:** Straightforward math and tick updates.  
- **Building placement on grid:** Standard TileMap or grid logic.  
- **Combat resolution:** Formula in one place; no real-time logic.

### Likely time sinks
- **UI layout and feedback:** Making all actions visible and understandable takes iteration.  
- **AI “personality” tuning:** Getting 4–5 personalities to feel distinct without endless edge cases.  
- **Playtesting and rebalancing:** Expect 20–30% of time on “it’s too hard/too easy” and number tweaks.

### Recommended build order
1. **Core data model** — Village, Building (definition + instance), Resource; no UI except debug print.
2. **Village view + building placement** — TileMap, place/upgrade buildings, deduct resources; show stockpiles (simple label or bar).
3. **Economy tick** — Time advance (turn or timer); production and consumption; population growth and cap.
4. **One AI village** — Data only; relationship value; simple “accept/refuse trade” or “gift” to test diplomacy data flow.
5. **Diplomacy UI** — List villages, show relationship, 2–3 actions (e.g. gift, trade, declare war).
6. **Combat resolver** — Resolve war declaration with strength vs. strength; apply outcome to resources/military.
7. **Events** — 2–3 events with choices; fire on timer or condition; apply effects through GameManager.
8. **Victory/loss** — Check conditions after tick or after combat; game over screen.
9. **Save/load** — Serialise all state; test with mid-game save.
10. **Expand content** — More buildings, events, AI villages, personalities; balance pass.

---

## 10. Final MVP Specification

### What the first version will contain
- **One player village** on a fixed or grid-based map with **10–14 building types**, 2–3 upgrade levels each, and worker assignment.
- **4–5 resources** (e.g. Food, Wood, Stone, Gold, Iron) produced and consumed by buildings, population, and diplomacy.
- **4–6 AI villages** with **4–5 leader personalities**, each with relationship tracking and **6–8 diplomacy actions** (trade, gift, alliance, war, peace, etc.).
- **Abstract combat** (1–2 resolution types: e.g. raid, invasion) with strength-based outcomes affecting resources and military.
- **8–12 events** with choices affecting resources, relationships, or population.
- **2 victory conditions** and **2 loss conditions**.
- **Full save/load** of game state.
- **UI** for village view, building, resources, population, diplomacy, trade, events, and game over.

### What success looks like
- A player can complete a 30–60 minute run, reach a victory or loss, and feel that their choices (building, trading, allying, warring) mattered.
- Different play styles (e.g. pacifist trader vs. warmonger) produce meaningfully different outcomes.
- The build is stable, save/load works, and the prototype is presentable as “this is the game.”

### What the player can actually do in that version
- Place and upgrade buildings, assign workers, and watch resources and population change over time.
- Open a diplomacy screen, see each AI village’s relationship and personality, and perform trade, gifts, alliances, and declarations of war.
- Engage in abstract combat when at war and see outcomes (gains/losses) applied to both sides.
- Respond to random or scripted events by choosing from 1–3 options and seeing consequences.
- Work toward one of two victory conditions or avoid two loss conditions.
- Save the game and load it later to continue the same run.

---

## Implementation Principles

1. **Build vertical slices first.** Implement one complete path (e.g. “build one building → produce resource → trade with one AI”) before adding more content. Ensures the loop works before scope grows.

2. **Data over code.** Put tunable values (costs, production rates, relationship thresholds) in Resources or JSON, not hardcoded. Balance and design iteration stay in data.

3. **Simulation over spectacle.** Prioritise correct and readable simulation logic (economy, diplomacy, combat). Placeholder art and minimal animation are acceptable; wrong or opaque behaviour is not.

4. **One source of truth for game state.** All authoritative state lives in GameManager (or a single state object). UI and systems read from and request changes through that layer; avoid duplicating state in scenes.

5. **Keep AI logic readable and testable.** Prefer explicit rules (e.g. “if relationship < -50 and personality is Aggressive, 30% chance to declare war”) over black-box logic. Log key AI decisions in debug so behaviour can be traced.

6. **Avoid overengineering.** No generic “entity component system” or plugin architecture unless the MVP clearly needs it. Use straightforward scripts and scenes; refactor when a second similar system appears.

7. **Save/load from day one.** Design the data model so every runtime entity can be serialised. Add save/load early (even if only “save to JSON file”) so new features don’t forget to persist.

8. **Names and IDs.** Use consistent naming: e.g. `village_id`, `building_type_id`, `resource_id`. Use enums or constants for fixed sets (personality types, resource types) to avoid typos and simplify refactors.

9. **Signals for loose coupling.** Emit signals for “resource changed,” “event fired,” “war declared” so UI and systems react without direct references. Keeps GameManager from depending on UI.

10. **Test the loop, not the parts.** Playtest short runs (e.g. 10 minutes) frequently. A feature is “done” when it contributes to a run that feels coherent, not when the code is tidy in isolation.

11. **Scope creep guard.** If a feature is not in this MVP spec, do not add it until the MVP is playable end-to-end. New ideas go in a “post-MVP” list, not into the current sprint.

12. **Document decisions.** When you make a non-obvious tradeoff (e.g. “relationship is -100 to +100” or “combat is one formula”), add a one-line comment or design note. Future you will thank you when tuning or extending.

---

*End of MVP Specification. Use this document as the single reference for “in scope” vs “out of scope” until the first playable prototype is complete.*
