extends Node

var _active := false
var _layer: CanvasLayer
var _backdrop: ColorRect
var _panel: Panel
var _title_label: Label
var _body_label: Label
var _prompt_label: Label


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_ui()


func show_death_screen() -> void:
	if _active:
		return
	_active = true
	_layer.visible = true
	get_tree().paused = true


func _input(event: InputEvent) -> void:
	if not _active:
		return

	var is_click: bool = event is InputEventMouseButton and event.pressed
	var is_submit := event.is_action_pressed("ui_accept") or event.is_action_pressed("interact")
	if not is_click and not is_submit:
		return

	_continue_after_death()
	get_viewport().set_input_as_handled()


func _continue_after_death() -> void:
	if not _active:
		return

	_active = false
	_layer.visible = false
	get_tree().paused = false
	StageManager.recover_player_after_death()


func _build_ui() -> void:
	_layer = CanvasLayer.new()
	_layer.name = "DeathScreenUI"
	_layer.visible = false
	_layer.process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	add_child(_layer)

	_backdrop = ColorRect.new()
	_backdrop.anchor_right = 1.0
	_backdrop.anchor_bottom = 1.0
	_backdrop.color = Color(0, 0, 0, 0.86)
	_backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	_layer.add_child(_backdrop)

	_panel = Panel.new()
	_panel.anchor_left = 0.5
	_panel.anchor_top = 0.5
	_panel.anchor_right = 0.5
	_panel.anchor_bottom = 0.5
	_panel.offset_left = -260
	_panel.offset_top = -130
	_panel.offset_right = 260
	_panel.offset_bottom = 130
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_layer.add_child(_panel)

	var container := VBoxContainer.new()
	container.anchor_right = 1.0
	container.anchor_bottom = 1.0
	container.offset_left = 20
	container.offset_top = 20
	container.offset_right = -20
	container.offset_bottom = -20
	container.alignment = BoxContainer.ALIGNMENT_CENTER
	container.add_theme_constant_override("separation", 12)
	_panel.add_child(container)

	_title_label = Label.new()
	_title_label.text = "You Died"
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_label.add_theme_font_size_override("font_size", 38)
	container.add_child(_title_label)

	_body_label = Label.new()
	_body_label.text = "You awaken at the overworld entrance."
	_body_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	container.add_child(_body_label)

	_prompt_label = Label.new()
	_prompt_label.text = "Click to continue"
	_prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_prompt_label.add_theme_font_size_override("font_size", 18)
	container.add_child(_prompt_label)
