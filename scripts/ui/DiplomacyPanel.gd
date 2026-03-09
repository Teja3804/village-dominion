extends Control

## List AI villages and diplomacy actions. Calls GameManager/DiplomacyManager.
## Local: selected_ai_id for UI focus only.

var selected_ai_id: String = ""

func _ready() -> void:
	if EventBus:
		EventBus.diplomacy_updated.connect(_on_diplomacy_updated)
	_refresh_from_game_state()


func _on_diplomacy_updated() -> void:
	_refresh_from_game_state()


func _refresh_from_game_state() -> void:
	# TODO: get GameManager.ai_villages; show name, relationship, personality; update buttons
	pass


func _on_gift_pressed() -> void:
	# TODO: open sub-panel or modal to choose resource/amount; call DiplomacyManager.apply_action(GIFT, params)
	pass


func _on_trade_pressed() -> void:
	# TODO: open TradePanel for selected_ai_id
	pass


func _on_declare_war_pressed() -> void:
	# TODO: call GameManager or DiplomacyManager to set at_war for selected_ai_id
	pass
