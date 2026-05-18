extends Node

const ARROW_SCENE: PackedScene = preload("res://entities/projectiles/arrow.tscn")


func spawn_arrow(origin: Vector2, direction: Vector2, speed: float = 520.0, max_distance: float = 520.0, damage: int = 1) -> Node2D:
	if direction == Vector2.ZERO:
		return null

	var scene := get_tree().current_scene
	if scene == null:
		return null

	var arrow := ARROW_SCENE.instantiate()
	arrow.global_position = origin
	arrow.direction = direction.normalized()
	arrow.speed = speed
	arrow.max_distance = max_distance
	arrow.damage = damage
	scene.add_child(arrow)
	return arrow
