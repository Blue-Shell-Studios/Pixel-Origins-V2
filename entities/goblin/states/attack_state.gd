extends GoblinState

var attack_last_frame := 0

func begin() -> void:
	goblin.stop()
	goblin.sprite.play("attack")
	
	while goblin.sprite.frame < 5:
		await goblin.sprite.frame_changed
		
	goblin.sword.set_deferred("monitoring", true)
	await goblin.sprite.animation_finished
	goblin.sword.set_deferred("monitoring", false)
	
	goblin.change_state(Goblin.State.RUNNING)

func handle_input() -> void:
	pass

func process(delta: float) -> void:
	pass

func end() -> void:
	pass

func _on_sword_area_entered(area: Area2D) -> void:
	if goblin.state != self or area.name != "Hitbox": return

	var target := area.get_parent()
	if target == self: return

	if target is Player and target.has_method("take_damage"):
		target.take_damage(goblin.attack_damage)
