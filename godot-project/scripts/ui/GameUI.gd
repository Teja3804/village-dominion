## GameUI.gd
## Entire game UI built 100% in code. No scene structure needed.

extends CanvasLayer

var _top_bar: HBoxContainer
var _log_label: RichTextLabel
var _turn_label: Label
var _year_label: Label
var _panel_root: Control
var _active_panel: Control = null
var _log_entries: Array = []
const MAX_LOG: int = 60

const C_PANEL      := Color(0.13, 0.14, 0.20, 0.98)
const C_BORDER     := Color(0.40, 0.42, 0.60, 0.90)
const C_BTN        := Color(0.18, 0.20, 0.30)
const C_BTN_HOV    := Color(0.26, 0.29, 0.42)
const C_END_TURN   := Color(0.15, 0.38, 0.18)
const C_END_HOV    := Color(0.20, 0.52, 0.22)
const C_DANGER     := Color(0.48, 0.10, 0.10)
const C_DANGER_HOV := Color(0.65, 0.14, 0.14)

func _ready() -> void:
	layer = 0
	set_process_unhandled_input(true)
	_build_top_bar()
	_build_map()
	_build_log()
	_build_nav_bar()
	_build_panel_root()
	_connect_bus()

# ---------- Style helpers ----------

func _mk_sb(bg: Color, border: Color = C_BORDER, radius: int = 5) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_width_left   = 1
	s.border_width_right  = 1
	s.border_width_top    = 1
	s.border_width_bottom = 1
	s.border_color = border
	s.corner_radius_top_left     = radius
	s.corner_radius_top_right    = radius
	s.corner_radius_bottom_left  = radius
	s.corner_radius_bottom_right = radius
	s.content_margin_left   = 8
	s.content_margin_right  = 8
	s.content_margin_top    = 4
	s.content_margin_bottom = 4
	return s

func _style(btn: Button, normal: Color, hover: Color) -> void:
	btn.add_theme_stylebox_override("normal",   _mk_sb(normal))
	btn.add_theme_stylebox_override("hover",    _mk_sb(hover))
	btn.add_theme_stylebox_override("pressed",  _mk_sb(normal.darkened(0.15)))
	btn.add_theme_stylebox_override("focus",    _mk_sb(hover, Color(0.8, 0.8, 1.0)))
	btn.add_theme_stylebox_override("disabled", _mk_sb(Color(0.12, 0.12, 0.18), Color(0.25, 0.25, 0.35)))
	btn.add_theme_color_override("font_color",          Color.WHITE)
	btn.add_theme_color_override("font_hover_color",    Color(0.95, 0.95, 1.0))
	btn.add_theme_color_override("font_pressed_color",  Color(0.75, 0.75, 0.9))
	btn.add_theme_color_override("font_disabled_color", Color(0.4, 0.4, 0.5))
	btn.add_theme_font_size_override("font_size", 13)

func _lbl(text: String, font_size: int = 13, color: Color = Color.WHITE) -> Label:
	var l := Label.new()
	l.text = text
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)
	return l

func _panel_bg(c: PanelContainer) -> void:
	var sb := _mk_sb(C_PANEL, C_BORDER, 6)
	sb.content_margin_left   = 10
	sb.content_margin_right  = 10
	sb.content_margin_top    = 8
	sb.content_margin_bottom = 8
	c.add_theme_stylebox_override("panel", sb)

# ---------- Top bar ----------

func _build_top_bar() -> void:
	var bar := PanelContainer.new()
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	bar.offset_bottom = 52.0
	_panel_bg(bar)
	add_child(bar)

	var hbox := HBoxContainer.new()
	hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hbox.add_theme_constant_override("separation", 18)
	bar.add_child(hbox)
	_top_bar = hbox

	_turn_label = _lbl("Turn 0/120", 12, Color(0.8, 0.8, 1.0))
	_year_label = _lbl("Year 1",     12, Color(0.8, 0.8, 1.0))

	for text in ["Lv.1 Village", "Food:200", "Wood:150",
				 "Stone:100", "Gold:50", "Weapons:20",
				 "Pop:10/10", "Soldiers:5", "Morale:70"]:
		hbox.add_child(_lbl(text, 13))

	var spacer := Control.new()
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(spacer)
	hbox.add_child(_turn_label)
	hbox.add_child(_year_label)

