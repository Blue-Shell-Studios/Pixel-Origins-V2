extends GoblinState

func begin() -> void:
	goblin.stop()
	goblin.sprite.play("idle")

func handle_input() -> void:
	pass

func process(delta: float) -> void:
	pass

func end() -> void:
	pass
