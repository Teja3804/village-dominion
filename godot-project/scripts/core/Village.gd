## Village.gd
## Core village data and logic. Both player and AI villages use this as base.

class_name Village
extends Node

signal resources_changed(village: Village)
signal population_changed(village: Village)
signal building_constructed(village: Village, building_type: int)
signal village_destroyed(village: Village)

# Identity
var village_id: int = 0
var village_name: String = "Unnamed Village"
var is_player: bool = false
var leader_name: String = "Unknown"

# Resources
var resources: Dictionary = {
	Constants.Resource.FOOD: 0,
	Constants.Resource.WOOD: 0,
	Constants.Resource.STONE: 0,
	Constants.Resource.GOLD: 0,
	Constants.Resource.WEAPONS: 0
}

# Storage
var storage_cap: int = Constants.MAX_STORAGE_BASE

# Population
var population: int = 10
var max_population: int = 10
var soldiers: int = 5
var weapon_level: int = 1  # 1-5, upgrades via Blacksmith

# Village level (1-5, based on Town Hall)
var village_level: int = 1

# Buildings: Array of {type: int, level: int}
var buildings: Array = []

# Diplomacy: village_id -> relationship score (-100 to 100)
var relationships: Dictionary = {}

# Active agreements: village_id -> {type: String, turns_left: int}
var agreements: Dictionary = {}

# Trade routes: village_id -> {resource_give: int, amount_give: int, resource_receive: int, amount_receive: int}
var trade_routes: Dictionary = {}

# Stats tracking
var turn_number: int = 0
var total_gold_earned: int = 0
var total_battles_won: int = 0
var total_battles_lost: int = 0
var is_alive: bool = true

# Morale (0-100), affects production and rebellion chance
var morale: int = 70

func _ready() -> void:
	_initialize_resources()

func _initialize_resources() -> void:
	resources[Constants.Resource.FOOD] = Constants.STARTING_FOOD
	resources[Constants.Resource.WOOD] = Constants.STARTING_WOOD
	resources[Constants.Resource.STONE] = Constants.STARTING_STONE
	resources[Constants.Resource.GOLD] = Constants.STARTING_GOLD
	resources[Constants.Resource.WEAPONS] = Constants.STARTING_WEAPONS

# --- Resource Management ---

func get_resource(type: int) -> int:
	return resources.get(type, 0)

func add_resource(type: int, amount: int) -> void:
	resources[type] = min(resources.get(type, 0) + amount, storage_cap)
	resources_changed.emit(self)

func consume_resource(type: int, amount: int) -> bool:
	if resources.get(type, 0) >= amount:
		resources[type] -= amount
		resources_changed.emit(self)
		return true
	return false

func can_afford(cost: Dictionary) -> bool:
	for res in cost:
		if resources.get(res, 0) < cost[res]:
			return false
	return true

func pay_cost(cost: Dictionary) -> bool:
	if not can_afford(cost):
		return false
	for res in cost:
		resources[res] -= cost[res]
	resources_changed.emit(self)
	return true

# --- Building Management ---

func construct_building(type: int) -> bool:
	var db = get_node("/root/GameManager").building_db
	var definition = db.get_definition(type)
	if definition == null:
		return false

	# Check count limit
	var current_count = count_buildings_of_type(type)
	if current_count >= definition.max_count:
		return false

	# Check prerequisites
	if definition.requires_building != -1:
		if count_buildings_of_type(definition.requires_building) == 0:
			return false

	# Check village level
	if definition.requires_level > village_level:
		return false

	# Check and pay cost
	var cost = definition.get_cost_for_level(1)
	if not pay_cost(cost):
		return false

	buildings.append({"type": type, "level": 1})
	_recalculate_stats()
	building_constructed.emit(self, type)
	return true

func upgrade_building(type: int) -> bool:
	var db = get_node("/root/GameManager").building_db
	var definition = db.get_definition(type)
	if definition == null:
		return false

	for i in range(buildings.size()):
		if buildings[i]["type"] == type and buildings[i]["level"] < definition.max_level:
			var cost = definition.get_cost_for_level(buildings[i]["level"] + 1)
			if not pay_cost(cost):
				return false
			buildings[i]["level"] += 1
			_recalculate_stats()
			return true
	return false

func count_buildings_of_type(type: int) -> int:
	var count = 0
	for b in buildings:
		if b["type"] == type:
			count += 1
	return count

func get_building_level(type: int) -> int:
	for b in buildings:
		if b["type"] == type:
			return b["level"]
	return 0

func _recalculate_stats() -> void:
	# Recalculate village level from Town Hall
	var th_level = get_building_level(Constants.BuildingType.TOWN_HALL)
	if th_level > 0:
		village_level = th_level

	# Recalculate max population from Houses + Town Hall
	max_population = 5  # base
	var db = get_node("/root/GameManager").building_db
	for b in buildings:
		var def = db.get_definition(b["type"])
		if def and def.population_capacity > 0:
			max_population += def.population_capacity * b["level"]

	# Recalculate storage cap from Warehouses
	var warehouse_count = count_buildings_of_type(Constants.BuildingType.WAREHOUSE)
	storage_cap = Constants.MAX_STORAGE_BASE + (warehouse_count * 200)

	# Weapon level from Blacksmith
	var blacksmith_level = get_building_level(Constants.BuildingType.BLACKSMITH)
	weapon_level = max(1, blacksmith_level + 1)

	population_changed.emit(self)

# --- Production & Consumption ---

