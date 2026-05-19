class_name ForestWispEnemy
extends BaseEnemy

const MOVE_SPEED := 120.0
const MAX_CHASE_DISTANCE := 360.0
const RETURN_STOP_DISTANCE := 6.0
const MAX_HEALTH := 3
const CONTACT_DAMAGE := 1
const CONTACT_DAMAGE_COOLDOWN := 0.7
const CONTACT_KNOCKBACK_FORCE := 280.0
const AGGRO_RANGE := 220.0


func _ready() -> void:
	enemy_type = &"forest_wisp"
	attack_sfx_id = &"enemy_forest_wisp_attack"
	hit_sfx_id = &"enemy_hit"
	defeat_sfx_id = &"enemy_forest_wisp_defeat"
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
