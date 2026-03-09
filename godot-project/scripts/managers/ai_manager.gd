extends Node

## Manages AI village simulation: economy and growth decisions each tick.
## Called by GameManager after AI production is applied. No diplomacy yet.
## Logs decisions to console for verification.

# Thresholds for "low" resources (AI will try to build production)
const FOOD_LOW_THRESHOLD: int = 25
const WOOD_LOW_THRESHOLD: int = 20
# Thresholds for "strong economy" (AI may build barracks)
const FOOD_STRONG_THRESHOLD: int = 40
const WOOD_STRONG_THRESHOLD: int = 35


func _ready() -> void:
	pass


## Run AI decisions for all AI villages. Call once per tick after production/consumption.
func process_tick(ai_villages: Array, building_db: BuildingDatabase) -> void:
	if building_db == null:
		return
	for ai in ai_villages:
		var ai_v = ai as AIVillage
		if ai_v == null:
			continue
		_run_ai_decisions(ai_v, building_db)


## Run AI diplomacy: aggressive can declare war, trader can propose trade, break alliance if relation low.
## Call from GameManager every N ticks. No battles; only relation/at_war state.
func process_diplomacy_tick(ai_villages: Array) -> void:
	if not DiplomacyManager:
		return
	var p = GameConstants.PersonalityType
	for ai in ai_villages:
		var ai_v = ai as AIVillage
		if ai_v == null:
			continue
		var rel: int = DiplomacyManager.get_relation(ai_v.village_id, "player")
		var allied: bool = DiplomacyManager.is_allied(ai_v.village_id, "player")
		var at_war: bool = DiplomacyManager.is_at_war(ai_v.village_id, "player")

		# Break alliance if relation dropped
		if allied and rel < 40:
			DiplomacyManager.set_alliance(ai_v.village_id, "player", false)
			_log_decision(ai_v.display_name, "broke the alliance")

		# Aggressive: chance to declare war if not already at war
		if ai_v.personality_type_id == p.AGGRESSIVE and not at_war and rel > -100:
			if randf() < 0.2:
				DiplomacyManager.declare_war(ai_v.village_id, "player")
				_log_decision(ai_v.display_name, "declared war on you")

		# Trader: chance to propose trade (relation +10)
		if ai_v.personality_type_id == p.TRADER and not at_war:
			if randf() < 0.15:
				DiplomacyManager.do_trade(ai_v.village_id, "player")
				_log_decision(ai_v.display_name, "proposed trade (relation improved)")


func _run_ai_decisions(ai_village: AIVillage, building_db: BuildingDatabase) -> void:
	var r = GameConstants.ResourceType
	var b = GameConstants.BuildingType
	var food: int = ai_village.get_resource(r.FOOD)
	var wood: int = ai_village.get_resource(r.WOOD)

	# 1) Food low → try build Farm (all personalities)
	if food < FOOD_LOW_THRESHOLD:
		if _try_build_for_ai(ai_village, b.FARM, building_db):
			_log_decision(ai_village.display_name, "built a Farm")
			return

	# 2) Wood low → try build Lumber Camp
	if wood < WOOD_LOW_THRESHOLD:
		if _try_build_for_ai(ai_village, b.LUMBER_CAMP, building_db):
			_log_decision(ai_village.display_name, "built a Lumber Camp")
			return

	# 3) Strong economy → try build Barracks (soldiers). Personality influences tendency.
	if food >= FOOD_STRONG_THRESHOLD and wood >= WOOD_STRONG_THRESHOLD:
		var build_military: bool = _personality_wants_military(ai_village.personality_type_id)
		if build_military and _try_build_for_ai(ai_village, b.BARRACKS, building_db):
			_log_decision(ai_village.display_name, "built Barracks (recruited soldiers)")
			return

	# 4) Trader / Opportunist: prefer more economy (extra Farm or Lumber Camp) when stable
	var p = GameConstants.PersonalityType
	if ai_village.personality_type_id == p.TRADER or ai_village.personality_type_id == p.OPPORTUNIST:
		if food < 50 and _try_build_for_ai(ai_village, b.FARM, building_db):
			_log_decision(ai_village.display_name, "built a Farm")
			return
		if wood < 45 and _try_build_for_ai(ai_village, b.LUMBER_CAMP, building_db):
			_log_decision(ai_village.display_name, "built a Lumber Camp")
			return
	# 5) Population cap: build Town Hall if no room
	if ai_village.max_population > 0 and ai_village.population >= ai_village.max_population:
		if _try_build_for_ai(ai_village, b.TOWN_HALL, building_db):
			_log_decision(ai_village.display_name, "built a Town Hall")
			return


func _personality_wants_military(personality_type_id: int) -> bool:
	var p = GameConstants.PersonalityType
	# Aggressive: high chance; others: moderate or low
	if personality_type_id == p.AGGRESSIVE:
		return true
	if personality_type_id == p.DIPLOMATIC:
		return false  # focus economy
	if personality_type_id == p.TRADER or personality_type_id == p.OPPORTUNIST:
		return randf() > 0.6  # 40% chance when economy strong
	return randf() > 0.3  # default 70% chance


## Try to build one building for an AI village. Deduct cost, add instance, recalc. Returns true if built.
func _try_build_for_ai(ai_village: AIVillage, building_type_id: int, building_db: BuildingDatabase) -> bool:
	var def = building_db.get_definition(building_type_id)
	if def == null:
		return false
	for res_type in def.cost:
		var need: int = def.cost[res_type]
		var have: int = ai_village.get_resource(res_type)
		if have < need:
			return false
	# Deduct cost
	for res_type in def.cost:
		var amount: int = ai_village.get_resource(res_type) - def.cost[res_type]
		ai_village.set_resource(res_type, amount)
	# Add building instance
	var count: int = ai_village.get_building_count(building_type_id)
	var inst = BuildingInstance.new()
	inst.instance_id = "%s_%s_%d" % [ai_village.village_id, building_type_id, count]
	inst.building_type_id = building_type_id
	inst.grid_x = count
	inst.grid_y = 0
	inst.level = 1
	inst.assigned_workers = mini(1, def.worker_slots)
	ai_village.add_building(inst)
	ai_village.recalculate_max_population(building_db)
	ai_village.recalculate_military_strength(building_db)
	return true


func _log_decision(village_name: String, action: String) -> void:
	print("[AI] %s %s" % [village_name, action])
