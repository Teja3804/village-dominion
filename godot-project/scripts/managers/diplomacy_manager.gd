## diplomacy_manager.gd
## Handles all diplomacy actions between villages.

extends Node

func player_action(action: int, target_id: int, extra: Dictionary = {}) -> Dictionary:
	var player = GameManager.player_village
	var target = GameManager.get_village_by_id(target_id)

	if player == null or target == null:
		return {"success": false, "message": "Invalid target."}

	var response = {"success": false, "message": "", "action": action, "target_id": target_id}

	match action:
		Constants.DiplomacyAction.DECLARE_WAR:
			response = _declare_war(player, target)
		Constants.DiplomacyAction.PROPOSE_PEACE:
			response = _propose_peace(player, target)
		Constants.DiplomacyAction.PROPOSE_ALLIANCE:
			response = _propose_alliance(player, target)
		Constants.DiplomacyAction.BREAK_ALLIANCE:
			response = _break_alliance(player, target)
		Constants.DiplomacyAction.SEND_GIFT:
			response = _send_gift(player, target, extra.get("amount", 20))
		Constants.DiplomacyAction.REQUEST_AID:
			response = _request_aid(player, target)
		Constants.DiplomacyAction.PROPOSE_TRADE:
			response = _propose_trade(player, target, extra)
		Constants.DiplomacyAction.CANCEL_TRADE:
			response = _cancel_trade(player, target)
		Constants.DiplomacyAction.THREATEN:
			response = _threaten(player, target)

	EventBus.diplomacy_action_taken.emit(response)
	EventBus.notify(response.get("message", ""), "info")
	return response

func _declare_war(actor: Village, target: Village) -> Dictionary:
	actor.relationships[target.village_id] = -80
	target.relationships[actor.village_id] = -80
	# Remove alliance if any
	actor.agreements.erase(target.village_id)
	target.agreements.erase(actor.village_id)
	EventBus.war_declared.emit(actor.village_id, target.village_id)
	EventBus.relationship_changed.emit(actor.village_id, target.village_id, -80)
	return {
		"success": true,
		"message": "%s has declared war on %s!" % [actor.village_name, target.village_name]
	}

func _propose_peace(actor: Village, target: Village) -> Dictionary:
	if not actor.is_at_war_with(target.village_id):
		return {"success": false, "message": "You are not at war with %s." % target.village_name}

	# AI decides whether to accept based on their strength vs actor
	var accepts = _ai_considers_peace(target, actor)
	if accepts:
		actor.relationships[target.village_id] = -20
		target.relationships[actor.village_id] = -20
		actor.agreements.erase(target.village_id)
		target.agreements.erase(actor.village_id)
		EventBus.peace_agreed.emit(actor.village_id, target.village_id)
		return {"success": true, "message": "%s agreed to peace with you." % target.village_name}
	else:
		return {"success": false, "message": "%s refused your peace offer." % target.village_name}

func _propose_alliance(actor: Village, target: Village) -> Dictionary:
	if actor.is_at_war_with(target.village_id):
		return {"success": false, "message": "Cannot ally with an enemy. Make peace first."}

	if actor.is_allied_with(target.village_id):
		return {"success": false, "message": "Already allied with %s." % target.village_name}

	var accepts = _ai_considers_alliance(target, actor)
	if accepts:
		actor.relationships[target.village_id] = 75
		target.relationships[actor.village_id] = 75
		actor.agreements[target.village_id] = {"type": "alliance", "turns_left": -1}
		target.agreements[actor.village_id] = {"type": "alliance", "turns_left": -1}
		EventBus.alliance_formed.emit(actor.village_id, target.village_id)
		EventBus.relationship_changed.emit(actor.village_id, target.village_id, 75)
		return {"success": true, "message": "%s has joined your alliance!" % target.village_name}
	else:
		actor.change_relationship(target.village_id, -5)
		return {"success": false, "message": "%s declined your alliance offer." % target.village_name}

