class_name ExitTrigger
extends Area2D

@export var target_stage: StringName
@export var target_spawn: StringName
@export var player_group: StringName = &"player"

var _is_transitioning := false


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node) -> void:
	if _is_transitioning:
		return
	if not body.is_in_group(String(player_group)):
		return
	if target_stage == &"":
		return

	_is_transitioning = true
	call_deferred("_transition")


func _transition() -> void:
	var changed := StageManager.go_to_stage_with_spawn(target_stage, target_spawn)
	if not changed:
		_is_transitioning = false
