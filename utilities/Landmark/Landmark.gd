class_name Landmark extends Area2D
 
var is_active := false
var connected_stage : Util.StageName
var spawn_name : String

func _process(delta: float) -> void:
	if not is_active: return
	
	if Input.is_action_pressed("action"):
		StageManager.switch_stage(connected_stage, spawn_name)
