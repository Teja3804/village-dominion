## SaveMenu.gd
## Save/Load slot selection UI.

extends Control

@onready var slot_list: VBoxContainer = $SlotList
@onready var close_btn: Button = $CloseButton
@onready var title_label: Label = $TitleLabel

func _ready() -> void:
	if close_btn:
		close_btn.pressed.connect(func(): EventBus.panel_close_requested.emit("save"))
	EventBus.game_saved.connect(func(_s): refresh())

func refresh() -> void:
	if slot_list == null:
		return
	for child in slot_list.get_children():
		child.queue_free()

	for i in range(1, SaveManager.SAVE_SLOTS + 1):
		var info = SaveManager.get_save_info(i)
		var row = _create_slot_row(i, info)
		slot_list.add_child(row)

func _create_slot_row(slot: int, info: Dictionary) -> Control:
	var row = HBoxContainer.new()

	var lbl = Label.new()
	if info.get("exists", false):
		lbl.text = "Slot %d — Turn %d, Year %d" % [slot, info.get("turn", 0), info.get("year", 1)]
	else:
		lbl.text = "Slot %d — Empty" % slot
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(lbl)

	var save_btn = Button.new()
	save_btn.text = "Save"
	save_btn.pressed.connect(func(): EventBus.save_requested.emit(slot))
	row.add_child(save_btn)

	var load_btn = Button.new()
	load_btn.text = "Load"
	load_btn.disabled = not info.get("exists", false)
	load_btn.pressed.connect(func(): EventBus.load_requested.emit(slot))
	row.add_child(load_btn)

	if info.get("exists", false):
		var del_btn = Button.new()
		del_btn.text = "Delete"
		del_btn.pressed.connect(func():
			SaveManager.delete_save(slot)
			refresh()
		)
		row.add_child(del_btn)

	return row
