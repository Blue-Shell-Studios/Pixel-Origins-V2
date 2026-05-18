class_name EntranceTrigger
extends Area2D

signal player_entered(trigger: EntranceTrigger)
signal player_exited(trigger: EntranceTrigger)

@export var entrance_id: StringName
@export var prompt_text: String = "Press Interact to enter location"
@export var target_stage: StringName
@export var target_spawn: StringName
@export var player_group: StringName = &"player"

var _player_inside := false
var _is_transitioning := false


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	add_to_group("entrance_trigger")


func can_enter() -> bool:
	return _player_inside and not _is_transitioning and not target_stage.is_empty()


func try_enter() -> bool:
	if not can_enter():
		return false
	_is_transitioning = true
	call_deferred("_transition")
	return true


func _on_body_entered(body: Node) -> void:
	if not body.is_in_group(String(player_group)):
		return
	_player_inside = true
	player_entered.emit(self)


func _on_body_exited(body: Node) -> void:
	if not body.is_in_group(String(player_group)):
		return
	_player_inside = false
	player_exited.emit(self)


func _transition() -> void:
	var changed := StageManager.go_to_stage_with_spawn(target_stage, target_spawn)
	if not changed:
		_is_transitioning = false
