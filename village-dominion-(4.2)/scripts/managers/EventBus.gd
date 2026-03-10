## EventBus.gd
## Global signal bus — all game systems communicate through here.
## Autoloaded as "EventBus".

extends Node

# --- Turn signals ---
signal turn_started(turn_number: int)
signal turn_ended(turn_number: int)
signal year_changed(year: int)

# --- Village signals ---
signal village_resources_updated(village_id: int)
signal village_population_updated(village_id: int)
signal village_destroyed(village_id: int)
signal player_village_updated()

# --- Building signals ---
signal building_constructed(village_id: int, building_type: int)
signal building_upgraded(village_id: int, building_type: int)
signal build_failed(reason: String)

# --- Combat signals ---
signal battle_started(attacker_id: int, defender_id: int)
signal battle_resolved(result: Dictionary)
signal war_declared(attacker_id: int, target_id: int)

# --- Diplomacy signals ---
signal diplomacy_action_taken(action: Dictionary)
signal relationship_changed(village_a_id: int, village_b_id: int, new_score: int)
signal alliance_formed(village_a_id: int, village_b_id: int)
signal alliance_broken(village_a_id: int, village_b_id: int)
signal peace_agreed(village_a_id: int, village_b_id: int)
signal trade_route_opened(village_a_id: int, village_b_id: int)
signal trade_route_closed(village_a_id: int, village_b_id: int)

# --- Event signals ---
signal world_event_triggered(event: Dictionary)
signal notification_posted(message: String, severity: String)  # severity: info, warning, danger, success

# --- UI signals ---
signal panel_open_requested(panel_name: String, data: Dictionary)
signal panel_close_requested(panel_name: String)
signal show_battle_result(result: Dictionary)
signal show_diplomacy_response(response: Dictionary)
signal game_over(reason: String, player_won: bool)

# --- Save/Load signals ---
signal save_requested(slot: int)
signal load_requested(slot: int)
signal game_saved(slot: int)
signal game_loaded()

# Helper to post a notification
func notify(message: String, severity: String = "info") -> void:
	notification_posted.emit(message, severity)
