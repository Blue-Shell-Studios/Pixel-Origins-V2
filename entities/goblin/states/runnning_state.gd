extends GoblinState

func begin() -> void:
	goblin.sprite.play("running")

func handle_input() -> void:
	if not is_instance_valid(goblin.target):
		goblin.change_state(Goblin.State.IDLE)
		return
	
	if goblin.global_position.distance_to(goblin.target.global_position) < goblin.attack_range:
		goblin.change_state(Goblin.State.ATTACK)
		return

func process(delta: float) -> void:
	if goblin.target:
		goblin.move_towards(goblin.target.global_position, goblin.RUNNING_SPEED)

func end() -> void:
	goblin.stop()
