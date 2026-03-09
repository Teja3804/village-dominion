extends Control

## Propose trade to selected AI. Give/get amounts; confirm calls GameManager/DiplomacyManager.

func _ready() -> void:
	# TODO: hide by default; show when Trade flow opened from DiplomacyPanel
	pass


func _on_confirm_pressed() -> void:
	# TODO: read give/get inputs; call DiplomacyManager.apply_action(TRADE, params); close
	pass


func _on_cancel_pressed() -> void:
	# TODO: hide panel
	pass
