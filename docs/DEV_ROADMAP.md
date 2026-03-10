# Village Dominion — Development Roadmap

## Timeline: 4–7 Months Solo Development

---

## Phase 1: Core Systems (Weeks 1–4) ✅ DONE
**Goal**: Playable village with buildings and resources.

- [x] Project setup (Godot 4, scene structure, autoloads)
- [x] Constants and enums
- [x] Building definitions and database
- [x] Village class with resources, population, building management
- [x] Resource production and consumption per turn
- [x] Turn system in GameManager

---

## Phase 2: AI Villages (Weeks 5–8) ✅ DONE
**Goal**: World populated with AI villages that make decisions.

- [x] AIVillage class with personality types
- [x] AI decision trees (aggressive, diplomatic, trader, opportunist, isolationist)
- [x] AI building priorities
- [x] AI manager processing all AI turns
- [x] Village relationships initialized

---

## Phase 3: Diplomacy & Combat (Weeks 9–13) ✅ DONE
**Goal**: Full interaction system between villages.

- [x] Relationship score system (-100 to +100)
- [x] CombatResolver (attack/defense power calculation, outcomes)
- [x] Battle manager
- [x] Diplomacy actions: war, peace, alliance, break, gift, aid, trade, threaten
- [x] AI diplomacy decision-making
- [x] Trade route system

---

## Phase 4: Events, UI & Save (Weeks 14–18) ✅ DONE
**Goal**: Complete game loop with events, full UI, and persistence.

- [x] 12 world event types with weighted random selection
- [x] EventBus signal system
- [x] Full UI: TopBar, BuildingPanel, DiplomacyPanel, TradePanel
- [x] Popups: EventPopup, BattleResultPopup, SaveMenu, GameOverScreen
- [x] Save/Load system (3 JSON slots)
- [x] Notification log
- [x] Win/lose conditions

---

## Phase 5: Visual Polish (Weeks 19–22) 🔲 TODO
**Goal**: Game looks and feels like a real game.

- [ ] TileMap-based world map showing all villages
- [ ] Village icons/sprites per personality
- [ ] Building visual feedback (show buildings placed)
- [ ] Animated turn transitions
- [ ] Color-coded relationship indicators on map
- [ ] Sound effects (construction, battle, diplomacy)
- [ ] Background music (ambient medieval)
- [ ] Custom UI theme / skin

---

## Phase 6: Content & Balance (Weeks 23–26) 🔲 TODO
**Goal**: Game is balanced and has depth.

- [ ] Balance resource production rates
- [ ] Tune AI aggression by difficulty setting
- [ ] Add difficulty modes (Easy / Normal / Hard)
- [ ] More building types (Library, Hospital, Harbor)
- [ ] Tech tree (unlock advanced buildings)
- [ ] More event variety (20+ events)
- [ ] Reputation system (global standing affects diplomacy)

---

## Phase 7: Advanced Features (Weeks 27–30) 🔲 OPTIONAL
**Goal**: Features that make the portfolio shine.

- [ ] Espionage system (send spies to steal info or sabotage)
- [ ] Procedural world map generation
- [ ] Trade caravan animations (visual trade caravans moving on map)
- [ ] Dynamic leader portraits (different art per personality)
- [ ] Diplomacy history log (record of all past interactions)
- [ ] Achievement system

---

## Technical Debt & Testing
- [ ] Unit tests for CombatResolver math
- [ ] Playtesting all AI personalities at high turns
- [ ] Edge case: what happens when all non-player villages die?
- [ ] Performance: 8 villages × 120 turns stress test
- [ ] Save file version migration

---

## Deployment
- [ ] Export for Windows
- [ ] Export for Web (HTML5)
- [ ] Itch.io page
- [ ] GitHub repository with screenshots

---

## Architecture Notes

### EventBus Pattern
All game systems communicate via EventBus signals — no direct references between managers. This keeps systems decoupled and testable.

### Data-Driven Design
Buildings, events, and personalities are defined in data (GDScript resources + JSON) rather than hardcoded logic. Easy to add content without touching game logic.

### Turn Flow
```
Player clicks "End Turn"
  → GameManager.end_turn()
    → All villages: village.process_turn() (production, consumption)
    → AIManager.process_all_ai() (AI decisions and actions)
    → EventManager.roll_events() (random world events)
    → _process_relationship_decay()
    → _check_game_over()
    → EventBus.turn_started.emit()
    → UI refreshes
```
