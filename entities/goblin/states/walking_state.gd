extends GoblinState

func begin() -> void:
	goblin.sprite.play("walking")

func handle_input() -> void:
	pass

func process(delta: float) -> void:
	goblin.move_towards(goblin.target_position, goblin.WALKING_SPEED)
	if goblin.has_reached_target():
		goblin.change_state(Goblin.State.IDLE)

func end() -> void:
	goblin.stop()
