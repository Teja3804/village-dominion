## building_definition.gd
## Data class for a building type definition

class_name BuildingDefinition
extends Resource

@export var id: int = 0
@export var type_name: String = ""
@export var description: String = ""
@export var max_level: int = 3
@export var base_cost: Dictionary = {}         # Resource -> amount
@export var upgrade_cost_multiplier: float = 1.5
@export var production_per_turn: Dictionary = {}  # Resource -> amount per level
@export var consumption_per_turn: Dictionary = {} # Resource -> amount per level
@export var population_capacity: int = 0       # bonus housing per level
@export var defense_bonus: int = 0             # added to village defense
@export var requires_building: int = -1        # BuildingType prerequisite (-1 = none)
@export var requires_level: int = 0            # village level required
@export var max_count: int = 99               # max of this building allowed

func get_cost_for_level(level: int) -> Dictionary:
	var cost = {}
	for res in base_cost:
		cost[res] = int(base_cost[res] * pow(upgrade_cost_multiplier, level - 1))
	return cost

func get_production_at_level(level: int) -> Dictionary:
	var prod = {}
	for res in production_per_turn:
		prod[res] = production_per_turn[res] * level
	return prod
