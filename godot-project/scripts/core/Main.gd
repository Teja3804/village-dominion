extends Control

## Root gameplay scene. Holds VillageView and UI layer. Does not own game state.
## Optionally starts a new game on ready if GameManager has no village (e.g. first run).

func _ready() -> void:
	# Ensure game state exists when entering Main (e.g. from New Game or Continue).
	if GameManager and GameManager.player_village == null:
		GameManager.new_game()
