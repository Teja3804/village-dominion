## GameUI.gd
## Entire game UI built 100% in code — no scene structure needed.

extends CanvasLayer

# ── Refs ──────────────────────────────────────────────────────────────
var _map_view: Control
var _top_bar: Control
var _log_label: RichTextLabel
var _turn_label: Label
var _year_label: Label

var _panel_root: Control      # parent for all overlay panels
var _active_panel: Control = null

var _log_entries: Array = []
const MAX_LOG: int = 60

# ── Boot ──────────────────────────────────────────────────────────────
func _ready() -> void:
	layer = 0
	_build_top_bar()
	_build_map()
	_build_log()
	_build_nav_bar()
	_build_panel_root()
	_connect_bus()

# ══════════════════════════════════════════════════════════════════════
# Layout helpers
# ══════════════════════════════════════════════════════════════════════
func _ctrl(type: GDScript = null) -> Control:
	var c: Control = Control.new() if type == null else type.new()
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return c

func _fullrect(c: Control) -> Control:
	c.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	return c

# ══════════════════════════════════════════════════════════════════════
# Top bar
# ══════════════════════════════════════════════════════════════════════
func _build_top_bar() -> void:
	var bar = PanelContainer.new()
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	bar.offset_bottom = 52.0
	add_child(bar)

	var hbox = HBoxContainer.new()
	hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hbox.add_theme_constant_override("separation", 20)
	bar.add_child(hbox)

	_top_bar = hbox
	_turn_label  = _lbl("Turn 0/120")
	_year_label  = _lbl("Year 1")

	for text in ["Lv.1 Village", "Food:200", "Wood:150", "Stone:100",
				 "Gold:50", "Weapons:20", "Pop:10/10", "Soldiers:5", "Morale:70"]:
		hbox.add_child(_lbl(text))

	# push turn/year to right
	var spacer = Control.new()
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(spacer)
	hbox.add_child(_turn_label)
	hbox.add_child(_year_label)

func _lbl(text: String, font_size: int = 13) -> Label:
	var l = Label.new()
	l.text = text
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.add_theme_font_size_override("font_size", font_size)
	return l

# ══════════════════════════════════════════════════════════════════════
# World map
# ══════════════════════════════════════════════════════════════════════
func _build_map() -> void:
	var map = load("res://scripts/ui/WorldMapView.gd").new()
	map.name = "WorldMap"
	map.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	map.offset_top = 52.0
	map.offset_bottom = -130.0
	map.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(map)
	_map_view = map

# ══════════════════════════════════════════════════════════════════════
# Log
# ══════════════════════════════════════════════════════════════════════
func _build_log() -> void:
	var log_bg = PanelContainer.new()
	log_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	log_bg.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	log_bg.offset_top = -180.0
	log_bg.offset_right = 560.0
	log_bg.offset_bottom = -130.0
	add_child(log_bg)

	var rtl = RichTextLabel.new()
	rtl.bbcode_enabled = true
	rtl.scroll_following = true
	rtl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rtl.add_theme_font_size_override("normal_font_size", 12)
	log_bg.add_child(rtl)
	_log_label = rtl

# ══════════════════════════════════════════════════════════════════════
# Nav bar
# ══════════════════════════════════════════════════════════════════════
func _build_nav_bar() -> void:
	var bar = HBoxContainer.new()
	bar.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	bar.offset_top = -125.0
	bar.offset_bottom = -80.0
	bar.offset_left = 20.0
	bar.offset_right = -20.0
	bar.alignment = BoxContainer.ALIGNMENT_CENTER
	bar.add_theme_constant_override("separation", 12)
	add_child(bar)

	_nav_btn(bar, "🏗 Build [B]",        func(): _show_panel(_make_building_panel()))
	_nav_btn(bar, "⚔ Diplomacy [D]",    func(): _show_panel(_make_diplomacy_panel()))
	_nav_btn(bar, "🛒 Trade [T]",        func(): _show_panel(_make_trade_panel()))
	_nav_btn(bar, "💾 Save/Load",        func(): _show_panel(_make_save_panel()))
	_nav_btn(bar, "⏭ End Turn [Enter]", func(): _end_turn(), Color(0.2, 0.6, 0.2))

