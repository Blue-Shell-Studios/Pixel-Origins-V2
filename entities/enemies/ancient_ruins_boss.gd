class_name AncientRuinsBoss
extends Area2D

signal encounter_started
signal phase_changed(phase: int)
signal defeated

const PHASE_ONE := 1
const PHASE_TWO := 2
const PHASE_THREE := 3

const BOLT_SCENE := preload("res://entities/projectiles/necro_bolt.tscn")
const THRALL_SCENE := preload("res://entities/enemies/undead_thrall.tscn")
const ESSENCE_SCENE := preload("res://entities/enemies/life_essence.tscn")
const COIN_PICKUP_SCENE := preload("res://entities/pickups/coin_pickup.tscn")

@export var phase_one_max_health: int = 52
@export var phase_two_max_health: int = 78
@export_range(0.1, 0.9, 0.01) var phase_three_threshold: float = 0.30
@export var phase_one_move_speed: float = 42.0
@export var phase_two_move_speed: float = 56.0
@export var phase_three_move_speed: float = 80.0
@export var phase_one_melee_range: float = 26.0
@export var phase_two_melee_range: float = 30.0
@export var melee_reach: float = 18.0
@export var phase_one_melee_damage: int = 1
@export var phase_two_melee_damage: int = 1
@export var phase_one_melee_cooldown: float = 0.85
@export var phase_two_melee_cooldown: float = 1.05
@export var melee_window_time: float = 0.12
@export var contact_damage: int = 1
@export var contact_knockback_force: float = 220.0
@export var contact_damage_cooldown: float = 0.80
@export var necro_bolt_speed: float = 150.0
@export var necro_bolt_range: float = 470.0
@export var necro_bolt_damage: int = 1
@export var phase_two_bolt_spread_degrees: float = 10.0
@export var phase_three_bolt_spread_degrees: float = 14.0
@export var phase_two_bolt_cooldown: float = 1.30
@export var phase_three_bolt_cooldown: float = 0.72
@export var phase_two_summon_cooldown: float = 4.2
@export var phase_three_summon_cooldown: float = 2.0
@export var phase_two_summon_count: int = 2
@export var phase_three_summon_count: int = 3
@export var max_active_thralls: int = 8
@export var shield_break_stun_min_time: float = 5.0
@export var shield_break_stun_max_time: float = 8.0

@onready var visuals: Node2D = $Visuals
@onready var knight_form: Node2D = $Visuals/KnightForm
@onready var necromancer_form: Node2D = $Visuals/NecromancerForm
@onready var necro_sprite: AnimatedSprite2D = $Visuals/NecromancerForm/AnimatedSprite2D
@onready var shield_visual: Polygon2D = $Visuals/Shield
@onready var status_label: Label = $StatusLabel
@onready var cast_origin: Marker2D = $CastOrigin
@onready var vision_area: Area2D = $VisionArea
@onready var sword_area: Area2D = $SwordArea

var _arena_rect: Rect2 = Rect2()
var _current_phase: int = PHASE_ONE
var _phase_health: int = 0
var _phase_max_health: int = 0
var _encounter_active := false
var _is_defeated := false
var _invulnerable := false
var _phase_two_transition_pending := false
var _is_casting := false
var _is_stunned := false
var _pending_cast_action: StringName = &""
var _target_player: Node2D
var _facing_side: float = 1.0
var _visual_elapsed: float = 0.0
var velocity: Vector2 = Vector2.ZERO

var _melee_cooldown: float = 0.0
var _melee_window_timer: float = 0.0
var _contact_timer: float = 0.0
var _ranged_cooldown: float = 0.0
var _summon_cooldown: float = 0.0
var _retarget_timer: float = 0.0
var _current_melee_damage: int = 1
var _stun_timer: float = 0.0

