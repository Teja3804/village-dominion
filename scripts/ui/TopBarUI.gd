extends Control

## Displays current resources and turn; Next Turn button. Reads from GameManager; emits via EventBus.

func _ready() -> void:
	if EventBus:
		EventBus.resources_changed.connect(_on_resources_changed)
		EventBus.turn_advanced.connect(_on_turn_advanced)
	_refresh_display()


func _on_resources_changed() -> void:
	_refresh_display()


func _on_turn_advanced() -> void:
	_refresh_display()


func _on_next_turn_pressed() -> void:
	if GameManager:
		GameManager.advance_turn()


func _refresh_display() -> void:
	# TODO: get GameManager.get_player_resources() and current_turn; update labels
	pass
