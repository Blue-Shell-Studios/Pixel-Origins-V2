extends Node

const PLAYER = preload("uid://dfex4074y0qp5")

const stages: Dictionary[Util.StageName, Resource] = {
	Util.StageName.TAURACRE: preload("uid://dcce0y587640t"),
	Util.StageName.OVERWORLD: preload("uid://rxrtnnpdlixq"),
	Util.StageName.BRAMBLEWILDS: preload("uid://b43klvpvq3j2r")
}

@onready var current_scene := get_tree().current_scene

var player: Player
var current_stage: Stage

func _ready() -> void:
	player = PLAYER.instantiate()
	current_stage = stages[Util.StageName.OVERWORLD].instantiate()
	
	current_scene.add_child(player)
	current_scene.add_child(current_stage)

func switch_stage(stage_name: Util.StageName, spawn_name: String) -> void:
	if current_stage: current_stage.queue_free()
	
	current_stage = stages[stage_name].instantiate()

	if current_stage == null:
		push_warning("StageManager could not instantiate stage as Stage.")
		return

	get_tree().current_scene.call_deferred("add_child", current_stage)

	var spawn := current_stage.get_node_or_null("Spawns/" + spawn_name)
	
	if spawn and player:
		player.call_deferred("set_global_position", spawn.global_position)
