class_name Goblin extends Monster

enum State {IDLE, ATTACK, WALKING, RUNNING}

const WALKING_SPEED := 50.0
const RUNNING_SPEED := 80.0
const HURT_TINT := Color(1.0, 0.35, 0.35, 1.0)

@export var max_health := 40
@export var attack_damage := 8
@export var attack_range := 20.0
@export var hurt_tint_duration := 0.12

@onready var state_dictionary: Dictionary[State, GoblinState] = {
	State.IDLE : $States/IdleState,
	State.WALKING : $States/WalkingState,
	State.RUNNING : $States/RunnningState,
	State.ATTACK : $States/AttackState
}

@onready var sprite: AnimatedSprite2D = $Sprite
@onready var vision: Area2D = $Vision
@onready var sword: Area2D = $Sword
@onready var health_bar: ProgressBar = $HealthBar


var target_position := Vector2.ZERO

var state : GoblinState
var target : Player

var camp: EnemyCamp
var camp_position: Vector2
var health : int :
	set(value):
		health = clamp(value, 0, max_health)

func _ready() -> void:
	health = max_health
	health_bar.max_value = max_health
	health_bar.value = health
	_update_health_bar_visibility()

	state = state_dictionary[State.IDLE]
	state.begin()
	
	var parent = get_parent()
	
	if parent is EnemyCamp:
		camp = parent
		camp_position = global_position
		
		vision.set_deferred("monitoring", false)
		vision.set_deferred("monitorable", false)

func _physics_process(delta: float) -> void:
	state.handle_input()
	state.process(delta)
	move_and_slide()

func change_state(new_state: State) -> void:
	var next_state: GoblinState = state_dictionary.get(new_state)
	if next_state == null:
		push_warning("Goblin.change_state got unmapped state: %s" % str(new_state))
		return

	if next_state == state:
		return

	state.end()
	state = next_state
	state.begin()

func has_target() -> bool:
	return is_instance_valid(target)

func target_player(player: Player) -> void:
	target = player

func set_target_position(pos: Vector2) -> void:
	target_position = pos

func move_towards(target_pos: Vector2, speed: float) -> void:
	var direction := global_position.direction_to(target_pos)
	velocity = direction * speed
	look(direction)

func has_reached_target() -> bool:
	return global_position.distance_to(target_position) < 10.0

func stop() -> void:
	velocity = Vector2.ZERO

func look(direction: Vector2) -> void:
	if direction.x < 0.0:
		sprite.flip_h = true
		sword.position.x = -abs(sword.position.x)
	elif direction.x > 0.0:
		sprite.flip_h = false
		sword.position.x = abs(sword.position.x)

func take_damage(amount: int) -> void:
	if amount <= 0:
		return

	health -= amount
	_refresh_health_bar()

	if health == 0:
		_die()
		return

	_flash_hurt()

func _die() -> void:
	velocity = Vector2.ZERO
	
	if is_instance_valid(camp):
		camp.monsters.erase(self)

	SignalBus.enemy_killed.emit("goblin")
	queue_free()

func _flash_hurt() -> void:
	sprite.modulate = HURT_TINT
	await get_tree().create_timer(hurt_tint_duration).timeout
	sprite.modulate = Color.WHITE

func _refresh_health_bar() -> void:
	health_bar.max_value = max_health
	health_bar.value = health
	_update_health_bar_visibility()

func _update_health_bar_visibility() -> void:
	health_bar.visible = health < max_health
