extends Node

## Central game state and orchestration. Single source of truth for runtime state.
## Owns game tick timer, player village, AI villages, and coordinates production/strength updates.
## UI and other systems read from here and request changes via methods.

var current_turn: int = 0
var game_state: int = GameConstants.GameState.PLAYING
var player_village: Village = null
var ai_villages: Array = []  # Array of AIVillage
var _building_database: BuildingDatabase = null
var _tick_timer: Timer = null

# Tick interval in seconds; advance_turn() runs each time the timer fires.
const TICK_INTERVAL_SEC: float = 2.0
const FOOD_PER_POP_PER_TICK: int = 1


func _ready() -> void:
	_building_database = BuildingDatabase.create_default()
	_setup_tick_timer()
	# Start game when Main loads (or call new_game() from menu).
	new_game()


func _setup_tick_timer() -> void:
	_tick_timer = Timer.new()
	_tick_timer.wait_time = TICK_INTERVAL_SEC
	_tick_timer.one_shot = false
	_tick_timer.timeout.connect(_on_tick_timeout)
	add_child(_tick_timer)


func _on_tick_timeout() -> void:
	advance_turn()


func new_game() -> void:
	current_turn = 0
	game_state = GameConstants.GameState.PLAYING
	player_village = _create_player_village()
	ai_villages = _create_ai_villages()
	if DiplomacyManager:
		var ai_ids: Array = []
		for ai in ai_villages:
			var a = ai as AIVillage
			if a:
				ai_ids.append(a.village_id)
		DiplomacyManager.init_relations("player", ai_ids)
	sync_ai_relations_from_diplomacy()
	_tick_timer.start()
	_emit_state_signals()


func _create_player_village() -> Village:
	var v = Village.new()
	v.village_id = "player"
	v.display_name = "Your Village"
	var r = GameConstants.ResourceType
	v.resources = {
		r.FOOD: 50,
		r.WOOD: 40,
		r.GOLD: 30,
		r.STONE: 20,
		r.IRON: 0
	}
	v.population = 5
	v.max_population = 10
	v.military_strength = 0

	# Starting buildings: one Farm (with workers), one Town Hall
	var farm = BuildingInstance.new()
	farm.instance_id = "player_farm_0"
	farm.building_type_id = GameConstants.BuildingType.FARM
	farm.grid_x = 1
	farm.grid_y = 1
	farm.level = 1
	farm.assigned_workers = 2
	v.add_building(farm)

	var town_hall = BuildingInstance.new()
	town_hall.instance_id = "player_townhall_0"
	town_hall.building_type_id = GameConstants.BuildingType.TOWN_HALL
	town_hall.grid_x = 0
	town_hall.grid_y = 0
	town_hall.level = 1
	v.add_building(town_hall)

	v.recalculate_max_population(_building_database)
	v.recalculate_military_strength(_building_database)
	return v


func _create_ai_villages() -> Array:
	var list: Array = []
	var r = GameConstants.ResourceType
	var p = GameConstants.PersonalityType
	var b = GameConstants.BuildingType

	# 3–5 AI villages with name, population, resources, soldiers (military_strength), buildings, personality
	var configs: Array = [
		{ "id": "ai_northbrook", "name": "Northbrook", "personality": p.TRADER, "food": 40, "wood": 35, "gold": 25, "stone": 15, "pop": 4 },
		{ "id": "ai_ironhold", "name": "Ironhold", "personality": p.AGGRESSIVE, "food": 30, "wood": 45, "gold": 20, "stone": 25, "pop": 3 },
		{ "id": "ai_redrock", "name": "Redrock", "personality": p.DIPLOMATIC, "food": 35, "wood": 30, "gold": 30, "stone": 20, "pop": 4 },
		{ "id": "ai_greenvale", "name": "Greenvale", "personality": p.OPPORTUNIST, "food": 45, "wood": 25, "gold": 22, "stone": 18, "pop": 5 },
		{ "id": "ai_ashford", "name": "Ashford", "personality": p.AGGRESSIVE, "food": 28, "wood": 40, "gold": 18, "stone": 22, "pop": 3 }
	]

	for cfg in configs:
		var ai = AIVillage.new()
		ai.village_id = cfg.id
		ai.display_name = cfg.name
		ai.resources = { r.FOOD: cfg.food, r.WOOD: cfg.wood, r.GOLD: cfg.gold, r.STONE: cfg.stone, r.IRON: 0 }
		ai.population = cfg.pop
		ai.max_population = 8
		ai.military_strength = 0
		ai.personality_type_id = cfg.personality
		ai.relationship_with_player = 0
		ai.at_war = false
		# Starting building: one Farm so they can grow
		var farm = BuildingInstance.new()
		farm.instance_id = "%s_farm_0" % ai.village_id
		farm.building_type_id = b.FARM
		farm.grid_x = 0
		farm.grid_y = 0
		farm.level = 1
		farm.assigned_workers = 2
		ai.add_building(farm)
		ai.recalculate_max_population(_building_database)
		ai.recalculate_military_strength(_building_database)
		list.append(ai)

	return list


