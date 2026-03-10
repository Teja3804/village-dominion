## ai_manager.gd
## Processes all AI village turns and delegates actions.

extends Node

func process_all_ai(all_villages: Array) -> void:
	for v in all_villages:
		if v is AIVillage and v.is_alive:
			_process_ai_village(v, all_villages)

func _process_ai_village(ai: AIVillage, all_villages: Array) -> void:
	var actions = ai.decide_turn(all_villages)

	for action in actions:
		match action.get("type", ""):
			"attack":
				var target = GameManager.get_village_by_id(action["target_id"])
				if target and target.is_alive:
					GameManager.battle_manager.execute_attack(ai, target)

			"declare_war":
				var target = GameManager.get_village_by_id(action["target_id"])
				if target and target.is_alive:
					ai.relationships[target.village_id] = -80
					target.relationships[ai.village_id] = -80
					EventBus.war_declared.emit(ai.village_id, target.village_id)
					if target.is_player:
						EventBus.notify("%s has declared war on you!" % ai.village_name, "danger")
					else:
						EventBus.notify("%s declared war on %s." % [ai.village_name, target.village_name], "warning")

			"build":
				var btype = action.get("building_type", -1)
				if btype >= 0:
					ai.construct_building(btype)

			"train_soldiers":
				var count = action.get("count", 3)
				ai.train_soldiers(count)

			_:
				# Delegate diplomacy actions
				action["actor_id"] = ai.village_id
				GameManager.diplomacy_manager.execute_ai_action(action, all_villages)
