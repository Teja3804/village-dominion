## Main.gd — root scene. Creates game + entire UI in code. No scene deps.
extends Node

func _ready() -> void:
	GameManager.new_game()

	var ui = load("res://scripts/ui/GameUI.gd").new()
	ui.name = "GameUI"
	add_child(ui)
