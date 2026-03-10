## GameOverScreen.gd
## Win/Lose screen shown at end of game.

extends Control

@onready var title_label: Label = $VBoxLayout/TitleLabel
@onready var reason_label: Label = $VBoxLayout/ReasonLabel
@onready var stats_label: Label = $VBoxLayout/StatsLabel
@onready var new_game_btn: Button = $VBoxLayout/ButtonRow/NewGameButton
@onready var quit_btn: Button = $VBoxLayout/ButtonRow/QuitButton

func _ready() -> void:
	if new_game_btn:
		new_game_btn.pressed.connect(_on_new_game)
	if quit_btn:
		quit_btn.pressed.connect(func(): get_tree().quit())
	hide()

func show_result(reason: String, player_won: bool) -> void:
	if title_label:
		title_label.text = "VICTORY!" if player_won else "DEFEATED"
		title_label.add_theme_color_override("font_color",
			Color(1.0, 0.9, 0.2) if player_won else Color(1.0, 0.3, 0.3))

	if reason_label:
		reason_label.text = reason

	if stats_label:
		var v = GameManager.player_village
		if v:
			stats_label.text = (
				"Final Stats:\n" +
				"Turns Survived: %d\n" +
				"Battles Won: %d\n" +
				"Battles Lost: %d\n" +
				"Gold Earned: %d\n" +
				"Village Level: %d"
			) % [v.turn_number, v.total_battles_won, v.total_battles_lost, v.total_gold_earned, v.village_level]

func _on_new_game() -> void:
	hide()
	# Clear and restart
	for v in GameManager.all_villages:
		v.queue_free()
	GameManager.all_villages.clear()
	GameManager.player_village = null
	GameManager.new_game()
