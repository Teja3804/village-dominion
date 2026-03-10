## MainUI.gd
## Main HUD controller. Manages all panels and notification log.

extends Control

# Panels — found via get_node_or_null so no onready crash if names differ
var building_panel: Control
var diplomacy_panel: Control
var trade_panel: Control
var event_popup: Control
var battle_result_popup: Control
var save_menu: Control
var notification_log: RichTextLabel
var turn_label: Label
var year_label: Label
var top_bar: Control

const MAX_LOG_ENTRIES: int = 50
var log_entries: Array = []

func _ready() -> void:
	# Find nodes safely
	top_bar             = get_node_or_null("TopBar")
	building_panel      = get_node_or_null("BuildingPanel")
	diplomacy_panel     = get_node_or_null("DiplomacyPanel")
	trade_panel         = get_node_or_null("TradePanel")
	event_popup         = get_node_or_null("EventPopup")
	battle_result_popup = get_node_or_null("BattleResultPopup")
	save_menu           = get_node_or_null("SaveMenu")
	notification_log    = get_node_or_null("NotificationLog")
	turn_label          = get_node_or_null("TurnLabel")
	year_label          = get_node_or_null("YearLabel")

	# Fix: non-interactive display nodes must not block mouse events
	if notification_log:
		notification_log.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if turn_label:
		turn_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if year_label:
		year_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if top_bar:
		top_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
		for child in top_bar.get_children():
			child.mouse_filter = Control.MOUSE_FILTER_IGNORE

	_spawn_world_map()
	_hide_all_panels()
	_build_nav_buttons()
	_connect_signals()
	_update_turn_display()

func _spawn_world_map() -> void:
	var map = load("res://scripts/ui/WorldMapView.gd").new()
	map.name = "WorldMap"
	map.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	# Leave room for top bar (55px) and nav buttons (55px at bottom)
	map.offset_top = 55.0
	map.offset_bottom = -130.0
	add_child(map)
	move_child(map, 0)  # behind panels

func _build_nav_buttons() -> void:
	# Create a clearly visible button bar in the center of the screen
	var bar = HBoxContainer.new()
	bar.name = "NavBar"
	bar.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	bar.offset_top = -120.0
	bar.offset_bottom = -90.0
	bar.offset_left = 10.0
	bar.offset_right = -10.0
	bar.alignment = BoxContainer.ALIGNMENT_CENTER
	bar.add_theme_constant_override("separation", 16)
	bar.z_index = 10
	add_child(bar)

	var btns = [
		["Build (B)", func(): _open_panel("building")],
		["Diplomacy (D)", func(): _open_panel("diplomacy")],
		["Trade (T)", func(): _open_panel("trade")],
		["Save/Load", func(): _open_panel("save")],
		["End Turn", func(): GameManager.end_turn()],
	]
	for b in btns:
		var btn = Button.new()
		btn.text = b[0]
		btn.custom_minimum_size = Vector2(140, 40)
		btn.pressed.connect(b[1])
		bar.add_child(btn)

func _connect_signals() -> void:
	EventBus.notification_posted.connect(_on_notification)
	EventBus.world_event_triggered.connect(_on_world_event)
	EventBus.battle_resolved.connect(_on_battle_resolved)
	EventBus.turn_started.connect(_on_turn_started)
	EventBus.year_changed.connect(_on_year_changed)
	EventBus.panel_open_requested.connect(_on_panel_open_requested)
	EventBus.panel_close_requested.connect(_on_panel_close_requested)
	EventBus.player_village_updated.connect(_on_player_updated)

func _hide_all_panels() -> void:
	for panel in [building_panel, diplomacy_panel, trade_panel, save_menu]:
		if panel:
			panel.hide()

func _open_panel(name: String) -> void:
	EventBus.panel_open_requested.emit(name, {})

func _on_panel_open_requested(panel_name: String, data: Dictionary) -> void:
	_hide_all_panels()
	match panel_name:
		"building":
			if building_panel:
				building_panel.refresh()
				building_panel.show()
				building_panel.move_to_front()
		"diplomacy":
			if diplomacy_panel:
				diplomacy_panel.refresh(data)
				diplomacy_panel.show()
				diplomacy_panel.move_to_front()
		"trade":
			if trade_panel:
				trade_panel.refresh(data)
				trade_panel.show()
				trade_panel.move_to_front()
		"save":
			if save_menu:
				save_menu.refresh()
				save_menu.show()
				save_menu.move_to_front()

func _on_panel_close_requested(panel_name: String) -> void:
	match panel_name:
		"building":   if building_panel:   building_panel.hide()
		"diplomacy":  if diplomacy_panel:  diplomacy_panel.hide()
		"trade":      if trade_panel:      trade_panel.hide()
		"save":       if save_menu:        save_menu.hide()

func _on_turn_started(_turn: int) -> void:
	_update_turn_display()
	if top_bar:
		top_bar.refresh()

func _on_year_changed(year: int) -> void:
	if year_label:
		year_label.text = "Year %d" % year

func _on_player_updated() -> void:
	if top_bar:
		top_bar.refresh()

func _update_turn_display() -> void:
	if turn_label:
		turn_label.text = "Turn %d / %d" % [GameManager.current_turn, Constants.MAX_TURNS]
	if year_label:
		year_label.text = "Year %d" % GameManager.current_year

func _on_notification(message: String, severity: String) -> void:
	var color = _severity_color(severity)
	var entry = "[color=%s]%s[/color]" % [color, message]
	log_entries.append(entry)
	if log_entries.size() > MAX_LOG_ENTRIES:
		log_entries.pop_front()
	if notification_log:
		notification_log.text = "\n".join(log_entries)
		notification_log.scroll_to_line(notification_log.get_line_count())

func _on_world_event(event: Dictionary) -> void:
	if event_popup and GameManager.player_village and event.get("village_id", -1) == GameManager.player_village.village_id:
		event_popup.show_event(event)
		event_popup.show()
		event_popup.move_to_front()

func _on_battle_resolved(result: Dictionary) -> void:
	if GameManager.player_village == null:
		return
	var player_id = GameManager.player_village.village_id
	if result.get("attacker_id") == player_id or result.get("defender_id") == player_id:
		if battle_result_popup:
			battle_result_popup.show_result(result)
			battle_result_popup.show()
			battle_result_popup.move_to_front()

func _severity_color(severity: String) -> String:
	match severity:
		"danger":  return "#ff4444"
		"warning": return "#ffaa00"
		"success": return "#44ff88"
		"info":    return "#aaddff"
		_:         return "#ffffff"

func _unhandled_key_input(event: InputEvent) -> void:
	if not event.pressed:
		return
	match (event as InputEventKey).keycode:
		KEY_B:       _open_panel("building")
		KEY_D:       _open_panel("diplomacy")
		KEY_T:       _open_panel("trade")
		KEY_ESCAPE:  _hide_all_panels()
		KEY_F5:      EventBus.save_requested.emit(1)
		KEY_F9:      EventBus.load_requested.emit(1)
