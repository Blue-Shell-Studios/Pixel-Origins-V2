extends CharacterBody2D

@export var move_speed: float = 100.0
@export var starting_weapons: PackedStringArray = []
@export var sword_damage: int = 1
@export var bow_damage: int = 1
@export var bow_arrow_speed: float = 250.0
@export var bow_arrow_range: float = 500.0
@export var max_health: int = 10
@export var knockback_decay: float = 1400.0
@export var hurt_lock_time: float = 0.12

var facing_direction: Vector2 = Vector2.DOWN
var facing_axis: StringName = &"down"
var selected_slot: int = 1
var equipped_weapon: StringName = &"sword"
var owned_weapons := {
	"sword": true,
	"bow": false,
}

@onready var sprite: AnimatedSprite2D = $Sprite
@onready var sword_slash_area: Area2D = $SwordSlashArea
@onready var health_bar: ProgressBar = $HUD/HUDRoot/HealthBar
@onready var health_label: Label = $HUD/HUDRoot/HealthLabel
@onready var coins_label: Label = $HUD/HUDRoot/CoinsLabel
@onready var active_quest_label: Label = $HUD/HUDRoot/ActiveQuestLabel
@onready var hud_status_label: Label = $HUD/HUDRoot/StatusLabel
@onready var slot_1_panel: Panel = $HUD/ActionBar/Slot1
@onready var slot_2_panel: Panel = $HUD/ActionBar/Slot2
@onready var slot_3_panel: Panel = $HUD/ActionBar/Slot3

var bow_aim_direction: Vector2 = Vector2.RIGHT
var health: int = 0
var coins: int = 0
var knockback_velocity: Vector2 = Vector2.ZERO
var is_attacking: bool = false
var is_hurt: bool = false
var hurt_timer: float = 0.0
var _sword_window_active := false
var _sword_hit_ids: Dictionary = {}
var _action_slot_idle_style: StyleBox
var _action_slot_active_style: StyleBox


func _ready() -> void:
	add_to_group("player")
	health = max_health
	sword_slash_area.monitoring = false
	sword_slash_area.area_entered.connect(_on_sword_area_entered)
	sword_slash_area.body_entered.connect(_on_sword_body_entered)
	_configure_animation_loops()
	sprite.animation_finished.connect(_on_sprite_animation_finished)
	_cache_action_slot_styles()
	_apply_starting_weapons()
	_select_slot(1)
	_refresh_hud()
	_play_animation("idle_down")
	if not QuestManager.quest_progressed.is_connected(_on_quest_progressed):
		QuestManager.quest_progressed.connect(_on_quest_progressed)
	if not QuestManager.npc_quest_state_changed.is_connected(_on_npc_quest_state_changed):
		QuestManager.npc_quest_state_changed.connect(_on_npc_quest_state_changed)


func _physics_process(delta: float) -> void:
	var input_dir := _get_input_dir()
	if is_attacking or is_hurt:
		input_dir = Vector2.ZERO
	if is_hurt and hurt_timer > 0.0:
		hurt_timer -= delta
		if hurt_timer <= 0.0:
			is_hurt = false
	var move_velocity := input_dir * move_speed
	knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, knockback_decay * delta)
	velocity = move_velocity + knockback_velocity
	_update_facing_from_input(input_dir)
	move_and_slide()
	_update_animation(input_dir)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_1:
				_select_slot(1)
			KEY_2:
				_select_slot(2)
			KEY_SPACE, KEY_J, KEY_K:
				_try_attack_pressed()


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_try_attack_pressed()


func _get_input_dir() -> Vector2:
	if _has_movement_actions():
		return Input.get_vector("move_left", "move_right", "move_up", "move_down")

	var x := int(Input.is_key_pressed(KEY_D)) - int(Input.is_key_pressed(KEY_A))
	var y := int(Input.is_key_pressed(KEY_S)) - int(Input.is_key_pressed(KEY_W))
	return Vector2(float(x), float(y)).normalized()


