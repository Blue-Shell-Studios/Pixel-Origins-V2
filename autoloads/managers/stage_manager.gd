extends Node

const STAGES := {
	"start_screen": "res://stages/startscreen/start_screen.tscn",
	"overworld": "res://stages/overworld/overworld.tscn",
	"bramble_wilds": "res://stages/bramblewilds/bramble_wilds.tscn",
	"tauracre": "res://stages/tauracre/tauracre.tscn",
}

var current_stage_id: StringName = &""
var previous_stage_id: StringName = &""
var pending_spawn_id: StringName = &""


func _ready() -> void:
	get_tree().scene_changed.connect(_on_scene_changed)
	# Boot into an explicit first stage so startup flow is centralized here.
	call_deferred("go_to_stage", &"start_screen")


func has_stage(stage_id: StringName) -> bool:
	return STAGES.has(String(stage_id))


func get_stage_path(stage_id: StringName) -> String:
	return STAGES.get(String(stage_id), "")


func go_to_stage(stage_id: StringName) -> bool:
	if not has_stage(stage_id):
		push_error("StageManager: Unknown stage id '%s'." % String(stage_id))
		return false

	var stage_path := get_stage_path(stage_id)
	if stage_path.is_empty():
		push_error("StageManager: Empty scene path for stage id '%s'." % String(stage_id))
		return false

	_capture_active_player_state()

	var err := get_tree().change_scene_to_file(stage_path)
	if err != OK:
		push_error("StageManager: Failed to load '%s' (error: %d)." % [stage_path, err])
		return false

	previous_stage_id = current_stage_id
	current_stage_id = stage_id
	return true


func go_to_stage_with_spawn(stage_id: StringName, spawn_id: StringName) -> bool:
	pending_spawn_id = spawn_id
	var changed := go_to_stage(stage_id)
	if not changed:
		pending_spawn_id = &""
	return changed


func reload_current_stage() -> bool:
	if String(current_stage_id).is_empty():
		push_warning("StageManager: No current stage to reload.")
		return false

	return go_to_stage(current_stage_id)


func go_to_previous_stage() -> bool:
	if String(previous_stage_id).is_empty():
		push_warning("StageManager: No previous stage to return to.")
		return false

	return go_to_stage(previous_stage_id)


func consume_pending_spawn() -> StringName:
	var spawn_id := pending_spawn_id
	pending_spawn_id = &""
	return spawn_id


func _on_scene_changed() -> void:
	var scene_root := get_tree().current_scene
	if scene_root == null:
		return

	if pending_spawn_id.is_empty():
		_apply_saved_player_state(scene_root)
		return

	_apply_pending_spawn(scene_root)
	_apply_saved_player_state(scene_root)


func _apply_pending_spawn(scene_root: Node) -> void:
	var spawn_node := scene_root.get_node_or_null("SpawnPoints/%s" % String(pending_spawn_id)) as Node2D
	if spawn_node == null:
		push_warning("StageManager: Spawn point '%s' not found in stage '%s'." % [String(pending_spawn_id), String(current_stage_id)])
		pending_spawn_id = &""
		return

	var player := _find_player(scene_root)
	if player == null:
		push_warning("StageManager: Player not found in stage '%s' while applying spawn '%s'." % [String(current_stage_id), String(pending_spawn_id)])
		pending_spawn_id = &""
		return

	player.global_position = spawn_node.global_position
	pending_spawn_id = &""


func _find_player(scene_root: Node) -> Node2D:
	for node in get_tree().get_nodes_in_group("player"):
		if node is Node2D and scene_root.is_ancestor_of(node):
			return node as Node2D

	var named_player := scene_root.get_node_or_null("Player")
	if named_player is Node2D:
		return named_player as Node2D
	return null


func _capture_active_player_state() -> void:
	var scene_root := get_tree().current_scene
	if scene_root == null:
		return
	var player := _find_player(scene_root)
	if player == null:
		return
	SaveManager.capture_player_state(player)


func _apply_saved_player_state(scene_root: Node) -> void:
	if not SaveManager.has_player_state():
		return
	var player := _find_player(scene_root)
	if player == null:
		return
	SaveManager.apply_player_state(player)
