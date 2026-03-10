## TradePanel.gd
## Shows active trade routes and lets player manage them.

extends Control

@onready var route_list: VBoxContainer = $ScrollContainer/RouteList
@onready var close_btn: Button = $CloseButton

func _ready() -> void:
	if close_btn:
		close_btn.pressed.connect(func(): EventBus.panel_close_requested.emit("trade"))
	EventBus.trade_route_opened.connect(func(_a, _b): refresh({}))
	EventBus.trade_route_closed.connect(func(_a, _b): refresh({}))

func refresh(_data: Dictionary) -> void:
	if route_list == null:
		return
	for child in route_list.get_children():
		child.queue_free()

	var player = GameManager.player_village
	if player == null:
		return

	if player.trade_routes.is_empty():
		var lbl = Label.new()
		lbl.text = "No active trade routes. Open the Diplomacy panel to propose trades."
		route_list.add_child(lbl)
		return

	for vid in player.trade_routes:
		var route = player.trade_routes[vid]
		var partner = GameManager.get_village_by_id(vid)
		if partner == null:
			continue

		var row = HBoxContainer.new()
		var lbl = Label.new()
		lbl.text = "→ %s: Give %d %s / Receive %d %s" % [
			partner.village_name,
			route["amount_give"], Constants.RESOURCE_NAMES[route["resource_give"]],
			route["amount_receive"], Constants.RESOURCE_NAMES[route["resource_receive"]]
		]
		lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(lbl)

		var cancel_btn = Button.new()
		cancel_btn.text = "Cancel"
		cancel_btn.pressed.connect(func(): _cancel_route(vid))
		row.add_child(cancel_btn)
		route_list.add_child(row)

func _cancel_route(vid: int) -> void:
	GameManager.diplomacy_manager.player_action(Constants.DiplomacyAction.CANCEL_TRADE, vid)
	refresh({})
