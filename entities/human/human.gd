class_name Human extends Area2D

signal movement_finished

@onready var body_sprite: AnimatedSprite2D = $BodySprite
@onready var tool_sprite: AnimatedSprite2D = $ToolSprite
@onready var collision: CollisionShape2D = $CollisionShape2D

func idle() -> void:
	body_sprite.play("idle")
	tool_sprite.play("default")

func attack() -> void:
	body_sprite.play("attack")
	tool_sprite.play("attack")

func walk() -> void:
	body_sprite.play("walking")
	tool_sprite.play("default")

func run() -> void:
	body_sprite.play("running")
	tool_sprite.play("default")

func look(direction: Util.Direction) -> void:
	var looking_left := direction == Util.Direction.LEFT
	body_sprite.flip_h = looking_left
	tool_sprite.flip_h = looking_left

func _on_body_sprite_animation_finished() -> void:
	movement_finished.emit()