func _has_movement_actions() -> bool:
	return (
		InputMap.has_action("move_left")
		and InputMap.has_action("move_right")
		and InputMap.has_action("move_up")
		and InputMap.has_action("move_down")
	)


func _update_facing_from_input(input_dir: Vector2) -> void:
	if input_dir == Vector2.ZERO:
		return

	if absf(input_dir.x) > absf(input_dir.y):
		facing_direction = Vector2(sign(input_dir.x), 0.0)
		facing_axis = &"side"
	else:
		facing_direction = Vector2(0.0, sign(input_dir.y))
		facing_axis = &"up" if facing_direction.y < 0.0 else &"down"


func _update_animation(input_dir: Vector2) -> void:
	if facing_axis == &"side":
		sprite.flip_h = facing_direction.x < 0.0
	else:
		sprite.flip_h = false

	if is_attacking or is_hurt:
		return

	var moving := input_dir != Vector2.ZERO
	var prefix := "run_" if moving else "idle_"
	_play_animation(prefix + String(facing_axis))


func is_facing_point(target_global_position: Vector2, min_dot: float = 0.45) -> bool:
	var to_target := target_global_position - global_position
	if to_target == Vector2.ZERO:
		return true
	return facing_direction.dot(to_target.normalized()) >= min_dot


func has_weapon(weapon_id: StringName) -> bool:
	return owned_weapons.get(String(weapon_id), false)


func grant_weapon(weapon_id: StringName) -> void:
	if not owned_weapons.has(String(weapon_id)):
		return
	owned_weapons[String(weapon_id)] = true
	_refresh_hud()


func _apply_starting_weapons() -> void:
	for weapon_id in starting_weapons:
		grant_weapon(StringName(weapon_id))


func _select_slot(slot: int) -> void:
	match slot:
		2:
			if has_weapon(&"bow"):
				selected_slot = 2
				equipped_weapon = &"bow"
			else:
				selected_slot = 1
				equipped_weapon = &"sword"
		_:
			selected_slot = 1
			equipped_weapon = &"sword"
	_refresh_hud()


func _try_attack_pressed() -> void:
	if is_hurt:
		return
	if not has_weapon(equipped_weapon):
		hud_status_label.text = "Weapon not owned."
		return

	match equipped_weapon:
		&"sword":
			_do_sword_attack()
		&"bow":
			_do_bow_attack()
		_:
			hud_status_label.text = "Cannot attack."


func _do_sword_attack() -> void:
	if is_attacking:
		return

	hud_status_label.text = "Sword slash."
	is_attacking = true
	_play_animation("sword_attack_" + String(facing_axis))
	_activate_sword_slash()


func _activate_sword_slash() -> void:
	var dir := facing_direction
	if dir == Vector2.ZERO:
		dir = Vector2.DOWN
	sword_slash_area.position = dir * 8.0
	sword_slash_area.rotation = dir.angle()
	_sword_hit_ids.clear()
	_sword_window_active = true
	sword_slash_area.monitoring = true
	_apply_sword_overlap_damage()

	var tween := create_tween()
	tween.tween_interval(0.1)
	tween.tween_callback(func():
		_sword_window_active = false
		sword_slash_area.monitoring = false
	)


func _do_bow_attack() -> void:
	if is_attacking:
		return

	var to_mouse := get_global_mouse_position() - global_position
	if to_mouse == Vector2.ZERO:
		to_mouse = facing_direction
	var dir4 := _quantize_to_4dir(to_mouse)
	if dir4 == Vector2.ZERO:
		dir4 = Vector2.DOWN
	bow_aim_direction = dir4
	_apply_bow_facing(dir4)

	hud_status_label.text = "Fired bow."
	is_attacking = true
	_play_animation("bow_attack_" + String(facing_axis))
	_fire_bow()


func _fire_bow() -> void:
	ProjectileManager.spawn_arrow(
		global_position + bow_aim_direction * 16.0,
		bow_aim_direction,
		bow_arrow_speed,
		bow_arrow_range,
		bow_damage
	)


