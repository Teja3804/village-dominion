## event_manager.gd
## Generates and applies random world events each turn.

extends Node

const EVENT_CHANCE_PER_TURN: float = 0.25  # 25% chance of an event each turn

var event_definitions: Array = []

func _ready() -> void:
	_build_events()

func _build_events() -> void:
	event_definitions = [
		{
			"type": Constants.EventType.FAMINE,
			"name": "Famine",
			"description": "Crops have failed. Food production halved for 3 turns.",
			"severity": "danger",
			"weight": 10,
			"effect": "food_production_halved"
		},
		{
			"type": Constants.EventType.PLAGUE,
			"name": "Plague",
			"description": "A disease swept through! Population decreased by 10%.",
			"severity": "danger",
			"weight": 8,
			"effect": "population_loss"
		},
		{
			"type": Constants.EventType.BANDIT_ATTACK,
			"name": "Bandit Attack",
			"description": "Bandits raided your village! Resources stolen.",
			"severity": "danger",
			"weight": 12,
			"effect": "resource_loss"
		},
		{
			"type": Constants.EventType.BUMPER_HARVEST,
			"name": "Bumper Harvest",
			"description": "Excellent growing season! Extra food produced.",
			"severity": "success",
			"weight": 15,
			"effect": "bonus_food"
		},
		{
			"type": Constants.EventType.GOLD_RUSH,
			"name": "Gold Rush",
			"description": "Miners struck gold! Bonus gold this turn.",
			"severity": "success",
			"weight": 10,
			"effect": "bonus_gold"
		},
		{
			"type": Constants.EventType.REBELLION,
			"name": "Rebellion",
			"description": "Unhappy citizens revolted! Morale dropped sharply.",
			"severity": "danger",
			"weight": 6,
			"effect": "morale_loss"
		},
		{
			"type": Constants.EventType.FESTIVAL,
			"name": "Festival",
			"description": "A grand festival was held! Morale boosted.",
			"severity": "success",
			"weight": 12,
			"effect": "morale_boost"
		},
		{
			"type": Constants.EventType.EARTHQUAKE,
			"name": "Earthquake",
			"description": "An earthquake damaged buildings and infrastructure!",
			"severity": "danger",
			"weight": 5,
			"effect": "building_damage"
		},
		{
			"type": Constants.EventType.TRADE_ROUTE_DISRUPTED,
			"name": "Trade Route Disrupted",
			"description": "Bandits blocked trade routes. All trade paused this turn.",
			"severity": "warning",
			"weight": 10,
			"effect": "trade_disrupted"
		},
		{
			"type": Constants.EventType.WANDERING_TRADER,
			"name": "Wandering Trader",
			"description": "A merchant arrived with rare goods!",
			"severity": "success",
			"weight": 12,
			"effect": "bonus_resources"
		},
		{
			"type": Constants.EventType.MIGRATION,
			"name": "Migration",
			"description": "Refugees arrived seeking shelter. Population increased!",
			"severity": "info",
			"weight": 10,
			"effect": "population_gain"
		}
	]

func roll_events(all_villages: Array, turn: int) -> void:
	if randf() > EVENT_CHANCE_PER_TURN:
		return

	# Pick a random village to be affected
	var alive = []
	for v in all_villages:
		if v.is_alive:
			alive.append(v)
	if alive.is_empty():
		return

	var target_village: Village = alive[randi() % alive.size()]
	var event_def = _pick_weighted_event(target_village)
	if event_def == null:
		return

	_apply_event(event_def, target_village)

	var event_data = {
		"type": event_def["type"],
		"name": event_def["name"],
		"description": event_def["description"],
		"severity": event_def["severity"],
		"village_id": target_village.village_id,
		"village_name": target_village.village_name,
		"turn": turn
	}

	EventBus.world_event_triggered.emit(event_data)

	var msg = "[%s] %s: %s" % [target_village.village_name, event_def["name"], event_def["description"]]
	EventBus.notify(msg, event_def["severity"])

func _pick_weighted_event(village: Village) -> Dictionary:
	# Filter events relevant to village state
	var eligible = event_definitions.duplicate()

	# Remove rebellion if morale is high
	if village.morale > 60:
		eligible = eligible.filter(func(e): return e["type"] != Constants.EventType.REBELLION)

	# Remove bumper harvest if no farms
	if village.count_buildings_of_type(Constants.BuildingType.FARM) == 0:
		eligible = eligible.filter(func(e): return e["type"] != Constants.EventType.BUMPER_HARVEST)

	if eligible.is_empty():
		return {}

	# Weighted random selection
	var total_weight = 0
	for e in eligible:
		total_weight += e["weight"]

	var roll = randi() % total_weight
	var cumulative = 0
	for e in eligible:
		cumulative += e["weight"]
		if roll < cumulative:
			return e

	return eligible[0]

func _apply_event(event_def: Dictionary, village: Village) -> void:
	match event_def["effect"]:
		"food_production_halved":
			# Remove half of current food
			var loss = village.get_resource(Constants.Resource.FOOD) / 4
			village.consume_resource(Constants.Resource.FOOD, loss)

		"population_loss":
			var loss = max(1, int(village.population * 0.1))
			village.population = max(1, village.population - loss)
			village.soldiers = min(village.soldiers, village.population - 1)

		"resource_loss":
			var gold_loss = min(30, village.get_resource(Constants.Resource.GOLD))
			var food_loss = min(50, village.get_resource(Constants.Resource.FOOD))
			village.consume_resource(Constants.Resource.GOLD, gold_loss)
			village.consume_resource(Constants.Resource.FOOD, food_loss)

		"bonus_food":
			village.add_resource(Constants.Resource.FOOD, 80)

		"bonus_gold":
			village.add_resource(Constants.Resource.GOLD, 40)
			village.total_gold_earned += 40

		"morale_loss":
			village.morale = max(0, village.morale - 25)
			if village.morale < 20:
				# Some soldiers desert
				var deserters = int(village.soldiers * 0.2)
				village.soldiers = max(0, village.soldiers - deserters)

		"morale_boost":
			village.morale = min(100, village.morale + 20)

		"building_damage":
			# Random building loses a level
			if not village.buildings.is_empty():
				var idx = randi() % village.buildings.size()
				if village.buildings[idx]["level"] > 1:
					village.buildings[idx]["level"] -= 1
				else:
					village.buildings.remove_at(idx)

		"trade_disrupted":
			# Handled in process_turn — just a notification here
			pass

		"bonus_resources":
			village.add_resource(Constants.Resource.GOLD, 25)
			village.add_resource(Constants.Resource.WOOD, 30)
			village.add_resource(Constants.Resource.STONE, 20)

		"population_gain":
			if village.population < village.max_population:
				var gain = min(5, village.max_population - village.population)
				village.population += gain
