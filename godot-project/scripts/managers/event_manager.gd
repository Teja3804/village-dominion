extends Node

## Generates random world events every 5–10 ticks, applies effects, and notifies UI via EventBus.event_triggered.

const TICK_MIN: int = 5
const TICK_MAX: int = 10

# Effect magnitudes
const FAMINE_FOOD_LOSS: int = 18
const BANDIT_GOLD_LOSS: int = 25
const FESTIVAL_RELATION_BONUS: int = 5
const DISPUTE_RELATION_PENALTY: int = -10
const TRADE_BOOM_GOLD_BONUS: int = 35

var _last_event_turn: int = -999
var _next_event_in_ticks: int = 5


func _ready() -> void:
	_next_event_in_ticks = randi_range(TICK_MIN, TICK_MAX)


## Call from GameManager each turn. If it's time, roll an event, apply it, and emit event_triggered.
func check_and_trigger(current_turn: int) -> void:
	if current_turn < _last_event_turn + _next_event_in_ticks:
		return
	_last_event_turn = current_turn
	_next_event_in_ticks = randi_range(TICK_MIN, TICK_MAX)

	var event_type: int = _pick_random_event()
	var event_data: Dictionary = _build_event_data(event_type)
	_apply_effect(event_type, event_data)

	if EventBus:
		EventBus.event_triggered.emit(event_data)
		EventBus.resources_changed.emit()
	if DiplomacyManager and event_data.get("relation_affected", false):
		if GameManager:
			GameManager.sync_ai_relations_from_diplomacy()
		if EventBus:
			EventBus.diplomacy_updated.emit()


func _pick_random_event() -> int:
	var e = GameConstants.WorldEventType
	var choices: Array = [e.FAMINE, e.BANDIT_RAID, e.HARVEST_FESTIVAL, e.POLITICAL_DISPUTE, e.TRADE_BOOM]
	return choices[randi() % choices.size()]


func _build_event_data(event_type: int) -> Dictionary:
	var e = GameConstants.WorldEventType
	match event_type:
		e.FAMINE:
			return {
				"event_type": event_type,
				"title": "Famine",
				"description": "Poor harvests have struck the region. Food stores are depleted.",
				"effects": "",
				"relation_affected": false
			}
		e.BANDIT_RAID:
			return {
				"event_type": event_type,
				"title": "Bandit Raid",
				"description": "Marauders have raided your village and made off with gold.",
				"effects": "",
				"relation_affected": false
			}
		e.HARVEST_FESTIVAL:
			return {
				"event_type": event_type,
				"title": "Harvest Festival",
				"description": "A shared harvest festival improves relations with neighboring villages.",
				"effects": "",
				"relation_affected": true
			}
		e.POLITICAL_DISPUTE:
			return {
				"event_type": event_type,
				"title": "Political Dispute",
				"description": "A border or trade dispute has soured relations with a neighboring village.",
				"effects": "",
				"relation_affected": true
			}
		e.TRADE_BOOM:
			return {
				"event_type": event_type,
				"title": "Trade Boom",
				"description": "Merchants are paying premium prices. Your market brings in extra gold.",
				"effects": "",
				"relation_affected": false
			}
	return { "event_type": event_type, "title": "Event", "description": "", "effects": "", "relation_affected": false }


func _apply_effect(event_type: int, event_data: Dictionary) -> void:
	if not GameManager or not GameManager.player_village:
		return
	var r = GameConstants.ResourceType
	var player = GameManager.player_village
	var e = GameConstants.WorldEventType

	match event_type:
		e.FAMINE:
			var have = player.get_resource(r.FOOD)
			var loss = mini(FAMINE_FOOD_LOSS, have)
			player.set_resource(r.FOOD, have - loss)
			event_data["effects"] = "Food -%d" % loss
		e.BANDIT_RAID:
			var have = player.get_resource(r.GOLD)
			var loss = mini(BANDIT_GOLD_LOSS, have)
			player.set_resource(r.GOLD, have - loss)
			event_data["effects"] = "Gold -%d" % loss
		e.HARVEST_FESTIVAL:
			if DiplomacyManager and GameManager.ai_villages.size() > 0:
				for ai in GameManager.ai_villages:
					var a = ai as AIVillage
					if a:
						DiplomacyManager.add_relation_delta("player", a.village_id, FESTIVAL_RELATION_BONUS)
			event_data["effects"] = "Relation with all villages +%d" % FESTIVAL_RELATION_BONUS
		e.POLITICAL_DISPUTE:
			if DiplomacyManager and GameManager.ai_villages.size() > 0:
				var ai = GameManager.ai_villages[randi() % GameManager.ai_villages.size()] as AIVillage
				if ai:
					DiplomacyManager.add_relation_delta("player", ai.village_id, DISPUTE_RELATION_PENALTY)
					event_data["effects"] = "Relation with %s %d" % [ai.display_name, DISPUTE_RELATION_PENALTY]
					event_data["target_village"] = ai.display_name
			else:
				event_data["effects"] = "Relation -10 with a village"
		e.TRADE_BOOM:
			var have = player.get_resource(r.GOLD)
			player.set_resource(r.GOLD, have + TRADE_BOOM_GOLD_BONUS)
			event_data["effects"] = "Gold +%d" % TRADE_BOOM_GOLD_BONUS
