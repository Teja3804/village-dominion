## battle_manager.gd
## Processes battle requests and emits results.

extends Node

func execute_attack(attacker: Village, defender: Village) -> Dictionary:
	if attacker == null or defender == null:
		return {}
	if not attacker.is_alive or not defender.is_alive:
		return {}

	EventBus.battle_started.emit(attacker.village_id, defender.village_id)

	# Force war state
	if attacker.get_relationship(defender.village_id) > Constants.RELATION_WAR:
		attacker.relationships[defender.village_id] = Constants.RELATION_WAR
		defender.relationships[attacker.village_id] = Constants.RELATION_WAR

	var result = CombatResolver.resolve_battle(attacker, defender)

	EventBus.battle_resolved.emit(result)

	var outcome_text = _outcome_text(result["outcome"])
	EventBus.notify("%s attacked %s — %s" % [
		attacker.village_name, defender.village_name, outcome_text
	], _outcome_severity(result["outcome"]))

	return result

func player_attack(target_id: int) -> Dictionary:
	var player = GameManager.player_village
	var target = GameManager.get_village_by_id(target_id)

	if player == null or target == null:
		EventBus.notify("Invalid attack target.", "warning")
		return {}

	if player.soldiers <= 0:
		EventBus.notify("You have no soldiers to attack with!", "warning")
		return {}

	return execute_attack(player, target)

func _outcome_text(outcome: int) -> String:
	match outcome:
		Constants.BattleOutcome.ATTACKER_WINS:
			return "Victory!"
		Constants.BattleOutcome.DEFENDER_WINS:
			return "Defeat!"
		Constants.BattleOutcome.DRAW:
			return "Draw!"
		Constants.BattleOutcome.ATTACKER_CAPTURES:
			return "Village Captured!"
		_:
			return "Unknown"

func _outcome_severity(outcome: int) -> String:
	match outcome:
		Constants.BattleOutcome.ATTACKER_WINS, Constants.BattleOutcome.ATTACKER_CAPTURES:
			return "success"
		Constants.BattleOutcome.DEFENDER_WINS:
			return "danger"
		_:
			return "warning"
