extends RefCounted
class_name BuildingDatabase

## Holds all building definitions for the game. Single source for costs and production.
## Create via create_default() to get Farm, Lumber Camp, Barracks, Town Hall.
## Extensible: add more definitions and register_definition() for future buildings.

var _definitions: Dictionary = {}  # BuildingType (int) -> BuildingDefinition


func register_definition(def: BuildingDefinition) -> void:
	if def.building_type_id != GameConstants.BuildingType.NONE:
		_definitions[def.building_type_id] = def


func get_definition(building_type_id: int) -> BuildingDefinition:
	return _definitions.get(building_type_id, null)


func get_all_type_ids() -> Array:
	var ids: Array = []
	for key in _definitions:
		ids.append(key)
	return ids


## Building types the player can construct from the panel. Order determines UI list order.
func get_buildable_type_ids() -> Array:
	var b = GameConstants.BuildingType
	return [b.FARM, b.LUMBER_CAMP, b.BARRACKS, b.TOWN_HALL]


## Human-readable cost string for UI, e.g. "30 wood, 10 gold".
func get_cost_string(def: BuildingDefinition) -> String:
	if def == null:
		return ""
	var r = GameConstants.ResourceType
	var names := { r.FOOD: "food", r.WOOD: "wood", r.STONE: "stone", r.GOLD: "gold", r.IRON: "iron" }
	var parts: PackedStringArray = []
	for res_type in def.cost:
		var amount: int = def.cost[res_type]
		var name_str: String = names.get(res_type, "?")
		parts.append("%d %s" % [amount, name_str])
	return ", ".join(parts)


## Short effect line for UI, e.g. "+5 food/tick" or "+3 soldiers".
func get_effect_string(def: BuildingDefinition) -> String:
	if def == null:
		return ""
	var r = GameConstants.ResourceType
	var names := { r.FOOD: "food", r.WOOD: "wood", r.STONE: "stone", r.GOLD: "gold", r.IRON: "iron" }
	var parts: PackedStringArray = []
	for res_type in def.production:
		var amount: int = def.production[res_type] * 1  # level 1
		parts.append("+%d %s/tick" % [amount, names.get(res_type, "?")])
	if def.population_cap_contribution > 0:
		parts.append("+%d pop cap" % (def.population_cap_contribution * 1))
	if def.military_per_level > 0:
		parts.append("+%d soldiers" % def.military_per_level)
	if parts.is_empty():
		return "—"
	return " ".join(parts)


static func create_default() -> BuildingDatabase:
	var db = BuildingDatabase.new()
	var r = GameConstants.ResourceType
	var b = GameConstants.BuildingType

	# Farm: produces food
	var farm = BuildingDefinition.new()
	farm.building_type_id = b.FARM
	farm.display_name = "Farm"
	farm.description = "Produces food each tick. Essential for population growth."
	farm.cost = { r.WOOD: 30, r.GOLD: 10 }
	farm.production = { r.FOOD: 5 }
	farm.max_level = 2
	farm.worker_slots = 2
	db.register_definition(farm)

	# Lumber Camp: produces wood
	var lumber = BuildingDefinition.new()
	lumber.building_type_id = b.LUMBER_CAMP
	lumber.display_name = "Lumber Camp"
	lumber.description = "Produces wood each tick. Used for construction."
	lumber.cost = { r.WOOD: 20, r.GOLD: 15 }
	lumber.production = { r.WOOD: 4 }
	lumber.max_level = 2
	lumber.worker_slots = 2
	db.register_definition(lumber)

	# Barracks: contributes to military strength
	var barracks = BuildingDefinition.new()
	barracks.building_type_id = b.BARRACKS
	barracks.display_name = "Barracks"
	barracks.description = "Increases military strength. Higher level adds more strength."
	barracks.cost = { r.WOOD: 40, r.STONE: 20, r.GOLD: 25 }
	barracks.production = {}
	barracks.military_per_level = 3
	barracks.max_level = 2
	barracks.worker_slots = 0
	db.register_definition(barracks)

	# Town Hall: base building, population cap
	var town_hall = BuildingDefinition.new()
	town_hall.building_type_id = b.TOWN_HALL
	town_hall.display_name = "Town Hall"
	town_hall.description = "Village center. Provides population capacity."
	town_hall.cost = { r.WOOD: 50, r.STONE: 30, r.GOLD: 20 }
	town_hall.production = {}
	town_hall.population_cap_contribution = 10
	town_hall.max_level = 2
	town_hall.worker_slots = 0
	db.register_definition(town_hall)

	return db
