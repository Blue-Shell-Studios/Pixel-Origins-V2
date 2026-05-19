class_name LifeEssence
extends Area2D

signal destroyed(essence: LifeEssence)

@export var max_health: int = 4
@export var bob_speed: float = 2.7
@export var bob_height: float = 2.2

var _health: int = 0
var _base_position: Vector2
var _elapsed: float = 0.0


func _ready() -> void:
	_health = max_health
	_base_position = position


func _physics_process(delta: float) -> void:
	_elapsed += delta
	position = _base_position + Vector2(0.0, sin(_elapsed * bob_speed) * bob_height)


func take_damage(amount: int) -> void:
	if _health <= 0:
		return

	_health -= max(1, amount)
	SoundManager.play_enemy_hit()
	modulate = Color(1.0, 0.82, 0.92, 1.0)
	var flash_tween := create_tween()
	flash_tween.tween_property(self, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.12)

	if _health > 0:
		return

	SoundManager.play_enemy_defeat()
	destroyed.emit(self)
	queue_free()
