extends Node

## Central game state and orchestration. Single source of truth for runtime state.
## Owns game tick timer, player village, AI villages, and coordinates production/strength updates.
## UI and other systems read from here and request changes via methods.

var current_turn: int = 0
var game_state: int = GameConstants.GameState.PLAYING
var player_village: Village = null
var ai_villages: Array = []  # Array of AIVillage
var diplomacy_manager = null
var event_manager = null

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

	var ai1 = AIVillage.new()
	ai1.village_id = "ai_northbrook"
	ai1.display_name = "Northbrook"
	ai1.resources = { r.FOOD: 40, r.WOOD: 35, r.GOLD: 25, r.STONE: 15, r.IRON: 0 }
	ai1.population = 4
	ai1.max_population = 8
	ai1.military_strength = 0
	ai1.personality_type_id = p.MERCANTILE
	ai1.relationship_with_player = 0
	ai1.at_war = false
	var ai1_farm = BuildingInstance.new()
	ai1_farm.instance_id = "ai_northbrook_farm_0"
	ai1_farm.building_type_id = GameConstants.BuildingType.FARM
	ai1_farm.grid_x = 0
	ai1_farm.grid_y = 0
	ai1_farm.level = 1
	ai1_farm.assigned_workers = 2
	ai1.add_building(ai1_farm)
	ai1.recalculate_max_population(_building_database)
	ai1.recalculate_military_strength(_building_database)
	list.append(ai1)

	var ai2 = AIVillage.new()
	ai2.village_id = "ai_ironhold"
	ai2.display_name = "Ironhold"
	ai2.resources = { r.FOOD: 30, r.WOOD: 45, r.GOLD: 20, r.STONE: 25, r.IRON: 0 }
	ai2.population = 3
	ai2.max_population = 6
	ai2.military_strength = 0
	ai2.personality_type_id = p.AGGRESSIVE
	ai2.relationship_with_player = 0
	ai2.at_war = false
	var ai2_barracks = BuildingInstance.new()
	ai2_barracks.instance_id = "ai_ironhold_barracks_0"
	ai2_barracks.building_type_id = GameConstants.BuildingType.BARRACKS
	ai2_barracks.grid_x = 0
	ai2_barracks.grid_y = 0
	ai2_barracks.level = 1
	ai2.add_building(ai2_barracks)
	ai2.recalculate_max_population(_building_database)
	ai2.recalculate_military_strength(_building_database)
	list.append(ai2)

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

	current_turn += 1
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


func check_victory_loss() -> void:
	# Stub for later: set game_state and emit game_over when conditions met.
	pass


func save_game(path: String) -> bool:
	if SaveManager:
		return SaveManager.save(path)
	return false


func load_game(path: String) -> bool:
	if SaveManager:
		return SaveManager.load(path)
	return false
