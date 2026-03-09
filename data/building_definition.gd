extends RefCounted
class_name BuildingDefinition

## Static definition for one building type. Used by BuildingDatabase and game logic.
## Cost and production use GameConstants.ResourceType / BuildingType as keys.

var building_type_id: int = 0
var display_name: String = ""
var description: String = ""
var cost: Dictionary = {}   # ResourceType (int) -> amount (int)
var production: Dictionary = {}  # ResourceType (int) -> amount per tick (int)
var max_level: int = 2
var worker_slots: int = 2
var population_cap_contribution: int = 0  # e.g. House, Town Hall
var military_per_level: int = 0  # e.g. Barracks adds this much strength per level


func get_production_at_level(level: int) -> Dictionary:
	var result: Dictionary = {}
	for res_type in production:
		result[res_type] = production[res_type] * level
	return result


## Upgrade cost for a given level. For now, same as base cost per level (level 2 = build cost again).
func get_cost_for_level(level: int) -> Dictionary:
	var result: Dictionary = {}
	for res_type in cost:
		result[res_type] = cost[res_type]
	return result
