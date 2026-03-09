extends RefCounted
class_name BuildingInstance

## Runtime data for one placed building. No logic; serializable via to_dict/from_dict.

var instance_id: String = ""
var building_type_id: int = 0  # GameConstants.BuildingType
var grid_x: int = 0
var grid_y: int = 0
var level: int = 1
var assigned_workers: int = 0


func to_dict() -> Dictionary:
	return {
		"instance_id": instance_id,
		"building_type_id": building_type_id,
		"grid_x": grid_x,
		"grid_y": grid_y,
		"level": level,
		"assigned_workers": assigned_workers
	}


static func from_dict(d: Dictionary) -> BuildingInstance:
	var inst = BuildingInstance.new()
	inst.instance_id = d.get("instance_id", "")
	inst.building_type_id = d.get("building_type_id", 0)
	inst.grid_x = d.get("grid_x", 0)
	inst.grid_y = d.get("grid_y", 0)
	inst.level = d.get("level", 1)
	inst.assigned_workers = d.get("assigned_workers", 0)
	return inst