func _play_animation(animation_name: String) -> void:
	if sprite.sprite_frames == null:
		return
	if not sprite.sprite_frames.has_animation(StringName(animation_name)):
		return
	if sprite.animation == StringName(animation_name) and sprite.is_playing():
		return
	sprite.play(StringName(animation_name))


func _on_sprite_animation_finished() -> void:
	if not is_attacking:
		return

	if String(sprite.animation).begins_with("sword_attack_") or String(sprite.animation).begins_with("bow_attack_"):
		is_attacking = false


func _configure_animation_loops() -> void:
	if sprite.sprite_frames == null:
		return

	for anim in [&"sword_attack_down", &"sword_attack_side", &"sword_attack_up"]:
		if sprite.sprite_frames.has_animation(anim):
			sprite.sprite_frames.set_animation_loop(anim, false)
	for anim in [&"bow_attack_down", &"bow_attack_side", &"bow_attack_up"]:
		if sprite.sprite_frames.has_animation(anim):
			sprite.sprite_frames.set_animation_loop(anim, false)
	for anim in [&"hurt_down", &"hurt_side", &"hurt_up"]:
		if sprite.sprite_frames.has_animation(anim):
			sprite.sprite_frames.set_animation_loop(anim, false)


func _try_damage_target(target: Node, damage: int) -> void:
	if target == null:
		return
	if target == self:
		return
	if target.has_method("take_damage"):
		target.take_damage(damage)


func _apply_sword_overlap_damage() -> void:
	for body in sword_slash_area.get_overlapping_bodies():
		_try_damage_target_once(body, sword_damage)
	for area in sword_slash_area.get_overlapping_areas():
		_try_damage_target_once(area, sword_damage)


func _try_damage_target_once(target: Node, damage: int) -> void:
	if target == null:
		return
	var key := target.get_instance_id()
	if _sword_hit_ids.has(key):
		return
	_sword_hit_ids[key] = true
	_try_damage_target(target, damage)


func _on_sword_area_entered(area: Area2D) -> void:
	if not _sword_window_active:
		return
	_try_damage_target_once(area, sword_damage)


func _on_sword_body_entered(body: Node2D) -> void:
	if not _sword_window_active:
		return
	_try_damage_target_once(body, sword_damage)


func _weapon_name(weapon_id: StringName) -> String:
	match weapon_id:
		&"sword":
			return "Sword"
		&"bow":
			return "Bow"
		_:
			return "None"


func _refresh_hud() -> void:
	# Keep HP bar compact, but let it grow with max health.
	var hp_bar_width := clampf(float(max_health) * 12.0, 120.0, 220.0)
	health_bar.custom_minimum_size.x = hp_bar_width
	health_bar.size.x = hp_bar_width
	health_bar.max_value = float(max_health)
	health_bar.value = float(health)
	health_bar.tooltip_text = "HP %d/%d" % [health, max_health]
	health_label.text = "HP %d/%d" % [health, max_health]
	coins_label.text = "Coins: %d" % coins
	var quest_summary := QuestManager.get_active_quest_summary()
	if quest_summary.is_empty():
		active_quest_label.text = "Active Quest: None"
	else:
		active_quest_label.text = "Active Quest: %s" % quest_summary
	_refresh_action_bar()


func take_damage(amount: int) -> void:
	health -= max(1, amount)
	if health < 0:
		health = 0
	is_attacking = false
	_start_hurt_feedback()
	hud_status_label.text = "Took %d damage." % max(1, amount)
	_refresh_hud()

	if health <= 0:
		hud_status_label.text = "You were defeated."
		set_physics_process(false)
		set_process_input(false)


func take_hit(amount: int, source_global_position: Vector2, force: float = 280.0) -> void:
	take_damage(amount)
	var away := global_position - source_global_position
	if away == Vector2.ZERO:
		away = Vector2(0.0, 1.0)
	knockback_velocity = away.normalized() * force


func add_coins(amount: int) -> void:
	coins += max(0, amount)
	hud_status_label.text = "Picked up %d coin%s." % [amount, "" if amount == 1 else "s"]
	_refresh_hud()


