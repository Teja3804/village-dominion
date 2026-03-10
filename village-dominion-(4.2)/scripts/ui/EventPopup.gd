## EventPopup.gd
## Shows a world event popup to the player.

extends Control

@onready var title_label: Label = $TitleLabel
@onready var description_label: Label = $DescriptionLabel
@onready var ok_btn: Button = $OkButton

func _ready() -> void:
	if ok_btn:
		ok_btn.pressed.connect(func(): hide())

func show_event(event: Dictionary) -> void:
	if title_label:
		title_label.text = event.get("name", "Event")
	if description_label:
		description_label.text = event.get("description", "")
