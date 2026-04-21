extends PlayerState


func begin() -> void:
	player.velocity = Vector2.ZERO
	player.play_animation("attack")

	while player.sprite.frame < 1:
		await player.sprite.frame_changed

	player.sword.set_deferred("monitoring", true)
	await player.sprite.frame_changed
	player.sword.set_deferred("monitoring", false)
	await player.sprite.animation_finished
	player.change_state(Player.State.IDLE)

func handle_input() -> void:
	pass

func process(delta: float) -> void:
	pass

func end() -> void:
	pass
