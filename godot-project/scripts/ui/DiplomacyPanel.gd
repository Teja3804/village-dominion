## DiplomacyPanel.gd
## Panel for diplomacy actions with other villages.

extends Control

@onready var village_list: VBoxContainer = $HBoxLayout/LeftPanel/ScrollContainer/VillageList
@onready var title_label: Label = $HBoxLayout/LeftPanel/TitleRow/TitleLabel
@onready var close_btn: Button = $HBoxLayout/LeftPanel/TitleRow/CloseButton
@onready var detail_panel: Control = $HBoxLayout/DetailPanel
@onready var detail_name: Label = $HBoxLayout/DetailPanel/VillageName
@onready var detail_info: Label = $HBoxLayout/DetailPanel/VillageInfo
@onready var action_buttons: VBoxContainer = $HBoxLayout/DetailPanel/ActionButtons

var selected_village_id: int = -1

func _ready() -> void:
	if close_btn:
		close_btn.pressed.connect(func(): EventBus.panel_close_requested.emit("diplomacy"))
	EventBus.diplomacy_action_taken.connect(func(_d): refresh({}))
	EventBus.relationship_changed.connect(func(_a, _b, _c): refresh({}))

func refresh(data: Dictionary) -> void:
	if title_label:
		title_label.text = "Diplomacy"
	if detail_panel:
		detail_panel.hide()

	if village_list == null:
		return

	for child in village_list.get_children():
		child.queue_free()

	var player = GameManager.player_village
	for v in GameManager.get_alive_villages():
		if v.is_player:
			continue
		var row = _create_village_row(player, v)
		village_list.add_child(row)

func _create_village_row(player: Village, v: Village) -> Control:
	var btn = Button.new()
	var rel = player.get_relationship(v.village_id)
	var state = _relation_state_name(player.get_relation_state(v.village_id))
	btn.text = "%s  [%s: %d]  Str:%d" % [v.village_name, state, rel, v.get_defense_power()]
	btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
	btn.pressed.connect(func(): _select_village(v.village_id))
	return btn

func _select_village(vid: int) -> void:
	selected_village_id = vid
	var v = GameManager.get_village_by_id(vid)
	var player = GameManager.player_village
	if v == null or detail_panel == null:
		return

	detail_panel.show()

	if detail_name:
		detail_name.text = v.village_name
	if detail_info:
		var rel = player.get_relationship(vid)
		var state = _relation_state_name(player.get_relation_state(vid))
		var personality = "Unknown"
		if v is AIVillage:
			personality = Constants.PERSONALITY_NAMES[v.personality]
		detail_info.text = (
			"Leader: %s\nPersonality: %s\nRelation: %s (%d)\n" +
			"Population: %d | Soldiers: %d\nVillage Lv.%d"
		) % [v.leader_name, personality, state, rel, v.population, v.soldiers, v.village_level]

	_rebuild_action_buttons(player, v)

func _rebuild_action_buttons(player: Village, v: Village) -> void:
	if action_buttons == null:
		return
	for child in action_buttons.get_children():
		child.queue_free()

	var at_war = player.is_at_war_with(v.village_id)
	var allied = player.is_allied_with(v.village_id)
	var rel = player.get_relationship(v.village_id)
	var has_trade = player.trade_routes.has(v.village_id)

	if not at_war:
		_add_action_btn("Declare War", func(): _do_action(Constants.DiplomacyAction.DECLARE_WAR))
	else:
		_add_action_btn("Propose Peace", func(): _do_action(Constants.DiplomacyAction.PROPOSE_PEACE))

	if not allied and not at_war and rel >= 10:
		_add_action_btn("Propose Alliance", func(): _do_action(Constants.DiplomacyAction.PROPOSE_ALLIANCE))
	elif allied:
		_add_action_btn("Break Alliance", func(): _do_action(Constants.DiplomacyAction.BREAK_ALLIANCE))
		_add_action_btn("Request Aid", func(): _do_action(Constants.DiplomacyAction.REQUEST_AID))

	_add_action_btn("Send Gift (20 Gold)", func(): _do_action(Constants.DiplomacyAction.SEND_GIFT, {"amount": 20}))
	_add_action_btn("Threaten", func(): _do_action(Constants.DiplomacyAction.THREATEN))

	if not has_trade and not at_war:
		_add_action_btn("Propose Trade", func(): _do_trade_dialog())
	elif has_trade:
		_add_action_btn("Cancel Trade Route", func(): _do_action(Constants.DiplomacyAction.CANCEL_TRADE))

	# Attack button
	if at_war or rel <= -50:
		_add_action_btn("ATTACK!", func(): _do_attack())

func _add_action_btn(label: String, callback: Callable) -> void:
	var btn = Button.new()
	btn.text = label
	btn.pressed.connect(callback)
	action_buttons.add_child(btn)

func _do_action(action: int, extra: Dictionary = {}) -> void:
	if selected_village_id < 0:
		return
	GameManager.diplomacy_manager.player_action(action, selected_village_id, extra)
	_select_village(selected_village_id)  # Refresh detail view

func _do_attack() -> void:
	if selected_village_id < 0:
		return
	GameManager.battle_manager.player_attack(selected_village_id)
	EventBus.panel_close_requested.emit("diplomacy")

func _do_trade_dialog() -> void:
	# Simple default trade: offer 20 Wood for 15 Gold
	var extra = {
		"resource_give": Constants.ResourceType.WOOD,
		"amount_give": 20,
		"resource_receive": Constants.ResourceType.GOLD,
		"amount_receive": 15
	}
	_do_action(Constants.DiplomacyAction.PROPOSE_TRADE, extra)

func _relation_state_name(state: int) -> String:
	match state:
		Constants.RelationState.WAR: return "WAR"
		Constants.RelationState.HOSTILE: return "Hostile"
		Constants.RelationState.NEUTRAL: return "Neutral"
		Constants.RelationState.FRIENDLY: return "Friendly"
		Constants.RelationState.ALLIED: return "ALLIED"
		_: return "Unknown"