func advance_turn() -> void:
	if game_state != GameConstants.GameState.PLAYING:
		return

	# Player village: production, consumption, then recalc caps and strength
	if player_village != null:
		var prod = player_village.get_production_per_tick(_building_database)
		player_village.apply_production(prod)
		player_village.apply_food_consumption(FOOD_PER_POP_PER_TICK)
		player_village.recalculate_max_population(_building_database)
		player_village.recalculate_military_strength(_building_database)

	for ai in ai_villages:
		var ai_v = ai as Village
		if ai_v == null:
			continue
		var ai_prod = ai_v.get_production_per_tick(_building_database)
		ai_v.apply_production(ai_prod)
		ai_v.apply_food_consumption(FOOD_PER_POP_PER_TICK)
		ai_v.recalculate_max_population(_building_database)
		ai_v.recalculate_military_strength(_building_database)

	# AI decisions: build buildings, recruit soldiers (barracks), adjust economy
	if AIManager:
		AIManager.process_tick(ai_villages, _building_database)
	# AI diplomacy: every 5 ticks
	if current_turn > 0 and current_turn % 5 == 0 and AIManager:
		AIManager.process_diplomacy_tick(ai_villages)
		sync_ai_relations_from_diplomacy()
		if EventBus:
			EventBus.diplomacy_updated.emit()

	current_turn += 1
	# World events: every 5–10 ticks (EventManager decides)
	if EventManager:
		EventManager.check_and_trigger(current_turn)
	_emit_state_signals()


func _emit_state_signals() -> void:
	if EventBus:
		EventBus.resources_changed.emit()
		EventBus.turn_advanced.emit()
		EventBus.buildings_changed.emit()


func get_building_database() -> BuildingDatabase:
	return _building_database


## Build a building without grid selection; auto-assigns a slot. Used by BuildingPanel.
func place_building_auto(building_type_id: int) -> bool:
	if player_village == null:
		return false
	var count: int = player_village.get_building_count(building_type_id)
	return place_building(count, 0, building_type_id)


func get_player_building_count(building_type_id: int) -> int:
	if player_village == null:
		return 0
	return player_village.get_building_count(building_type_id)


func place_building(grid_x: int, grid_y: int, building_type_id: int) -> bool:
	if player_village == null:
		return false
	var def = _building_database.get_definition(building_type_id)
	if def == null:
		return false
	for res_type in def.cost:
		var need: int = def.cost[res_type]
		var have: int = player_village.get_resource(res_type)
		if have < need:
			return false
	for res_type in def.cost:
		var amount = player_village.get_resource(res_type) - def.cost[res_type]
		player_village.set_resource(res_type, amount)
	var inst = BuildingInstance.new()
	inst.instance_id = "player_%s_%d_%d" % [building_type_id, grid_x, grid_y]
	inst.building_type_id = building_type_id
	inst.grid_x = grid_x
	inst.grid_y = grid_y
	inst.level = 1
	inst.assigned_workers = mini(1, def.worker_slots)
	player_village.add_building(inst)
	player_village.recalculate_max_population(_building_database)
	player_village.recalculate_military_strength(_building_database)
	_emit_state_signals()
	return true


func upgrade_building(instance_id: String) -> bool:
	if player_village == null:
		return false
	var inst = player_village.get_building(instance_id)
	if inst == null:
		return false
	var def = _building_database.get_definition(inst.building_type_id)
	if def == null or inst.level >= def.max_level:
		return false
	var next_level = inst.level + 1
	var cost = def.get_cost_for_level(next_level)
	for res_type in cost:
		if player_village.get_resource(res_type) < cost[res_type]:
			return false
	for res_type in cost:
		player_village.set_resource(res_type, player_village.get_resource(res_type) - cost[res_type])
	inst.level = next_level
	player_village.recalculate_max_population(_building_database)
	player_village.recalculate_military_strength(_building_database)
	_emit_state_signals()
	return true


func assign_workers(instance_id: String, count: int) -> void:
	if player_village == null:
		return
	var inst = player_village.get_building(instance_id)
	if inst == null:
		return
	var def = _building_database.get_definition(inst.building_type_id)
	if def == null:
		return
	inst.assigned_workers = clampi(count, 0, def.worker_slots)
	_emit_state_signals()