func _nav_btn(parent: Control, text: String, cb: Callable, col: Color = Color(0.25, 0.25, 0.35)) -> void:
	var btn = Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(160, 44)
	btn.pressed.connect(cb)
	btn.add_theme_color_override("font_color", Color.WHITE)
	parent.add_child(btn)

# ══════════════════════════════════════════════════════════════════════
# Panel root (overlay container)
# ══════════════════════════════════════════════════════════════════════
func _build_panel_root() -> void:
	_panel_root = Control.new()
	_panel_root.name = "PanelRoot"
	_panel_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_panel_root.offset_top = 52.0
	_panel_root.offset_bottom = -130.0
	_panel_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
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

# ══════════════════════════════════════════════════════════════════════
# BUILDING PANEL
# ══════════════════════════════════════════════════════════════════════
func _make_building_panel() -> Control:
	var root = _panel_base("🏗 Buildings — %s" % GameManager.player_village.village_name)
	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.get_child(0).add_child(scroll)    # vbox

	var list = VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(list)

	var v = GameManager.player_village
	var db = GameManager.building_db

	for btype in Constants.BuildingType.values():
		var def = db.get_definition(btype)
		if def == null:
			continue

		var row = HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		list.add_child(row)

		var nm = Label.new()
		nm.text = Constants.BUILDING_NAMES[btype]
		nm.custom_minimum_size = Vector2(130, 0)
		nm.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(nm)

		var count = v.count_buildings_of_type(btype)
		var level = v.get_building_level(btype)
		var st = Label.new()
		st.text = ("Lv.%d (%d)" % [level, count]) if count > 0 else "—"
		st.custom_minimum_size = Vector2(80, 0)
		st.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(st)

		if count < def.max_count:
			var cost = def.get_cost_for_level(1)
			var bb = Button.new()
			bb.text = "Build (%s)" % _fmt_cost(cost)
			bb.disabled = not v.can_afford(cost)
			bb.pressed.connect(func():
				if v.construct_building(btype):
					_post("[color=#44ff88]Built %s![/color]" % Constants.BUILDING_NAMES[btype])
					_refresh_top_bar()
					_show_panel(_make_building_panel())
				else:
					_post("[color=#ff4444]Cannot build — check resources/prerequisites.[/color]")
			)
			row.add_child(bb)

		if count > 0 and level < def.max_level:
			var cost = def.get_cost_for_level(level + 1)
			var ub = Button.new()
			ub.text = "Upgrade (%s)" % _fmt_cost(cost)
			ub.disabled = not v.can_afford(cost)
			ub.pressed.connect(func():
				if v.upgrade_building(btype):
					_post("[color=#44ff88]Upgraded %s![/color]" % Constants.BUILDING_NAMES[btype])
					_refresh_top_bar()
					_show_panel(_make_building_panel())
				else:
					_post("[color=#ff4444]Cannot upgrade — not enough resources.[/color]")
			)
			row.add_child(ub)

		# Train soldiers button on Barracks
		if btype == Constants.BuildingType.BARRACKS and count > 0:
			var tb = Button.new()
			tb.text = "Train 3 (30g, 6w)"
			tb.pressed.connect(func():
				if v.train_soldiers(3):
					_post("[color=#44ff88]Trained 3 soldiers.[/color]")
					_refresh_top_bar()
				else:
					_post("[color=#ff4444]Cannot train — not enough gold/weapons or population.[/color]")
			)
			row.add_child(tb)

		var desc = Label.new()
		desc.text = def.description
		desc.add_theme_color_override("font_color", Color(0.65, 0.65, 0.75))
		desc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		desc.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(desc)

	return root

