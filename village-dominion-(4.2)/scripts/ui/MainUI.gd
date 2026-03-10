## MainUI.gd
## Main HUD controller. Manages all panels and notification log.

extends Control

@onready var top_bar: Control = $TopBar
@onready var building_panel: Control = $BuildingPanel
@onready var diplomacy_panel: Control = $DiplomacyPanel
@onready var trade_panel: Control = $TradePanel
@onready var event_popup: Control = $EventPopup
@onready var battle_result_popup: Control = $BattleResultPopup
@onready var save_menu: Control = $SaveMenu
@onready var notification_log: RichTextLabel = $NotificationLog
@onready var end_turn_button: Button = $EndTurnButton
@onready var turn_label: Label = $TurnLabel
@onready var year_label: Label = $YearLabel

const MAX_LOG_ENTRIES: int = 50
var log_entries: Array = []

func _ready() -> void:
	_connect_signals()
	_hide_all_panels()
	_update_turn_display()

func _connect_signals() -> void:
	EventBus.notification_posted.connect(_on_notification)
	EventBus.world_event_triggered.connect(_on_world_event)
	EventBus.battle_resolved.connect(_on_battle_resolved)
	EventBus.turn_started.connect(_on_turn_started)
	EventBus.year_changed.connect(_on_year_changed)
	EventBus.panel_open_requested.connect(_on_panel_open_requested)
	EventBus.panel_close_requested.connect(_on_panel_close_requested)
	EventBus.player_village_updated.connect(_on_player_updated)

	if end_turn_button:
		end_turn_button.pressed.connect(_on_end_turn_pressed)

func _hide_all_panels() -> void:
	for panel in [building_panel, diplomacy_panel, trade_panel, save_menu]:
		if panel:
			panel.hide()

func _on_end_turn_pressed() -> void:
	GameManager.end_turn()

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
	if event_popup and event.get("village_id", -1) == GameManager.player_village.village_id:
		event_popup.show_event(event)
		event_popup.show()

func _on_battle_resolved(result: Dictionary) -> void:
	var player_id = GameManager.player_village.village_id
	if result.get("attacker_id") == player_id or result.get("defender_id") == player_id:
		if battle_result_popup:
			battle_result_popup.show_result(result)
			battle_result_popup.show()

func _on_panel_open_requested(panel_name: String, data: Dictionary) -> void:
	match panel_name:
		"building":
			if building_panel:
				building_panel.refresh()
				building_panel.show()
		"diplomacy":
			if diplomacy_panel:
				diplomacy_panel.refresh(data)
				diplomacy_panel.show()
		"trade":
			if trade_panel:
				trade_panel.refresh(data)
				trade_panel.show()
		"save":
			if save_menu:
				save_menu.refresh()
				save_menu.show()

func _on_panel_close_requested(panel_name: String) -> void:
	match panel_name:
		"building":
			if building_panel:
				building_panel.hide()
		"diplomacy":
			if diplomacy_panel:
				diplomacy_panel.hide()
		"trade":
			if trade_panel:
				trade_panel.hide()
		"save":
			if save_menu:
				save_menu.hide()

func _severity_color(severity: String) -> String:
	match severity:
		"danger": return "#ff4444"
		"warning": return "#ffaa00"
		"success": return "#44ff88"
		"info": return "#aaddff"
		_: return "#ffffff"

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_B:
				EventBus.panel_open_requested.emit("building", {})
			KEY_D:
				EventBus.panel_open_requested.emit("diplomacy", {})
			KEY_T:
				EventBus.panel_open_requested.emit("trade", {})
			KEY_ESCAPE:
				_hide_all_panels()
			KEY_F5:
				EventBus.save_requested.emit(1)
			KEY_F9:
				EventBus.load_requested.emit(1)
