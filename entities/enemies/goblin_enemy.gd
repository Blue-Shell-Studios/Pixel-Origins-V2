class_name GoblinEnemy
extends BaseEnemy

const MOVE_SPEED := 40.0
const AGGRO_RANGE := 84.0
const MAX_CHASE_DISTANCE := 340.0
const RETURN_STOP_DISTANCE := 6.0
const MAX_HEALTH := 4
const CONTACT_DAMAGE := 1
const CONTACT_DAMAGE_COOLDOWN := 0.7
const CONTACT_KNOCKBACK_FORCE := 200.0

const SWORD_DAMAGE := 1
const SWORD_REACH := 12.5
const SWORD_RANGE := 25.0
const SWORD_COOLDOWN := 0.9
const SWORD_ACTIVE_TIME := 0.12
const CHARGE_SPEED_MULTIPLIER := 1.0
const HURT_STUN_TIME := 0.25
const CHARGE_HIT_RECOVERY_TIME := 0.22

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var sword_area: Area2D = $SwordArea

var _sword_timer: float = 0.0
var _is_dead := false
var _is_hurt := false
var _is_attacking := false
var _last_side: float = 1.0
var _sword_window_active := false
var _sword_hit_ids: Dictionary = {}
var _sword_hit_frame_fired := false
var _hurt_stun_timer: float = 0.0
var _charge_recovery_timer: float = 0.0
var _is_charging := false


func _ready() -> void:
	enemy_type = &"goblin"
	attack_sfx_id = &"enemy_goblin_attack"
	hit_sfx_id = &"enemy_hit"
	defeat_sfx_id = &"enemy_goblin_defeat"
	move_speed = MOVE_SPEED
	aggro_range = AGGRO_RANGE
	max_chase_distance = MAX_CHASE_DISTANCE
	return_stop_distance = RETURN_STOP_DISTANCE
	max_health = MAX_HEALTH
	contact_damage = CONTACT_DAMAGE
	contact_damage_cooldown = CONTACT_DAMAGE_COOLDOWN
	contact_knockback_force = CONTACT_KNOCKBACK_FORCE
	var shape := $VisionArea/CollisionShape2D.shape as CircleShape2D
	if shape != null:
		shape.radius = aggro_range

	super._ready()
	sword_area.monitoring = false
	sword_area.area_entered.connect(_on_sword_area_entered)
	sword_area.body_entered.connect(_on_sword_body_entered)
	sprite.animation_finished.connect(_on_sprite_animation_finished)
	_play_animation("idle")


func _physics_process(delta: float) -> void:
	if _is_dead:
		return
	if _sword_timer > 0.0:
		_sword_timer -= delta
	if _hurt_stun_timer > 0.0:
		_hurt_stun_timer -= delta
		velocity = Vector2.ZERO
		_update_animation()
		return
	if _charge_recovery_timer > 0.0:
		_charge_recovery_timer -= delta
		_is_charging = false
		velocity = Vector2.ZERO
		_sword_window_active = false
		sword_area.monitoring = false
		_update_animation()
		return
	super._physics_process(delta)
	_update_sword_hit_window()
	_update_animation()


func _process_chase() -> void:
	if _is_attacking:
		velocity = Vector2.ZERO
		return

	if target_player == null or not is_instance_valid(target_player):
		_lose_aggro()
		return

	var distance_from_spawn := global_position.distance_to(spawn_position)
	if distance_from_spawn > max_chase_distance:
		_lose_aggro()
		return

	var to_target := target_player.global_position - global_position
	if to_target == Vector2.ZERO:
		velocity = Vector2.ZERO
		return

	var dx := to_target.x
	var dy := to_target.y

	# Workaround for limited assets: sword animation/arc is side-only.
	# If target is mostly above/below, use a direct charge instead.
	if absf(dy) > absf(dx):
		_is_charging = true
		var side_for_charge: int = sign(dx)
		if side_for_charge != 0.0:
			_last_side = side_for_charge
		_update_sprite_facing(_last_side)
		velocity = to_target.normalized() * move_speed * CHARGE_SPEED_MULTIPLIER
		return

	_is_charging = false
	var side: int = sign(dx)
	if side == 0.0:
		side = 1.0
	_last_side = side
	_update_sprite_facing(side)

	var horizontal_distance := absf(dx)
	if horizontal_distance <= SWORD_RANGE:
		velocity = Vector2.ZERO
		_try_side_swing(side)
	else:
		velocity = Vector2(side, 0.0) * move_speed