func _break_alliance(actor: Village, target: Village) -> Dictionary:
	if not actor.is_allied_with(target.village_id):
		return {"success": false, "message": "Not allied with %s." % target.village_name}

	actor.relationships[target.village_id] = -10
	target.relationships[actor.village_id] = -30  # betrayal hurts more for target
	actor.agreements.erase(target.village_id)
	target.agreements.erase(actor.village_id)
	EventBus.alliance_broken.emit(actor.village_id, target.village_id)
	return {"success": true, "message": "You broke your alliance with %s." % target.village_name}

func _send_gift(actor: Village, target: Village, gold_amount: int) -> Dictionary:
	if not actor.consume_resource(Constants.Resource.GOLD, gold_amount):
		return {"success": false, "message": "Not enough gold to send as gift."}

	target.add_resource(Constants.Resource.GOLD, gold_amount)
	actor.change_relationship(target.village_id, Constants.RELATION_CHANGE_GIFT)
	target.change_relationship(actor.village_id, Constants.RELATION_CHANGE_GIFT)
	EventBus.relationship_changed.emit(actor.village_id, target.village_id, actor.get_relationship(target.village_id))
	return {"success": true, "message": "Sent %d gold to %s. Relations improved." % [gold_amount, target.village_name]}

func _request_aid(actor: Village, target: Village) -> Dictionary:
	if not actor.is_allied_with(target.village_id):
		return {"success": false, "message": "Only allies will send aid."}

	var aid_food = min(50, target.get_resource(Constants.Resource.FOOD) / 4)
	var aid_gold = min(30, target.get_resource(Constants.Resource.GOLD) / 4)

	if aid_food == 0 and aid_gold == 0:
		return {"success": false, "message": "%s has nothing to spare." % target.village_name}

	target.consume_resource(Constants.Resource.FOOD, aid_food)
	target.consume_resource(Constants.Resource.GOLD, aid_gold)
	actor.add_resource(Constants.Resource.FOOD, aid_food)
	actor.add_resource(Constants.Resource.GOLD, aid_gold)
	actor.change_relationship(target.village_id, Constants.RELATION_CHANGE_AID)
	return {
		"success": true,
		"message": "%s sent you %d food and %d gold as aid." % [target.village_name, aid_food, aid_gold]
	}

func _propose_trade(actor: Village, target: Village, extra: Dictionary) -> Dictionary:
	if actor.is_at_war_with(target.village_id):
		return {"success": false, "message": "Cannot trade with enemies."}

	var accepts = _ai_considers_trade(target, actor, extra)
	if accepts:
		var route = {
			"resource_give": extra.get("resource_give", Constants.Resource.WOOD),
			"amount_give": extra.get("amount_give", 20),
			"resource_receive": extra.get("resource_receive", Constants.Resource.GOLD),
			"amount_receive": extra.get("amount_receive", 15)
		}
		actor.trade_routes[target.village_id] = route
		# Reverse route for target
		target.trade_routes[actor.village_id] = {
			"resource_give": route["resource_receive"],
			"amount_give": route["amount_receive"],
			"resource_receive": route["resource_give"],
			"amount_receive": route["amount_give"]
		}
		actor.change_relationship(target.village_id, Constants.RELATION_CHANGE_TRADE)
		target.change_relationship(actor.village_id, Constants.RELATION_CHANGE_TRADE)
		EventBus.trade_route_opened.emit(actor.village_id, target.village_id)
		return {"success": true, "message": "Trade route opened with %s." % target.village_name}
	else:
		return {"success": false, "message": "%s declined your trade offer." % target.village_name}

func _cancel_trade(actor: Village, target: Village) -> Dictionary:
	if not actor.trade_routes.has(target.village_id):
		return {"success": false, "message": "No active trade route with %s." % target.village_name}

	actor.trade_routes.erase(target.village_id)
	target.trade_routes.erase(actor.village_id)
	actor.change_relationship(target.village_id, -5)
	EventBus.trade_route_closed.emit(actor.village_id, target.village_id)
	return {"success": true, "message": "Trade route with %s cancelled." % target.village_name}

