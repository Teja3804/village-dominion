## Main.gd
## Root scene controller. Wires up UI and starts/loads the game.

extends Node

@onready var main_ui: Control = $MainUI
@onready var game_over_screen: Control = $GameOverScreen

func _ready() -> void:
	EventBus.game_over.connect(_on_game_over)
	EventBus.game_loaded.connect(_on_game_loaded)

	# Auto-start new game for now
	GameManager.new_game()

func _on_game_over(reason: String, player_won: bool) -> void:
	if game_over_screen:
		game_over_screen.show_result(reason, player_won)
		game_over_screen.show()

func _on_game_loaded() -> void:
	if game_over_screen:
		game_over_screen.hide()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_end_turn"):
		GameManager.end_turn()