# ══════════════════════════════════════════════════════════════════════
# DIPLOMACY PANEL
# ══════════════════════════════════════════════════════════════════════
func _make_diplomacy_panel(preselect: int = -1) -> Control:
	var root = _panel_base("⚔ Diplomacy")
	var hbox = HBoxContainer.new()
	hbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.get_child(0).add_child(hbox)

	# Left: village list
	var left = VBoxContainer.new()
	left.custom_minimum_size = Vector2(280, 0)
	hbox.add_child(left)

	# Right: detail
	var right = VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(right)

	var player = GameManager.player_village
	var detail_name = _lbl("Select a village", 15)
	var detail_info = Label.new()
	detail_info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail_info.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var action_box = VBoxContainer.new()

	right.add_child(detail_name)
	right.add_child(detail_info)
	right.add_child(action_box)

	var select_fn = func(v: Village):
		detail_name.text = v.village_name + " (Lv.%d)" % v.village_level
		var rel = player.get_relationship(v.village_id)
		var pname = Constants.PERSONALITY_NAMES[(v as AIVillage).personality] if v is AIVillage else "Player"
		detail_info.text = "Leader: %s\nPersonality: %s\nRelation: %+d (%s)\nPop: %d | Soldiers: %d\nAtk: %d | Def: %d" % [
			v.leader_name, pname, rel, _rel_name(player.get_relation_state(v.village_id)),
			v.population, v.soldiers, v.get_attack_power(), v.get_defense_power()
		]
		# Clear old actions
		for c in action_box.get_children(): c.queue_free()
		# Add action buttons
		var at_war = player.is_at_war_with(v.village_id)
		var allied = player.is_allied_with(v.village_id)
		var has_trade = player.trade_routes.has(v.village_id)
		if at_war:
			_action_btn(action_box, "🕊 Propose Peace",    func(): _dipl_act(Constants.DiplomacyAction.PROPOSE_PEACE, v.village_id))
			_action_btn(action_box, "⚔ ATTACK!",           func(): _do_attack(v.village_id), Color(0.7,0.1,0.1))
		else:
			_action_btn(action_box, "⚔ Declare War",       func(): _dipl_act(Constants.DiplomacyAction.DECLARE_WAR, v.village_id), Color(0.6,0.1,0.1))
		if not allied and not at_war and player.get_relationship(v.village_id) >= -10:
			_action_btn(action_box, "🤝 Propose Alliance", func(): _dipl_act(Constants.DiplomacyAction.PROPOSE_ALLIANCE, v.village_id))
		if allied:
			_action_btn(action_box, "💔 Break Alliance",   func(): _dipl_act(Constants.DiplomacyAction.BREAK_ALLIANCE, v.village_id))
			_action_btn(action_box, "📦 Request Aid",      func(): _dipl_act(Constants.DiplomacyAction.REQUEST_AID, v.village_id))
		_action_btn(action_box, "🎁 Send Gift (20g)",      func(): _dipl_act(Constants.DiplomacyAction.SEND_GIFT, v.village_id, {"amount":20}))
		_action_btn(action_box, "😠 Threaten",             func(): _dipl_act(Constants.DiplomacyAction.THREATEN, v.village_id))
		if not has_trade and not at_war:
			_action_btn(action_box, "📜 Propose Trade",    func(): _dipl_act(Constants.DiplomacyAction.PROPOSE_TRADE, v.village_id, {"resource_give":Constants.ResourceType.WOOD,"amount_give":20,"resource_receive":Constants.ResourceType.GOLD,"amount_receive":15}))
		if has_trade:
			_action_btn(action_box, "❌ Cancel Trade",     func(): _dipl_act(Constants.DiplomacyAction.CANCEL_TRADE, v.village_id))

	for v in GameManager.get_alive_villages():
		if v.is_player: continue
		var rel = player.get_relationship(v.village_id)
		var state_col = _rel_color(player.get_relation_state(v.village_id))
		var btn = Button.new()
		btn.text = "[%s] %s (%+d)" % [_rel_name(player.get_relation_state(v.village_id)), v.village_name, rel]
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.add_theme_color_override("font_color", state_col)
		var captured_v = v
		btn.pressed.connect(func(): select_fn.call(captured_v))
		left.add_child(btn)
		if v.village_id == preselect:
			select_fn.call(v)

	return root

