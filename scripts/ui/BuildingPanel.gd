extends Control

## Building construction panel. Lists buildable buildings with cost, effect, and Build button.
## Refreshes on resources_changed and buildings_changed. Shows error when build fails (e.g. insufficient resources).

@onready var title_label: Label = $MarginContainer/VBox/TitleRow/TitleLabel
@onready var close_button: Button = $MarginContainer/VBox/TitleRow/CloseButton
@onready var error_label: Label = $MarginContainer/VBox/ErrorLabel
@onready var building_list: VBoxContainer = $MarginContainer/VBox/ScrollContainer/BuildingList

var _building_rows: Dictionary = {}  # building_type_id -> { panel, build_button, owned_label }


func _ready() -> void:
	if EventBus:
		EventBus.resources_changed.connect(_refresh)
		EventBus.buildings_changed.connect(_refresh)
	if close_button:
		close_button.pressed.connect(_on_close_pressed)
	_build_ui()
	_refresh()


func _build_ui() -> void:
	if not GameManager:
		return
	var db: BuildingDatabase = GameManager.get_building_database()
	if db == null:
		return
	for type_id in db.get_buildable_type_ids():
		_add_building_row(type_id, db.get_definition(type_id))


func _add_building_row(building_type_id: int, def: BuildingDefinition) -> void:
	if def == null or building_list == null:
		return
	var row = _create_row(building_type_id, def)
	building_list.add_child(row.container)
	_building_rows[building_type_id] = row


func _create_row(building_type_id: int, def: BuildingDefinition) -> Dictionary:
	var db: BuildingDatabase = GameManager.get_building_database()
	var container = VBoxContainer.new()
	container.add_theme_constant_override("separation", 4)

	var name_label = Label.new()
	name_label.text = def.display_name
	name_label.add_theme_font_size_override("font_size", 16)
	container.add_child(name_label)

	var cost_label = Label.new()
	cost_label.text = "Cost: %s" % db.get_cost_string(def)
	cost_label.add_theme_color_override("font_color", Color(0.85, 0.85, 0.7))
	container.add_child(cost_label)

	var effect_label = Label.new()
	effect_label.text = db.get_effect_string(def)
	effect_label.add_theme_color_override("font_color", Color(0.7, 0.9, 0.7))
	container.add_child(effect_label)

	var owned_label = Label.new()
	owned_label.name = "OwnedLabel"
	owned_label.text = "Owned: 0"
	container.add_child(owned_label)

	var build_btn = Button.new()
	build_btn.text = "Build"
	build_btn.pressed.connect(_on_build_pressed.bind(building_type_id))
	container.add_child(build_btn)

	var sep = HSeparator.new()
	container.add_child(sep)

	return {
		"container": container,
		"build_button": build_btn,
		"owned_label": owned_label
	}


func _refresh() -> void:
	if not GameManager:
		return
	var db: BuildingDatabase = GameManager.get_building_database()
	if db == null:
		return
	for type_id in _building_rows:
		var row = _building_rows[type_id]
		var def = db.get_definition(type_id)
		var count: int = GameManager.get_player_building_count(type_id)
		if row.owned_label:
			row.owned_label.text = "Owned: %d" % count
		if row.build_button and def != null:
			row.build_button.disabled = not _can_afford(def)


func _can_afford(def: BuildingDefinition) -> bool:
	if not GameManager or not GameManager.player_village:
		return false
	for res_type in def.cost:
		var need: int = def.cost[res_type]
		var have: int = GameManager.player_village.get_resource(res_type)
		if have < need:
			return false
	return true


func _on_build_pressed(building_type_id: int) -> void:
	_clear_error()
	if not GameManager:
		return
	var success: bool = GameManager.place_building_auto(building_type_id)
	if not success:
		_set_error("Insufficient resources.")


func _set_error(message: String) -> void:
	if error_label:
		error_label.text = message
		error_label.add_theme_color_override("font_color", Color(1.0, 0.4, 0.4))


func _clear_error() -> void:
	if error_label:
		error_label.text = ""


func _on_close_pressed() -> void:
	hide()
