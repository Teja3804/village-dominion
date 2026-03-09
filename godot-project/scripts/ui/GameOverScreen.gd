extends Control

## Victory/Defeat screen. Shown when game_state is won/lost. Restart / Quit.

func _ready() -> void:
	if EventBus:
		EventBus.game_over.connect(_on_game_over)
	hide()


func _on_game_over(won: bool, reason: String) -> void:
	# TODO: set title (Victory/Defeat), reason label; show()
	show()


func _on_restart_pressed() -> void:
	if GameManager:
		GameManager.new_game()
	hide()


func _on_quit_pressed() -> void:
	get_tree().quit()
