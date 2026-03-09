extends Control

## Shows battle outcome (result text). OK button closes. No state.

func _ready() -> void:
	# Hidden by default. Shown when EventBus.battle_resolved emitted.
	if EventBus:
		EventBus.battle_resolved.connect(_on_battle_resolved)
	hide()


func _on_battle_resolved(result: Dictionary) -> void:
	# TODO: set label from result (winner, losses); show()
	show()


func _on_ok_pressed() -> void:
	hide()