func _try_side_swing(side: float) -> void:
	if _sword_timer > 0.0 or _is_attacking or _is_hurt or _is_dead:
		return

	_play_attack_sfx()
	_is_attacking = true
	velocity = Vector2.ZERO
	_update_sprite_facing(side)
	_play_animation("attack")

	sword_area.position = Vector2(side * SWORD_REACH, 0.0)
	_sword_hit_ids.clear()
	_sword_window_active = false
	_sword_hit_frame_fired = false
	sword_area.monitoring = false

	_sword_timer = SWORD_COOLDOWN


func _try_apply_sword_damage(target: Node) -> void:
	if target == null or target == self:
		return
	if target == target_player and target_player.has_method("take_hit"):
		target_player.take_hit(SWORD_DAMAGE, global_position, contact_knockback_force)
		return
	if target.has_method("take_damage"):
		target.take_damage(SWORD_DAMAGE)


func _apply_sword_overlap_damage() -> void:
	for area in sword_area.get_overlapping_areas():
		_try_apply_sword_damage_once(area)
	for body in sword_area.get_overlapping_bodies():
		_try_apply_sword_damage_once(body)


func _try_apply_sword_damage_once(target: Node) -> void:
	if target == null:
		return
	var key := target.get_instance_id()
	if _sword_hit_ids.has(key):
		return
	_sword_hit_ids[key] = true
	_try_apply_sword_damage(target)


func _on_sword_area_entered(area: Area2D) -> void:
	if not _sword_window_active:
		return
	_try_apply_sword_damage_once(area)


func _on_sword_body_entered(body: Node2D) -> void:
	if not _sword_window_active:
		return
	_try_apply_sword_damage_once(body)


func take_damage(amount: int) -> void:
	if _is_dead:
		return

	health -= max(1, amount)
	if health <= 0:
		health = 0
		_play_defeat_sfx()
		_die()
		return

	_play_hit_sfx()
	_is_hurt = true
	_hurt_stun_timer = HURT_STUN_TIME
	_is_attacking = false
	_sword_window_active = false
	_sword_hit_frame_fired = false
	sword_area.monitoring = false
	_play_animation("hurt")


func _try_contact_damage() -> void:
	if _contact_timer > 0.0:
		return
	if target_player == null:
		return
	if not is_instance_valid(target_player):
		return
	if not _is_player_hitbox_overlapping():
		return

	if _is_charging and target_player.has_method("take_hit"):
		target_player.take_hit(contact_damage, global_position, contact_knockback_force)
		_play_attack_sfx()
		_charge_recovery_timer = CHARGE_HIT_RECOVERY_TIME
		velocity = Vector2.ZERO
	else:
		if target_player.has_method("take_damage"):
			target_player.take_damage(contact_damage)
		elif target_player.has_method("take_hit"):
			target_player.take_hit(contact_damage, global_position, 0.0)
		_play_attack_sfx()

	_contact_timer = contact_damage_cooldown


func _die() -> void:
	_is_dead = true
	_is_hurt = false
	_is_attacking = false
	is_aggro = false
	target_player = null
	velocity = Vector2.ZERO
	_sword_window_active = false
	_sword_hit_frame_fired = false
	sword_area.monitoring = false
	set_deferred("monitoring", false)
	set_deferred("monitorable", false)
	$VisionArea.set_deferred("monitoring", false)
	$VisionArea.set_deferred("monitorable", false)
	_report_defeat()
	_drop_coin_loot(1, 2)
	_play_animation("dead")


func _update_sprite_facing(side: float) -> void:
	sprite.flip_h = side < 0.0


func _update_animation() -> void:
	if _is_dead or _is_hurt or _is_attacking:
		return
	if velocity.length() > 0.1:
		_play_animation("run")
	else:
		_play_animation("idle")


func _play_animation(name: String) -> void:
	if sprite.sprite_frames == null:
		return
	var anim := StringName(name)
	if not sprite.sprite_frames.has_animation(anim):
		return
	if sprite.animation == anim and sprite.is_playing():
		return
	sprite.play(anim)


func _on_sprite_animation_finished() -> void:
	match String(sprite.animation):
		"attack":
			_is_attacking = false
			_sword_window_active = false
			_sword_hit_frame_fired = false
			sword_area.monitoring = false
		"hurt":
			_is_hurt = false
		"dead":
			queue_free()


func _update_sword_hit_window() -> void:
	var is_attack_anim := _is_attacking and String(sprite.animation) == "attack"
	if not is_attack_anim:
		_sword_window_active = false
		sword_area.monitoring = false
		return

	var is_hit_frame := sprite.frame == 5
	_sword_window_active = is_hit_frame
	sword_area.monitoring = is_hit_frame
	if is_hit_frame and not _sword_hit_frame_fired:
		_apply_sword_overlap_damage()
		_sword_hit_frame_fired = true
