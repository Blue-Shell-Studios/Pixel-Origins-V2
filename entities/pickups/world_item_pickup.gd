class_name WorldItemPickup
extends StaticBody2D

@export var item_id: StringName = &"old_key"
@export var item_name: String = "Old Key"
@export var interaction_prompt_text: String = "Press Interact to Pick Up"
@export var spawn_id: StringName = &""
@export var required_events: PackedStringArray = PackedStringArray()
@export var blocked_events: PackedStringArray = PackedStringArray()

@onready var interact_area: Area2D = $InteractArea
@onready var body_collision: CollisionShape2D = $BodyCollision
@onready var interact_collision: CollisionShape2D = $InteractArea/CollisionShape2D

var _nearby_player: Node2D
var _interaction_available := false
var _picked_up := false
var _spawn_active := true
var _resolved_spawn_id: StringName


func _ready() -> void:
	_resolved_spawn_id = _resolve_spawn_id()
	if EventsManager.is_spawn_consumed(_resolved_spawn_id):
		queue_free()
		return

	if not EventsManager.should_spawn(_resolved_spawn_id, required_events, blocked_events):
		_set_spawn_active(false)
		if not EventsManager.event_marked.is_connected(_on_event_marked):
			EventsManager.event_marked.connect(_on_event_marked)
	else:
		_set_spawn_active(true)

	interact_area.body_entered.connect(_on_body_entered)
	interact_area.body_exited.connect(_on_body_exited)


func _process(_delta: float) -> void:
	if not _spawn_active:
		return
	_refresh_interaction_state()


func get_interaction_prompt_text() -> String:
	return interaction_prompt_text


func interact() -> void:
	if not _spawn_active or _picked_up or not _can_player_interact():
		return
	if _nearby_player == null or not _nearby_player.has_method("add_inventory_item"):
		return

	var picked := bool(_nearby_player.add_inventory_item(item_id, item_name, 1))
	if not picked:
		return

	SoundManager.play_item_pickup()
	_picked_up = true
	InteractionManager.clear_active_interactable(self)
	EventsManager.consume_spawn(_resolved_spawn_id)
	if not item_id.is_empty():
		EventsManager.mark_event(StringName("item_picked/%s" % String(item_id)))
	var resource := _build_pickup_dialogue()
	if resource == null:
		queue_free()
		return

	DialogueService.start_dialogue(resource, "start")
	await DialogueService.dialogue_ended
	queue_free()


func _on_body_entered(body: Node) -> void:
	if not body.is_in_group("player"):
		return
	_nearby_player = body as Node2D
	_refresh_interaction_state()


func _on_body_exited(body: Node) -> void:
	if body != _nearby_player:
		return
	_nearby_player = null
	_refresh_interaction_state()


func _can_player_interact() -> bool:
	if _nearby_player == null:
		return false
	if not _nearby_player.has_method("is_facing_point"):
		return true
	return _nearby_player.is_facing_point(global_position)


func _refresh_interaction_state() -> void:
	var should_be_available := _spawn_active and not _picked_up and _can_player_interact() and not get_tree().paused
	if should_be_available == _interaction_available:
		return

	_interaction_available = should_be_available
	if _interaction_available:
		InteractionManager.set_active_interactable(self)
	else:
		InteractionManager.clear_active_interactable(self)


func _build_pickup_dialogue() -> Resource:
	var safe_name := item_name.strip_edges()
	if safe_name.is_empty():
		safe_name = "Item"
	var line := "You got %s." % safe_name
	var compiled_text := "~ start\nSystem: %s\n" % line
	return DialogueManager.create_resource_from_text(compiled_text)


func _resolve_spawn_id() -> StringName:
	if not spawn_id.is_empty():
		return spawn_id
	var path_token := String(get_path()).replace("/", "_").replace(":", "_").strip_edges()
	if path_token.is_empty():
		path_token = "%s_%d" % [String(item_id), get_instance_id()]
	return StringName(path_token.to_snake_case())


func _set_spawn_active(is_active: bool) -> void:
	_spawn_active = is_active
	visible = is_active
	body_collision.disabled = not is_active
	interact_collision.disabled = not is_active
	interact_area.monitoring = is_active
	interact_area.monitorable = is_active
	if not is_active:
		_interaction_available = false
		InteractionManager.clear_active_interactable(self)


func _on_event_marked(_event_id: StringName) -> void:
	if _spawn_active:
		return
	if EventsManager.is_spawn_consumed(_resolved_spawn_id):
		queue_free()
		return
	if EventsManager.should_spawn(_resolved_spawn_id, required_events, blocked_events):
		_set_spawn_active(true)
		if EventsManager.event_marked.is_connected(_on_event_marked):
			EventsManager.event_marked.disconnect(_on_event_marked)
