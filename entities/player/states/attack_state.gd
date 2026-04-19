extends PlayerState

func begin() -> void:
	player.velocity = Vector2.ZERO
	player.body.attack()

	while player.body.tool_sprite.frame < 5:
		await player.body.tool_sprite.frame_changed

	player.sword.set_deferred("monitoring", true)

	await player.body.movement_finished
	player.sword.set_deferred("monitoring", false)

	player.change_state(Player.State.IDLE)

func handle_input() -> void:
	pass

func process(delta: float) -> void:
	pass

func end() -> void:
	pass
