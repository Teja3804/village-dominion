extends RefCounted
class_name EventManager

## When to fire events; holds pending event; applies choice effects. No UI.
## Called by GameManager. advance_turn() calls roll_for_event(); UI calls apply_choice().

var _event_definitions: Array = []  # EventDefinition resources or dicts
var _pending_event: Dictionary = {}  # { "event_id", "title", "description", "choices": [] }


func roll_for_event(_turn: int, _conditions: Dictionary) -> bool:
	## Stub: maybe set _pending_event and return true if event fired.
	return false


func get_pending_event() -> Dictionary:
	return _pending_event.duplicate(true)


func apply_choice(_choice_index: int) -> void:
	## Stub: apply effects (resource/relationship deltas) via GameManager; clear _pending_event.
	_pending_event = {}


func clear_pending() -> void:
	_pending_event = {}
