extends Control

## Lists AI villages with name, personality, relation score, and diplomacy action buttons.
## Refreshes on EventBus.diplomacy_updated and when opened.

@onready var village_list: VBoxContainer = $MarginContainer/VBox/ScrollContainer/VillageList
@onready var title_label: Label = $MarginContainer/VBox/TitleRow/TitleLabel
@onready var close_button: Button = $MarginContainer/VBox/TitleRow/CloseButton
@onready var message_label: Label = $MarginContainer/VBox/MessageLabel

const ROW_SEPARATION: int = 8
const PERSONALITY_NAMES: Dictionary = {
	GameConstants.PersonalityType.NONE: "—",
	GameConstants.PersonalityType.AGGRESSIVE: "Aggressive",
	GameConstants.PersonalityType.CAUTIOUS: "Cautious",
	GameConstants.PersonalityType.MERCANTILE: "Mercantile",
	GameConstants.PersonalityType.PROUD: "Proud",
	GameConstants.PersonalityType.PRAGMATIC: "Pragmatic",
	GameConstants.PersonalityType.DIPLOMATIC: "Diplomatic",
	GameConstants.PersonalityType.TRADER: "Trader",
	GameConstants.PersonalityType.OPPORTUNIST: "Opportunist"
}


func _ready() -> void:
	if close_button:
		close_button.pressed.connect(_on_close_pressed)
	if EventBus:
		EventBus.diplomacy_updated.connect(_refresh)
	_refresh()


func _refresh() -> void:
	_populate_list()


func _populate_list() -> void:
	if village_list == null or not GameManager:
		return
	for c in village_list.get_children():
		c.queue_free()

	var header = HBoxContainer.new()
	header.add_theme_constant_override("separation", ROW_SEPARATION)
	var h_name = Label.new()
	h_name.custom_minimum_size.x = 100
	h_name.text = "Village"
	header.add_child(h_name)
	var h_pers = Label.new()
	h_pers.custom_minimum_size.x = 90
	h_pers.text = "Personality"
	header.add_child(h_pers)
	var h_rel = Label.new()
	h_rel.custom_minimum_size.x = 44
	h_rel.text = "Rel"
	header.add_child(h_rel)
	# Spacer for buttons
	var spacer = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(spacer)
	village_list.add_child(header)

	for ai in GameManager.ai_villages:
		var a = ai as AIVillage
		if a == null:
			continue
		village_list.add_child(_make_row(a))


func _make_row(ai_village: AIVillage) -> Control:
	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", ROW_SEPARATION)

	var name_label = Label.new()
	name_label.custom_minimum_size.x = 100
	name_label.text = ai_village.display_name
	name_label.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	row.add_child(name_label)

	var personality_label = Label.new()
	personality_label.custom_minimum_size.x = 90
	personality_label.text = PERSONALITY_NAMES.get(ai_village.personality_type_id, "—")
	row.add_child(personality_label)

	var rel = GameManager.get_relation_to_ai(ai_village.village_id)
	var rel_label = Label.new()
	rel_label.custom_minimum_size.x = 44
	rel_label.text = str(rel)
	row.add_child(rel_label)

	var trade_btn = Button.new()
	trade_btn.text = "Trade"
	trade_btn.pressed.connect(_on_trade_pressed.bind(ai_village.village_id))
	row.add_child(trade_btn)

	var alliance_btn = Button.new()
	alliance_btn.text = "Alliance"
	alliance_btn.pressed.connect(_on_alliance_pressed.bind(ai_village.village_id))
	row.add_child(alliance_btn)

	var war_btn = Button.new()
	war_btn.text = "War"
	war_btn.pressed.connect(_on_war_pressed.bind(ai_village.village_id))
	row.add_child(war_btn)

	var aid_btn = Button.new()
	aid_btn.text = "Request Aid"
	aid_btn.pressed.connect(_on_aid_pressed.bind(ai_village.village_id))
	row.add_child(aid_btn)

	return row


func _show_message(text: String) -> void:
	if message_label:
		message_label.text = text


func _on_trade_pressed(ai_id: String) -> void:
	var result = GameManager.perform_diplomacy_action(GameConstants.DiplomacyAction.TRADE, ai_id)
	_show_message(result.get("message", ""))


func _on_alliance_pressed(ai_id: String) -> void:
	var result = GameManager.perform_diplomacy_action(GameConstants.DiplomacyAction.REQUEST_ALLIANCE, ai_id)
	_show_message(result.get("message", ""))


func _on_war_pressed(ai_id: String) -> void:
	var result = GameManager.perform_diplomacy_action(GameConstants.DiplomacyAction.DECLARE_WAR, ai_id)
	_show_message(result.get("message", ""))


func _on_aid_pressed(ai_id: String) -> void:
	var result = GameManager.perform_diplomacy_action(GameConstants.DiplomacyAction.REQUEST_AID, ai_id)
	_show_message(result.get("message", ""))


func _on_close_pressed() -> void:
	visible = false
