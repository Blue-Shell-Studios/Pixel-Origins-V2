extends PlayerState

func _ready() -> void:
	SignalBus.dialogue_finished.connect(_on_dialogue_finished)

func begin() -> void:
	player.velocity = Vector2.ZERO
	player.play_animation("idle")

func handle_input() -> void:
	pass
	
func process(delta: float) -> void:
	pass

func end() -> void:
	pass

func _on_dialogue_finished() -> void:
	if player.state == self:
		player.change_state(Player.State.IDLE)