# ══════════════════════════════════════════════════════════════════════
# TRADE PANEL
# ══════════════════════════════════════════════════════════════════════
func _make_trade_panel() -> Control:
	var root = _panel_base("🛒 Active Trade Routes")
	var list = VBoxContainer.new()
	list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.get_child(0).add_child(list)

	var player = GameManager.player_village
	if player.trade_routes.is_empty():
		var lbl = _lbl("No active trade routes.\nOpen Diplomacy and propose a trade to a friendly village.")
		lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		list.add_child(lbl)
	else:
		for vid in player.trade_routes:
			var route = player.trade_routes[vid]
			var partner = GameManager.get_village_by_id(vid)
			if partner == null: continue
			var row = HBoxContainer.new()
			var lbl = _lbl("→ %s: Give %d %s / Receive %d %s" % [
				partner.village_name,
				route["amount_give"], Constants.RESOURCE_NAMES[route["resource_give"]],
				route["amount_receive"], Constants.RESOURCE_NAMES[route["resource_receive"]]
			])
			lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			row.add_child(lbl)
			var cb = Button.new()
			cb.text = "Cancel"
			var vid_cap = vid
			cb.pressed.connect(func():
				GameManager.diplomacy_manager.player_action(Constants.DiplomacyAction.CANCEL_TRADE, vid_cap)
				_show_panel(_make_trade_panel())
			)
			row.add_child(cb)
			list.add_child(row)
	return root

# ══════════════════════════════════════════════════════════════════════
# SAVE PANEL
# ══════════════════════════════════════════════════════════════════════
func _make_save_panel() -> Control:
	var root = _panel_base("💾 Save / Load Game")
	var list = VBoxContainer.new()
	list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.get_child(0).add_child(list)

	for slot in range(1, SaveManager.SAVE_SLOTS + 1):
		var info = SaveManager.get_save_info(slot)
		var row = HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)
		var lbl = _lbl("Slot %d — %s" % [slot, ("Turn %d, Year %d" % [info["turn"], info["year"]]) if info.get("exists") else "Empty"])
		lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(lbl)
		var sb = Button.new()
		sb.text = "Save"
		var sc = slot
		sb.pressed.connect(func():
			SaveManager.save_game(sc)
			_show_panel(_make_save_panel())
		)
		row.add_child(sb)
		var lb = Button.new()
		lb.text = "Load"
		lb.disabled = not info.get("exists", false)
		lb.pressed.connect(func():
			SaveManager.load_game(sc)
			_close_panel()
			_refresh_top_bar()
		)
		row.add_child(lb)
		list.add_child(row)
	return root

# ══════════════════════════════════════════════════════════════════════
# Shared panel base: PanelContainer + VBoxContainer + title + close btn
# ══════════════════════════════════════════════════════════════════════
func _panel_base(title: String) -> Control:
	var panel = PanelContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var vbox = VBoxContainer.new()
	panel.add_child(vbox)

	var title_row = HBoxContainer.new()
	vbox.add_child(title_row)

	var tlabel = _lbl(title, 16)
	tlabel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_row.add_child(tlabel)

	var close = Button.new()
	close.text = "✕ Close"
	close.pressed.connect(_close_panel)
	title_row.add_child(close)

	return panel

func _action_btn(parent: Control, text: String, cb: Callable, col: Color = Color.WHITE) -> void:
	var btn = Button.new()
	btn.text = text
	btn.add_theme_color_override("font_color", col)
	btn.pressed.connect(cb)
	parent.add_child(btn)

# ══════════════════════════════════════════════════════════════════════
# End Turn
# ══════════════════════════════════════════════════════════════════════
func _end_turn() -> void:
	_close_panel()
	GameManager.end_turn()
	_refresh_top_bar()
	_update_turn_labels()

# ══════════════════════════════════════════════════════════════════════
# Diplomacy helper
# ══════════════════════════════════════════════════════════════════════
func _do_attack(target_id: int) -> void:
	var result = GameManager.battle_manager.player_attack(target_id)
	if result.is_empty(): return
	var msg = "[color=%s]%s[/color]" % [
		"#44ff88" if result.get("outcome") in [Constants.BattleOutcome.ATTACKER_WINS, Constants.BattleOutcome.ATTACKER_CAPTURES] else "#ff4444",
		result.get("description", "Battle resolved.")
	]
	_post(msg)
	_close_panel()

