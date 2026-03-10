## AIVillage.gd
## AI-controlled village with personality-driven decision making.

class_name AIVillage
extends Village

var personality: int = 0  # Set via setup()

# Aggression threshold — AI attacks if player strength ratio is below this
var aggression_threshold: float = 1.2

# How many turns since last major action
var turns_since_action: int = 0

# Targets being considered
var current_war_target: int = -1

func setup(p_id: int, p_name: String, p_leader: String, p_personality: int) -> void:
	village_id = p_id
	village_name = p_name
	leader_name = p_leader
	personality = p_personality
	is_player = false
	_apply_personality_modifiers()

func _apply_personality_modifiers() -> void:
	match personality:
		Constants.Personality.AGGRESSIVE:
			soldiers = 12
			resources[Constants.ResourceType.WEAPONS] = 40
		Constants.Personality.DIPLOMATIC:
			resources[Constants.ResourceType.GOLD] = 80
			morale = 80
		Constants.Personality.TRADER:
			resources[Constants.ResourceType.GOLD] = 100
			resources[Constants.ResourceType.WOOD] = 200
		Constants.Personality.OPPORTUNIST:
			soldiers = 8
			resources[Constants.ResourceType.GOLD] = 60
		Constants.Personality.ISOLATIONIST:
			resources[Constants.ResourceType.STONE] = 200
			# Will have strong walls

func decide_turn(all_villages: Array) -> Array:
	## Returns list of action dictionaries to process this turn
	var actions = []
	turns_since_action += 1

	match personality:
		Constants.Personality.AGGRESSIVE:
			actions.append_array(_aggressive_decisions(all_villages))
		Constants.Personality.DIPLOMATIC:
			actions.append_array(_diplomatic_decisions(all_villages))
		Constants.Personality.TRADER:
			actions.append_array(_trader_decisions(all_villages))
		Constants.Personality.OPPORTUNIST:
			actions.append_array(_opportunist_decisions(all_villages))
		Constants.Personality.ISOLATIONIST:
			actions.append_array(_isolationist_decisions(all_villages))

	# Everyone builds if they have resources
	actions.append_array(_build_decisions())

	return actions

func _aggressive_decisions(all_villages: Array) -> Array:
	var actions = []

	# Look for weak targets
	for v in all_villages:
		if v.village_id == village_id or not v.is_alive:
			continue
		if is_at_war_with(v.village_id):
			# Already at war — attack
			if soldiers > 5 and turns_since_action >= 2:
				actions.append({"type": "attack", "target_id": v.village_id})
				turns_since_action = 0
		else:
			# Consider declaring war on weak villages
			var my_power = float(get_attack_power())
			var their_defense = float(v.get_defense_power())
			if my_power > their_defense * aggression_threshold and get_relationship(v.village_id) < 30:
				if randf() < 0.3:
					actions.append({"type": "declare_war", "target_id": v.village_id})

	# Train more soldiers
	if soldiers < 20 and resources[Constants.ResourceType.GOLD] > 50:
		actions.append({"type": "train_soldiers", "count": 3})

	return actions

func _diplomatic_decisions(all_villages: Array) -> Array:
	var actions = []

	for v in all_villages:
		if v.village_id == village_id or not v.is_alive:
			continue
		var rel = get_relationship(v.village_id)

		# Propose alliance to friendly villages
		if rel >= 40 and not is_allied_with(v.village_id) and not agreements.has(v.village_id):
			if randf() < 0.2:
				actions.append({"type": "propose_alliance", "target_id": v.village_id})

		# Send gifts to improve relations
		if rel < 20 and resources[Constants.ResourceType.GOLD] > 60 and randf() < 0.25:
			actions.append({"type": "send_gift", "target_id": v.village_id, "amount": 20})

		# Propose peace if at war
		if is_at_war_with(v.village_id) and soldiers < v.soldiers:
			actions.append({"type": "propose_peace", "target_id": v.village_id})

	return actions

func _trader_decisions(all_villages: Array) -> Array:
	var actions = []

	for v in all_villages:
		if v.village_id == village_id or not v.is_alive:
			continue
		# Open trade routes with neutral or friendly villages
		if get_relationship(v.village_id) >= 0 and not trade_routes.has(v.village_id):
			if randf() < 0.3 and resources[Constants.ResourceType.WOOD] > 100:
				actions.append({
					"type": "propose_trade",
					"target_id": v.village_id,
					"resource_give": Constants.ResourceType.WOOD,
					"amount_give": 20,
					"resource_receive": Constants.ResourceType.GOLD,
					"amount_receive": 15
				})

	return actions

func _opportunist_decisions(all_villages: Array) -> Array:
	var actions = []

	# Attack villages that are already at war with someone else (vulnerable)
	for v in all_villages:
		if v.village_id == village_id or not v.is_alive:
			continue
		if is_at_war_with(v.village_id):
			if soldiers > 6:
				actions.append({"type": "attack", "target_id": v.village_id})
		else:
			# Look for villages weakened by other wars
			var is_already_at_war = false
			for other in all_villages:
				if other.village_id != village_id and other.village_id != v.village_id:
					if v.is_at_war_with(other.village_id):
						is_already_at_war = true
						break
			if is_already_at_war and get_attack_power() > v.get_defense_power() * 1.1:
				if randf() < 0.35:
					actions.append({"type": "declare_war", "target_id": v.village_id})

	return actions

func _isolationist_decisions(_all_villages: Array) -> Array:
	var actions = []
	# Mostly builds walls and defenses; rarely interacts
	if count_buildings_of_type(Constants.BuildingType.WALLS) == 0:
		actions.append({"type": "build", "building_type": Constants.BuildingType.WALLS})
	return actions

func _build_decisions() -> Array:
	var actions = []

	# Priority build order based on personality
	var priority_buildings = _get_build_priority()
	for btype in priority_buildings:
		var db = get_node("/root/GameManager").building_db
		var def = db.get_definition(btype)
		if def == null:
			continue
		if count_buildings_of_type(btype) < def.max_count:
			var cost = def.get_cost_for_level(1)
			if can_afford(cost):
				actions.append({"type": "build", "building_type": btype})
				break  # one build per turn

	return actions

func _get_build_priority() -> Array:
	match personality:
		Constants.Personality.AGGRESSIVE:
			return [Constants.BuildingType.BARRACKS, Constants.BuildingType.BLACKSMITH, Constants.BuildingType.FARM, Constants.BuildingType.HOUSE]
		Constants.Personality.DIPLOMATIC:
			return [Constants.BuildingType.TEMPLE, Constants.BuildingType.MARKET, Constants.BuildingType.FARM, Constants.BuildingType.HOUSE]
		Constants.Personality.TRADER:
			return [Constants.BuildingType.MARKET, Constants.BuildingType.WAREHOUSE, Constants.BuildingType.LUMBER_MILL, Constants.BuildingType.FARM]
		Constants.Personality.OPPORTUNIST:
			return [Constants.BuildingType.BARRACKS, Constants.BuildingType.FARM, Constants.BuildingType.MARKET]
		Constants.Personality.ISOLATIONIST:
			return [Constants.BuildingType.WALLS, Constants.BuildingType.WATCHTOWER, Constants.BuildingType.FARM, Constants.BuildingType.WAREHOUSE]
		_:
			return [Constants.BuildingType.FARM, Constants.BuildingType.HOUSE]
