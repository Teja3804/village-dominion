## CombatResolver.gd
## Handles battle simulation between villages.

class_name CombatResolver
extends RefCounted

static func resolve_battle(attacker: Village, defender: Village) -> Dictionary:
	var attack_power = attacker.get_attack_power()
	var defense_power = defender.get_defense_power()

	var result = {
		"outcome": Constants.BattleOutcome.DRAW,
		"attacker_id": attacker.village_id,
		"defender_id": defender.village_id,
		"attacker_soldiers_lost": 0,
		"defender_soldiers_lost": 0,
		"resources_looted": {},
		"description": ""
	}

	# Determine outcome
	var ratio = float(attack_power) / max(1.0, float(defense_power))

	if ratio >= 2.0:
		# Decisive attacker victory — village captured
		result["outcome"] = Constants.BattleOutcome.ATTACKER_CAPTURES
		result["description"] = "%s has been CAPTURED by %s!" % [defender.village_name, attacker.village_name]
		result["attacker_soldiers_lost"] = int(attacker.soldiers * 0.15)
		result["defender_soldiers_lost"] = defender.soldiers
		result["resources_looted"] = _calculate_loot(defender, 0.6)
	elif ratio >= 1.2:
		# Attacker wins
		result["outcome"] = Constants.BattleOutcome.ATTACKER_WINS
		result["description"] = "%s defeated %s in battle!" % [attacker.village_name, defender.village_name]
		result["attacker_soldiers_lost"] = int(attacker.soldiers * 0.2)
		result["defender_soldiers_lost"] = int(defender.soldiers * 0.4)
		result["resources_looted"] = _calculate_loot(defender, 0.3)
	elif ratio <= 0.5:
		# Decisive defender victory
		result["outcome"] = Constants.BattleOutcome.DEFENDER_WINS
		result["description"] = "%s repelled %s's attack decisively!" % [defender.village_name, attacker.village_name]
		result["attacker_soldiers_lost"] = int(attacker.soldiers * 0.5)
		result["defender_soldiers_lost"] = int(defender.soldiers * 0.1)
	elif ratio <= 0.8:
		# Defender wins
		result["outcome"] = Constants.BattleOutcome.DEFENDER_WINS
		result["description"] = "%s repelled %s's attack." % [defender.village_name, attacker.village_name]
		result["attacker_soldiers_lost"] = int(attacker.soldiers * 0.3)
		result["defender_soldiers_lost"] = int(defender.soldiers * 0.15)
	else:
		# Draw
		result["outcome"] = Constants.BattleOutcome.DRAW
		result["description"] = "Battle between %s and %s ended in a draw." % [attacker.village_name, defender.village_name]
		result["attacker_soldiers_lost"] = int(attacker.soldiers * 0.2)
		result["defender_soldiers_lost"] = int(defender.soldiers * 0.2)

	# Apply losses
	attacker.lose_soldiers(result["attacker_soldiers_lost"])
	defender.lose_soldiers(result["defender_soldiers_lost"])

	# Apply loot
	for res in result["resources_looted"]:
		var amount = result["resources_looted"][res]
		defender.consume_resource(res, amount)
		attacker.add_resource(res, amount)

	# Apply relationship penalty
	attacker.change_relationship(defender.village_id, Constants.RELATION_CHANGE_WAR_WIN
		if result["outcome"] != Constants.BattleOutcome.DEFENDER_WINS else Constants.RELATION_CHANGE_WAR_LOSE)
	defender.change_relationship(attacker.village_id, -20)

	# Track stats
	if result["outcome"] in [Constants.BattleOutcome.ATTACKER_WINS, Constants.BattleOutcome.ATTACKER_CAPTURES]:
		attacker.total_battles_won += 1
		defender.total_battles_lost += 1
	elif result["outcome"] == Constants.BattleOutcome.DEFENDER_WINS:
		defender.total_battles_won += 1
		attacker.total_battles_lost += 1

	# Morale impacts
	match result["outcome"]:
		Constants.BattleOutcome.ATTACKER_WINS, Constants.BattleOutcome.ATTACKER_CAPTURES:
			attacker.morale = min(100, attacker.morale + 10)
			defender.morale = max(0, defender.morale - 20)
		Constants.BattleOutcome.DEFENDER_WINS:
			defender.morale = min(100, defender.morale + 10)
			attacker.morale = max(0, attacker.morale - 15)

	# Check if defender is destroyed
	if result["outcome"] == Constants.BattleOutcome.ATTACKER_CAPTURES:
		defender.is_alive = false
		defender.village_destroyed.emit(defender)

	return result

static func _calculate_loot(village: Village, fraction: float) -> Dictionary:
	var loot = {}
	for res in village.resources:
		var amount = int(village.resources[res] * fraction)
		if amount > 0:
			loot[res] = amount
	return loot