# ---------- World map ----------

func _build_map() -> void:
	var map = load("res://scripts/ui/WorldMapView.gd").new()
	map.name = "WorldMap"
	map.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	map.offset_top    = 52.0
	map.offset_bottom = -135.0
	map.mouse_filter  = Control.MOUSE_FILTER_IGNORE
	add_child(map)

# ---------- Notification log ----------

func _build_log() -> void:
	var log_bg := PanelContainer.new()
	log_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	log_bg.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	log_bg.offset_top    = -180.0
	log_bg.offset_right  = 560.0
	log_bg.offset_bottom = -135.0
	_panel_bg(log_bg)
	add_child(log_bg)

	var rtl := RichTextLabel.new()
	rtl.bbcode_enabled    = true
	rtl.scroll_following  = true
	rtl.mouse_filter      = Control.MOUSE_FILTER_IGNORE
	rtl.add_theme_font_size_override("normal_font_size", 12)
	log_bg.add_child(rtl)
	_log_label = rtl

# ---------- Nav bar ----------

func _build_nav_bar() -> void:
	var bg := PanelContainer.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	bg.offset_top    = -135.0
	bg.offset_bottom = 0.0
	_panel_bg(bg)
	add_child(bg)

	var bar := HBoxContainer.new()
	bar.alignment = BoxContainer.ALIGNMENT_CENTER
	bar.add_theme_constant_override("separation", 14)
	bg.add_child(bar)

	_nav_btn(bar, "Build  [B]",        func(): _show_panel(_make_building_panel()))
	_nav_btn(bar, "Diplomacy  [D]",    func(): _show_panel(_make_diplomacy_panel()))
	_nav_btn(bar, "Trade  [T]",        func(): _show_panel(_make_trade_panel()))
	_nav_btn(bar, "Save / Load",       func(): _show_panel(_make_save_panel()))
	_nav_btn(bar, "End Turn  [Enter]", func(): _end_turn(), C_END_TURN, C_END_HOV)

	var hint := _lbl(
		"[B]=Build  [D]=Diplomacy  [T]=Trade  [Esc]=Close  [F5]=Quick Save  [F9]=Quick Load",
		11, Color(0.50, 0.50, 0.65))
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.add_child(hint)

func _nav_btn(parent: Control, text: String, cb: Callable,
			  normal: Color = C_BTN, hover: Color = C_BTN_HOV) -> void:
	var btn := Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(155, 50)
	_style(btn, normal, hover)
	btn.pressed.connect(cb)
	parent.add_child(btn)

# ---------- Panel root ----------

func _build_panel_root() -> void:
	_panel_root = Control.new()
	_panel_root.name = "PanelRoot"
	_panel_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_panel_root.offset_top    = 52.0
	_panel_root.offset_bottom = -135.0
	_panel_root.mouse_filter  = Control.MOUSE_FILTER_IGNORE
	add_child(_panel_root)

func _show_panel(panel: Control) -> void:
	if _active_panel and is_instance_valid(_active_panel):
		_active_panel.queue_free()
	_active_panel = panel
	_panel_root.add_child(panel)

func _close_panel() -> void:
	if _active_panel and is_instance_valid(_active_panel):
		_active_panel.queue_free()
		_active_panel = null

# ---------- Panel base ----------

