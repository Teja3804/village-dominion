extends Node

## Tracks relationships between villages. Range -100 (enemy) to 100 (ally).
## Handles diplomacy actions: Trade, Offer Alliance, Declare War, Request Aid.
## No battle resolution; war only updates relationship state.

# Relation deltas per action
const TRADE_RELATION_DELTA: int = 10
const ALLIANCE_MIN_RELATION: int = 50
const WAR_RELATION_VALUE: int = -100
const REQUEST_AID_RELATION_DELTA: int = 5

var _relations: Dictionary = {}   # "id1|id2" (sorted) -> score (-100 to 100)
var _alliances: Dictionary = {}    # "id1|id2" (sorted) -> true
var _at_war: Dictionary = {}       # "id1|id2" (sorted) -> true


func _ready() -> void:
	pass


static func _pair_key(id_a: String, id_b: String) -> String:
	if id_a < id_b:
		return id_a + "|" + id_b
	return id_b + "|" + id_a


## Initialize relations for all villages. Call at game start.
func init_relations(player_id: String, ai_village_ids: Array) -> void:
	_relations.clear()
	_alliances.clear()
	_at_war.clear()
	var all_ids: Array = [player_id]
	for id in ai_village_ids:
		all_ids.append(id)
	for i in range(all_ids.size()):
		for j in range(i + 1, all_ids.size()):
			var key = _pair_key(all_ids[i], all_ids[j])
			_relations[key] = 0
			_alliances[key] = false
			_at_war[key] = false


func get_relation(from_id: String, to_id: String) -> int:
	var key = _pair_key(from_id, to_id)
	return _relations.get(key, 0)


func set_relation(from_id: String, to_id: String, value: int) -> void:
	var key = _pair_key(from_id, to_id)
	_relations[key] = clampi(value, -100, 100)
	if value <= WAR_RELATION_VALUE:
		_at_war[key] = true
	else:
		_at_war[key] = false


func add_relation_delta(from_id: String, to_id: String, delta: int) -> void:
	var current = get_relation(from_id, to_id)
	set_relation(from_id, to_id, current + delta)


func is_allied(id_a: String, id_b: String) -> bool:
	var key = _pair_key(id_a, id_b)
	return _alliances.get(key, false)


func set_alliance(id_a: String, id_b: String, allied: bool) -> void:
	var key = _pair_key(id_a, id_b)
	_alliances[key] = allied


func is_at_war(id_a: String, id_b: String) -> bool:
	var key = _pair_key(id_a, id_b)
	return _at_war.get(key, false)


## Export relations, alliances, at_war for save. Keys are strings (pair_key).
func export_state() -> Dictionary:
	return {
		"relations": _relations.duplicate(),
		"alliances": _alliances.duplicate(),
		"at_war": _at_war.duplicate()
	}


## Restore state from save. Call after GameManager has restored villages.
func import_state(d: Dictionary) -> void:
	_relations = d.get("relations", {}).duplicate()
	_alliances = d.get("alliances", {}).duplicate()
	_at_war = d.get("at_war", {}).duplicate()


## Player trades with AI. Relation +10. Returns true if applied.
func do_trade(from_id: String, to_id: String) -> Dictionary:
	add_relation_delta(from_id, to_id, TRADE_RELATION_DELTA)
	return { "success": true, "message": "Trade completed. Relation improved." }


## Offer alliance. Requires relation > 50. Returns { success, message }.
func offer_alliance(offerer_id: String, target_id: String) -> Dictionary:
	var rel = get_relation(offerer_id, target_id)
	if rel < ALLIANCE_MIN_RELATION:
		return { "success": false, "message": "Relation too low (need > %d)." % ALLIANCE_MIN_RELATION }
	set_alliance(offerer_id, target_id, true)
	return { "success": true, "message": "Alliance offered and accepted." }


## Declare war. Sets relation to -100 and at_war, then triggers one battle simulation.
func declare_war(declarer_id: String, target_id: String) -> Dictionary:
	var key = _pair_key(declarer_id, target_id)
	set_relation(declarer_id, target_id, WAR_RELATION_VALUE)
	_at_war[key] = true
	set_alliance(declarer_id, target_id, false)
	if BattleManager:
		BattleManager.simulate_battle(declarer_id, target_id)
	return { "success": true, "message": "War declared." }


## Request aid. Relation +5 if "accepted" (simple roll for now).
func request_aid(requester_id: String, target_id: String) -> Dictionary:
	var rel = get_relation(requester_id, target_id)
	# Higher relation = more likely to accept
	var accept_chance = (rel + 100) / 200.0
	if randf() <= accept_chance:
		add_relation_delta(requester_id, target_id, REQUEST_AID_RELATION_DELTA)
		return { "success": true, "message": "Aid granted. Relation improved." }
	return { "success": false, "message": "Request refused." }
