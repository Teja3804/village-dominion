## GameManager.gd
## Central game orchestrator. Autoloaded as "GameManager".
## Manages turn flow, all villages, and delegates to sub-managers.

extends Node

const VILLAGE_NAMES = [
	"Ironhollow", "Ashveil", "Stonemark", "Emberfall",
	"Duskridge", "Thornwick", "Coldwater", "Sablecrest"
]
const LEADER_NAMES = [
	"Chief Aldric", "Warlord Draven", "Councilor Mira", "Elder Orin",
	"Baron Serath", "Lady Vex", "Governor Holt", "Chieftain Bram"
]

# Sub-systems
var building_db: BuildingDatabase
var battle_manager: Node
var diplomacy_manager: Node
var event_manager: Node
var ai_manager: Node

# State
var all_villages: Array = []         # Array of Village / AIVillage
var player_village: Village = null
var current_turn: int = 0
var current_year: int = 1
var game_running: bool = false

func _ready() -> void:
	building_db = BuildingDatabase.new()
	add_child(building_db)

	battle_manager = load("res://scripts/managers/battle_manager.gd").new()
	add_child(battle_manager)

	diplomacy_manager = load("res://scripts/managers/diplomacy_manager.gd").new()
	add_child(diplomacy_manager)

	event_manager = load("res://scripts/managers/event_manager.gd").new()
	add_child(event_manager)

	ai_manager = load("res://scripts/managers/ai_manager.gd").new()
	add_child(ai_manager)

func new_game() -> void:
	all_villages.clear()
	current_turn = 0
	current_year = 1

	# Create player village
	var pv = Village.new()
	pv.village_id = 0
	pv.village_name = "Your Village"
	pv.leader_name = "You"
	pv.is_player = true
	pv._initialize_resources()
	# Start with Town Hall
	pv.buildings.append({"type": Constants.BuildingType.TOWN_HALL, "level": 1})
	pv.buildings.append({"type": Constants.BuildingType.FARM, "level": 1})
	pv.buildings.append({"type": Constants.BuildingType.HOUSE, "level": 1})
	add_child(pv)
	player_village = pv
	all_villages.append(pv)

	# Create AI villages
	var personalities = [
		Constants.Personality.AGGRESSIVE,
		Constants.Personality.DIPLOMATIC,
		Constants.Personality.TRADER,
		Constants.Personality.OPPORTUNIST,
		Constants.Personality.ISOLATIONIST,
		Constants.Personality.AGGRESSIVE,
		Constants.Personality.DIPLOMATIC
	]

	for i in range(min(7, Constants.MAX_VILLAGES - 1)):
		var av = AIVillage.new()
		av.setup(i + 1, VILLAGE_NAMES[i + 1], LEADER_NAMES[i + 1], personalities[i])
		av._initialize_resources()
		av.buildings.append({"type": Constants.BuildingType.TOWN_HALL, "level": 1})
		av.buildings.append({"type": Constants.BuildingType.FARM, "level": 1})
		add_child(av)
		all_villages.append(av)

	# Initialize all relationships to neutral
	for v in all_villages:
		for other in all_villages:
			if v.village_id != other.village_id:
				v.relationships[other.village_id] = 0

	game_running = true
	EventBus.turn_started.emit(current_turn)
	EventBus.notify("Welcome to Village Dominion! Build, expand, and conquer.", "info")

func end_turn() -> void:
	if not game_running:
		return

	EventBus.turn_ended.emit(current_turn)
	current_turn += 1

	# Process all villages
	for v in all_villages:
		if v.is_alive:
			v.process_turn()

	# AI decisions
	ai_manager.process_all_ai(all_villages)

	# World events
	event_manager.roll_events(all_villages, current_turn)

	# Relationship decay toward neutral
	_process_relationship_decay()

	# Year change
	if current_turn % Constants.TURNS_PER_YEAR == 0:
		current_year += 1
		EventBus.year_changed.emit(current_year)
		EventBus.notify("Year %d has begun." % current_year, "info")

	# Check win/loss
	_check_game_over()

	if game_running:
		EventBus.turn_started.emit(current_turn)
		EventBus.player_village_updated.emit()

func _process_relationship_decay() -> void:
	for v in all_villages:
		for other_id in v.relationships:
			var score = v.relationships[other_id]
			if score > 0:
				v.relationships[other_id] = max(0, score - Constants.RELATION_DECAY_PER_TURN)
			elif score < 0:
				v.relationships[other_id] = min(0, score + Constants.RELATION_DECAY_PER_TURN)

func _check_game_over() -> void:
	if player_village == null or not player_village.is_alive:
		game_running = false
		EventBus.game_over.emit("Your village was conquered.", false)
		return

	# Win condition: survive 10 years (120 turns)
	if current_turn >= Constants.MAX_TURNS:
		game_running = false
		EventBus.game_over.emit("You survived 10 years and became a legend!", true)
		return

	# Win condition: conquer all other villages
	var alive_enemies = 0
	for v in all_villages:
		if v.village_id != player_village.village_id and v.is_alive:
			alive_enemies += 1
	if alive_enemies == 0:
		game_running = false
		EventBus.game_over.emit("You conquered the entire world!", true)

func get_village_by_id(vid: int) -> Village:
	for v in all_villages:
		if v.village_id == vid:
			return v
	return null

func get_alive_villages() -> Array:
	var alive = []
	for v in all_villages:
		if v.is_alive:
			alive.append(v)
	return alive

func get_ai_villages() -> Array:
	var ai = []
	for v in all_villages:
		if not v.is_player and v.is_alive:
			ai.append(v)
	return ai
