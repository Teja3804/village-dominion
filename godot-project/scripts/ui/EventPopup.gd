extends Control

## Displays world event title, description, and effects. Shown when EventBus.event_triggered is emitted.

@onready var title_label: Label = $Background/MarginContainer/VBox/TitleLabel
@onready var desc_label: Label = $Background/MarginContainer/VBox/DescLabel
@onready var effects_label: Label = $Background/MarginContainer/VBox/EffectsLabel
@onready var button_close: Button = $Background/MarginContainer/VBox/ButtonClose


func _ready() -> void:
	visible = false
	if EventBus:
		EventBus.event_triggered.connect(_on_event_triggered)
	if button_close:
		button_close.pressed.connect(_on_close_pressed)


func _on_event_triggered(event_data: Dictionary) -> void:
	if title_label:
		title_label.text = event_data.get("title", "World Event")
	if desc_label:
		desc_label.text = event_data.get("description", "")
	if effects_label:
		var effects: String = event_data.get("effects", "")
		effects_label.text = "Effects: " + (effects if effects else "—")
	visible = true


func _on_close_pressed() -> void:
	visible = false
