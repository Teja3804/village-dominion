extends Control

## Save/Load/Delete menu with 3 slots. Shows slot label (e.g. "Slot 1: Day 12" or "Slot 1: Empty").

const NUM_SLOTS: int = 3

@onready var slot_list: VBoxContainer = $Background/MarginContainer/VBox/ScrollContainer/SlotList
@onready var title_label: Label = $Background/MarginContainer/VBox/TitleRow/TitleLabel
@onready var close_button: Button = $Background/MarginContainer/VBox/TitleRow/CloseButton

var _slot_buttons: Array = []  # Each element: { panel, label, save_btn, load_btn, delete_btn }


func _ready() -> void:
	if close_button:
		close_button.pressed.connect(_on_close_pressed)
	_build_slot_rows()
	_refresh_slot_labels()


func _build_slot_rows() -> void:
	if slot_list == null:
		return
	for i in range(NUM_SLOTS):
		var slot_index: int = i + 1
		var row = HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)

		var label = Label.new()
		label.custom_minimum_size.x = 120
		label.text = "Slot %d: —" % slot_index
		row.add_child(label)

		var save_btn = Button.new()
		save_btn.text = "Save"
		save_btn.pressed.connect(_on_save_pressed.bind(slot_index))
		row.add_child(save_btn)

		var load_btn = Button.new()
		load_btn.text = "Load"
		load_btn.pressed.connect(_on_load_pressed.bind(slot_index))
		row.add_child(load_btn)

		var delete_btn = Button.new()
		delete_btn.text = "Delete"
		delete_btn.pressed.connect(_on_delete_pressed.bind(slot_index))
		row.add_child(delete_btn)

		slot_list.add_child(row)
		_slot_buttons.append({ "label": label, "save_btn": save_btn, "load_btn": load_btn, "delete_btn": delete_btn })


func _refresh_slot_labels() -> void:
	if not SaveManager:
		return
	for i in range(_slot_buttons.size()):
		var slot_index: int = i + 1
		var info: Dictionary = SaveManager.get_slot_info(slot_index)
		var row_data = _slot_buttons[i]
		var lab: Label = row_data.label
		if lab == null:
			continue
		if info.is_empty():
			lab.text = "Slot %d: Empty" % slot_index
		else:
			lab.text = "Slot %d: Day %d" % [slot_index, info.get("turn", 0)]


func _on_save_pressed(slot: int) -> void:
	if GameManager and SaveManager:
		if GameManager.save_game_to_slot(slot):
			_refresh_slot_labels()


func _on_load_pressed(slot: int) -> void:
	if SaveManager and SaveManager.has_save_in_slot(slot) and GameManager:
		if GameManager.load_game_from_slot(slot):
			visible = false


func _on_delete_pressed(slot: int) -> void:
	if SaveManager:
		SaveManager.delete_slot(slot)
		_refresh_slot_labels()


func _on_close_pressed() -> void:
	visible = false


func show_menu() -> void:
	_refresh_slot_labels()
	visible = true
