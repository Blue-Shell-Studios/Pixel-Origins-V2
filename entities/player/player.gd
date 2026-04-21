class_name Player extends CharacterBody2D

const WALK_SPEED := 90
const RUNNING_SPEED := 180
const HURT_TINT := Color(1.0, 0.35, 0.35, 1.0)

enum State {IDLE, ATTACK, WALKING, RUNNING, ACTION}

@onready var state_dictionary: Dictionary[int, PlayerState] = {
	State.IDLE : $PlayerStates/IdleState,
	State.ATTACK : $PlayerStates/AttackState,
	State.WALKING : $PlayerStates/WalkingState,
	State.RUNNING : $PlayerStates/RunningState,
	State.ACTION : $PlayerStates/ActionState
}

@onready var sprite: AnimatedSprite2D = $Sprite
@onready var animation_name: String = "idle"
@onready var animation_modifier: String = "_down"
@onready var look_dir: Util.Direction = Util.Direction.DOWN

@onready var state: PlayerState = state_dictionary[State.IDLE]
@onready var sword: Area2D = $Sword
@onready var actionable_finder: Area2D = $ActionableFinder

@export var max_health := 100
@export var attack_damage := 10
@export var hurt_tint_duration := 0.12

var health : int :
	set(value):
		health = clamp(value, 0, max_health)
		SignalBus.player_health_changed.emit(health, max_health)

var current_actionable: Area2D

func _ready() -> void:
	look(Util.Direction.DOWN)
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

func play_animation(name: String) -> void:
	animation_name = name
	sprite.play(animation_name + animation_modifier)

func look(direction: Util.Direction) -> void:
	if direction == look_dir: return
	look_dir = direction
	
	var collision: CollisionShape2D = sword.get_child(0)
	match look_dir:
		Util.Direction.LEFT:
			sprite.flip_h = true
			animation_modifier = "_side"
			
			sword.position = Vector2(-16.0, -7.0)
			collision.shape.size = Vector2(14.0, 22.0)
			actionable_finder.position = Vector2(-8.0, -7.0)
		Util.Direction.RIGHT:
			sprite.flip_h = false
			animation_modifier = "_side"
			
			sword.position = Vector2(16.0, -7.0)
			collision.shape.size = Vector2(14.0, 22.0)
			actionable_finder.position = Vector2(8.0, -7.0)
		Util.Direction.UP:
			sprite.flip_h = false
			animation_modifier = "_up"
			
			sword.position = Vector2(0.0, -23.0)
			collision.shape.size = Vector2(22.0, 14.0)
			actionable_finder.position = Vector2(0.0, -17.0)
		Util.Direction.DOWN:
			sprite.flip_h = false
			animation_modifier = "_down"
			
			sword.position = Vector2(0.0, 7.0)
			collision.shape.size = Vector2(22.0, 14.0)
			actionable_finder.position = Vector2(0.0, 6.0)
	sprite.play(animation_name + animation_modifier)

func _on_sword_area_entered(area: Area2D) -> void:
	if area.name != "Hitbox":
		return

	var target := area.get_parent()
	if target == self: return

	if target != null and target.has_method("take_damage"):
		target.take_damage(attack_damage)

func _on_actionable_finder_area_entered(area: Area2D) -> void:
	current_actionable = area

func _on_actionable_finder_area_exited(area: Area2D) -> void:
	if area == current_actionable:
		current_actionable = null

func interact_with_actionable() -> bool:
	if not is_instance_valid(current_actionable):
		return false

	var actionable_owner := current_actionable.get_parent()
	if actionable_owner != null and actionable_owner.has_method("interact"):
		return bool(actionable_owner.interact())

	return false

func heal_damage(amount: int) -> void:
	if amount <= 0: return
	health += amount

func take_damage(amount: int) -> void:
	if amount <= 0: return

	health -= amount
	_flash_hurt()
	
	if health == 0:
		SignalBus.player_died.emit()

func _flash_hurt() -> void:
	modulate = HURT_TINT
	await get_tree().create_timer(hurt_tint_duration).timeout
	modulate = Color.WHITE
