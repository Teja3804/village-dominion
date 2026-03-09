extends RefCounted
class_name DiplomacyManager

## Holds relationship state and applies diplomacy actions. No UI.
## Called by GameManager. Relationship map: ai_id -> { value, at_war, allied } or similar.

var _relationships: Dictionary = {}  # ai_village_id -> relationship value or struct


func get_relationship(ai_village_id: String) -> int:
	return _relationships.get(ai_village_id, {}).get("value", 0)


func set_relationship(ai_village_id: String, value: int) -> void:
	if not _relationships.has(ai_village_id):
		_relationships[ai_village_id] = {}
	_relationships[ai_village_id]["value"] = clampi(value, -100, 100)


func set_relationship_delta(ai_village_id: String, delta: int) -> void:
	var current = get_relationship(ai_village_id)
	set_relationship(ai_village_id, current + delta)


func is_at_war(ai_village_id: String) -> bool:
	return _relationships.get(ai_village_id, {}).get("at_war", false)


func set_at_war(ai_village_id: String, at_war: bool) -> void:
	if not _relationships.has(ai_village_id):
		_relationships[ai_village_id] = {}
	_relationships[ai_village_id]["at_war"] = at_war


func apply_action(_player_village: Village, _ai_village: AIVillage, _action_type: int, _params: Dictionary) -> Dictionary:
	## Stub: apply gift/trade/war; update relationships and resources. Return { "success": bool, "message": String }.
	return { "success": false, "message": "Not implemented" }


func to_dict() -> Dictionary:
	return { "relationships": _relationships.duplicate(true) }


func from_dict(d: Dictionary) -> void:
	_relationships = d.get("relationships", {}).duplicate(true)
