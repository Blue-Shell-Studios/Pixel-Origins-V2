extends Node

signal event_marked(event_id: StringName)
signal spawn_consumed(spawn_id: StringName)

var _events: Dictionary = {}
var _consumed_spawns: Dictionary = {}


func mark_event(event_id: StringName) -> void:
	var id := _normalize_token(event_id)
	if id.is_empty():
		return
	if _events.has(id):
		return
	_events[id] = true
	event_marked.emit(id)


func has_event(event_id: StringName) -> bool:
	var id := _normalize_token(event_id)
	if id.is_empty():
		return false
	return _events.has(id)


func mark_npc_talked(npc_id: StringName) -> void:
	var id := _normalize_token(npc_id)
	if id.is_empty():
		return
	mark_event(StringName("npc_talked/%s" % String(id)))


func mark_quest_started(quest_id: StringName) -> void:
	var id := _normalize_token(quest_id)
	if id.is_empty():
		return
	mark_event(StringName("quest_started/%s" % String(id)))


func mark_quest_completed(quest_id: StringName) -> void:
	var id := _normalize_token(quest_id)
	if id.is_empty():
		return
	mark_event(StringName("quest_completed/%s" % String(id)))


func mark_task_completed(task_id: StringName) -> void:
	var id := _normalize_token(task_id)
	if id.is_empty():
		return
	mark_event(StringName("task_completed/%s" % String(id)))


func consume_spawn(spawn_id: StringName) -> void:
	var id := _normalize_token(spawn_id)
	if id.is_empty():
		return
	if _consumed_spawns.has(id):
		return
	_consumed_spawns[id] = true
	spawn_consumed.emit(id)


func is_spawn_consumed(spawn_id: StringName) -> bool:
	var id := _normalize_token(spawn_id)
	if id.is_empty():
		return false
	return _consumed_spawns.has(id)


func should_spawn(spawn_id: StringName, required_events: PackedStringArray = PackedStringArray(), blocked_events: PackedStringArray = PackedStringArray()) -> bool:
	if is_spawn_consumed(spawn_id):
		return false

	for required_event in required_events:
		if not has_event(StringName(required_event)):
			return false

	for blocked_event in blocked_events:
		if has_event(StringName(blocked_event)):
			return false

	return true


func clear_all() -> void:
	_events.clear()
	_consumed_spawns.clear()


func get_session_state() -> Dictionary:
	return {
		"events": _events.duplicate(true),
		"consumed_spawns": _consumed_spawns.duplicate(true),
	}


func apply_session_state(state: Dictionary) -> void:
	_events.clear()
	_consumed_spawns.clear()
	if state.has("events"):
		_events = (state["events"] as Dictionary).duplicate(true)
	if state.has("consumed_spawns"):
		_consumed_spawns = (state["consumed_spawns"] as Dictionary).duplicate(true)


func _normalize_token(token: StringName) -> StringName:
	var value := String(token).strip_edges()
	if value.is_empty():
		return &""
	return StringName(value)
