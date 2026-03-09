extends Control

## Shows one event (title, description, choice buttons). On choice, notifies EventManager/GameManager.

func _ready() -> void:
	# Hidden by default. Shown when EventBus.event_triggered emitted with event_data.
	if EventBus:
		EventBus.event_triggered.connect(_on_event_triggered)
	hide()


func _on_event_triggered(event_data: Dictionary) -> void:
	# TODO: set title, description, create choice buttons from event_data["choices"]; show()
	show()


func _on_choice_selected(choice_index: int) -> void:
	# TODO: call EventManager.apply_choice(choice_index); hide()
	hide()