func _panel_base(title: String) -> Control:
	var panel := PanelContainer.new()
	panel.set_anchor(SIDE_LEFT,   0.04)
	panel.set_anchor(SIDE_TOP,    0.02)
	panel.set_anchor(SIDE_RIGHT,  0.96)
	panel.set_anchor(SIDE_BOTTOM, 0.98)
	panel.offset_left   = 0.0
	panel.offset_top    = 0.0
	panel.offset_right  = 0.0
	panel.offset_bottom = 0.0
	_panel_bg(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	panel.add_child(vbox)

	var title_row := HBoxContainer.new()
	vbox.add_child(title_row)

	var tlabel := _lbl(title, 17, Color(0.85, 0.90, 1.0))
	tlabel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_row.add_child(tlabel)

	var close := Button.new()
	close.text = "X  Close  [Esc]"
	close.custom_minimum_size = Vector2(120, 34)
	_style(close, Color(0.35, 0.12, 0.12), Color(0.55, 0.15, 0.15))
	close.pressed.connect(_close_panel)
	title_row.add_child(close)

	return panel

func _action_btn(parent: Control, text: String, cb: Callable,
				 col: Color = C_BTN, hov: Color = C_BTN_HOV) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
	_style(btn, col, hov)
	btn.pressed.connect(cb)
	parent.add_child(btn)
	return btn

# ---------- Building panel ----------

func _make_building_panel() -> Control:
	var root := _panel_base("Buildings -- " + GameManager.player_village.village_name)
	var vbox: VBoxContainer = root.get_child(0)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(scroll)

	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 6)
	scroll.add_child(list)

	var v := GameManager.player_village
	var db := GameManager.building_db

	for btype in Constants.BuildingType.values():
		var def := db.get_definition(btype)
		if def == null:
			continue
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		list.add_child(row)

		var nm := _lbl(Constants.BUILDING_NAMES[btype], 14)
		nm.custom_minimum_size = Vector2(130, 0)
		row.add_child(nm)

		var count := v.count_buildings_of_type(btype)
		var level := v.get_building_level(btype)
		var st_col: Color = Color(0.7, 0.8, 0.7) if count > 0 else Color(0.5, 0.5, 0.6)
		var st_txt: String = ("Lv.%d (%d)" % [level, count]) if count > 0 else "--"
		var st := _lbl(st_txt, 12, st_col)
		st.custom_minimum_size = Vector2(80, 0)
		row.add_child(st)

		if count < def.max_count:
			var cost := def.get_cost_for_level(1)
			var bb := Button.new()
			bb.text = "Build (%s)" % _fmt_cost(cost)
			bb.disabled = not v.can_afford(cost)
			_style(bb, Color(0.15, 0.30, 0.15), Color(0.20, 0.42, 0.20))
			bb.pressed.connect(func():
				if v.construct_building(btype):
					_post("[color=#44ff88]Built %s![/color]" % Constants.BUILDING_NAMES[btype])
					_refresh_top_bar()
					_show_panel(_make_building_panel())
				else:
					_post("[color=#ff6666]Cannot build -- check resources or prerequisites.[/color]")
			)
			row.add_child(bb)

		if count > 0 and level < def.max_level:
			var cost := def.get_cost_for_level(level + 1)
			var ub := Button.new()
			ub.text = "Upgrade (%s)" % _fmt_cost(cost)
			ub.disabled = not v.can_afford(cost)
			_style(ub, Color(0.25, 0.25, 0.10), Color(0.38, 0.38, 0.14))
			ub.pressed.connect(func():
				if v.upgrade_building(btype):
					_post("[color=#ffdd44]Upgraded %s![/color]" % Constants.BUILDING_NAMES[btype])
					_refresh_top_bar()
					_show_panel(_make_building_panel())
				else:
					_post("[color=#ff6666]Cannot upgrade -- not enough resources.[/color]")
			)
			row.add_child(ub)

		if btype == Constants.BuildingType.BARRACKS and count > 0:
			var tb := Button.new()
			tb.text = "Train 3 soldiers (30 Gold + 6 Weapons)"
			_style(tb, Color(0.25, 0.15, 0.10), Color(0.38, 0.22, 0.14))
			tb.pressed.connect(func():
				if v.train_soldiers(3):
					_post("[color=#44ff88]Trained 3 soldiers.[/color]")
					_refresh_top_bar()
				else:
					_post("[color=#ff6666]Cannot train -- need gold/weapons and free population.[/color]")
			)
			row.add_child(tb)

		var desc := _lbl(def.description, 11, Color(0.55, 0.60, 0.75))
		desc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		row.add_child(desc)

	return root

# ---------- Diplomacy panel ----------

