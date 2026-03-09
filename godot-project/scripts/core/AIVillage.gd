extends Village
class_name AIVillage

## AI village: Village state plus personality and relationship to player.
## Used only for AI-controlled villages. Serializable.

var personality_type_id: int = 0  # GameConstants.PersonalityType
var relationship_with_player: int = 0  # -100 to 100
var at_war: bool = false


func get_relationship() -> int:
	return relationship_with_player


func set_relationship_delta(delta: int) -> void:
	relationship_with_player = clampi(relationship_with_player + delta, -100, 100)


func decide_response(_action: int, _params: Dictionary) -> Dictionary:
	## Stub: return { "accepted": bool, "counter_offer": optional }. Called by GameManager/DiplomacyManager.
	return { "accepted": false }


func to_dict() -> Dictionary:
	var d = super.to_dict()
	d["personality_type_id"] = personality_type_id
	d["relationship_with_player"] = relationship_with_player
	d["at_war"] = at_war
	return d


static func from_dict(d: Dictionary) -> AIVillage:
	var v = AIVillage.new()
	v.village_id = d.get("village_id", "")
	v.display_name = d.get("display_name", "")
	var raw_res = d.get("resources", {})
	v.resources = {}
	for k in raw_res:
		v.resources[int(k)] = raw_res[k]
	v.population = d.get("population", 0)
	v.max_population = d.get("max_population", 0)
	v.military_strength = d.get("military_strength", 0)
	v.personality_type_id = d.get("personality_type_id", 0)
	v.relationship_with_player = d.get("relationship_with_player", 0)
	v.at_war = d.get("at_war", false)
	for b in d.get("building_instances", []):
		v.building_instances.append(BuildingInstance.from_dict(b))
	return v
