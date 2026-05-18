class_name ShopKeeperJacobNPC
extends BaseNPC

const BOW_COST := 20
const BOW_ID: StringName = &"bow"

var _shop_layer: CanvasLayer
var _shop_panel: Panel
var _shop_message: Label
var _buy_button: Button


func _ready() -> void:
	super._ready()
	_build_shop_ui()


func interact() -> void:
	if not _can_player_interact():
		return

	_record_npc_talk_event()
	var lines := PackedStringArray([
		"Welcome to my stall.",
		"If you have 20 coins, I can set you up with a bow.",
	])
	var resource := _build_dialogue_resource_from_lines(lines)
	if resource != null:
		DialogueService.start_dialogue(resource, dialogue_start)
		await DialogueService.dialogue_ended

	_show_shop()


func _show_shop() -> void:
	if _nearby_player == null:
		return

	var has_bow: bool = _nearby_player.has_method("has_weapon") and _nearby_player.has_weapon(BOW_ID)
	if has_bow:
		_shop_message.text = "You already own a bow."
		_buy_button.disabled = true
		_buy_button.text = "Bought"
	else:
		_shop_message.text = "Bow - 20 coins"
		_buy_button.disabled = false
		_buy_button.text = "Buy Bow"

	get_tree().paused = true
	_shop_layer.visible = true


func _hide_shop() -> void:
	_shop_layer.visible = false
	get_tree().paused = false


func _on_buy_pressed() -> void:
	if _nearby_player == null:
		return
	if not _nearby_player.has_method("has_weapon"):
		return
	if _nearby_player.has_weapon(BOW_ID):
		_shop_message.text = "You already own this."
		return
	if not _nearby_player.has_method("try_spend_coins"):
		_shop_message.text = "Cannot process purchase."
		return
	if not _nearby_player.try_spend_coins(BOW_COST):
		_shop_message.text = "Not enough coins."
		return

	_nearby_player.grant_weapon(BOW_ID)
	_shop_message.text = "Pleasure doing business. Bow acquired."
	_buy_button.disabled = true
	_buy_button.text = "Bought"


func _on_leave_pressed() -> void:
	_hide_shop()


func _build_shop_ui() -> void:
	_shop_layer = CanvasLayer.new()
	_shop_layer.name = "ShopUI"
	_shop_layer.visible = false
	_shop_layer.process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	add_child(_shop_layer)

	var backdrop := ColorRect.new()
	backdrop.color = Color(0, 0, 0, 0.45)
	backdrop.anchor_right = 1.0
	backdrop.anchor_bottom = 1.0
	_shop_layer.add_child(backdrop)

	_shop_panel = Panel.new()
	_shop_panel.offset_left = 265
	_shop_panel.offset_top = 170
	_shop_panel.offset_right = 760
	_shop_panel.offset_bottom = 420
	_shop_layer.add_child(_shop_panel)

	var title := Label.new()
	title.text = "Shop Keeper Jacob"
	title.position = Vector2(20, 14)
	title.add_theme_font_size_override("font_size", 20)
	_shop_panel.add_child(title)

	_shop_message = Label.new()
	_shop_message.text = "Bow - 20 coins"
	_shop_message.position = Vector2(20, 74)
	_shop_message.size = Vector2(420, 34)
	_shop_message.add_theme_font_size_override("font_size", 18)
	_shop_panel.add_child(_shop_message)

	_buy_button = Button.new()
	_buy_button.text = "Buy Bow"
	_buy_button.position = Vector2(20, 148)
	_buy_button.size = Vector2(170, 40)
	_buy_button.pressed.connect(_on_buy_pressed)
	_shop_panel.add_child(_buy_button)

	var leave_button := Button.new()
	leave_button.text = "Leave"
	leave_button.position = Vector2(210, 148)
	leave_button.size = Vector2(150, 40)
	leave_button.pressed.connect(_on_leave_pressed)
	_shop_panel.add_child(leave_button)


func _build_dialogue_resource_from_lines(lines: PackedStringArray) -> Resource:
	if lines.is_empty():
		return null

	var compiled_text := "~ %s\n" % dialogue_start
	for line in lines:
		compiled_text += "%s: %s\n" % [npc_name, line]
	return DialogueManager.create_resource_from_text(compiled_text)
