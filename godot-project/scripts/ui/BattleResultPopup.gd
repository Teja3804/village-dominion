extends Control

## Displays battle result: attacker, defender, outcome, losses, rewards.
## Connects to EventBus.battle_resolved to show when a battle completes.

@onready var label_attacker: Label = $MarginContainer/VBox/LabelAttacker
@onready var label_defender: Label = $MarginContainer/VBox/LabelDefender
@onready var label_result: Label = $MarginContainer/VBox/LabelResult
@onready var label_losses: Label = $MarginContainer/VBox/LabelLosses
@onready var label_rewards: Label = $MarginContainer/VBox/LabelRewards
@onready var button_close: Button = $MarginContainer/VBox/ButtonClose

const RESOURCE_NAMES: Dictionary = {
	GameConstants.ResourceType.FOOD: "Food",
	GameConstants.ResourceType.WOOD: "Wood",
	GameConstants.ResourceType.GOLD: "Gold",
	GameConstants.ResourceType.STONE: "Stone",
	GameConstants.ResourceType.IRON: "Iron"
}


func _ready() -> void:
	if button_close:
		button_close.pressed.connect(_on_close_pressed)
	if EventBus:
		EventBus.battle_resolved.connect(_on_battle_resolved)
	visible = false


func _on_battle_resolved(result: Dictionary) -> void:
	if result.get("error", ""):
		label_result.text = result.error
		label_attacker.text = ""
		label_defender.text = ""
		label_losses.text = ""
		label_rewards.text = ""
	else:
		label_attacker.text = "Attacker: %s" % result.get("attacker_name", "?")
		label_defender.text = "Defender: %s" % result.get("defender_name", "?")
		var outcome: int = result.get("outcome", GameConstants.BattleResult.DRAW)
		match outcome:
			GameConstants.BattleResult.VICTORY:
				label_result.text = "Result: Attacker Victory"
			GameConstants.BattleResult.DEFEAT:
				label_result.text = "Result: Defender Victory"
			_:
				label_result.text = "Result: Draw"
		label_losses.text = "Losses: Attacker %d soldiers, Defender %d soldiers" % [
			result.get("attacker_losses", 0),
			result.get("defender_losses", 0)
		]
		var stolen: Dictionary = result.get("resources_stolen", {})
		if stolen.is_empty():
			label_rewards.text = "Rewards: —"
		else:
			var parts: PackedStringArray = []
			for res_type in stolen:
				var name_str = RESOURCE_NAMES.get(res_type, "?")
				parts.append("%d %s" % [stolen[res_type], name_str])
			label_rewards.text = "Stolen: " + ", ".join(parts)
	visible = true


func _on_close_pressed() -> void:
	visible = false
