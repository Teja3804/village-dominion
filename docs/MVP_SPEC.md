# Village Dominion — MVP Specification

## Overview
A turn-based village strategy and diplomacy simulator where the player builds a village, manages resources, and interacts with AI-controlled villages through war, trade, alliances, and diplomacy.

## Core Systems

### 1. Village Building
- 12 building types with up to 5 upgrade levels
- Grid-based (logical) placement with resource costs
- Prerequisites: some buildings require others (e.g., Blacksmith needs Barracks)
- Buildings produce resources each turn

### 2. Resource Economy
| Resource | Source | Used For |
|----------|--------|---------|
| Food | Farms | Feeding population, soldiers |
| Wood | Lumber Mill | Construction |
| Stone | Quarry | Construction, walls |
| Gold | Market, trade | Soldiers, diplomacy gifts |
| Weapons | Blacksmith | Soldier effectiveness |

### 3. Population & Workers
- Population grows if food is adequate and housing available
- Soldiers consume gold upkeep; if unpaid, some desert
- Morale (0-100) affects production efficiency

### 4. AI Villages
- 7 AI villages with distinct personalities
- Turn-based decision making: attack, build, trade, ally, send gifts
- Personalities: Aggressive, Diplomatic, Trader, Opportunist, Isolationist

### 5. Diplomacy
- Relationship score: -100 (war) to +100 (allied)
- Actions: Declare War, Propose Peace, Propose Alliance, Break Alliance, Send Gift, Request Aid, Propose Trade, Threaten

### 6. Combat
- Simulation-based (not RTS)
- Attack power = soldiers × weapon_level ± 20% randomness
- Defense power = soldiers + wall/watchtower bonuses ± 20% randomness
- Outcomes: Attacker Wins, Defender Wins, Draw, Village Captured

### 7. Events
- 25% chance per turn of a world event
- Affects random village (player or AI)
- Events: Famine, Plague, Bandit Attack, Bumper Harvest, Gold Rush, Rebellion, Festival, Earthquake, Trade Route Disrupted, Wandering Trader, Migration, Political Conflict

### 8. Win/Lose Conditions
- **Win**: Survive 120 turns (10 in-game years) OR conquer all villages
- **Lose**: Player village is captured/destroyed

## UI Layout
```
[Top Bar: Resources + Village Stats]
[                                    ] [Turn/Year]
[                                    ]
[  Main Game Area (panels overlay)  ]
[                                    ] [End Turn]
[Notification Log                   ] [Hotkeys]
```

## Hotkeys
- B = Building Panel
- D = Diplomacy Panel
- T = Trade Panel
- Enter = End Turn
- F5 = Quick Save
- F9 = Quick Load
- Esc = Close Panel
