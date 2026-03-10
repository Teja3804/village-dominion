## TopBarUI.gd
## Displays player village resources, population, and soldiers.

extends Control

@onready var food_label: Label = $FoodLabel
@onready var wood_label: Label = $WoodLabel
@onready var stone_label: Label = $StoneLabel
@onready var gold_label: Label = $GoldLabel
@onready var weapons_label: Label = $WeaponsLabel
@onready var population_label: Label = $PopulationLabel
@onready var soldiers_label: Label = $SoldiersLabel
@onready var morale_label: Label = $MoraleLabel
@onready var village_level_label: Label = $VillageLevelLabel

func _ready() -> void:
	EventBus.player_village_updated.connect(refresh)
	EventBus.turn_started.connect(func(_t): refresh())
	refresh()

func refresh() -> void:
	var v = GameManager.player_village
	if v == null:
		return

	_set_label(food_label, "Food: %d" % v.get_resource(Constants.Resource.FOOD))
	_set_label(wood_label, "Wood: %d" % v.get_resource(Constants.Resource.WOOD))
	_set_label(stone_label, "Stone: %d" % v.get_resource(Constants.Resource.STONE))
	_set_label(gold_label, "Gold: %d" % v.get_resource(Constants.Resource.GOLD))
	_set_label(weapons_label, "Weapons: %d" % v.get_resource(Constants.Resource.WEAPONS))
	_set_label(population_label, "Pop: %d/%d" % [v.population, v.max_population])
	_set_label(soldiers_label, "Soldiers: %d" % v.soldiers)
	_set_label(morale_label, "Morale: %d" % v.morale)
	_set_label(village_level_label, "Lv.%d %s" % [v.village_level, v.village_name])

func _set_label(label: Label, text: String) -> void:
	if label:
		label.text = text
