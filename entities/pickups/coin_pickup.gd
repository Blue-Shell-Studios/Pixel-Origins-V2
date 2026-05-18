class_name CoinPickup
extends Area2D

@export var value: int = 1
@export var launch_distance_min: float = 8.0
@export var launch_distance_max: float = 20.0
@export var launch_duration: float = 0.16
@export var magnet_delay: float = 0.25
@export var magnet_speed: float = 220.0
@export var pickup_distance: float = 8.0
@export var idle_bob_height: float = 2.5
@export var idle_bob_time: float = 0.22
@export var idle_spin_speed_deg: float = 220.0

@onready var body_visual: Node2D = $Body

var _launching := true
var _magnet_enabled := false
var _player: Node2D
var _base_body_y: float = 0.0


func _ready() -> void:
	monitoring = true
	body_entered.connect(_on_body_entered)
	_base_body_y = body_visual.position.y
	_setup_launch_motion()
	_start_idle_juice()


func _physics_process(delta: float) -> void:
	body_visual.rotation += deg_to_rad(idle_spin_speed_deg) * delta

	if not _magnet_enabled:
		return
	if _player == null or not is_instance_valid(_player):
		_player = _find_player()
		if _player == null:
			return

	var to_player := _player.global_position - global_position
	if to_player.length() <= pickup_distance:
		_collect()
		return

	if to_player != Vector2.ZERO:
		global_position += to_player.normalized() * magnet_speed * delta


func _setup_launch_motion() -> void:
	var angle := randf() * TAU
	var distance := randf_range(launch_distance_min, launch_distance_max)
	var target := global_position + Vector2.RIGHT.rotated(angle) * distance
	var tween := create_tween()
	tween.tween_property(self, "global_position", target, launch_duration)
	tween.tween_callback(func(): _launching = false)
	tween.tween_callback(func(): _begin_magnet_delay())


func _begin_magnet_delay() -> void:
	var tween := create_tween()
	tween.tween_interval(magnet_delay)
	tween.tween_callback(func():
		_magnet_enabled = true
		_player = _find_player()
	)


func _find_player() -> Node2D:
	for node in get_tree().get_nodes_in_group("player"):
		if node is Node2D:
			return node as Node2D
	return null


func _on_body_entered(body: Node) -> void:
	if not body.is_in_group("player"):
		return
	_player = body as Node2D
	if _magnet_enabled or not _launching:
		_collect()


func _collect() -> void:
	if _player != null and _player.has_method("add_coins"):
		_player.add_coins(value)
	queue_free()


func _start_idle_juice() -> void:
	var tween := create_tween()
	tween.set_loops()
	tween.tween_property(body_visual, "position:y", _base_body_y - idle_bob_height, idle_bob_time)
	tween.tween_property(body_visual, "position:y", _base_body_y + idle_bob_height * 0.45, idle_bob_time)