func get_player_resources() -> Dictionary:
	if player_village == null:
		return {}
	return player_village.resources.duplicate()


func get_player_buildings() -> Array:
	if player_village == null:
		return []
	return player_village.building_instances.duplicate()


func get_current_turn() -> int:
	return current_turn


func get_player_population() -> int:
	return player_village.population if player_village != null else 0


func get_player_military_strength() -> int:
	return player_village.military_strength if player_village != null else 0


func get_player_village_name() -> String:
	return player_village.display_name if player_village != null else ""


## Production per tick for the player village (for UI display). Does not apply it.
func get_player_production_per_tick() -> Dictionary:
	if player_village == null or _building_database == null:
		return {}
	return player_village.get_production_per_tick(_building_database)


## Sync AIVillage.relationship_with_player and at_war from DiplomacyManager.
func sync_ai_relations_from_diplomacy() -> void:
	if not DiplomacyManager or player_village == null:
		return
	for ai in ai_villages:
		var a = ai as AIVillage
		if a == null:
			continue
		a.relationship_with_player = DiplomacyManager.get_relation("player", a.village_id)
		a.at_war = DiplomacyManager.is_at_war("player", a.village_id)


## Player performs a diplomacy action toward an AI village. Emits diplomacy_updated.
func perform_diplomacy_action(action_type: int, ai_village_id: String) -> Dictionary:
	if not DiplomacyManager or player_village == null:
		return { "success": false, "message": "Diplomacy not available." }
	var result: Dictionary
	match action_type:
		GameConstants.DiplomacyAction.TRADE:
			result = DiplomacyManager.do_trade("player", ai_village_id)
		GameConstants.DiplomacyAction.REQUEST_ALLIANCE:
			result = DiplomacyManager.offer_alliance("player", ai_village_id)
		GameConstants.DiplomacyAction.DECLARE_WAR:
			result = DiplomacyManager.declare_war("player", ai_village_id)
		GameConstants.DiplomacyAction.REQUEST_AID:
			result = DiplomacyManager.request_aid("player", ai_village_id)
		_:
			return { "success": false, "message": "Unknown action." }
	sync_ai_relations_from_diplomacy()
	if EventBus:
		EventBus.diplomacy_updated.emit()
	return result


func get_relation_to_ai(ai_village_id: String) -> int:
	if not DiplomacyManager:
		return 0
	return DiplomacyManager.get_relation("player", ai_village_id)


func is_allied_with_ai(ai_village_id: String) -> bool:
	if not DiplomacyManager:
		return false
	return DiplomacyManager.is_allied("player", ai_village_id)


func is_at_war_with_ai(ai_village_id: String) -> bool:
	if not DiplomacyManager:
		return false
	return DiplomacyManager.is_at_war("player", ai_village_id)


## Return Village (player or AI) by village_id. Used by BattleManager.
func get_village_by_id(village_id: String) -> Village:
	if player_village != null and player_village.village_id == village_id:
		return player_village
	for ai in ai_villages:
		var v = ai as Village
		if v != null and v.village_id == village_id:
			return v
	return null


func check_victory_loss() -> void:
	# Stub for later: set game_state and emit game_over when conditions met.
	pass


## Restore full game state from a save data dictionary. Called by SaveManager.load().
func load_state(data: Dictionary) -> void:
	current_turn = data.get("current_turn", 0)
	game_state = data.get("game_state", GameConstants.GameState.PLAYING)
	var pd = data.get("player_village", {})
	if typeof(pd) == TYPE_DICTIONARY:
		player_village = Village.from_dict(pd)
		if _building_database:
			player_village.recalculate_max_population(_building_database)
			player_village.recalculate_military_strength(_building_database)
	ai_villages.clear()
	for ad in data.get("ai_villages", []):
		if typeof(ad) == TYPE_DICTIONARY:
			var ai = AIVillage.from_dict(ad)
			if _building_database:
				ai.recalculate_max_population(_building_database)
				ai.recalculate_military_strength(_building_database)
			ai_villages.append(ai)
	_tick_timer.start()


func save_game(path: String) -> bool:
	if SaveManager:
		return SaveManager.save(path)
	return false


func load_game(path: String) -> bool:
	if SaveManager:
		return SaveManager.load(path)
	return false


## Save to slot (1–3). Returns true on success.
func save_game_to_slot(slot: int) -> bool:
	if SaveManager:
		return SaveManager.save_to_slot(slot)
	return false


## Load from slot (1–3). Returns true on success.
func load_game_from_slot(slot: int) -> bool:
	if SaveManager:
		return SaveManager.load_from_slot(slot)
	return false
