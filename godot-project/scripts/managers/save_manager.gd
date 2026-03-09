extends Node

## Saves and loads full game state to/from JSON. Supports 3 save slots.
## Reads state from GameManager and DiplomacyManager; restores via GameManager.load_state and DiplomacyManager.import_state.
##
## Example JSON structure (saved to user://village_dominion_slot_1.json etc.):
## {
##   "version": 1,
##   "current_turn": 12,
##   "game_state": 0,
##   "player_village": {
##     "village_id": "player",
##     "display_name": "Your Village",
##     "resources": { "1": 50, "2": 40, "3": 30, "4": 20, "5": 0 },
##     "population": 5,
##     "max_population": 10,
##     "military_strength": 0,
##     "building_instances": [
##       { "instance_id": "player_farm_0", "building_type_id": 2, "grid_x": 1, "grid_y": 1, "level": 1, "assigned_workers": 2 }
##     ]
##   },
##   "ai_villages": [
##     { "village_id": "ai_northbrook", "display_name": "Northbrook", "personality_type_id": 7, "relationship_with_player": 10, "at_war": false, "resources": {...}, "building_instances": [...] }
##   ],
##   "diplomacy": {
##     "relations": { "player|ai_northbrook": 10, "player|ai_ironhold": 0, ... },
##     "alliances": { "player|ai_redrock": true, ... },
##     "at_war": { "player|ai_ashford": true, ... }
##   }
## }

const SAVE_DIR: String = "user://"
const SLOT_PREFIX: String = "village_dominion_slot_"
const NUM_SLOTS: int = 3

var last_save_path: String = ""


func get_slot_path(slot: int) -> String:
	slot = clampi(slot, 1, NUM_SLOTS)
	return SAVE_DIR + SLOT_PREFIX + str(slot) + ".json"


## Save current game to slot (1–3). Returns true on success.
func save_to_slot(slot: int) -> bool:
	if not GameManager:
		return false
	var path: String = get_slot_path(slot)
	var ok: bool = save(path)
	if ok:
		last_save_path = path
	return ok


## Save game state to a specific path. Used by save_to_slot and can be used with custom paths.
func save(path: String) -> bool:
	if not GameManager or not GameManager.player_village:
		return false
	var data: Dictionary = _collect_save_data()
	var json_str: String = JSON.stringify(data)
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(json_str)
	file.close()
	last_save_path = path
	return true


## Load game from slot (1–3). Returns true on success.
func load_from_slot(slot: int) -> bool:
	var path: String = get_slot_path(slot)
	return load(path)


## Load game state from path. Restores GameManager and DiplomacyManager.
func load(path: String) -> bool:
	if not FileAccess.file_exists(path):
		return false
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return false
	var json_str: String = file.get_as_text()
	file.close()
	var parse_result: JSON = JSON.new()
	var err: Error = parse_result.parse(json_str)
	if err != OK:
		return false
	var data: Variant = parse_result.data
	if typeof(data) != TYPE_DICTIONARY:
		return false
	if not GameManager:
		return false
	GameManager.load_state(data)
	var diplomacy: Variant = data.get("diplomacy", {})
	if DiplomacyManager and typeof(diplomacy) == TYPE_DICTIONARY:
		DiplomacyManager.import_state(diplomacy)
	GameManager.sync_ai_relations_from_diplomacy()
	if EventBus:
		EventBus.resources_changed.emit()
		EventBus.turn_advanced.emit()
		EventBus.buildings_changed.emit()
		EventBus.diplomacy_updated.emit()
	last_save_path = path
	return true


## Return true if the given slot has a save file.
func has_save_in_slot(slot: int) -> bool:
	return FileAccess.file_exists(get_slot_path(slot))


func has_save() -> bool:
	for slot in range(1, NUM_SLOTS + 1):
		if has_save_in_slot(slot):
			return true
	return false


## Get a short description for the slot (e.g. "Day 12") for UI. Returns empty dict if no save.
func get_slot_info(slot: int) -> Dictionary:
	var path: String = get_slot_path(slot)
	if not FileAccess.file_exists(path):
		return {}
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var json_str: String = file.get_as_text()
	file.close()
	var parse_result: JSON = JSON.new()
	if parse_result.parse(json_str) != OK:
		return {}
	var data: Variant = parse_result.data
	if typeof(data) != TYPE_DICTIONARY:
		return {}
	return {
		"turn": data.get("current_turn", 0),
		"game_state": data.get("game_state", 0)
	}


## Delete save file for slot. Returns true if deleted or no file existed.
func delete_slot(slot: int) -> bool:
	var path: String = get_slot_path(slot)
	if not FileAccess.file_exists(path):
		return true
	return DirAccess.remove_absolute(path) == OK


func _collect_save_data() -> Dictionary:
	var player_data: Dictionary = GameManager.player_village.to_dict()
	var ai_list: Array = []
	for ai in GameManager.ai_villages:
		var a = ai as AIVillage
		if a:
			ai_list.append(a.to_dict())
	var diplomacy_data: Dictionary = {}
	if DiplomacyManager:
		diplomacy_data = DiplomacyManager.export_state()
	return {
		"version": 1,
		"current_turn": GameManager.current_turn,
		"game_state": GameManager.game_state,
		"player_village": player_data,
		"ai_villages": ai_list,
		"diplomacy": diplomacy_data
	}
