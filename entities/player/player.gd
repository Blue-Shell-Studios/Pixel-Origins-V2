class_name Player extends CharacterBody2D

const WALK_SPEED := 80
const RUNNING_SPEED := 160
const HURT_TINT := Color(1.0, 0.35, 0.35, 1.0)

enum State {IDLE, ATTACK, WALKING, RUNNING}

@onready var body: Human = $Human
@onready var state_dictionary: Dictionary[int, PlayerState] = {
	State.IDLE : $PlayerStates/IdleState,
	State.ATTACK : $PlayerStates/AttackState,
	State.WALKING : $PlayerStates/WalkingState,
	State.RUNNING : $PlayerStates/RunningState
}

@onready var state: PlayerState = state_dictionary[State.IDLE]
@onready var sword: Area2D = $Sword

@export var max_health := 100
@export var attack_damage := 10
@export var hurt_tint_duration := 0.12

var health : int :
	set(value):
		health = clamp(value, 0, max_health)
		SignalBus.player_health_changed.emit(health, max_health)

func _ready() -> void:
	add_to_group("player")
	health = max_health
	state.begin()

func _physics_process(delta: float) -> void:
	state.handle_input()
	state.process(delta)
	move_and_slide()

func change_state(new_state: State) -> void:
	var next_state: PlayerState = state_dictionary.get(new_state)
	if next_state == state:
		return

	state.end()
	state = next_state
	state.begin()
	
func look(direction: Util.Direction) -> void:
	body.look(direction)
	
	if direction == Util.Direction.RIGHT:
		sword.position.x = abs(sword.position.x)
	else:
		sword.position.x = -abs(sword.position.x)

func _on_sword_area_entered(area: Area2D) -> void:
	if area.name != "Hitbox":
		return

	var target := area.get_parent()
	if target == self: return

	if target != null and target.has_method("take_damage"):
		target.take_damage(attack_damage)

func take_damage(amount: int) -> void:
	if amount <= 0: return

	health -= amount
	_flash_hurt()
	
	if health == 0:
		SignalBus.player_died.emit()

func _flash_hurt() -> void:
	body.modulate = HURT_TINT
	await get_tree().create_timer(hurt_tint_duration).timeout
	body.modulate = Color.WHITE