var _move_target: Vector2 = Vector2.ZERO
var _melee_hit_ids: Dictionary = {}
var _active_thralls: Array[Node2D] = []
var _life_essences: Array[LifeEssence] = []
var _queued_bolt_directions: Array[Vector2] = []
var _queued_summon_count: int = 0
var _queued_ranged_cooldown: float = 0.0
var _queued_summon_cooldown: float = 0.0


func configure_arena(arena_rect: Rect2) -> void:
	_arena_rect = arena_rect


func _ready() -> void:
	vision_area.body_entered.connect(_on_vision_body_entered)
	vision_area.body_exited.connect(_on_vision_body_exited)
	sword_area.monitoring = false
	sword_area.area_entered.connect(_on_sword_area_entered)
	sword_area.body_entered.connect(_on_sword_body_entered)
	if necro_sprite != null:
		necro_sprite.animation_finished.connect(_on_necro_animation_finished)
		_configure_necro_cast_animations()

	_phase_max_health = phase_one_max_health
	_phase_health = phase_one_max_health

	if _arena_rect.size.length_squared() <= 0.001:
		_arena_rect = Rect2(global_position - Vector2(180.0, 110.0), Vector2(360.0, 220.0))

	_move_target = global_position
	_apply_phase_visuals()
	_refresh_status_label()


func _configure_necro_cast_animations() -> void:
	if necro_sprite == null or necro_sprite.sprite_frames == null:
		return

	for anim in [&"fire_projectile", &"summon_undead", &"gain_shield"]:
		if not necro_sprite.sprite_frames.has_animation(anim):
			continue
		necro_sprite.sprite_frames.set_animation_speed(anim, 12.0)
		necro_sprite.sprite_frames.set_animation_loop(anim, false)


func _physics_process(delta: float) -> void:
	if _is_defeated:
		return

	_tick_timers(delta)
	_cleanup_summoned_thralls()
	_reacquire_player()

	if not _encounter_active:
		velocity = Vector2.ZERO
		_animate_visuals(delta)
		return
	if _is_stunned:
		velocity = Vector2.ZERO
		_update_necro_animation()
		_animate_visuals(delta)
		return

	match _current_phase:
		PHASE_ONE:
			_process_phase_one(delta)
		PHASE_TWO:
			_process_phase_two(delta)
		PHASE_THREE:
			_process_phase_three(delta)

	global_position += velocity * delta
	_clamp_inside_arena()
	_update_facing()
	_try_body_contact_damage()
	_update_necro_animation()
	_animate_visuals(delta)


func take_damage(amount: int) -> void:
	if _is_defeated:
		return

	if not _encounter_active:
		_start_encounter()

	if _current_phase == PHASE_TWO and _invulnerable:
		_pulse_shield()
		SoundManager.play_enemy_hit()
		return

	_phase_health -= max(1, amount)
	_phase_health = max(0, _phase_health)
	SoundManager.play_enemy_hit()

	if _current_phase == PHASE_ONE and _phase_health <= 0:
		if not _phase_two_transition_pending:
			_phase_two_transition_pending = true
			call_deferred("_enter_phase_two")
		return

	if _current_phase == PHASE_TWO:
		var health_ratio := float(_phase_health) / float(max(1, _phase_max_health))
		if health_ratio <= phase_three_threshold:
			_enter_phase_three()

	if _phase_health <= 0:
		_defeat_boss()
		return

	_refresh_status_label()


func _start_encounter() -> void:
	if _encounter_active:
		return
	_encounter_active = true
	encounter_started.emit()


func _process_phase_one(_delta: float) -> void:
	if _target_player == null:
		velocity = Vector2.ZERO
		return

	var to_target := _target_player.global_position - global_position
	var distance := to_target.length()
	if distance > phase_one_melee_range:
		velocity = to_target.normalized() * phase_one_move_speed
	else:
		velocity = Vector2.ZERO
		_try_melee_attack(phase_one_melee_damage, phase_one_melee_cooldown)


