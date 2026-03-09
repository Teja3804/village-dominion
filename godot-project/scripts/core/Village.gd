extends RefCounted
class_name Village

## One village's state: buildings, resources, population, military.
## Used for both player and AI villages. Serializable for save/load.
## Production and strength are computed from building instances and definitions.

var village_id: String = ""
var display_name: String = ""
var building_instances: Array = []  # Array of BuildingInstance
var resources: Dictionary = {}  # GameConstants.ResourceType (int) -> amount (int)
var population: int = 0
var max_population: int = 0
var military_strength: int = 0


func add_building(inst: BuildingInstance) -> void:
	building_instances.append(inst)


func remove_building(instance_id: String) -> void:
	for i in range(building_instances.size() - 1, -1, -1):
		if building_instances[i].instance_id == instance_id:
			building_instances.remove_at(i)
			return


func get_building(instance_id: String) -> BuildingInstance:
	for inst in building_instances:
		if inst.instance_id == instance_id:
			return inst
	return null


## Number of buildings of this type (by building_type_id). Used for UI and auto-placement.
func get_building_count(building_type_id: int) -> int:
	var count := 0
	for inst in building_instances:
		if inst.building_type_id == building_type_id:
			count += 1
	return count


## Compute total production per tick from all buildings. Uses assigned_workers or level.
func get_production_per_tick(building_db: BuildingDatabase) -> Dictionary:
	var total: Dictionary = {}
	for inst in building_instances:
		var def = building_db.get_definition(inst.building_type_id)
		if def == null or def.production.is_empty():
			continue
		var workers: int = mini(inst.assigned_workers, def.worker_slots) if def.worker_slots > 0 else 1
		if workers <= 0:
			continue
		var prod = def.get_production_at_level(inst.level)
		for res_type in prod:
			if not total.has(res_type):
				total[res_type] = 0
			total[res_type] += prod[res_type] * workers
	return total


## Add production dict to village resources. Does not clamp; caller can clamp if needed.
func apply_production(production_dict: Dictionary) -> void:
	for res_type in production_dict:
		if not resources.has(res_type):
			resources[res_type] = 0
		resources[res_type] += production_dict[res_type]


## Set max_population from buildings that contribute population cap (Town Hall, House, etc.).
func recalculate_max_population(building_db: BuildingDatabase) -> void:
	var cap: int = 0
	for inst in building_instances:
		var def = building_db.get_definition(inst.building_type_id)
		if def != null and def.population_cap_contribution > 0:
			cap += def.population_cap_contribution * inst.level
	max_population = maxi(cap, 0)
	if population > max_population and max_population > 0:
		population = max_population


## Set military_strength from Barracks (and future military buildings).
func recalculate_military_strength(building_db: BuildingDatabase) -> void:
	var strength: int = 0
	for inst in building_instances:
		var def = building_db.get_definition(inst.building_type_id)
		if def != null and def.military_per_level > 0:
			strength += def.military_per_level * inst.level
	military_strength = maxi(strength, 0)


## Apply one tick of consumption (e.g. food per population). Call after production.
func apply_food_consumption(food_per_pop: int = 1) -> void:
	var r = GameConstants.ResourceType
	if not resources.has(r.FOOD):
		resources[r.FOOD] = 0
	resources[r.FOOD] -= population * food_per_pop


func get_resource(resource_type: int) -> int:
	return resources.get(resource_type, 0)


func set_resource(resource_type: int, amount: int) -> void:
	resources[resource_type] = amount


func to_dict() -> Dictionary:
	var buildings_data = []
	for inst in building_instances:
		buildings_data.append(inst.to_dict())
	return {
		"village_id": village_id,
		"display_name": display_name,
		"building_instances": buildings_data,
		"resources": resources.duplicate(),
		"population": population,
		"max_population": max_population,
		"military_strength": military_strength
	}


static func from_dict(d: Dictionary) -> Village:
	var v = Village.new()
	v.village_id = d.get("village_id", "")
	v.display_name = d.get("display_name", "")
	var raw_res = d.get("resources", {})
	v.resources = {}
	for k in raw_res:
		v.resources[int(k)] = raw_res[k]
	v.population = d.get("population", 0)
	v.max_population = d.get("max_population", 0)
	v.military_strength = d.get("military_strength", 0)
	for b in d.get("building_instances", []):
		v.building_instances.append(BuildingInstance.from_dict(b))
	return v
