## SaveManager.gd
## Handles game save and load via JSON files. Autoloaded as "SaveManager".

extends Node

const SAVE_DIR: String = "user://saves/"
const SAVE_SLOTS: int = 3

func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(SAVE_DIR)
	EventBus.save_requested.connect(_on_save_requested)
	EventBus.load_requested.connect(_on_load_requested)

func _on_save_requested(slot: int) -> void:
	save_game(slot)

func _on_load_requested(slot: int) -> void:
	load_game(slot)

func save_game(slot: int) -> bool:
	var gm = GameManager
	if gm == null:
		return false

	var data = {
		"version": "1.0",
		"current_turn": gm.current_turn,
		"current_year": gm.current_year,
		"villages": []
	}

	for v in gm.all_villages:
		data["villages"].append(v.to_dict())

	var path = SAVE_DIR + "save_%d.json" % slot
	var file = FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		EventBus.notify("Save failed: could not open file.", "danger")
		return false

	file.store_string(JSON.stringify(data, "\t"))
	file.close()
	EventBus.game_saved.emit(slot)
	EventBus.notify("Game saved to slot %d." % slot, "success")
	return true

func load_game(slot: int) -> bool:
	var path = SAVE_DIR + "save_%d.json" % slot
	if not FileAccess.file_exists(path):
		EventBus.notify("No save found in slot %d." % slot, "warning")
		return false

	var file = FileAccess.open(path, FileAccess.READ)
	if file == null:
		EventBus.notify("Load failed: could not open file.", "danger")
		return false

	var text = file.get_as_text()
	file.close()

	var json = JSON.new()
	var err = json.parse(text)
	if err != OK:
		EventBus.notify("Load failed: corrupted save file.", "danger")
		return false

	var data = json.get_data()
	var gm = GameManager

	# Clear existing villages
	for v in gm.all_villages:
		v.queue_free()
	gm.all_villages.clear()
	gm.player_village = null

	gm.current_turn = data.get("current_turn", 0)
	gm.current_year = data.get("current_year", 1)

	for vdata in data.get("villages", []):
		var village: Village
		if vdata.get("is_player", false):
			village = Village.new()
		else:
			village = AIVillage.new()
		village.from_dict(vdata)
		gm.add_child(village)
		gm.all_villages.append(village)
		if village.is_player:
			gm.player_village = village

	gm.game_running = true
	EventBus.game_loaded.emit()
	EventBus.player_village_updated.emit()
	EventBus.notify("Game loaded from slot %d." % slot, "success")
	return true

func get_save_info(slot: int) -> Dictionary:
	var path = SAVE_DIR + "save_%d.json" % slot
	if not FileAccess.file_exists(path):
		return {"exists": false}

	var file = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {"exists": false}

	var text = file.get_as_text()
	file.close()

	var json = JSON.new()
	if json.parse(text) != OK:
		return {"exists": false}

	var data = json.get_data()
	return {
		"exists": true,
		"turn": data.get("current_turn", 0),
		"year": data.get("current_year", 1),
		"version": data.get("version", "?")
	}

func delete_save(slot: int) -> void:
	var path = SAVE_DIR + "save_%d.json" % slot
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)
