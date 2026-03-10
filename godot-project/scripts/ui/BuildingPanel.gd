## BuildingPanel.gd
## Panel for constructing and upgrading buildings.

extends Control

@onready var building_list: VBoxContainer = $ScrollContainer/BuildingList
@onready var title_label: Label = $TitleLabel
@onready var close_btn: Button = $CloseButton

const BuildingRowScene: PackedScene = null  # Will be instanced manually

func _ready() -> void:
	if close_btn:
		close_btn.pressed.connect(func(): EventBus.panel_close_requested.emit("building"))

func refresh() -> void:
	if title_label:
		title_label.text = "Buildings — %s" % GameManager.player_village.village_name

	if building_list == null:
		return

	# Clear old rows
	for child in building_list.get_children():
		child.queue_free()

	var v = GameManager.player_village
	var db = GameManager.building_db

	# Show all available building types
	for btype in Constants.BuildingType.values():
		var def = db.get_definition(btype)
		if def == null:
			continue

		var row = _create_building_row(v, def, btype)
		building_list.add_child(row)

func _create_building_row(v: Village, def: BuildingDefinition, btype: int) -> Control:
	var container = HBoxContainer.new()
	container.custom_minimum_size = Vector2(0, 40)

	var name_label = Label.new()
	name_label.text = def.type_name
	name_label.custom_minimum_size = Vector2(140, 0)
	container.add_child(name_label)

	var level = v.get_building_level(btype)
	var count = v.count_buildings_of_type(btype)

	var status_label = Label.new()
	if level > 0:
		status_label.text = "Lv.%d (%d built)" % [level, count]
	else:
		status_label.text = "Not built"
	status_label.custom_minimum_size = Vector2(120, 0)
	container.add_child(status_label)

	# Build button
	if count < def.max_count:
		var cost = def.get_cost_for_level(1)
		var can_build = v.can_afford(cost)
		var build_btn = Button.new()
		build_btn.text = "Build (%s)" % _format_cost(cost)
		build_btn.disabled = not can_build
		build_btn.pressed.connect(func(): _on_build_pressed(btype))
		container.add_child(build_btn)

	# Upgrade button
	if level > 0 and level < def.max_level:
		var cost = def.get_cost_for_level(level + 1)
		var can_upgrade = v.can_afford(cost)
		var upgrade_btn = Button.new()
		upgrade_btn.text = "Upgrade (%s)" % _format_cost(cost)
		upgrade_btn.disabled = not can_upgrade
		upgrade_btn.pressed.connect(func(): _on_upgrade_pressed(btype))
		container.add_child(upgrade_btn)

	# Description tooltip
	var desc_label = Label.new()
	desc_label.text = def.description
	desc_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	desc_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	container.add_child(desc_label)

	return container

func _on_build_pressed(btype: int) -> void:
	var success = GameManager.player_village.construct_building(btype)
	if success:
		EventBus.building_constructed.emit(GameManager.player_village.village_id, btype)
		EventBus.notify("Built %s!" % Constants.BUILDING_NAMES[btype], "success")
		refresh()
	else:
		EventBus.notify("Cannot build %s. Check resources or prerequisites." % Constants.BUILDING_NAMES[btype], "warning")

func _on_upgrade_pressed(btype: int) -> void:
	var success = GameManager.player_village.upgrade_building(btype)
	if success:
		EventBus.notify("Upgraded %s!" % Constants.BUILDING_NAMES[btype], "success")
		refresh()
	else:
		EventBus.notify("Cannot upgrade %s." % Constants.BUILDING_NAMES[btype], "warning")

func _format_cost(cost: Dictionary) -> String:
	var parts = []
	for res in cost:
		parts.append("%d %s" % [cost[res], Constants.RESOURCE_NAMES[res]])
	return ", ".join(parts)
