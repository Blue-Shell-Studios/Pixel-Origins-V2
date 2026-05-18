class_name BaseEnemy
extends Area2D

const COIN_PICKUP_SCENE := preload("res://entities/pickups/coin_pickup.tscn")

var move_speed: float
var aggro_range: float
var enemy_type: StringName = &""
var max_chase_distance: float
var return_stop_distance: float
var max_health: int
var contact_damage: int
var contact_damage_cooldown: float
var contact_knockback_force: float

@onready var vision_shape: CollisionShape2D = $VisionArea/CollisionShape2D
@onready var body_visual: Node2D = get_node_or_null("Body") as Node2D
@onready var animated_visual: AnimatedSprite2D = get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D

var spawn_position: Vector2
var target_player: Node2D
var is_aggro := false
var health: int = 0
var _contact_timer: float = 0.0
var velocity: Vector2 = Vector2.ZERO


func _ready() -> void:
	spawn_position = global_position
	health = max_health

	$VisionArea.body_entered.connect(_on_vision_body_entered)
	$VisionArea.body_exited.connect(_on_vision_body_exited)


func _physics_process(delta: float) -> void:
	if _contact_timer > 0.0:
		_contact_timer -= delta

	if is_aggro:
		_process_chase()
	else:
		_process_return_to_spawn()

	global_position += velocity * delta
	_update_facing()
	_try_contact_damage()


func _process_chase() -> void:
	if target_player == null:
		_lose_aggro()
		return

	var distance_from_spawn := global_position.distance_to(spawn_position)
	if distance_from_spawn > max_chase_distance:
		_lose_aggro()
		return

	var to_target := target_player.global_position - global_position
	if to_target == Vector2.ZERO:
		velocity = Vector2.ZERO
	else:
		velocity = to_target.normalized() * move_speed


func _process_return_to_spawn() -> void:
	var to_spawn := spawn_position - global_position
	if to_spawn.length() <= return_stop_distance:
		velocity = Vector2.ZERO
		global_position = spawn_position
		return

	velocity = to_spawn.normalized() * move_speed * 0.85


func _on_vision_body_entered(body: Node) -> void:
	if not body.is_in_group("player"):
		return
	target_player = body as Node2D
	is_aggro = true


func _on_vision_body_exited(body: Node) -> void:
	if body != target_player:
		return
	_lose_aggro()


func _lose_aggro() -> void:
	is_aggro = false
	target_player = null


func _update_facing() -> void:
	if velocity.x == 0.0:
		return
	var side: int = sign(velocity.x)
	if body_visual != null:
		body_visual.scale.x = absf(body_visual.scale.x) * side
	if animated_visual != null:
		animated_visual.flip_h = side < 0.0


func take_damage(amount: int) -> void:
	health -= max(1, amount)
	if health <= 0:
		_report_defeat()
		_drop_coin_loot(1, 2)
		queue_free()


func _try_contact_damage() -> void:
	if _contact_timer > 0.0:
		return

	if target_player == null:
		return
	if not is_instance_valid(target_player):
		return
	if not target_player.has_method("take_hit"):
		return

	if not _is_player_hitbox_overlapping():
		return

	target_player.take_hit(contact_damage, global_position, contact_knockback_force)
	_contact_timer = contact_damage_cooldown


func _is_player_hitbox_overlapping() -> bool:
	for area in get_overlapping_areas():
		if area == null:
			continue
		var parent := area.get_parent()
		if parent == target_player and area.name == "HitBox":
			return true
	return false


func _drop_coin_loot(min_coins: int, max_coins: int) -> void:
	if COIN_PICKUP_SCENE == null:
		return
	var parent := get_parent() as Node2D
	if parent == null:
		return
	var count := randi_range(min_coins, max_coins)
	for i in range(count):
		var coin := COIN_PICKUP_SCENE.instantiate() as Node2D
		if coin == null:
			continue
		coin.position = parent.to_local(global_position)
		parent.call_deferred("add_child", coin)


func _report_defeat() -> void:
	if enemy_type.is_empty():
		return
	QuestManager.record_enemy_kill(enemy_type)