func _make_diplomacy_panel(preselect: int = -1) -> Control:
	var root := _panel_base("Diplomacy")
	var vbox: VBoxContainer = root.get_child(0)

	var hbox := HBoxContainer.new()
	hbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	hbox.add_theme_constant_override("separation", 12)
	vbox.add_child(hbox)

	var left_wrap := PanelContainer.new()
	left_wrap.custom_minimum_size = Vector2(260, 0)
	_panel_bg(left_wrap)
	hbox.add_child(left_wrap)

	var left := VBoxContainer.new()
	left.add_theme_constant_override("separation", 4)
	left_wrap.add_child(left)

	var right := VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.add_theme_constant_override("separation", 8)
	hbox.add_child(right)

	var player := GameManager.player_village
	var detail_name := _lbl("<-- Select a village from the list", 14, Color(0.7, 0.8, 1.0))
	var detail_info := Label.new()
	detail_info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail_info.mouse_filter  = Control.MOUSE_FILTER_IGNORE
	detail_info.add_theme_font_size_override("font_size", 13)
	detail_info.add_theme_color_override("font_color", Color(0.8, 0.85, 0.9))
	var action_box := VBoxContainer.new()
	action_box.add_theme_constant_override("separation", 5)

	right.add_child(detail_name)
	right.add_child(detail_info)
	right.add_child(action_box)

	var select_fn := func(v: Village):
		detail_name.text = "%s  (Lv.%d)" % [v.village_name, v.village_level]
		var rel := player.get_relationship(v.village_id)
		var pname: String
		if v is AIVillage:
			pname = Constants.PERSONALITY_NAMES[(v as AIVillage).personality]
		else:
			pname = "Player"
		detail_info.text = (
			"Leader: %s\nPersonality: %s\nRelation: %+d  (%s)\n"
			+ "Population: %d  |  Soldiers: %d\nAttack: %d  |  Defense: %d"
		) % [v.leader_name, pname, rel, _rel_name(player.get_relation_state(v.village_id)),
			 v.population, v.soldiers, v.get_attack_power(), v.get_defense_power()]

		for c in action_box.get_children():
			c.queue_free()

		var at_war := player.is_at_war_with(v.village_id)
		var allied := player.is_allied_with(v.village_id)
		var has_trade := player.trade_routes.has(v.village_id)

		if at_war:
			_action_btn(action_box, "Propose Peace",
						func(): _dipl_act(Constants.DiplomacyAction.PROPOSE_PEACE, v.village_id))
			_action_btn(action_box, "ATTACK NOW!",
						func(): _do_attack(v.village_id), C_DANGER, C_DANGER_HOV)
		else:
			_action_btn(action_box, "Declare War",
						func(): _dipl_act(Constants.DiplomacyAction.DECLARE_WAR, v.village_id),
						C_DANGER, C_DANGER_HOV)

		if not allied and not at_war and player.get_relationship(v.village_id) >= -10:
			_action_btn(action_box, "Propose Alliance",
						func(): _dipl_act(Constants.DiplomacyAction.PROPOSE_ALLIANCE, v.village_id))
		if allied:
			_action_btn(action_box, "Break Alliance",
						func(): _dipl_act(Constants.DiplomacyAction.BREAK_ALLIANCE, v.village_id))
			_action_btn(action_box, "Request Aid",
						func(): _dipl_act(Constants.DiplomacyAction.REQUEST_AID, v.village_id))

		_action_btn(action_box, "Send Gift (20 gold)",
					func(): _dipl_act(Constants.DiplomacyAction.SEND_GIFT, v.village_id, {"amount": 20}))
		_action_btn(action_box, "Threaten",
					func(): _dipl_act(Constants.DiplomacyAction.THREATEN, v.village_id))

		if not has_trade and not at_war:
			_action_btn(action_box, "Propose Trade (20 Wood -> 15 Gold/turn)",
						func(): _dipl_act(Constants.DiplomacyAction.PROPOSE_TRADE, v.village_id,
							{"resource_give": Constants.ResourceType.WOOD, "amount_give": 20,
							 "resource_receive": Constants.ResourceType.GOLD, "amount_receive": 15}))
		if has_trade:
			_action_btn(action_box, "Cancel Trade Route",
						func(): _dipl_act(Constants.DiplomacyAction.CANCEL_TRADE, v.village_id),
						C_DANGER, C_DANGER_HOV)

	for v in GameManager.get_alive_villages():
		if v.is_player:
			continue
		var sc := player.get_relation_state(v.village_id)
		var state_col := _rel_color(sc)
		var btn := Button.new()
		var rel := player.get_relationship(v.village_id)
		btn.text = "[%s]  %s  (%+d)" % [_rel_name(sc), v.village_name, rel]
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		var dc := state_col.darkened(0.75)
		dc.a = 1.0
		var dh := state_col.darkened(0.60)
		dh.a = 1.0
		_style(btn, dc, dh)
		btn.add_theme_color_override("font_color", state_col)
		var cv: Village = v
		btn.pressed.connect(func(): select_fn.call(cv))
		left.add_child(btn)
		if v.village_id == preselect:
			select_fn.call(v)

	return root