func _process_phase_two(_delta: float) -> void:
	if _is_casting:
		velocity = Vector2.ZERO
		return

	_float_and_retarget(phase_two_move_speed, 1.0, 1.6, false)
	_try_cast_bolts(false)
	_try_summon_thralls(phase_two_summon_count, phase_two_summon_cooldown)

	if _target_player != null and global_position.distance_to(_target_player.global_position) <= phase_two_melee_range:
		_try_melee_attack(phase_two_melee_damage, phase_two_melee_cooldown)


func _process_phase_three(_delta: float) -> void:
	if _is_casting:
		velocity = Vector2.ZERO
		return

	_float_and_retarget(phase_three_move_speed, 0.45, 0.95, true)
	_try_cast_bolts(true)
	_try_summon_thralls(phase_three_summon_count, phase_three_summon_cooldown)

	if _target_player != null and global_position.distance_to(_target_player.global_position) <= phase_two_melee_range:
		_try_melee_attack(phase_two_melee_damage, phase_two_melee_cooldown)


func _float_and_retarget(speed: float, retarget_min: float, retarget_max: float, erratic: bool) -> void:
	if _retarget_timer <= 0.0 or global_position.distance_to(_move_target) <= 14.0:
		if _target_player != null:
			var around_target := _target_player.global_position + Vector2(randf_range(-90.0, 90.0), randf_range(-70.0, 70.0))
			_move_target = _clamp_point_to_arena(around_target, 24.0)
		else:
			_move_target = _random_arena_point(24.0)
		_retarget_timer = randf_range(retarget_min, retarget_max)

	var to_target := _move_target - global_position
	if to_target.length() <= 2.0:
		velocity = Vector2.ZERO
		return

	velocity = to_target.normalized() * speed
	if erratic:
		velocity += Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * speed * 0.35


func _try_melee_attack(damage: int, cooldown: float) -> void:
	if _melee_cooldown > 0.0:
		return
	if _target_player == null:
		return

	var direction := _target_player.global_position - global_position
	if direction == Vector2.ZERO:
		direction = Vector2(_facing_side, 0.0)

	_facing_side = sign(direction.x)
	if _facing_side == 0.0:
		_facing_side = 1.0

	_current_melee_damage = max(1, damage)
	_melee_cooldown = maxf(0.05, cooldown)
	_melee_window_timer = melee_window_time
	sword_area.position = Vector2(_facing_side * melee_reach, -2.0)
	sword_area.monitoring = true
	_melee_hit_ids.clear()
	_apply_melee_overlap_damage()
	SoundManager.play_enemy_attack()


func _on_sword_area_entered(area: Area2D) -> void:
	if _melee_window_timer <= 0.0:
		return
	_try_apply_melee_damage_once(area)


func _on_sword_body_entered(body: Node2D) -> void:
	if _melee_window_timer <= 0.0:
		return
	_try_apply_melee_damage_once(body)


func _apply_melee_overlap_damage() -> void:
	for area in sword_area.get_overlapping_areas():
		_try_apply_melee_damage_once(area)
	for body in sword_area.get_overlapping_bodies():
		_try_apply_melee_damage_once(body)


func _try_apply_melee_damage_once(target: Node) -> void:
	if target == null:
		return
	var key := target.get_instance_id()
	if _melee_hit_ids.has(key):
		return
	_melee_hit_ids[key] = true

	var player := _resolve_player_target(target)
	if player == null:
		return
	if player.has_method("take_hit"):
		player.take_hit(_current_melee_damage, global_position, contact_knockback_force)


func _resolve_player_target(target: Node) -> Node2D:
	if target is Node2D and target.is_in_group("player"):
		return target as Node2D
	if target is Area2D:
		var parent := target.get_parent()
		if parent is Node2D and parent.is_in_group("player"):
			return parent as Node2D
	return null


func _try_body_contact_damage() -> void:
	if _contact_timer > 0.0:
		return
	if _target_player == null:
		return
	if not is_instance_valid(_target_player):
		return
	if not _target_player.has_method("take_hit"):
		return
	if not _is_player_hitbox_overlapping():
		return

	_target_player.take_hit(contact_damage, global_position, contact_knockback_force)
	_contact_timer = contact_damage_cooldown
	SoundManager.play_enemy_attack()


