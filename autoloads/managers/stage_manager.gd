extends Node

const PLAYER = preload("uid://dfex4074y0qp5")

const stages: Dictionary[Util.StageName, Resource] = {
	Util.StageName.TAURACRE: preload("uid://blqef7t1rrrvp"),
	Util.StageName.OVERWORLD: preload("uid://dpworspig040p"),
	Util.StageName.BRAMBLEWILDS: preload("uid://xf1140ihx0yy"),
	Util.StageName.START_SCREEN: preload("uid://grwu3pkt0qb5")
}

@onready var current_scene := get_tree().current_scene

var player: Player
var current_stage: Stage
var current_stage_name := Util.StageName.NONE

func _ready() -> void:
	current_stage = stages[Util.StageName.START_SCREEN].instantiate()
	current_stage_name = Util.StageName.START_SCREEN
	current_scene.add_child(current_stage)

func switch_stage(stage_name: Util.StageName, ...args) -> void:
	if current_stage: current_stage.queue_free()
	
	current_stage = stages[stage_name].instantiate()
	current_stage_name = stage_name

	if current_stage == null:
		push_warning("StageManager could not instantiate stage as Stage.")
		return

	get_tree().current_scene.add_child(current_stage)

	var spawn_name := ""
	if args.size() > 0 and args[0] is String:
		spawn_name = args[0]

	var exact_position: Variant = null
	if args.size() > 1 and args[1] is Vector2:
		exact_position = args[1]

	var loaded_health: Variant = null
	if args.size() > 2 and (args[2] is int or args[2] is float):
		loaded_health = args[2]

	var loaded_gold: Variant = null
	if args.size() > 3 and (args[3] is int or args[3] is float):
		loaded_gold = args[3]

	match current_stage.type:
		Stage.Type.MAP:
			require_player(true)
			_apply_loaded_player_state(loaded_health, loaded_gold)
			var saved_position := _place_player(spawn_name, exact_position)
			_save_progress(stage_name, saved_position)
		Stage.Type.LOCATION:
			require_player(true)
			_apply_loaded_player_state(loaded_health, loaded_gold)
			var saved_position := _place_player(spawn_name, exact_position)
			_save_progress(stage_name, saved_position)
		Stage.Type.UI:
			require_player(false)

func load_last_save() -> bool:
	var progress := SaveManager.load_progress()
	if progress.is_empty():
		return false

	var stage_name := str(progress.get("stage", ""))
	var stage := stage_name_from_string(stage_name)
	if stage == Util.StageName.NONE or stage == Util.StageName.START_SCREEN:
		return false

	var position_data = progress.get("position", {})
	if not (position_data is Dictionary):
		return false

	var x := float(position_data.get("x", 0.0))
	var y := float(position_data.get("y", 0.0))

	var health: Variant = null
	if progress.has("health"):
		health = int(progress.get("health", 0))

	var gold: Variant = null
	if progress.has("gold"):
		gold = int(progress.get("gold", 0))

	switch_stage(stage, "", Vector2(x, y), health, gold)
	return true

func require_player(is_player_needed: bool) -> void:
	if is_player_needed:
		if not is_instance_valid(player):
			player = PLAYER.instantiate()
		if player.get_parent() == null:
			current_scene.add_child(player)
	else:
		if is_instance_valid(player):
			player.queue_free()
			player = null

func _place_player(spawn_name: String, exact_position: Variant = null) -> Vector2:
	if not is_instance_valid(player):
		return Vector2.ZERO

	var target_position := player.global_position

	if spawn_name != "":
		var spawn := current_stage.get_node_or_null("Spawns/" + spawn_name)
		if spawn is Node2D:
			target_position = spawn.global_position
			player.call_deferred("set_global_position", spawn.global_position)

	if exact_position is Vector2:
		target_position = exact_position
		player.call_deferred("set_global_position", exact_position)

	return target_position

func _save_progress(stage_name: Util.StageName, position: Vector2) -> void:
	if stage_name == Util.StageName.NONE or stage_name == Util.StageName.START_SCREEN:
		return

	var stage_name_string := stage_name_to_string(stage_name)
	if stage_name_string == "":
		return

	if not is_instance_valid(player):
		return

	SaveManager.save_progress(stage_name_string, position, player.health, QuestManager.get_total_gold())

func _apply_loaded_player_state(loaded_health: Variant, loaded_gold: Variant) -> void:
	if loaded_gold is int or loaded_gold is float:
		QuestManager.set_total_gold(int(loaded_gold))

	if not is_instance_valid(player):
		return

	if loaded_health is int or loaded_health is float:
		player.health = int(clamp(int(loaded_health), 0, player.max_health))

func stage_name_to_string(stage_name: Util.StageName) -> String:
	match stage_name:
		Util.StageName.TAURACRE:
			return "TAURACRE"
		Util.StageName.OVERWORLD:
			return "OVERWORLD"
		Util.StageName.BRAMBLEWILDS:
			return "BRAMBLEWILDS"
		Util.StageName.START_SCREEN:
			return "START_SCREEN"
		_:
			return ""

func stage_name_from_string(value: String) -> Util.StageName:
	match value:
		"TAURACRE":
			return Util.StageName.TAURACRE
		"OVERWORLD":
			return Util.StageName.OVERWORLD
		"BRAMBLEWILDS":
			return Util.StageName.BRAMBLEWILDS
		"START_SCREEN":
			return Util.StageName.START_SCREEN
		_:
			return Util.StageName.NONE