# ---------- Trade panel ----------

func _make_trade_panel() -> Control:
	var root := _panel_base("Active Trade Routes")
	var vbox: VBoxContainer = root.get_child(0)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(scroll)

	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 8)
	scroll.add_child(list)

	var player := GameManager.player_village
	if player.trade_routes.is_empty():
		var lbl := _lbl(
			"No active trade routes.\n\nOpen Diplomacy and propose a trade to a friendly village.\nTrade routes earn resources every turn automatically.",
			13, Color(0.65, 0.65, 0.75))
		lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		list.add_child(lbl)
	else:
		for vid in player.trade_routes:
			var route := player.trade_routes[vid]
			var partner := GameManager.get_village_by_id(vid)
			if partner == null:
				continue
			var row := HBoxContainer.new()
			row.add_theme_constant_override("separation", 10)
			var lbl := _lbl("-> %s:  Give %d %s / Receive %d %s per turn" % [
				partner.village_name,
				route["amount_give"],    Constants.RESOURCE_NAMES[route["resource_give"]],
				route["amount_receive"], Constants.RESOURCE_NAMES[route["resource_receive"]]
			], 13)
			lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			row.add_child(lbl)
			var cb := Button.new()
			cb.text = "Cancel"
			_style(cb, C_DANGER, C_DANGER_HOV)
			var vc: int = vid
			cb.pressed.connect(func():
				GameManager.diplomacy_manager.player_action(Constants.DiplomacyAction.CANCEL_TRADE, vc)
				_show_panel(_make_trade_panel())
			)
			row.add_child(cb)
			list.add_child(row)

	return root

# ---------- Save panel ----------

func _make_save_panel() -> Control:
	var root := _panel_base("Save / Load Game")
	var vbox: VBoxContainer = root.get_child(0)

	var list := VBoxContainer.new()
	list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 14)
	vbox.add_child(list)

	for slot in range(1, SaveManager.SAVE_SLOTS + 1):
		var info := SaveManager.get_save_info(slot)
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 14)

		var slot_text: String
		if info.get("exists"):
			slot_text = "Turn %d,  Year %d" % [info["turn"], info["year"]]
		else:
			slot_text = "Empty"
		var lbl_col: Color = Color(0.75, 0.80, 0.90) if info.get("exists") else Color(0.45, 0.45, 0.55)
		var lbl := _lbl("Slot %d  --  %s" % [slot, slot_text], 13, lbl_col)
		lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(lbl)

		var sc := slot
		var sb := Button.new()
		sb.text = "Save"
		_style(sb, Color(0.15, 0.28, 0.15), Color(0.22, 0.42, 0.22))
		sb.pressed.connect(func():
			SaveManager.save_game(sc)
			_show_panel(_make_save_panel())
		)
		row.add_child(sb)

		var lb := Button.new()
		lb.text = "Load"
		lb.disabled = not info.get("exists", false)
		_style(lb, Color(0.15, 0.22, 0.35), Color(0.20, 0.32, 0.50))
		lb.pressed.connect(func():
			SaveManager.load_game(sc)
			_close_panel()
			_refresh_top_bar()
		)
		row.add_child(lb)
		list.add_child(row)

	return root

# ---------- End Turn ----------

