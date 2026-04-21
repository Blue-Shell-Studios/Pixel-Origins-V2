extends PlayerState

func begin() -> void:
	player.velocity = Vector2.ZERO
	player.play_animation("idle")

func handle_input() -> void:
	if Input.is_action_pressed("attack"):
		player.change_state(Player.State.ATTACK)
		return

	if Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down") != Vector2.ZERO:
		player.change_state(Player.State.WALKING)
		return
	
	if Input.is_action_pressed("action") and is_instance_valid(player.current_actionable):
		if player.interact_with_actionable():
			player.change_state(Player.State.ACTION)
		return
	
func process(delta: float) -> void:
	pass

func end() -> void:
	pass
