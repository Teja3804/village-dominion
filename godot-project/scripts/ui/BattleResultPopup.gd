## BattleResultPopup.gd
## Shows battle result to the player.

extends Control

@onready var title_label: Label = $VBoxLayout/TitleLabel
@onready var result_label: RichTextLabel = $VBoxLayout/ResultLabel
@onready var ok_btn: Button = $VBoxLayout/OkButton

func _ready() -> void:
	if ok_btn:
		ok_btn.pressed.connect(func(): hide())

func show_result(result: Dictionary) -> void:
	var player_id = GameManager.player_village.village_id
	var player_attacked = result.get("attacker_id") == player_id

	var outcome = result.get("outcome", Constants.BattleOutcome.DRAW)
	var player_won = (player_attacked and outcome in [Constants.BattleOutcome.ATTACKER_WINS, Constants.BattleOutcome.ATTACKER_CAPTURES]) or \
					 (not player_attacked and outcome == Constants.BattleOutcome.DEFENDER_WINS)

	if title_label:
		title_label.text = "Victory!" if player_won else ("Draw" if outcome == Constants.BattleOutcome.DRAW else "Defeat!")

	if result_label:
		var attacker = GameManager.get_village_by_id(result.get("attacker_id", -1))
		var defender = GameManager.get_village_by_id(result.get("defender_id", -1))
		var attacker_name = attacker.village_name if attacker else "?"
		var defender_name = defender.village_name if defender else "?"

		var text = "[b]%s[/b]\n\n" % result.get("description", "Battle resolved.")
		text += "%s lost: %d soldiers\n" % [attacker_name, result.get("attacker_soldiers_lost", 0)]
		text += "%s lost: %d soldiers\n" % [defender_name, result.get("defender_soldiers_lost", 0)]

		var loot = result.get("resources_looted", {})
		if not loot.is_empty():
			text += "\nResources looted:\n"
			for res in loot:
				text += "  %d %s\n" % [loot[res], Constants.RESOURCE_NAMES[res]]

		result_label.text = text
