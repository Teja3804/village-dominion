extends RefCounted
class_name CombatResolver

## Stateless battle resolution. Input: strengths and type; output: winner, losses, pillage.
## Called by GameManager when a battle is triggered. No scene; pure logic.

func resolve_battle(attacker_strength: int, defender_strength: int, _battle_type: int) -> Dictionary:
	## Stub: return { "winner": "attacker"|"defender", "attacker_losses": int, "defender_losses": int, "pillage": {} }
	var winner = "attacker" if attacker_strength >= defender_strength else "defender"
	return {
		"winner": winner,
		"attacker_losses": 0,
		"defender_losses": 0,
		"pillage": {}
	}
