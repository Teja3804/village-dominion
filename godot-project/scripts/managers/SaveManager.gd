extends Node

## Saves and loads full game state to/from disk. Reads state from GameManager; writes JSON.
## Do not store game state here; only serialization logic.

var last_save_path: String = ""


func save(path: String) -> bool:
	## Serialize GameManager state to JSON file. Return true on success.
	last_save_path = path
	# TODO: get state from GameManager (player_village.to_dict(), ai_villages, relationships, turn, etc.)
	# TODO: write to path as JSON
	return false


func load(path: String) -> bool:
	## Deserialize JSON and restore GameManager state. Return true on success.
	# TODO: read JSON from path
	# TODO: GameManager.player_village = Village.from_dict(...), etc.
	return false


func has_save() -> bool:
	## Return true if a save file exists (e.g. user://save.json or last_save_path).
	# TODO: FileAccess.file_exists(user://save.json) or similar
	return false