func _dipl_act(action: int, target_id: int, extra: Dictionary = {}) -> void:
	var resp = GameManager.diplomacy_manager.player_action(action, target_id, extra)
	var col = "#44ff88" if resp.get("success", false) else "#ffaa00"
	_post("[color=%s]%s[/color]" % [col, resp.get("message", "")])
	_show_panel(_make_diplomacy_panel(target_id))

# ══════════════════════════════════════════════════════════════════════
# Top bar refresh
# ══════════════════════════════════════════════════════════════════════
func _refresh_top_bar() -> void:
	var v = GameManager.player_village
	if v == null or _top_bar == null: return
	var labels = [
		"Lv.%d %s" % [v.village_level, v.village_name],
		"Food:%d" % v.get_resource(Constants.ResourceType.FOOD),
		"Wood:%d" % v.get_resource(Constants.ResourceType.WOOD),
		"Stone:%d" % v.get_resource(Constants.ResourceType.STONE),
		"Gold:%d" % v.get_resource(Constants.ResourceType.GOLD),
		"Weapons:%d" % v.get_resource(Constants.ResourceType.WEAPONS),
		"Pop:%d/%d" % [v.population, v.max_population],
		"Soldiers:%d" % v.soldiers,
		"Morale:%d" % v.morale
	]
	var children = _top_bar.get_children()
	for i in range(min(labels.size(), children.size())):
		if children[i] is Label:
			children[i].text = labels[i]

func _update_turn_labels() -> void:
	if _turn_label: _turn_label.text = "Turn %d/%d" % [GameManager.current_turn, Constants.MAX_TURNS]
	if _year_label:  _year_label.text  = "Year %d" % GameManager.current_year

# ══════════════════════════════════════════════════════════════════════
# Notification log
# ══════════════════════════════════════════════════════════════════════
func _post(msg: String) -> void:
	_log_entries.append(msg)
	if _log_entries.size() > MAX_LOG:
		_log_entries.pop_front()
	if _log_label:
		_log_label.text = "\n".join(_log_entries)
		_log_label.scroll_to_line(_log_label.get_line_count())

# ══════════════════════════════════════════════════════════════════════
# Event bus connections
# ══════════════════════════════════════════════════════════════════════
func _connect_bus() -> void:
	EventBus.notification_posted.connect(func(msg, sev): _post("[color=%s]%s[/color]" % [_sev_col(sev), msg]))
	EventBus.turn_started.connect(func(_t): _refresh_top_bar(); _update_turn_labels())
	EventBus.player_village_updated.connect(func(): _refresh_top_bar(); _update_turn_labels())
	EventBus.year_changed.connect(func(_y): _update_turn_labels())
	EventBus.battle_resolved.connect(func(r):
		var pid = GameManager.player_village.village_id
		if r.get("attacker_id") == pid or r.get("defender_id") == pid:
			_show_battle_popup(r)
	)
	EventBus.world_event_triggered.connect(func(e):
		if GameManager.player_village and e.get("village_id") == GameManager.player_village.village_id:
			_show_event_popup(e)
	)
	EventBus.game_over.connect(func(reason, won): _show_game_over(reason, won))

