extends Node

var _menu_open := false
var _layer: CanvasLayer
var _panel: Panel
var _resume_button: Button
var _exit_button: Button


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_ui()


func _unhandled_input(event: InputEvent) -> void:
	if not _is_escape_pressed(event):
		return

	if _menu_open:
		_resume_game()
		get_viewport().set_input_as_handled()
		return

	if get_tree().paused:
		return
	if StageManager.current_stage_id == &"start_screen":
		return

	_pause_game()
	get_viewport().set_input_as_handled()


func _is_escape_pressed(event: InputEvent) -> bool:
	if event is InputEventKey:
		var key_event := event as InputEventKey
		if key_event.pressed and not key_event.echo and key_event.keycode == KEY_ESCAPE:
			return true
	return event.is_action_pressed("ui_cancel")


func _pause_game() -> void:
	_menu_open = true
	get_tree().paused = true
	_layer.visible = true
	_resume_button.grab_focus()


func _resume_game() -> void:
	_menu_open = false
	_layer.visible = false
	get_tree().paused = false


func _on_resume_pressed() -> void:
	_resume_game()


func _on_exit_pressed() -> void:
	get_tree().paused = false
	get_tree().quit()


func _build_ui() -> void:
	_layer = CanvasLayer.new()
	_layer.name = "PauseMenuUI"
	_layer.visible = false
	_layer.process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	add_child(_layer)

	var backdrop := ColorRect.new()
	backdrop.color = Color(0, 0, 0, 0.5)
	backdrop.anchor_right = 1.0
	backdrop.anchor_bottom = 1.0
	_layer.add_child(backdrop)

	_panel = Panel.new()
	_panel.custom_minimum_size = Vector2(220, 140)
	_panel.anchor_left = 0.5
	_panel.anchor_top = 0.5
	_panel.anchor_right = 0.5
	_panel.anchor_bottom = 0.5
	_panel.offset_left = -110
	_panel.offset_top = -70
	_panel.offset_right = 110
	_panel.offset_bottom = 70
	_layer.add_child(_panel)

	var container := VBoxContainer.new()
	container.anchor_right = 1.0
	container.anchor_bottom = 1.0
	container.offset_left = 16
	container.offset_top = 16
	container.offset_right = -16
	container.offset_bottom = -16
	container.alignment = BoxContainer.ALIGNMENT_CENTER
	container.add_theme_constant_override("separation", 10)
	_panel.add_child(container)

	var title := Label.new()
	title.text = "Paused"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 20)
	container.add_child(title)

	_resume_button = Button.new()
	_resume_button.text = "Resume"
	_resume_button.custom_minimum_size = Vector2(0, 34)
	_resume_button.pressed.connect(_on_resume_pressed)
	container.add_child(_resume_button)

	_exit_button = Button.new()
	_exit_button.text = "Exit"
	_exit_button.custom_minimum_size = Vector2(0, 34)
	_exit_button.pressed.connect(_on_exit_pressed)
	container.add_child(_exit_button)