func process_turn() -> Dictionary:
	turn_number += 1
	var report = {"produced": {}, "consumed": {}, "events": []}

	# Produce resources from buildings
	var db = get_node("/root/GameManager").building_db
	for b in buildings:
		var def = db.get_definition(b["type"])
		if def == null:
			continue
		var prod = def.get_production_at_level(b["level"])
		for res in prod:
			var amount = int(prod[res] * (morale / 100.0))
			add_resource(res, amount)
			report["produced"][res] = report["produced"].get(res, 0) + amount

	# Consume food for population
	var food_needed = int(population * Constants.FOOD_PER_VILLAGER)
	if not consume_resource(Constants.Resource.FOOD, food_needed):
		# Not enough food — morale drops, possible population loss
		morale = max(0, morale - 10)
		if morale < 20 and randf() < 0.3:
			population = max(1, population - int(population * 0.05))
			report["events"].append("Famine: population declined")
	else:
		report["consumed"][Constants.Resource.FOOD] = food_needed

	# Consume gold for soldier upkeep
	var gold_needed = soldiers * Constants.SOLDIER_UPKEEP_GOLD
	if not consume_resource(Constants.Resource.GOLD, gold_needed):
		# Can't pay soldiers — some desert
		var deserters = min(soldiers, int(soldiers * 0.2))
		soldiers -= deserters
		report["events"].append("Soldiers deserted: no gold for upkeep")

	# Process trade routes
	for vid in trade_routes:
		var route = trade_routes[vid]
		consume_resource(route["resource_give"], route["amount_give"])
		add_resource(route["resource_receive"], route["amount_receive"])

	# Natural morale recovery
	if morale < 70:
		morale = min(70, morale + 2)

	# Grow population if conditions good
	if population < max_population and resources[Constants.Resource.FOOD] > 50 and morale > 50:
		if randf() < 0.3:
			population += 1
			population_changed.emit(self)

	return report

# --- Military ---

func get_attack_power() -> int:
	return int(soldiers * weapon_level * (1.0 + randf() * Constants.ATTACK_RANDOMNESS))

func get_defense_power() -> int:
	var db = get_node("/root/GameManager").building_db
	var defense = soldiers
	for b in buildings:
		var def = db.get_definition(b["type"])
		if def and def.defense_bonus > 0:
			defense += def.defense_bonus * b["level"]
	return int(defense * (1.0 + randf() * Constants.ATTACK_RANDOMNESS))

func train_soldiers(count: int) -> bool:
	if population <= soldiers + count:
		return false
	var cost = {
		Constants.Resource.GOLD: count * 10,
		Constants.Resource.WEAPONS: count * 2
	}
	if not pay_cost(cost):
		return false
	soldiers += count
	return true

func lose_soldiers(count: int) -> void:
	soldiers = max(0, soldiers - count)

# --- Relationships ---

func get_relationship(village_id: int) -> int:
	return relationships.get(village_id, 0)

func change_relationship(village_id: int, delta: int) -> void:
	var current = relationships.get(village_id, 0)
	relationships[village_id] = clamp(current + delta, -100, 100)

func get_relation_state(village_id: int) -> int:
	var score = get_relationship(village_id)
	if score <= Constants.RELATION_WAR:
		return Constants.RelationState.WAR
	elif score <= Constants.RELATION_HOSTILE:
		return Constants.RelationState.HOSTILE
	elif score >= Constants.RELATION_ALLIED:
		return Constants.RelationState.ALLIED
	elif score >= Constants.RELATION_FRIENDLY:
		return Constants.RelationState.FRIENDLY
	else:
		return Constants.RelationState.NEUTRAL

func is_at_war_with(village_id: int) -> bool:
	return get_relation_state(village_id) == Constants.RelationState.WAR

func is_allied_with(village_id: int) -> bool:
	return get_relation_state(village_id) == Constants.RelationState.ALLIED

# --- Serialization ---

func to_dict() -> Dictionary:
	return {
		"village_id": village_id,
		"village_name": village_name,
		"is_player": is_player,
		"leader_name": leader_name,
		"resources": resources,
		"storage_cap": storage_cap,
		"population": population,
		"max_population": max_population,
		"soldiers": soldiers,
		"weapon_level": weapon_level,
		"village_level": village_level,
		"buildings": buildings,
		"relationships": relationships,
		"agreements": agreements,
		"trade_routes": trade_routes,
		"morale": morale,
		"is_alive": is_alive,
		"turn_number": turn_number,
		"total_gold_earned": total_gold_earned,
		"total_battles_won": total_battles_won,
		"total_battles_lost": total_battles_lost
	}

func from_dict(data: Dictionary) -> void:
	village_id = data.get("village_id", 0)
	village_name = data.get("village_name", "")
	is_player = data.get("is_player", false)
	leader_name = data.get("leader_name", "")
	resources = data.get("resources", {})
	storage_cap = data.get("storage_cap", Constants.MAX_STORAGE_BASE)
	population = data.get("population", 10)
	max_population = data.get("max_population", 10)
	soldiers = data.get("soldiers", 5)
	weapon_level = data.get("weapon_level", 1)
	village_level = data.get("village_level", 1)
	buildings = data.get("buildings", [])
	relationships = data.get("relationships", {})
	agreements = data.get("agreements", {})
	trade_routes = data.get("trade_routes", {})
	morale = data.get("morale", 70)
	is_alive = data.get("is_alive", true)
	turn_number = data.get("turn_number", 0)
	total_gold_earned = data.get("total_gold_earned", 0)
	total_battles_won = data.get("total_battles_won", 0)
	total_battles_lost = data.get("total_battles_lost", 0)
