## building_database.gd
## Stores all building definitions. Loaded as autoload or accessed via GameManager.

class_name BuildingDatabase
extends Node

var buildings: Dictionary = {}  # BuildingType -> BuildingDefinition

func _ready() -> void:
	_load_all_buildings()

func _load_all_buildings() -> void:
	_add_town_hall()
	_add_house()
	_add_farm()
	_add_lumber_mill()
	_add_quarry()
	_add_market()
	_add_barracks()
	_add_blacksmith()
	_add_walls()
	_add_watchtower()
	_add_warehouse()
	_add_temple()

func get_definition(type: int) -> BuildingDefinition:
	return buildings.get(type, null)

func _add_town_hall() -> void:
	var b = BuildingDefinition.new()
	b.id = Constants.BuildingType.TOWN_HALL
	b.type_name = "Town Hall"
	b.description = "The heart of your village. Upgrade to unlock new buildings and raise village level."
	b.max_level = 5
	b.max_count = 1
	b.base_cost = {Constants.Resource.WOOD: 100, Constants.Resource.STONE: 100, Constants.Resource.GOLD: 50}
	b.population_capacity = 5
	b.requires_building = -1
	buildings[b.id] = b

func _add_house() -> void:
	var b = BuildingDefinition.new()
	b.id = Constants.BuildingType.HOUSE
	b.type_name = "House"
	b.description = "Provides housing for villagers. More houses = more workers."
	b.max_level = 3
	b.max_count = 10
	b.base_cost = {Constants.Resource.WOOD: 30, Constants.Resource.STONE: 10}
	b.population_capacity = 4
	buildings[b.id] = b

func _add_farm() -> void:
	var b = BuildingDefinition.new()
	b.id = Constants.BuildingType.FARM
	b.type_name = "Farm"
	b.description = "Produces food to feed your villagers and soldiers."
	b.max_level = 3
	b.max_count = 8
	b.base_cost = {Constants.Resource.WOOD: 20, Constants.Resource.GOLD: 10}
	b.production_per_turn = {Constants.Resource.FOOD: 15}
	buildings[b.id] = b

func _add_lumber_mill() -> void:
	var b = BuildingDefinition.new()
	b.id = Constants.BuildingType.LUMBER_MILL
	b.type_name = "Lumber Mill"
	b.description = "Chops wood for construction and trade."
	b.max_level = 3
	b.max_count = 5
	b.base_cost = {Constants.Resource.WOOD: 40, Constants.Resource.GOLD: 15}
	b.production_per_turn = {Constants.Resource.WOOD: 12}
	buildings[b.id] = b

func _add_quarry() -> void:
	var b = BuildingDefinition.new()
	b.id = Constants.BuildingType.QUARRY
	b.type_name = "Quarry"
	b.description = "Mines stone for buildings and walls."
	b.max_level = 3
	b.max_count = 5
	b.base_cost = {Constants.Resource.WOOD: 30, Constants.Resource.STONE: 20}
	b.production_per_turn = {Constants.Resource.STONE: 10}
	buildings[b.id] = b

func _add_market() -> void:
	var b = BuildingDefinition.new()
	b.id = Constants.BuildingType.MARKET
	b.type_name = "Market"
	b.description = "Generates gold and enables trade with other villages."
	b.max_level = 3
	b.max_count = 3
	b.base_cost = {Constants.Resource.WOOD: 50, Constants.Resource.STONE: 30, Constants.Resource.GOLD: 20}
	b.production_per_turn = {Constants.Resource.GOLD: 8}
	b.requires_building = Constants.BuildingType.TOWN_HALL
	buildings[b.id] = b

func _add_barracks() -> void:
	var b = BuildingDefinition.new()
	b.id = Constants.BuildingType.BARRACKS
	b.type_name = "Barracks"
	b.description = "Train soldiers to defend your village and attack enemies."
	b.max_level = 3
	b.max_count = 3
	b.base_cost = {Constants.Resource.WOOD: 60, Constants.Resource.STONE: 40, Constants.Resource.GOLD: 30}
	b.production_per_turn = {}
	b.requires_building = Constants.BuildingType.TOWN_HALL
	buildings[b.id] = b

func _add_blacksmith() -> void:
	var b = BuildingDefinition.new()
	b.id = Constants.BuildingType.BLACKSMITH
	b.type_name = "Blacksmith"
	b.description = "Forges weapons, increasing soldier effectiveness."
	b.max_level = 3
	b.max_count = 2
	b.base_cost = {Constants.Resource.STONE: 50, Constants.Resource.GOLD: 40}
	b.production_per_turn = {Constants.Resource.WEAPONS: 5}
	b.requires_building = Constants.BuildingType.BARRACKS
	buildings[b.id] = b

func _add_walls() -> void:
	var b = BuildingDefinition.new()
	b.id = Constants.BuildingType.WALLS
	b.type_name = "Walls"
	b.description = "Defensive fortifications that protect against attacks."
	b.max_level = 3
	b.max_count = 1
	b.base_cost = {Constants.Resource.STONE: 80, Constants.Resource.WOOD: 40}
	b.defense_bonus = 20
	buildings[b.id] = b

func _add_watchtower() -> void:
	var b = BuildingDefinition.new()
	b.id = Constants.BuildingType.WATCHTOWER
	b.type_name = "Watchtower"
	b.description = "Detects incoming attacks early and boosts defense."
	b.max_level = 2
	b.max_count = 3
	b.base_cost = {Constants.Resource.WOOD: 30, Constants.Resource.STONE: 20}
	b.defense_bonus = 10
	buildings[b.id] = b

func _add_warehouse() -> void:
	var b = BuildingDefinition.new()
	b.id = Constants.BuildingType.WAREHOUSE
	b.type_name = "Warehouse"
	b.description = "Increases resource storage capacity."
	b.max_level = 3
	b.max_count = 3
	b.base_cost = {Constants.Resource.WOOD: 40, Constants.Resource.STONE: 30}
	buildings[b.id] = b

func _add_temple() -> void:
	var b = BuildingDefinition.new()
	b.id = Constants.BuildingType.TEMPLE
	b.type_name = "Temple"
	b.description = "Boosts villager morale, reducing rebellion chance and attracting migrants."
	b.max_level = 2
	b.max_count = 1
	b.base_cost = {Constants.Resource.STONE: 60, Constants.Resource.GOLD: 50}
	b.requires_building = Constants.BuildingType.TOWN_HALL
	b.requires_level = 2
	buildings[b.id] = b