func _end_turn() -> void:
	_close_panel()
	GameManager.end_turn()
	_refresh_top_bar()
	_update_turn_labels()

# ---------- Diplomacy helpers ----------

func _do_attack(target_id: int) -> void:
	var result := GameManager.battle_manager.player_attack(target_id)
	if result.is_empty():
		return
	var won := result.get("outcome") in [Constants.BattleOutcome.ATTACKER_WINS,
										  Constants.BattleOutcome.ATTACKER_CAPTURES]
	_post("[color=%s]%s[/color]" % [
		"#44ff88" if won else "#ff5555",
		result.get("description", "Battle resolved.")])
	_close_panel()

func _dipl_act(action: int, target_id: int, extra: Dictionary = {}) -> void:
	var resp := GameManager.diplomacy_manager.player_action(action, target_id, extra)
	_post("[color=%s]%s[/color]" % [
		"#44ff88" if resp.get("success") else "#ffaa44",
		resp.get("message", "")])
	_show_panel(_make_diplomacy_panel(target_id))

# ---------- Top bar refresh ----------

func _refresh_top_bar() -> void:
	var v := GameManager.player_village
	if v == null or _top_bar == null:
		return
	var labels := [
		"Lv.%d %s"   % [v.village_level, v.village_name],
		"Food:%d"     % v.get_resource(Constants.ResourceType.FOOD),
		"Wood:%d"     % v.get_resource(Constants.ResourceType.WOOD),
		"Stone:%d"    % v.get_resource(Constants.ResourceType.STONE),
		"Gold:%d"     % v.get_resource(Constants.ResourceType.GOLD),
		"Weapons:%d"  % v.get_resource(Constants.ResourceType.WEAPONS),
		"Pop:%d/%d"   % [v.population, v.max_population],
		"Soldiers:%d" % v.soldiers,
		"Morale:%d"   % v.morale,
	]
	var children := _top_bar.get_children()
	for i in range(min(labels.size(), children.size())):
		if children[i] is Label:
			children[i].text = labels[i]

func _update_turn_labels() -> void:
	if _turn_label:
		_turn_label.text = "Turn %d/%d" % [GameManager.current_turn, Constants.MAX_TURNS]
	if _year_label:
		_year_label.text = "Year %d" % GameManager.current_year

# ---------- Log ----------

func _post(msg: String) -> void:
	_log_entries.append(msg)
	if _log_entries.size() > MAX_LOG:
		_log_entries.pop_front()
	if _log_label:
		_log_label.text = "\n".join(_log_entries)
		_log_label.scroll_to_line(_log_label.get_line_count())

# ---------- EventBus ----------

func _connect_bus() -> void:
	EventBus.notification_posted.connect(func(msg: String, sev: String):
		_post("[color=%s]%s[/color]" % [_sev_col(sev), msg]))
	EventBus.turn_started.connect(func(_t): _refresh_top_bar(); _update_turn_labels())
	EventBus.player_village_updated.connect(func(): _refresh_top_bar(); _update_turn_labels())
	EventBus.year_changed.connect(func(_y): _update_turn_labels())
	EventBus.battle_resolved.connect(func(r: Dictionary):
		if GameManager.player_village == null:
			return
		var pid := GameManager.player_village.village_id
		if r.get("attacker_id") == pid or r.get("defender_id") == pid:
			_show_battle_popup(r))
	EventBus.world_event_triggered.connect(func(e: Dictionary):
		if GameManager.player_village and e.get("village_id") == GameManager.player_village.village_id:
			_show_event_popup(e))
	EventBus.game_over.connect(func(reason: String, won: bool):
		_show_game_over(reason, won))

# ---------- Popups ----------

