class_name WarpArea extends Area2D

var connected_stage := Util.StageName.NONE
var spawn_name : String

func activate() -> void:
	if connected_stage == Util.StageName.NONE:
		push_warning("WarpArea has no connected_stage_scene assigned.")
		return
	StageManager.switch_stage(connected_stage, spawn_name)
