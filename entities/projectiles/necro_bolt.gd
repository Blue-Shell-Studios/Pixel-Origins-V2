extends Area2D

@export var speed: float = 210.0
@export var max_distance: float = 520.0
@export var damage: int = 1
@export var knockback_force: float = 240.0

var direction: Vector2 = Vector2.RIGHT
var _start_position: Vector2


func _ready() -> void:
	_start_position = global_position
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)
	rotation = direction.angle()


func _physics_process(delta: float) -> void:
	global_position += direction * speed * delta
	if global_position.distance_to(_start_position) >= max_distance:
		queue_free()


func _on_body_entered(body: Node) -> void:
	_try_hit_player(body)


func _on_area_entered(area: Area2D) -> void:
	if area == null:
		return
	_try_hit_player(area)
	if area.get_parent() != null:
		_try_hit_player(area.get_parent())


func _try_hit_player(target: Node) -> void:
	if target == null:
		return
	if not target.is_in_group("player"):
		return
	if not target.has_method("take_hit"):
		return

	target.take_hit(damage, global_position, knockback_force)
	queue_free()
