extends Control

## Minimal playable UI: village name, food, wood, gold, population, soldiers, tick count.
## Refreshes on EventBus.resources_changed and turn_advanced. Next Turn button advances turn.
## Placeholder hooks for future panels (Building, Diplomacy) without implementing them yet.

@onready var label_village_name: Label = $MarginContainer/VBox/RowVillage/LabelVillageName
@onready var label_food: Label = $MarginContainer/VBox/RowResources/LabelFood
@onready var label_wood: Label = $MarginContainer/VBox/RowResources/LabelWood
@onready var label_gold: Label = $MarginContainer/VBox/RowResources/LabelGold
@onready var label_population: Label = $MarginContainer/VBox/RowStats/LabelPopulation
@onready var label_soldiers: Label = $MarginContainer/VBox/RowStats/LabelSoldiers
@onready var label_tick: Label = $MarginContainer/VBox/RowTick/LabelTick
@onready var label_production: Label = $MarginContainer/VBox/RowProduction/LabelProduction
@onready var button_next_turn: Button = $MarginContainer/VBox/ButtonNextTurn
@onready var button_building_placeholder: Button = $MarginContainer/VBox/RowButtons/ButtonBuilding
@onready var button_diplomacy_placeholder: Button = $MarginContainer/VBox/RowButtons/ButtonDiplomacy
@onready var button_save: Button = $MarginContainer/VBox/RowButtons/ButtonSave

var _building_panel: Control = null
var _diplomacy_panel: Control = null
var _save_menu: Control = null


func _ready() -> void:
	# Building and Diplomacy panels are siblings under UICanvas (parent of TopBar).
	var ui_canvas = get_parent()
	if ui_canvas:
		_building_panel = ui_canvas.get_node_or_null("BuildingPanel")
		_diplomacy_panel = ui_canvas.get_node_or_null("DiplomacyPanel")
		_save_menu = ui_canvas.get_node_or_null("SaveMenu")
	if EventBus:
		EventBus.resources_changed.connect(_refresh)
		EventBus.turn_advanced.connect(_refresh)
	if button_next_turn:
		button_next_turn.pressed.connect(_on_next_turn_pressed)
	if button_building_placeholder:
		button_building_placeholder.pressed.connect(_on_building_placeholder_pressed)
	if button_diplomacy_placeholder:
		button_diplomacy_placeholder.pressed.connect(_on_diplomacy_placeholder_pressed)
	_refresh()


func _refresh() -> void:
	if not GameManager:
		return
	# Village name
	if label_village_name:
		label_village_name.text = GameManager.get_player_village_name()
	# Resources
	var r = GameConstants.ResourceType
	var res = GameManager.get_player_resources()
	if label_food:
		label_food.text = "Food: %d" % res.get(r.FOOD, 0)
	if label_wood:
		label_wood.text = "Wood: %d" % res.get(r.WOOD, 0)
	if label_gold:
		label_gold.text = "Gold: %d" % res.get(r.GOLD, 0)
	# Population and soldiers
	if label_population:
		label_population.text = "Population: %d" % GameManager.get_player_population()
	if label_soldiers:
		label_soldiers.text = "Soldiers: %d" % GameManager.get_player_military_strength()
	# Tick / day
	if label_tick:
		label_tick.text = "Day: %d" % GameManager.get_current_turn()
	# Production next tick (optional)
	if label_production:
		var prod = GameManager.get_player_production_per_tick()
		var r = GameConstants.ResourceType
		var parts: PackedStringArray = []
		if prod.get(r.FOOD, 0) != 0:
			parts.append("+%d food" % prod[r.FOOD])
		if prod.get(r.WOOD, 0) != 0:
			parts.append("+%d wood" % prod[r.WOOD])
		if prod.get(r.GOLD, 0) != 0:
			parts.append("+%d gold" % prod[r.GOLD])
		label_production.text = "Production: " + ", ".join(parts) if parts.size() > 0 else "Production: —"


func _on_next_turn_pressed() -> void:
	if GameManager:
		GameManager.advance_turn()


func _on_building_placeholder_pressed() -> void:
	if _building_panel != null:
		_building_panel.visible = !_building_panel.visible


func _on_diplomacy_placeholder_pressed() -> void:
	if _diplomacy_panel != null:
		_diplomacy_panel.visible = !_diplomacy_panel.visible


func _on_save_pressed() -> void:
	if _save_menu != null and _save_menu.has_method("show_menu"):
		_save_menu.show_menu()
