extends Node

const STAGES := {
	"start_screen": "res://stages/startscreen/start_screen.tscn",
	"overworld": "res://stages/overworld/overworld.tscn",
	"bramble_wilds": "res://stages/bramblewilds/bramble_wilds.tscn",
	"tauracre": "res://stages/tauracre/tauracre.tscn",
	"ancient_ruins": "res://stages/ancientruins/ancient_ruins.tscn",
}
const OVERWORLD_STAGE_ID: StringName = &"overworld"
const OVERWORLD_RETURN_SPAWNS := {
	&"tauracre": &"tauracre_landmark",
	&"bramble_wilds": &"bramble_wilds_landmark",
	&"ancient_ruins": &"ancient_ruins_landmark",
}

var current_stage_id: StringName = &""
var previous_stage_id: StringName = &""
var pending_spawn_id: StringName = &""
var _death_checkpoint_valid := false
var _death_checkpoint_snapshot: Dictionary = {}
var _death_checkpoint_return_spawn: StringName = &""


func _ready() -> void:
	get_tree().scene_changed.connect(_on_scene_changed)
	# Boot into an explicit first stage so startup flow is centralized here.
	call_deferred("go_to_stage", &"start_screen")


func has_stage(stage_id: StringName) -> bool:
	return STAGES.has(String(stage_id))


func get_stage_path(stage_id: StringName) -> String:
	return STAGES.get(String(stage_id), "")


func go_to_stage(stage_id: StringName) -> bool:
	_maybe_set_death_checkpoint(stage_id)
	return _go_to_stage(stage_id, true)


func go_to_stage_with_spawn(stage_id: StringName, spawn_id: StringName) -> bool:
	_maybe_set_death_checkpoint(stage_id)
	pending_spawn_id = spawn_id
	var changed := _go_to_stage(stage_id, true)
	if not changed:
		pending_spawn_id = &""
	return changed


func recover_player_after_death() -> bool:
	if _death_checkpoint_valid:
		SaveManager.restore_snapshot(_death_checkpoint_snapshot)
		pending_spawn_id = _death_checkpoint_return_spawn
		var recovered := _go_to_stage(OVERWORLD_STAGE_ID, false)
		if recovered:
			_clear_death_checkpoint()
		return recovered

	push_warning("StageManager: No death checkpoint available; returning to overworld.")
	return _go_to_stage(OVERWORLD_STAGE_ID, false)


func _go_to_stage(stage_id: StringName, capture_state: bool) -> bool:
	if not has_stage(stage_id):
		push_error("StageManager: Unknown stage id '%s'." % String(stage_id))
		return false

	var stage_path := get_stage_path(stage_id)
	if stage_path.is_empty():
		push_error("StageManager: Empty scene path for stage id '%s'." % String(stage_id))
		return false

	if capture_state:
		_capture_active_player_state()

	var err := get_tree().change_scene_to_file(stage_path)
	if err != OK:
		push_error("StageManager: Failed to load '%s' (error: %d)." % [stage_path, err])
		return false

	previous_stage_id = current_stage_id
	current_stage_id = stage_id
	if stage_id == OVERWORLD_STAGE_ID and previous_stage_id != OVERWORLD_STAGE_ID:
		_clear_death_checkpoint()
	return true


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
	else:
		_apply_pending_spawn(scene_root)
		_apply_saved_player_state(scene_root)

	if not current_stage_id.is_empty():
		SoundManager.play_music_for_stage(current_stage_id)


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


func _maybe_set_death_checkpoint(target_stage_id: StringName) -> void:
	if current_stage_id != OVERWORLD_STAGE_ID:
		return
	if target_stage_id == OVERWORLD_STAGE_ID:
		return

	var return_spawn := _resolve_overworld_return_spawn(target_stage_id)
	if return_spawn.is_empty():
		return

	var scene_root := get_tree().current_scene
	if scene_root == null:
		return
	var player := _find_player(scene_root)
	var snapshot := SaveManager.create_snapshot(player)
	if snapshot.is_empty():
		return

	_death_checkpoint_snapshot = snapshot.duplicate(true)
	_death_checkpoint_return_spawn = return_spawn
	_death_checkpoint_valid = true


func _resolve_overworld_return_spawn(stage_id: StringName) -> StringName:
	if OVERWORLD_RETURN_SPAWNS.has(stage_id):
		return OVERWORLD_RETURN_SPAWNS[stage_id]
	var stage_key := String(stage_id).strip_edges()
	if stage_key.is_empty():
		return &""
	return StringName("%s_landmark" % stage_key)


func _clear_death_checkpoint() -> void:
	_death_checkpoint_valid = false
	_death_checkpoint_snapshot = {}
	_death_checkpoint_return_spawn = &""
