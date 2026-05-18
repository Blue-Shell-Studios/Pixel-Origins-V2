extends Node2D

@onready var title_card: Panel = $CanvasLayer/TitleCard
@onready var prompt_label: Label = $CanvasLayer/TitleCard/Prompt
@onready var main_menu: Panel = $CanvasLayer/MainMenu
@onready var play_button: Button = $CanvasLayer/MainMenu/VBoxContainer/PlayButton
@onready var exit_button: Button = $CanvasLayer/MainMenu/VBoxContainer/ExitButton

var menu_unlocked := false


func _ready() -> void:
	main_menu.visible = false
	title_card.modulate.a = 0.0
	prompt_label.modulate.a = 0.0

	play_button.pressed.connect(_on_play_pressed)
	exit_button.pressed.connect(_on_exit_pressed)

	var tween := create_tween()
	tween.tween_property(title_card, "modulate:a", 1.0, 0.45)
	tween.tween_property(prompt_label, "modulate:a", 1.0, 0.35)
	menu_unlocked = true


func _unhandled_input(event: InputEvent) -> void:
	if not menu_unlocked or main_menu.visible:
		return

	var is_click: bool = event is InputEventMouseButton and event.pressed
	var is_submit := event.is_action_pressed("ui_accept")
	if is_click or is_submit:
		_show_main_menu()
		get_viewport().set_input_as_handled()


func _show_main_menu() -> void:
	main_menu.visible = true
	title_card.visible = false
	play_button.grab_focus()


func _on_play_pressed() -> void:
	StageManager.go_to_stage(&"tauracre")


func _on_exit_pressed() -> void:
	get_tree().quit()