func _is_player_hitbox_overlapping() -> bool:
	for area in get_overlapping_areas():
		if area == null:
			continue
		var parent := area.get_parent()
		if parent == _target_player and area.name == "HitBox":
			return true
	return false


func _try_cast_bolts(enraged: bool) -> void:
	if _ranged_cooldown > 0.0:
		return
	if _target_player == null:
		return
	if _is_casting:
		return

	var from := cast_origin.global_position
	var dir := (_target_player.global_position - from).normalized()
	if dir == Vector2.ZERO:
		dir = Vector2.RIGHT

	_queued_bolt_directions.clear()
	if enraged:
		var spread := deg_to_rad(phase_three_bolt_spread_degrees)
		var jitter_left := randf_range(-spread * 0.35, spread * 0.35)
		var jitter_right := randf_range(-spread * 0.35, spread * 0.35)
		_queued_bolt_directions.append(dir.rotated(-spread + jitter_left))
		_queued_bolt_directions.append(dir.rotated(spread + jitter_right))
		_queued_ranged_cooldown = phase_three_bolt_cooldown
	else:
		var spread_single := deg_to_rad(phase_two_bolt_spread_degrees)
		_queued_bolt_directions.append(dir.rotated(randf_range(-spread_single, spread_single)))
		_queued_ranged_cooldown = phase_two_bolt_cooldown

	if not _begin_necro_cast(&"fire_projectile"):
		_resolve_cast_action()


func _fire_bolt(direction: Vector2) -> void:
	var bolt := BOLT_SCENE.instantiate() as Area2D
	if bolt == null:
		return

	bolt.global_position = cast_origin.global_position
	bolt.set("direction", direction.normalized())
	bolt.set("speed", necro_bolt_speed * (1.15 if _current_phase == PHASE_THREE else 1.0))
	bolt.set("max_distance", necro_bolt_range)
	bolt.set("damage", necro_bolt_damage)

	var scene_root := get_tree().current_scene
	if scene_root == null:
		bolt.queue_free()
		return
	scene_root.add_child(bolt)


func _try_summon_thralls(count: int, cooldown: float) -> void:
	if _summon_cooldown > 0.0:
		return
	if _is_casting:
		return

	_cleanup_summoned_thralls()
	var remaining_slots := max_active_thralls - _active_thralls.size()
	if remaining_slots <= 0:
		_summon_cooldown = cooldown * 0.6
		return

	var safe_count: int = max(1, count)
	_queued_summon_count = mini(safe_count, remaining_slots)
	_queued_summon_cooldown = cooldown
	if _queued_summon_count <= 0:
		return
	if not _begin_necro_cast(&"summon_undead"):
		_resolve_cast_action()


func _spawn_thralls_now(count: int) -> void:
	var summon_count: int = max(0, count)
	var parent := get_parent()
	if parent == null:
		return
	for i in range(summon_count):
		if _active_thralls.size() >= max_active_thralls:
			break
		var thrall := THRALL_SCENE.instantiate() as Node2D
		if thrall == null:
			continue
		thrall.global_position = _random_arena_point(22.0)
		parent.add_child(thrall)
		_active_thralls.append(thrall)


func _cleanup_summoned_thralls() -> void:
	var alive_thralls: Array[Node2D] = []
	for thrall in _active_thralls:
		if thrall != null and is_instance_valid(thrall):
			alive_thralls.append(thrall)
	_active_thralls = alive_thralls


func _despawn_all_thralls() -> void:
	for thrall in _active_thralls:
		if thrall != null and is_instance_valid(thrall):
			thrall.queue_free()
	_active_thralls.clear()