func _threaten(actor: Village, target: Village) -> Dictionary:
	var my_power = actor.get_attack_power()
	var their_defense = target.get_defense_power()

	if my_power > their_defense * 1.5:
		# Threat works — target backs down
		target.change_relationship(actor.village_id, -10)
		actor.change_relationship(target.village_id, Constants.RELATION_CHANGE_THREAT)
		return {"success": true, "message": "%s is intimidated by your threat." % target.village_name}
	else:
		# Threat fails — target is angered
		target.change_relationship(actor.village_id, -20)
		actor.change_relationship(target.village_id, -10)
		return {"success": false, "message": "%s laughed at your empty threat!" % target.village_name}

# --- AI acceptance logic ---

func _ai_considers_peace(ai: Village, proposer: Village) -> bool:
	# AI accepts peace if weaker or if diplomatic personality
	if ai is AIVillage:
		if ai.personality == Constants.Personality.DIPLOMATIC:
			return true
		if ai.personality == Constants.Personality.AGGRESSIVE:
			return ai.get_defense_power() < proposer.get_attack_power()
	return ai.soldiers < proposer.soldiers or randf() < 0.4

func _ai_considers_alliance(ai: Village, proposer: Village) -> bool:
	if ai is AIVillage:
		if ai.personality == Constants.Personality.AGGRESSIVE:
			return false
		if ai.personality == Constants.Personality.DIPLOMATIC:
			return ai.get_relationship(proposer.village_id) >= -10
	return ai.get_relationship(proposer.village_id) >= 10

func _ai_considers_trade(ai: Village, _proposer: Village, _extra: Dictionary) -> bool:
	if ai is AIVillage:
		if ai.personality == Constants.Personality.TRADER:
			return true
		if ai.personality == Constants.Personality.ISOLATIONIST:
			return false
	return ai.get_relationship(_proposer.village_id) >= -20

# Execute AI diplomacy action from ai_manager
func execute_ai_action(action: Dictionary, all_villages: Array) -> void:
	var actor_id = action.get("actor_id", -1)
	var target_id = action.get("target_id", -1)
	var actor: Village = null
	var target: Village = null
	for v in all_villages:
		if v.village_id == actor_id:
			actor = v
		if v.village_id == target_id:
			target = v
	if actor == null or target == null:
		return

	match action.get("type", ""):
		"declare_war":
			_declare_war(actor, target)
		"propose_alliance":
			if _ai_considers_alliance(target, actor):
				actor.relationships[target.village_id] = 75
				target.relationships[actor.village_id] = 75
				actor.agreements[target.village_id] = {"type": "alliance", "turns_left": -1}
				target.agreements[actor.village_id] = {"type": "alliance", "turns_left": -1}
				EventBus.alliance_formed.emit(actor.village_id, target.village_id)
		"propose_peace":
			if _ai_considers_peace(target, actor):
				actor.relationships[target.village_id] = -20
				target.relationships[actor.village_id] = -20
		"send_gift":
			var amount = action.get("amount", 20)
			if actor.consume_resource(Constants.Resource.GOLD, amount):
				target.add_resource(Constants.Resource.GOLD, amount)
				actor.change_relationship(target.village_id, Constants.RELATION_CHANGE_GIFT)
				target.change_relationship(actor.village_id, Constants.RELATION_CHANGE_GIFT)
				if target.is_player:
					EventBus.notify("%s sent you %d gold as a gift." % [actor.village_name, amount], "success")
		"propose_trade":
			if _ai_considers_trade(target, actor, action):
				var route = {
					"resource_give": action.get("resource_give", Constants.Resource.WOOD),
					"amount_give": action.get("amount_give", 20),
					"resource_receive": action.get("resource_receive", Constants.Resource.GOLD),
					"amount_receive": action.get("amount_receive", 15)
				}
				actor.trade_routes[target.village_id] = route
				target.trade_routes[actor.village_id] = {
					"resource_give": route["resource_receive"],
					"amount_give": route["amount_receive"],
					"resource_receive": route["resource_give"],
					"amount_receive": route["amount_give"]
				}
				if target.is_player:
					EventBus.notify("%s opened a trade route with you." % actor.village_name, "info")
