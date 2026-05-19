extends Node2D

@onready var canvas_layer: CanvasLayer = $CanvasLayer
@onready var background: TextureRect = $CanvasLayer/TextureRect
@onready var title_card: Control = $CanvasLayer/TitleCard
@onready var menu_container: Control = $CanvasLayer/VBoxContainer
@onready var play_button: Button = $CanvasLayer/VBoxContainer/PlayButton
@onready var exit_button: Button = $CanvasLayer/VBoxContainer/ExitButton


func _ready() -> void:
	play_button.pressed.connect(_on_play_pressed)
	exit_button.pressed.connect(_on_exit_pressed)

	# No click-to-unlock transition. Show title + menu immediately, with a startup fade-in.
	title_card.visible = true
	menu_container.visible = true
	background.modulate.a = 0.0
	title_card.modulate.a = 0.0
	menu_container.modulate.a = 0.0

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(background, "modulate:a", 1.0, 0.45)
	tween.tween_property(title_card, "modulate:a", 1.0, 0.45)
	tween.tween_property(menu_container, "modulate:a", 1.0, 0.45)
	tween.finished.connect(func():
		play_button.grab_focus()
	)


func _on_play_pressed() -> void:
	SoundManager.play_ui_click()
	StageManager.go_to_stage(&"tauracre")


func _on_exit_pressed() -> void:
	SoundManager.play_ui_click()
	get_tree().quit()