func _enter_phase_two() -> void:
	if _current_phase != PHASE_ONE:
		return
	_phase_two_transition_pending = false
	_current_phase = PHASE_TWO
	_phase_max_health = phase_two_max_health
	_phase_health = phase_two_max_health
	_invulnerable = false
	_set_melee_window(false)
	_ranged_cooldown = 0.7
	_summon_cooldown = 1.4
	_retarget_timer = 0.0
	_apply_phase_visuals()
	_refresh_status_label("Necromancer reveals true form...")
	if not _begin_necro_cast(&"gain_shield"):
		_pending_cast_action = &"gain_shield"
		_resolve_cast_action()
	phase_changed.emit(PHASE_TWO)


func _enter_phase_three() -> void:
	if _current_phase == PHASE_THREE:
		return
	_current_phase = PHASE_THREE
	_is_casting = false
	_is_stunned = false
	_stun_timer = 0.0
	_pending_cast_action = &""
	_queued_bolt_directions.clear()
	_queued_summon_count = 0
	_queued_ranged_cooldown = 0.0
	_queued_summon_cooldown = 0.0
	_invulnerable = false
	_clear_life_essences()
	_retarget_timer = 0.0
	_ranged_cooldown = minf(_ranged_cooldown, 0.4)
	_summon_cooldown = minf(_summon_cooldown, 0.8)
	_apply_phase_visuals()
	_refresh_status_label()
	SoundManager.play_enemy_attack()
	phase_changed.emit(PHASE_THREE)


func _defeat_boss() -> void:
	if _is_defeated:
		return

	_is_defeated = true
	_encounter_active = false
	_is_casting = false
	_is_stunned = false
	_stun_timer = 0.0
	_pending_cast_action = &""
	_queued_bolt_directions.clear()
	_queued_summon_count = 0
	_queued_ranged_cooldown = 0.0
	_queued_summon_cooldown = 0.0
	_invulnerable = false
	_set_melee_window(false)
	_clear_life_essences()
	_despawn_all_thralls()
	_apply_phase_visuals()
	_refresh_status_label("Necromancer defeated")
	SoundManager.play_enemy_defeat()
	_drop_coin_loot(6, 10)
	QuestManager.record_enemy_kill(&"ancient_ruins_boss")
	defeated.emit()
	queue_free()


func _spawn_life_essences() -> void:
	_clear_life_essences()

	var center := _arena_rect.get_center()
	var radius := minf(_arena_rect.size.x, _arena_rect.size.y) * 0.34
	for i in range(3):
		var angle := (-PI * 0.5) + (TAU * (float(i) / 3.0))
		var spawn_point := center + Vector2.RIGHT.rotated(angle) * radius
		var essence := ESSENCE_SCENE.instantiate() as LifeEssence
		if essence == null:
			continue
		essence.global_position = _clamp_point_to_arena(spawn_point, 18.0)
		essence.destroyed.connect(_on_life_essence_destroyed)
		get_parent().add_child(essence)
		_life_essences.append(essence)


func _clear_life_essences() -> void:
	for essence in _life_essences:
		if essence != null and is_instance_valid(essence):
			essence.queue_free()
	_life_essences.clear()


func _on_life_essence_destroyed(essence: LifeEssence) -> void:
	_life_essences.erase(essence)
	_refresh_status_label()

	if _life_essences.is_empty() and _current_phase == PHASE_TWO:
		_invulnerable = false
		_enter_stun_from_shield_break()
		_apply_phase_visuals()
		_refresh_status_label()
		SoundManager.play_enemy_hit()


func _pulse_shield() -> void:
	if shield_visual == null:
		return
	shield_visual.modulate = Color(0.82, 0.58, 1.0, 0.9)
	var pulse := create_tween()
	pulse.tween_property(shield_visual, "modulate", Color(0.56, 0.36, 0.83, 0.42), 0.14)


