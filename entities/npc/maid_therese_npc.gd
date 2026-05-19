class_name MaidThereseNPC
extends BaseNPC

var _heal_layer: CanvasLayer
var _heal_panel: Panel
var _heal_message: Label


func _ready() -> void:
	super._ready()
	_build_heal_ui()


func interact() -> void:
	if not _can_player_interact():
		return

	_record_npc_talk_event()
	if _is_player_full_health():
		var full_health_lines := PackedStringArray([
			"Oh, you're looking healthy already.",
			"Take care out there, all right? Come back in one piece.",
		])
		var full_health_resource := _build_dialogue_resource_from_lines(full_health_lines)
		if full_health_resource != null:
			DialogueService.start_dialogue(full_health_resource, dialogue_start)
			await DialogueService.dialogue_ended
		return

	var lines := PackedStringArray([
		"You look worn out from the road.",
		"Let me patch you up, free of charge.",
	])
	var resource := _build_dialogue_resource_from_lines(lines)
	if resource != null:
		DialogueService.start_dialogue(resource, dialogue_start)
		await DialogueService.dialogue_ended

	_show_heal_prompt()


func _is_player_full_health() -> bool:
	if _nearby_player == null:
		return false
	var current_health = _nearby_player.get("health")
	var current_max_health = _nearby_player.get("max_health")
	if current_health == null or current_max_health == null:
		return false
	return float(current_health) >= float(current_max_health)


func _show_heal_prompt() -> void:
	if _nearby_player == null:
		return
	_heal_message.text = "Would you like me to restore your health?"
	get_tree().paused = true
	_heal_layer.visible = true


func _hide_heal_prompt() -> void:
	_heal_layer.visible = false
	get_tree().paused = false


func _on_yes_pressed() -> void:
	if _nearby_player != null and _nearby_player.has_method("heal_to_full"):
		_nearby_player.heal_to_full()
	_heal_message.text = "All done. You should feel much better now."


func _on_close_pressed() -> void:
	_hide_heal_prompt()


func _build_heal_ui() -> void:
	_heal_layer = CanvasLayer.new()
	_heal_layer.name = "HealUI"
	_heal_layer.visible = false
	_heal_layer.process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	add_child(_heal_layer)

	var backdrop := ColorRect.new()
	backdrop.color = Color(0, 0, 0, 0.45)
	backdrop.anchor_right = 1.0
	backdrop.anchor_bottom = 1.0
	_heal_layer.add_child(backdrop)

	_heal_panel = Panel.new()
	_heal_panel.offset_left = 270
	_heal_panel.offset_top = 190
	_heal_panel.offset_right = 760
	_heal_panel.offset_bottom = 390
	_heal_layer.add_child(_heal_panel)

	var title := Label.new()
	title.text = "Maid Therese"
	title.position = Vector2(20, 14)
	title.add_theme_font_size_override("font_size", 20)
	_heal_panel.add_child(title)

	_heal_message = Label.new()
	_heal_message.text = "Would you like me to restore your health?"
	_heal_message.position = Vector2(20, 70)
	_heal_message.size = Vector2(430, 44)
	_heal_message.add_theme_font_size_override("font_size", 17)
	_heal_panel.add_child(_heal_message)

	var yes_button := Button.new()
	yes_button.text = "Yes, heal me"
	yes_button.position = Vector2(20, 130)
	yes_button.size = Vector2(180, 40)
	yes_button.pressed.connect(_on_yes_pressed)
	_heal_panel.add_child(yes_button)

	var close_button := Button.new()
	close_button.text = "Maybe later"
	close_button.position = Vector2(220, 130)
	close_button.size = Vector2(170, 40)
	close_button.pressed.connect(_on_close_pressed)
	_heal_panel.add_child(close_button)


func _build_dialogue_resource_from_lines(lines: PackedStringArray) -> Resource:
	if lines.is_empty():
		return null

	var compiled_text := "~ %s\n" % dialogue_start
	for line in lines:
		compiled_text += "%s: %s\n" % [npc_name, line]
	return DialogueManager.create_resource_from_text(compiled_text)
