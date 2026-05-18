class_name LandmarkTrigger
extends Area2D

signal player_entered(trigger: LandmarkTrigger)
signal player_exited(trigger: LandmarkTrigger)

@export var landmark_id: StringName
@export var prompt_text: String = "Press Interact to enter location"
@export var target_stage: StringName
@export var target_spawn: StringName
@export var player_group: StringName = &"player"


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	add_to_group("landmark_trigger")


func can_enter() -> bool:
	return not target_stage.is_empty()


func try_enter() -> bool:
	if not can_enter():
		return false
	call_deferred("_transition")
	return true


func _on_body_entered(body: Node) -> void:
	if not body.is_in_group(String(player_group)):
		return
	player_entered.emit(self)


func _on_body_exited(body: Node) -> void:
	if not body.is_in_group(String(player_group)):
		return
	player_exited.emit(self)


func _transition() -> void:
	StageManager.go_to_stage_with_spawn(target_stage, target_spawn)