func _tick_timers(delta: float) -> void:
	if _melee_cooldown > 0.0:
		_melee_cooldown -= delta
	if _contact_timer > 0.0:
		_contact_timer -= delta
	if _ranged_cooldown > 0.0:
		_ranged_cooldown -= delta
	if _summon_cooldown > 0.0:
		_summon_cooldown -= delta
	if _retarget_timer > 0.0:
		_retarget_timer -= delta
	if _melee_window_timer > 0.0:
		_melee_window_timer -= delta
		if _melee_window_timer <= 0.0:
			_set_melee_window(false)
	if _is_stunned and _stun_timer > 0.0:
		_stun_timer -= delta
		if _stun_timer <= 0.0:
			_recover_from_stun()


func _set_melee_window(active: bool) -> void:
	if not active:
		_melee_window_timer = 0.0
	sword_area.monitoring = active
	if not active:
		_melee_hit_ids.clear()


func _begin_necro_cast(action: StringName) -> bool:
	if action.is_empty():
		return false
	if _current_phase == PHASE_ONE:
		return false

	_pending_cast_action = action
	if necro_sprite == null or necro_sprite.sprite_frames == null:
		_is_casting = false
		return false
	if not necro_sprite.sprite_frames.has_animation(action):
		_is_casting = false
		return false

	_is_casting = true
	necro_sprite.stop()
	necro_sprite.animation = action
	necro_sprite.frame = 0
	necro_sprite.play()
	return true


func _on_necro_animation_finished() -> void:
	if not _is_casting:
		return
	_is_casting = false
	_resolve_cast_action()


func _resolve_cast_action() -> void:
	var action := _pending_cast_action
	_pending_cast_action = &""

	match action:
		&"fire_projectile":
			for direction in _queued_bolt_directions:
				_fire_bolt(direction)
			_queued_bolt_directions.clear()
			_ranged_cooldown = _queued_ranged_cooldown
			_queued_ranged_cooldown = 0.0
			SoundManager.play_enemy_attack()
		&"summon_undead":
			_spawn_thralls_now(_queued_summon_count)
			_queued_summon_count = 0
			_summon_cooldown = _queued_summon_cooldown
			_queued_summon_cooldown = 0.0
			SoundManager.play_enemy_attack()
		&"gain_shield":
			_invulnerable = true
			_spawn_life_essences()
			_apply_phase_visuals()
			_refresh_status_label()
			SoundManager.play_enemy_defeat()
		_:
			_queued_bolt_directions.clear()
			_queued_summon_count = 0
			_queued_ranged_cooldown = 0.0
			_queued_summon_cooldown = 0.0

	_update_necro_animation()


func _update_necro_animation() -> void:
	if necro_sprite == null:
		return
	if _current_phase == PHASE_ONE:
		return
	if _is_casting:
		return
	if _is_stunned:
		_play_necro_animation(&"idle")
		return

	if velocity.length() > 4.0:
		_play_necro_animation(&"move_right")
	else:
		_play_necro_animation(&"idle")


func _play_necro_animation(animation_name: StringName) -> void:
	if necro_sprite == null or necro_sprite.sprite_frames == null:
		return
	if not necro_sprite.sprite_frames.has_animation(animation_name):
		return
	if necro_sprite.animation == animation_name and necro_sprite.is_playing():
		return
	necro_sprite.play(animation_name)


func _on_vision_body_entered(body: Node) -> void:
	if not body.is_in_group("player"):
		return
	_target_player = body as Node2D
	_start_encounter()


func _on_vision_body_exited(body: Node) -> void:
	if body != _target_player:
		return
	_target_player = null


func _reacquire_player() -> void:
	if _target_player != null and is_instance_valid(_target_player):
		return
	_target_player = null
	for node in get_tree().get_nodes_in_group("player"):
		if node is Node2D:
			_target_player = node as Node2D
			return


func _clamp_inside_arena() -> void:
	if _arena_rect.size.length_squared() <= 0.001:
		return
	global_position = _clamp_point_to_arena(global_position, 14.0)


