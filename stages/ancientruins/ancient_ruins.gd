extends Node2D

const BOSS_SCENE := preload("res://entities/enemies/ancient_ruins_boss.tscn")

@onready var enemies_root: Node2D = $Enemies
@onready var arena_hint_shape: CollisionShape2D = $ForCodexContext/Arena
@onready var arena_exit: Area2D = $ArenaExit
@onready var arena_exit_collision: CollisionShape2D = $ArenaExit/CollisionShape2D


func _ready() -> void:
	_spawn_boss()


func _spawn_boss() -> void:
	if enemies_root == null:
		return
	if enemies_root.get_node_or_null("AncientRuinsBoss") != null:
		return

	var arena_rect := _resolve_arena_rect()
	var boss := BOSS_SCENE.instantiate() as AncientRuinsBoss
	if boss == null:
		return

	boss.configure_arena(arena_rect)
	boss.global_position = arena_rect.get_center()
	boss.encounter_started.connect(_on_boss_encounter_started)
	boss.defeated.connect(_on_boss_defeated)
	enemies_root.add_child(boss)
	_set_arena_exit_locked(false)


func _resolve_arena_rect() -> Rect2:
	if arena_hint_shape == null:
		return Rect2(Vector2(470.0, 470.0), Vector2(350.0, 200.0))

	var rect_shape := arena_hint_shape.shape as RectangleShape2D
	if rect_shape == null:
		return Rect2(arena_hint_shape.global_position - Vector2(180.0, 110.0), Vector2(360.0, 220.0))

	var size := rect_shape.size
	var top_left := arena_hint_shape.global_position - size * 0.5
	return Rect2(top_left, size)


func _on_boss_encounter_started() -> void:
	_set_arena_exit_locked(true)


func _on_boss_defeated() -> void:
	_set_arena_exit_locked(false)


func _set_arena_exit_locked(locked: bool) -> void:
	if arena_exit != null:
		arena_exit.set_deferred("monitoring", not locked)
	if arena_exit_collision != null:
		arena_exit_collision.set_deferred("disabled", locked)
