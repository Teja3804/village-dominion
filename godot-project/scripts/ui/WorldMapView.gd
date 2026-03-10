## WorldMapView.gd
## Draws the world map with villages, relationship lines, and animations.

extends Control

# Village positions on the map (fixed layout for 8 villages)
const VILLAGE_POSITIONS: Array = [
	Vector2(640, 340),   # 0 = Player (center)
	Vector2(250, 180),   # 1
	Vector2(500, 130),   # 2
	Vector2(800, 130),   # 3
	Vector2(1050, 200),  # 4
	Vector2(1080, 400),  # 5
	Vector2(850, 520),   # 6
	Vector2(380, 500),   # 7
]

const VILLAGE_RADIUS: float = 36.0
const PLAYER_RADIUS: float = 44.0

# Turn flash
var flash_alpha: float = 0.0
var flash_active: bool = false

# Village hover
var hovered_village_id: int = -1

# Pulse animation
var pulse_timer: float = 0.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	EventBus.turn_started.connect(_on_turn_started)
	EventBus.battle_resolved.connect(func(_r): queue_redraw())
	EventBus.relationship_changed.connect(func(_a, _b, _c): queue_redraw())
	EventBus.alliance_formed.connect(func(_a, _b): queue_redraw())
	EventBus.war_declared.connect(func(_a, _b): queue_redraw())
	EventBus.player_village_updated.connect(func(): queue_redraw())

func _process(delta: float) -> void:
	pulse_timer += delta * 2.0

	# Flash decay
	if flash_active:
		flash_alpha -= delta * 2.5
		if flash_alpha <= 0.0:
			flash_alpha = 0.0
			flash_active = false
		queue_redraw()
	else:
		# Gentle pulse redraws
		var prev = int(pulse_timer - delta * 2.0)
		var curr = int(pulse_timer)
		if prev != curr:
			queue_redraw()

func _on_turn_started(_turn: int) -> void:
	flash_alpha = 0.6
	flash_active = true
	queue_redraw()

func _draw() -> void:
	if not GameManager.game_running:
		return

	var all_villages = GameManager.get_alive_villages()
	var player = GameManager.player_village
	if player == null:
		return

	# Draw background grid
	_draw_grid()

	# Draw relationship lines first (behind villages)
	_draw_relationship_lines(all_villages, player)

	# Draw each village
	for v in all_villages:
		var pos = _get_village_pos(v.village_id)
		_draw_village(v, pos, player)

	# Draw turn flash overlay
	if flash_alpha > 0.0:
		draw_rect(Rect2(Vector2.ZERO, size), Color(1, 1, 0.5, flash_alpha * 0.15))

func _draw_grid() -> void:
	# Subtle dot grid background
	var col = Color(0.3, 0.3, 0.35, 0.3)
	var step = 60
	for x in range(0, int(size.x), step):
		for y in range(0, int(size.y), step):
			draw_circle(Vector2(x, y), 1.5, col)

func _draw_relationship_lines(all_villages: Array, player: Village) -> void:
	for v in all_villages:
		if v.is_player:
			continue
		var pos_a = _get_village_pos(player.village_id)
		var pos_b = _get_village_pos(v.village_id)
		var rel = player.get_relationship(v.village_id)
		var state = player.get_relation_state(v.village_id)

		var line_color: Color
		var line_width: float = 1.5
		match state:
			Constants.RelationState.ALLIED:
				line_color = Color(0.2, 0.9, 0.3, 0.7)
				line_width = 3.0
			Constants.RelationState.WAR:
				line_color = Color(1.0, 0.15, 0.15, 0.7)
				line_width = 3.0
			Constants.RelationState.FRIENDLY:
				line_color = Color(0.4, 0.8, 1.0, 0.5)
			Constants.RelationState.HOSTILE:
				line_color = Color(1.0, 0.5, 0.1, 0.4)
			_:
				line_color = Color(0.5, 0.5, 0.5, 0.2)

		draw_line(pos_a, pos_b, line_color, line_width)

		# Draw relationship score midpoint label
		var mid = (pos_a + pos_b) * 0.5
		var score_text = "%+d" % rel
		var score_color = Color(0.2, 1.0, 0.4) if rel >= 0 else Color(1.0, 0.3, 0.3)
		draw_string(ThemeDB.fallback_font, mid + Vector2(-12, 4), score_text, HORIZONTAL_ALIGNMENT_CENTER, -1, 11, score_color)