func _clamp_point_to_arena(point: Vector2, margin: float = 0.0) -> Vector2:
	if _arena_rect.size.length_squared() <= 0.001:
		return point
	var min_x := _arena_rect.position.x + margin
	var min_y := _arena_rect.position.y + margin
	var max_x := _arena_rect.end.x - margin
	var max_y := _arena_rect.end.y - margin
	return Vector2(clampf(point.x, min_x, max_x), clampf(point.y, min_y, max_y))


func _random_arena_point(margin: float = 0.0) -> Vector2:
	if _arena_rect.size.length_squared() <= 0.001:
		return global_position + Vector2(randf_range(-80.0, 80.0), randf_range(-48.0, 48.0))
	return Vector2(
		randf_range(_arena_rect.position.x + margin, _arena_rect.end.x - margin),
		randf_range(_arena_rect.position.y + margin, _arena_rect.end.y - margin)
	)


func _update_facing() -> void:
	if absf(velocity.x) <= 0.001:
		return
	_facing_side = sign(velocity.x)
	if _facing_side == 0.0:
		return
	visuals.scale.x = absf(visuals.scale.x) * _facing_side


func _animate_visuals(delta: float) -> void:
	_visual_elapsed += delta

	if _current_phase == PHASE_ONE:
		knight_form.position.y = sin(_visual_elapsed * 2.1) * 0.9
		necromancer_form.position = Vector2(0.0, -10.0)
	else:
		knight_form.position.y = 0.0
		necromancer_form.position = Vector2(0.0, -10.0 + sin(_visual_elapsed * 3.2) * 2.2)

	if shield_visual.visible:
		shield_visual.rotation -= delta * 2.0

	if necro_sprite != null:
		if _current_phase == PHASE_THREE:
			necro_sprite.modulate = Color(1.0, 0.88, 0.88, 1.0)
			necro_sprite.scale = Vector2.ONE * (1.0 + sin(_visual_elapsed * 12.0) * 0.05)
		else:
			necro_sprite.modulate = Color(1.0, 1.0, 1.0, 1.0)
			necro_sprite.scale = Vector2.ONE


func _apply_phase_visuals() -> void:
	knight_form.visible = _current_phase == PHASE_ONE
	necromancer_form.visible = _current_phase != PHASE_ONE
	shield_visual.visible = _current_phase == PHASE_TWO and _invulnerable
	_update_necro_animation()


func _refresh_status_label(override_text: String = "") -> void:
	if override_text != "":
		status_label.text = override_text
		return

	var phase_text := "Undead Knight"
	if _current_phase == PHASE_TWO:
		phase_text = "Necromancer"
	elif _current_phase == PHASE_THREE:
		phase_text = "Necromancer (Enraged)"

	if _is_stunned:
		status_label.text = "%s | Stunned" % phase_text
		return

	if _current_phase == PHASE_TWO and _invulnerable:
		status_label.text = "%s | Shielded (%d essences)" % [phase_text, _life_essences.size()]
		return

	status_label.text = "%s | HP %d/%d" % [phase_text, _phase_health, _phase_max_health]


func _enter_stun_from_shield_break() -> void:
	if _current_phase != PHASE_TWO:
		return
	_is_stunned = true
	var min_stun := maxf(0.1, shield_break_stun_min_time)
	var max_stun := maxf(min_stun, shield_break_stun_max_time)
	_stun_timer = randf_range(min_stun, max_stun)
	_cancel_cast_state()
	velocity = Vector2.ZERO
	_set_melee_window(false)
	_refresh_status_label()


func _recover_from_stun() -> void:
	_is_stunned = false
	_stun_timer = 0.0
	if _current_phase == PHASE_TWO and not _is_defeated:
		_invulnerable = true
		_spawn_life_essences()
		_apply_phase_visuals()
	_refresh_status_label()


func _cancel_cast_state() -> void:
	_is_casting = false
	_pending_cast_action = &""
	_queued_bolt_directions.clear()
	_queued_summon_count = 0
	_queued_ranged_cooldown = 0.0
	_queued_summon_cooldown = 0.0


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
