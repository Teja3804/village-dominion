extends Node

## Stat-based battle simulation. No real-time combat.
## Simulates outcome from attack_power vs defense_power, applies losses and rewards.
## Emits battle_resolved with result for UI.
##
## Example battle calculation:
##   Attacker: 6 soldiers, 1 Barracks -> attack_bonus = 2, random e.g. +1
##   Defender: 3 soldiers, 0 Barracks, 0 Walls -> defense_bonus = 0, random e.g. -2
##   attack_power  = 6 + 2 + 1 = 9
##   defense_power = 3 + 0 - 2 = 1
##   Outcome: Victory (9 > 1). Attacker loses 15% (0), defender loses 40% (1). Loot 15% resources.

signal battle_resolved(result: Dictionary)

# Formula constants
const ATTACK_BARRACKS_BONUS: int = 2
const DEFENSE_BARRACKS_BONUS: int = 1
const DEFENSE_WALL_BONUS: int = 3
const RANDOM_FACTOR_MIN: int = -3
const RANDOM_FACTOR_MAX: int = 3

# Casualty and loot (0.0–1.0 or counts)
const LOSER_SOLDIER_LOSS_RATE: float = 0.4
const WINNER_SOLDIER_LOSS_RATE: float = 0.15
const DRAW_SOLDIER_LOSS_RATE: float = 0.25
const RESOURCE_LOOT_RATE: float = 0.15
const RELATION_AFTER_BATTLE_DELTA: int = -5


func _ready() -> void:
	pass


## Run a battle: attacker vs defender. Gets villages from GameManager, computes outcome, applies effects.
## Returns result dict and emits battle_resolved(result).
func simulate_battle(attacker_id: String, defender_id: String) -> Dictionary:
	if not GameManager:
		return _empty_result("No GameManager")
	var attacker = GameManager.get_village_by_id(attacker_id)
	var defender = GameManager.get_village_by_id(defender_id)
	if attacker == null or defender == null:
		return _empty_result("Village not found")

	var b = GameConstants.BuildingType
	var attack_bonus = attacker.get_building_count(b.BARRACKS) * ATTACK_BARRACKS_BONUS
	var def_barracks = defender.get_building_count(b.BARRACKS) * DEFENSE_BARRACKS_BONUS
	var def_walls = defender.get_building_count(b.WALL) * DEFENSE_WALL_BONUS
	var defense_bonus = def_barracks + def_walls

	var attack_power = attacker.military_strength + attack_bonus + randi_range(RANDOM_FACTOR_MIN, RANDOM_FACTOR_MAX)
	var defense_power = defender.military_strength + defense_bonus + randi_range(RANDOM_FACTOR_MIN, RANDOM_FACTOR_MAX)
	attack_power = maxi(0, attack_power)
	defense_power = maxi(0, defense_power)

	var outcome: int
	if attack_power > defense_power:
		outcome = GameConstants.BattleResult.VICTORY
	elif attack_power < defense_power:
		outcome = GameConstants.BattleResult.DEFEAT
	else:
		outcome = GameConstants.BattleResult.DRAW

	var attacker_soldiers_before = attacker.military_strength
	var defender_soldiers_before = defender.military_strength
	var attacker_losses: int = 0
	var defender_losses: int = 0
	var resources_stolen: Dictionary = {}

	if outcome == GameConstants.BattleResult.VICTORY:
		attacker_losses = maxi(0, int(attacker_soldiers_before * WINNER_SOLDIER_LOSS_RATE))
		defender_losses = maxi(0, int(defender_soldiers_before * LOSER_SOLDIER_LOSS_RATE))
		resources_stolen = _steal_resources(defender, attacker, RESOURCE_LOOT_RATE)
	elif outcome == GameConstants.BattleResult.DEFEAT:
		attacker_losses = maxi(0, int(attacker_soldiers_before * LOSER_SOLDIER_LOSS_RATE))
		defender_losses = maxi(0, int(defender_soldiers_before * WINNER_SOLDIER_LOSS_RATE))
		resources_stolen = _steal_resources(attacker, defender, RESOURCE_LOOT_RATE)
	else:
		attacker_losses = maxi(0, int(attacker_soldiers_before * DRAW_SOLDIER_LOSS_RATE))
		defender_losses = maxi(0, int(defender_soldiers_before * DRAW_SOLDIER_LOSS_RATE))

	_apply_casualties(attacker, attacker_losses)
	_apply_casualties(defender, defender_losses)

	if DiplomacyManager:
		var rel = DiplomacyManager.get_relation(attacker_id, defender_id)
		DiplomacyManager.set_relation(attacker_id, defender_id, rel + RELATION_AFTER_BATTLE_DELTA)

	var result := {
		"attacker_id": attacker_id,
		"defender_id": defender_id,
		"attacker_name": attacker.display_name,
		"defender_name": defender.display_name,
		"outcome": outcome,
		"attack_power": attack_power,
		"defense_power": defense_power,
		"attacker_losses": attacker_losses,
		"defender_losses": defender_losses,
		"resources_stolen": resources_stolen
	}
	battle_resolved.emit(result)
	if EventBus:
		EventBus.battle_resolved.emit(result)
		EventBus.resources_changed.emit()
	return result


func _empty_result(msg: String) -> Dictionary:
	return {
		"attacker_id": "", "defender_id": "",
		"attacker_name": "", "defender_name": "",
		"outcome": GameConstants.BattleResult.DRAW,
		"attack_power": 0, "defense_power": 0,
		"attacker_losses": 0, "defender_losses": 0,
		"resources_stolen": {}, "error": msg
	}


func _steal_resources(from_village: Village, to_village: Village, rate: float) -> Dictionary:
	var r = GameConstants.ResourceType
	var stealable = [r.FOOD, r.WOOD, r.GOLD]
	var stolen := {}
	for res_type in stealable:
		var have = from_village.get_resource(res_type)
		var amount = maxi(0, int(have * rate))
		if amount <= 0:
			continue
		from_village.set_resource(res_type, have - amount)
		var to_have = to_village.get_resource(res_type)
		to_village.set_resource(res_type, to_have + amount)
		stolen[res_type] = amount
	return stolen


func _apply_casualties(village: Village, losses: int) -> void:
	village.military_strength = maxi(0, village.military_strength - losses)
