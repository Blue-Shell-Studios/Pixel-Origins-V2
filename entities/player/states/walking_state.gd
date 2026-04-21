extends PlayerState

var direction : Vector2

func begin() -> void:
	direction = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	player.play_animation("walk")

func handle_input() -> void:
	direction = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")

	if Input.is_action_pressed("attack"):
		player.change_state(Player.State.ATTACK)
		return

	if direction == Vector2.ZERO:
		player.change_state(Player.State.IDLE)
		return

	if Input.is_action_pressed("run_prefix"):
		player.change_state(Player.State.RUNNING)
		return

	if direction == Vector2.ZERO:
		pass
	elif direction.x < 0:
		player.look(Util.Direction.LEFT)
	elif direction.x > 0:
		player.look(Util.Direction.RIGHT)
	elif direction.y < 0:
		player.look(Util.Direction.UP)
	elif direction.y > 0:
		player.look(Util.Direction.DOWN)
	
func process(delta: float) -> void:
	player.velocity = direction * player.WALK_SPEED

func end() -> void:
	pass
