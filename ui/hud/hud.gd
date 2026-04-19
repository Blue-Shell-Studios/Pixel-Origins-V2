class_name HUD extends CanvasLayer

@onready var bottom_label: Label = $Bottom/Label
@onready var game_over_root: Control = $GameOver
@onready var health_bar: ProgressBar = $TopLeft/VBoxContainer/HealthBar
@onready var health_label: Label = $TopLeft/VBoxContainer/HealthLabel

var is_game_over := false

func _ready() -> void:
	SignalBus.print_text.connect(print_text)
	SignalBus.player_health_changed.connect(_on_player_health_changed)
	SignalBus.player_died.connect(_on_player_died)
	game_over_root.visible = false
	health_bar.max_value = 100
	health_bar.value = 100
	health_label.text = "HP 100/100"

func _unhandled_input(event: InputEvent) -> void:
	if not is_game_over:
		return
	if event.is_action_pressed("ui_accept"):
		get_tree().reload_current_scene()

func print_text(text: String, text_pos: Util.TextPos) -> void:
	match text_pos:
		Util.TextPos.BOTTOM:
			$Bottom/Label.text = text

func _on_player_died() -> void:
	is_game_over = true
	game_over_root.visible = true
	bottom_label.text = ""

func _on_player_health_changed(current: int, max: int) -> void:
	health_bar.max_value = max
	health_bar.value = current
	health_label.text = "HP %d/%d" % [current, max]