func _show_battle_popup(result: Dictionary) -> void:
	var panel := _panel_base("Battle Result")
	var vbox: VBoxContainer = panel.get_child(0)
	var pid := GameManager.player_village.village_id
	var won := (result.get("attacker_id") == pid
			and result.get("outcome") in [Constants.BattleOutcome.ATTACKER_WINS,
										   Constants.BattleOutcome.ATTACKER_CAPTURES])
	var col := "#44ff88" if won else "#ff5555"
	var txt := "[b][color=%s]%s[/color][/b]\n\n%s\n\nAttacker lost: [b]%d[/b] soldiers\nDefender lost: [b]%d[/b] soldiers" % [
		col, "VICTORY!" if won else "DEFEAT",
		result.get("description", ""),
		result.get("attacker_soldiers_lost", 0),
		result.get("defender_soldiers_lost", 0)
	]
	var loot := result.get("resources_looted", {})
	if not loot.is_empty():
		txt += "\n\n[color=#ffdd88]Looted:[/color]"
		for res in loot:
			txt += "\n  %d %s" % [loot[res], Constants.RESOURCE_NAMES[res]]
	var rl := RichTextLabel.new()
	rl.bbcode_enabled = true
	rl.custom_minimum_size = Vector2(0, 180)
	rl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rl.text = txt
	vbox.add_child(rl)
	_show_panel(panel)

func _show_event_popup(event: Dictionary) -> void:
	var panel := _panel_base(event.get("name", "Event"))
	var vbox: VBoxContainer = panel.get_child(0)
	var lbl := _lbl(event.get("description", ""), 14, Color(0.9, 0.9, 1.0))
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(lbl)
	_show_panel(panel)

func _show_game_over(reason: String, won: bool) -> void:
	var panel := _panel_base("VICTORY!" if won else "DEFEATED")
	var vbox: VBoxContainer = panel.get_child(0)
	var col := Color(0.3, 1.0, 0.5) if won else Color(1.0, 0.35, 0.35)
	var header := _lbl(reason, 16, col)
	header.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(header)
	var v := GameManager.player_village
	if v:
		vbox.add_child(_lbl(
			"\nTurns: %d   |   Wins: %d   |   Losses: %d" % [
				v.turn_number, v.total_battles_won, v.total_battles_lost],
			13, Color(0.7, 0.7, 0.9)))
	_action_btn(vbox, "New Game", func():
		_close_panel()
		for vi in GameManager.all_villages:
			vi.queue_free()
		GameManager.all_villages.clear()
		GameManager.player_village = null
		GameManager.new_game()
		_refresh_top_bar()
	, Color(0.15, 0.35, 0.15), Color(0.22, 0.52, 0.22))
	_show_panel(panel)

# ---------- Keyboard shortcuts ----------

func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey) or not event.pressed or event.echo:
		return
	var key := (event as InputEventKey).keycode
	match key:
		KEY_B:                   _show_panel(_make_building_panel())
		KEY_D:                   _show_panel(_make_diplomacy_panel())
		KEY_T:                   _show_panel(_make_trade_panel())
		KEY_ESCAPE:              _close_panel()
		KEY_ENTER, KEY_KP_ENTER: _end_turn()
		KEY_F5:                  SaveManager.save_game(1)
		KEY_F9:                  SaveManager.load_game(1)
		_: return
	get_viewport().set_input_as_handled()

# ---------- Utility ----------

func _fmt_cost(cost: Dictionary) -> String:
	var p := []
	for r in cost:
		p.append("%d %s" % [cost[r], Constants.RESOURCE_NAMES[r]])
	return ", ".join(p)

func _rel_name(state: int) -> String:
	match state:
		Constants.RelationState.WAR:      return "WAR"
		Constants.RelationState.HOSTILE:  return "Hostile"
		Constants.RelationState.FRIENDLY: return "Friendly"
		Constants.RelationState.ALLIED:   return "ALLIED"
		_:                                return "Neutral"

func _rel_color(state: int) -> Color:
	match state:
		Constants.RelationState.WAR:      return Color(1.0, 0.30, 0.30)
		Constants.RelationState.HOSTILE:  return Color(1.0, 0.60, 0.20)
		Constants.RelationState.FRIENDLY: return Color(0.40, 0.90, 0.50)
		Constants.RelationState.ALLIED:   return Color(0.20, 1.00, 0.45)
		_:                                return Color(0.75, 0.75, 0.85)

func _sev_col(sev: String) -> String:
	match sev:
		"danger":  return "#ff5555"
		"warning": return "#ffaa44"
		"success": return "#44ff88"
		_:         return "#aaddff"