func try_spend_coins(amount: int) -> bool:
	if amount <= 0:
		return true
	if coins < amount:
		hud_status_label.text = "Need %d more coins." % (amount - coins)
		return false
	coins -= amount
	hud_status_label.text = "Spent %d coin%s." % [amount, "" if amount == 1 else "s"]
	_refresh_hud()
	return true


func heal_to_full() -> void:
	health = max_health
	hud_status_label.text = "Health fully restored."
	_refresh_hud()


func _start_hurt_feedback() -> void:
	var hurt_anim := "hurt_" + String(facing_axis)
	if sprite.sprite_frames != null and sprite.sprite_frames.has_animation(StringName(hurt_anim)):
		is_hurt = true
		hurt_timer = hurt_lock_time
		_play_animation(hurt_anim)


func _on_quest_progressed(_quest_id: StringName, _progress: int, _required: int) -> void:
	_refresh_hud()


func _on_npc_quest_state_changed(_npc_id: StringName) -> void:
	_refresh_hud()


func get_session_state() -> Dictionary:
	return {
		"health": health,
		"coins": coins,
		"selected_slot": selected_slot,
		"equipped_weapon": String(equipped_weapon),
		"owned_weapons": owned_weapons.duplicate(true),
	}


func apply_session_state(state: Dictionary) -> void:
	if state.has("health"):
		health = clampi(int(state["health"]), 0, max_health)
	if state.has("coins"):
		coins = max(0, int(state["coins"]))
	if state.has("owned_weapons"):
		owned_weapons = (state["owned_weapons"] as Dictionary).duplicate(true)

	if state.has("selected_slot"):
		_select_slot(int(state["selected_slot"]))
	else:
		_refresh_hud()


func _cache_action_slot_styles() -> void:
	_action_slot_idle_style = slot_1_panel.get_theme_stylebox("panel")
	if _action_slot_idle_style is StyleBoxFlat:
		var active := (_action_slot_idle_style as StyleBoxFlat).duplicate() as StyleBoxFlat
		active.bg_color = Color(0.93, 0.8, 0.28, 0.95)
		active.border_width_left = 2
		active.border_width_top = 2
		active.border_width_right = 2
		active.border_width_bottom = 2
		active.border_color = Color(0.98, 0.95, 0.66, 1)
		_action_slot_active_style = active


func _refresh_action_bar() -> void:
	if _action_slot_idle_style == null:
		_action_slot_idle_style = slot_1_panel.get_theme_stylebox("panel")
	if _action_slot_active_style == null:
		_cache_action_slot_styles()

	slot_1_panel.visible = true
	slot_2_panel.visible = has_weapon(&"bow")
	slot_3_panel.visible = false

	_apply_slot_visual(slot_1_panel, equipped_weapon == &"sword", has_weapon(&"sword"))
	_apply_slot_visual(slot_2_panel, equipped_weapon == &"bow", has_weapon(&"bow"))
	# Slot3 is deprecated; keep hidden for scene compatibility.


func _apply_slot_visual(panel: Panel, is_active: bool, is_owned: bool) -> void:
	if panel == null:
		return
	if not panel.visible:
		return
	panel.modulate = Color(1, 1, 1, 1) if is_owned else Color(0.55, 0.55, 0.55, 1)
	panel.remove_theme_stylebox_override("panel")
	if is_active and _action_slot_active_style != null:
		panel.add_theme_stylebox_override("panel", _action_slot_active_style)
	elif _action_slot_idle_style != null:
		panel.add_theme_stylebox_override("panel", _action_slot_idle_style)


func _quantize_to_4dir(vec: Vector2) -> Vector2:
	if absf(vec.x) > absf(vec.y):
		return Vector2(sign(vec.x), 0.0)
	if absf(vec.y) > 0.0:
		return Vector2(0.0, sign(vec.y))
	return Vector2.ZERO


func _apply_bow_facing(dir: Vector2) -> void:
	if dir.x != 0.0:
		facing_axis = &"side"
		facing_direction = Vector2(sign(dir.x), 0.0)
	else:
		facing_axis = &"up" if dir.y < 0.0 else &"down"
		facing_direction = Vector2(0.0, sign(dir.y))