func _draw_village(v: Village, pos: Vector2, player: Village) -> void:
	var is_player = v.is_player
	var radius = PLAYER_RADIUS if is_player else VILLAGE_RADIUS

	# Pulse effect for player village
	if is_player:
		var pulse = sin(pulse_timer) * 4.0
		draw_circle(pos, radius + pulse + 6, Color(0.3, 0.6, 1.0, 0.2))

	# Outer glow ring based on relation
	var glow_color = _relation_color(v, player)
	draw_circle(pos, radius + 5, Color(glow_color.r, glow_color.g, glow_color.b, 0.35))

	# Main circle fill
	draw_circle(pos, radius, glow_color)

	# Inner circle (lighter)
	var inner = Color(glow_color.r + 0.2, glow_color.g + 0.2, glow_color.b + 0.2, 1.0).clamp()
	draw_circle(pos, radius * 0.65, inner)

	# Village level indicator ring
	for i in range(v.village_level):
		var angle = (TAU / 5.0) * i - PI / 2.0
		var dot_pos = pos + Vector2(cos(angle), sin(angle)) * (radius + 12)
		draw_circle(dot_pos, 4, Color(1.0, 0.9, 0.3))

	# War X mark
	if not is_player and player.is_at_war_with(v.village_id):
		var s = radius * 0.5
		draw_line(pos + Vector2(-s, -s), pos + Vector2(s, s), Color(1, 0.1, 0.1), 3.0)
		draw_line(pos + Vector2(s, -s), pos + Vector2(-s, s), Color(1, 0.1, 0.1), 3.0)

	# Allied star
	if not is_player and player.is_allied_with(v.village_id):
		draw_string(ThemeDB.fallback_font, pos + Vector2(-6, -radius - 14), "★", HORIZONTAL_ALIGNMENT_CENTER, -1, 18, Color(0.2, 1.0, 0.4))

	# Village name
	var font = ThemeDB.fallback_font
	var name_pos = pos + Vector2(0, radius + 18)
	# Shadow
	draw_string(font, name_pos + Vector2(1, 1), v.village_name, HORIZONTAL_ALIGNMENT_CENTER, -1, 13, Color(0, 0, 0, 0.7))
	draw_string(font, name_pos, v.village_name, HORIZONTAL_ALIGNMENT_CENTER, -1, 13, Color(1, 1, 1))

	# Personality label for AI
	if not is_player and v is AIVillage:
		var pname = Constants.PERSONALITY_NAMES[v.personality]
		draw_string(font, pos + Vector2(0, radius + 34), pname, HORIZONTAL_ALIGNMENT_CENTER, -1, 11, Color(0.7, 0.7, 0.9))

	# Soldier count
	var mil_text = "⚔ %d" % v.soldiers
	draw_string(font, pos + Vector2(0, 5), mil_text, HORIZONTAL_ALIGNMENT_CENTER, -1, 12, Color(1, 1, 1))

	# Hover highlight
	if hovered_village_id == v.village_id:
		draw_arc(pos, radius + 8, 0, TAU, 32, Color(1, 1, 0.5, 0.8), 2.5)
		# Show stats tooltip
		_draw_tooltip(v, pos, player)

func _draw_tooltip(v: Village, pos: Vector2, player: Village) -> void:
	var font = ThemeDB.fallback_font
	var lines = [
		v.village_name + " (Lv.%d)" % v.village_level,
		"Pop: %d  Soldiers: %d" % [v.population, v.soldiers],
		"Morale: %d" % v.morale,
	]
	if not v.is_player:
		lines.append("Relation: %+d" % player.get_relationship(v.village_id))

	var box_w = 180.0
	var box_h = lines.size() * 18.0 + 12.0
	var tp = pos + Vector2(VILLAGE_RADIUS + 10, -box_h / 2.0)
	tp.x = clamp(tp.x, 4, size.x - box_w - 4)
	tp.y = clamp(tp.y, 4, size.y - box_h - 4)

	draw_rect(Rect2(tp, Vector2(box_w, box_h)), Color(0.1, 0.1, 0.15, 0.92))
	draw_rect(Rect2(tp, Vector2(box_w, box_h)), Color(0.6, 0.6, 0.8, 0.5), false, 1.5)

	for i in range(lines.size()):
		draw_string(font, tp + Vector2(8, 16 + i * 18), lines[i], HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(1, 1, 1))

func _relation_color(v: Village, player: Village) -> Color:
	if v.is_player:
		return Color(0.2, 0.5, 1.0)
	match player.get_relation_state(v.village_id):
		Constants.RelationState.ALLIED:  return Color(0.15, 0.75, 0.25)
		Constants.RelationState.FRIENDLY: return Color(0.3, 0.65, 0.5)
		Constants.RelationState.WAR:     return Color(0.85, 0.15, 0.15)
		Constants.RelationState.HOSTILE: return Color(0.8, 0.4, 0.1)
		_:                               return Color(0.45, 0.45, 0.5)

func _get_village_pos(vid: int) -> Vector2:
	if vid < VILLAGE_POSITIONS.size():
		return VILLAGE_POSITIONS[vid]
	# Fallback: evenly spaced around a circle
	var angle = (TAU / 8.0) * vid
	return Vector2(640, 340) + Vector2(cos(angle), sin(angle)) * 280.0

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		# Convert global mouse pos to local coords
		var local_pos = get_global_transform().affine_inverse() * event.position
		var vid = _village_at(local_pos)
		if vid >= 0 and GameManager.player_village and vid != GameManager.player_village.village_id:
			EventBus.panel_open_requested.emit("diplomacy", {"selected_id": vid})
	elif event is InputEventMouseMotion:
		var local_pos = get_global_transform().affine_inverse() * event.position
		var vid = _village_at(local_pos)
		if vid != hovered_village_id:
			hovered_village_id = vid
			queue_redraw()

func _village_at(mouse_pos: Vector2) -> int:
	if not GameManager.game_running:
		return -1
	for v in GameManager.get_alive_villages():
		var pos = _get_village_pos(v.village_id)
		var r = PLAYER_RADIUS if v.is_player else VILLAGE_RADIUS
		if mouse_pos.distance_to(pos) <= r + 8:
			return v.village_id
	return -1
