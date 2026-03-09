extends Node

## Global signal bus. Emit from GameManager/managers; connect in UI.
## No state; only signals. Keeps systems decoupled.

signal resources_changed
signal turn_advanced
signal buildings_changed
signal event_triggered(event_data: Dictionary)
signal battle_resolved(result: Dictionary)
signal diplomacy_updated
signal game_over(won: bool, reason: String)