# ══════════════════════════════════════════════════════════════════════
# Popup helpers
# ══════════════════════════════════════════════════════════════════════
func _show_battle_popup(result: Dictionary) -> void:
	var panel = _panel_base("⚔ Battle Result")
	var vbox = panel.get_child(0)
	var rl = RichTextLabel.new()
	rl.bbcode_enabled = true
	rl.custom_minimum_size = Vector2(0, 200)
	rl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var pid = GameManager.player_village.village_id
	var won = result.get("attacker_id") == pid and result.get("outcome") in [Constants.BattleOutcome.ATTACKER_WINS, Constants.BattleOutcome.ATTACKER_CAPTURES]
	var col = "#44ff88" if won else "#ff4444"
	var text = "[b][color=%s]%s[/color][/b]\n\n%s\n\nAttacker lost: %d soldiers\nDefender lost: %d soldiers" % [
		col, "VICTORY!" if won else "DEFEAT",
		result.get("description", ""),
		result.get("attacker_soldiers_lost", 0),
		result.get("defender_soldiers_lost", 0)
	]
	var loot = result.get("resources_looted", {})
	if not loot.is_empty():
		text += "\n\n[color=#ffdd88]Looted:[/color]"
		for res in loot:
			text += "\n  %d %s" % [loot[res], Constants.RESOURCE_NAMES[res]]
	rl.text = text
	vbox.add_child(rl)
	_show_panel(panel)

func _show_event_popup(event: Dictionary) -> void:
	var panel = _panel_base("📢 " + event.get("name", "Event"))
	var vbox = panel.get_child(0)
	var lbl = Label.new()
	lbl.text = event.get("description", "")
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(lbl)
	_show_panel(panel)

func _show_game_over(reason: String, won: bool) -> void:
	var panel = _panel_base("🏆 " + ("VICTORY!" if won else "DEFEATED"))
	var vbox = panel.get_child(0)
	var lbl = Label.new()
	lbl.text = reason
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(lbl)
	var v = GameManager.player_village
	if v:
		var stats = Label.new()
		stats.mouse_filter = Control.MOUSE_FILTER_IGNORE
		stats.text = "\nTurns: %d | Wins: %d | Losses: %d | Gold earned: %d" % [v.turn_number, v.total_battles_won, v.total_battles_lost, v.total_gold_earned]
		vbox.add_child(stats)
	_action_btn(vbox, "New Game", func():
		_close_panel()
		for vi in GameManager.all_villages: vi.queue_free()
		GameManager.all_villages.clear()
		GameManager.player_village = null
		GameManager.new_game()
		_refresh_top_bar()
	)
	_show_panel(panel)

# ══════════════════════════════════════════════════════════════════════
# Keyboard shortcuts
# ══════════════════════════════════════════════════════════════════════
func _unhandled_key_input(event: InputEvent) -> void:
	if not event.pressed: return
	match (event as InputEventKey).keycode:
		KEY_B:      _show_panel(_make_building_panel())
		KEY_D:      _show_panel(_make_diplomacy_panel())
		KEY_T:      _show_panel(_make_trade_panel())
		KEY_ESCAPE: _close_panel()
		KEY_ENTER, KEY_KP_ENTER: _end_turn()
		KEY_F5:     SaveManager.save_game(1)
		KEY_F9:     SaveManager.load_game(1)

# ══════════════════════════════════════════════════════════════════════
# Utilities
# ══════════════════════════════════════════════════════════════════════
func _fmt_cost(cost: Dictionary) -> String:
	var p = []
	for r in cost:
		p.append("%d%s" % [cost[r], Constants.RESOURCE_NAMES[r][0]])
	return ",".join(p)

func _rel_name(state: int) -> String:
	match state:
		Constants.RelationState.WAR:      return "WAR"
		Constants.RelationState.HOSTILE:  return "Hostile"
		Constants.RelationState.FRIENDLY: return "Friendly"
		Constants.RelationState.ALLIED:   return "ALLIED"
		_:                                return "Neutral"

func _rel_color(state: int) -> Color:
	match state:
		Constants.RelationState.WAR:      return Color(1.0, 0.3, 0.3)
		Constants.RelationState.HOSTILE:  return Color(1.0, 0.6, 0.2)
		Constants.RelationState.FRIENDLY: return Color(0.4, 0.9, 0.5)
		Constants.RelationState.ALLIED:   return Color(0.2, 1.0, 0.4)
		_:                                return Color(0.8, 0.8, 0.8)

func _sev_col(sev: String) -> String:
	match sev:
		"danger":  return "#ff4444"
		"warning": return "#ffaa00"
		"success": return "#44ff88"
		_:         return "#aaddff"
