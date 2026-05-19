class_name HelpBulletinBoard
extends StaticBody2D

const EXIT_TOPIC_ID := &"done"

const NPC_HELP_TOPICS := [
	{
		"id": "elder_mara",
		"label": "Elder Mara",
		"path": "NPCs/ElderMara",
		"line": "Elder Mara keeps the town's history and gives guidance to new adventurers."
	},
	{
		"id": "blacksmith_tovin",
		"label": "Blacksmith Tovin",
		"path": "NPCs/BlacksmithTovin",
		"line": "Blacksmith Tovin can help you stay battle ready before heading out."
	},
	{
		"id": "shop_keeper_jacob",
		"label": "Shop Keeper Jacob",
		"path": "NPCs/ShopKeeperJacob",
		"line": "Shop Keeper Jacob sells useful gear, including a bow once you have enough coins."
	},
	{
		"id": "maid_therese",
		"label": "Maid Therese",
		"path": "NPCs/MaidTherese",
		"line": "Maid Therese can restore your health when you return from the wilds."
	},
	{
		"id": "scout_lyra",
		"label": "Scout Lyra",
		"path": "NPCs/ScoutLyra",
		"line": "Scout Lyra tracks local troubles and is a key contact for town quests."
	},
]

@export var interaction_prompt_text: String = "Press Interact to Read Bulletin Board"
@export var camera_pan_duration: float = 0.9
@export var camera_hold_duration: float = 0.2
@export var narrator_name: String = "Bulletin Board"

@onready var interact_area: Area2D = $InteractArea

var _nearby_player: Node2D
var _interaction_available := false
var _tour_running := false
var _pending_topic_id: StringName = &""


func _ready() -> void:
	interact_area.body_entered.connect(_on_body_entered)
	interact_area.body_exited.connect(_on_body_exited)


func _process(_delta: float) -> void:
	_refresh_interaction_state()


func interact() -> void:
	if _tour_running:
		return
	if not _can_player_interact():
		return

	_tour_running = true
	InteractionManager.clear_active_interactable(self)
	await _run_help_center_tour()
	_tour_running = false
	_refresh_interaction_state()


func get_interaction_prompt_text() -> String:
	return interaction_prompt_text


func queue_help_topic(topic_id: String) -> void:
	_pending_topic_id = StringName(topic_id.strip_edges())


func _run_help_center_tour() -> void:
	var player := _resolve_player()
	if player == null:
		await _speak_lines(PackedStringArray([
			"This bulletin board seems to contain a lot of information.",
			"What do you wish to know?",
		]))
		return

	var stage_root := get_tree().current_scene
	if stage_root == null:
		await _speak_lines(PackedStringArray([
			"This bulletin board seems to contain a lot of information.",
		]))
		return

	var player_camera := player.get_node_or_null("Camera2D") as Camera2D
	var tour_camera := _create_tour_camera(stage_root, player_camera, player.global_position)
	_set_player_controls_enabled(player, false)

	var show_intro_prompt := true

	while true:
		_pending_topic_id = &""
		var menu_resource := _build_topic_menu_dialogue(show_intro_prompt)
		if menu_resource == null:
			break

		DialogueService.start_dialogue(menu_resource, "start", [self])
		await DialogueService.dialogue_ended

		var selected_topic := _pending_topic_id
		if selected_topic.is_empty() or selected_topic == EXIT_TOPIC_ID:
			break

		await _present_topic(selected_topic, stage_root, tour_camera, player)
		show_intro_prompt = false

	await _pan_camera_to(tour_camera, player.global_position, camera_pan_duration * 0.8)
	if is_instance_valid(player_camera):
		player_camera.make_current()
	if is_instance_valid(tour_camera):
		tour_camera.queue_free()
	_set_player_controls_enabled(player, true)


func _build_topic_menu_dialogue(show_intro_prompt: bool) -> Resource:
	var compiled_text := "~ start\n"
	if show_intro_prompt:
		compiled_text += "%s: This bulletin board seems to contain a lot of information.\n" % narrator_name
		compiled_text += "%s: What do you wish to know?\n" % narrator_name
	else:
		compiled_text += "%s: What else do you wish to know?\n" % narrator_name

	for topic in NPC_HELP_TOPICS:
		var topic_id := String(topic.get("id", "")).strip_edges()
		var label := String(topic.get("label", "")).strip_edges()
		if topic_id.is_empty() or label.is_empty():
			continue

		compiled_text += "- %s\n" % label
		compiled_text += "\tdo queue_help_topic(\"%s\")\n" % topic_id
	compiled_text += "\t=> END\n"

	compiled_text += "- Nothing right now\n"
	compiled_text += "\t%s: That should cover the essentials for now. Safe travels.\n" % narrator_name
	compiled_text += "\tdo queue_help_topic(\"%s\")\n" % String(EXIT_TOPIC_ID)
	compiled_text += "\t=> END\n"

	return DialogueManager.create_resource_from_text(compiled_text)


func _present_topic(topic_id: StringName, stage_root: Node, tour_camera: Camera2D, player: Node2D) -> void:
	var topic := _find_topic(topic_id)
	if topic.is_empty():
		push_warning("HelpBulletinBoard: Unknown topic id '%s'." % String(topic_id))
		return

	var npc_path := String(topic.get("path", "")).strip_edges()
	var description := String(topic.get("line", "")).strip_edges()
	if description.is_empty():
		return

	var npc := stage_root.get_node_or_null(npc_path) as Node2D
	if npc != null:
		await _pan_camera_to(tour_camera, npc.global_position, camera_pan_duration)
		if camera_hold_duration > 0.0:
			await create_tween().tween_interval(camera_hold_duration).finished
	else:
		push_warning("HelpBulletinBoard: Could not find NPC at path '%s'." % npc_path)

	await _speak_lines(PackedStringArray([description]))
	await _pan_camera_to(tour_camera, player.global_position, camera_pan_duration * 0.75)


func _find_topic(topic_id: StringName) -> Dictionary:
	for topic in NPC_HELP_TOPICS:
		var token := String(topic.get("id", "")).strip_edges()
		if StringName(token) == topic_id:
			return topic
	return {}


func _create_tour_camera(stage_root: Node, player_camera: Camera2D, start_position: Vector2) -> Camera2D:
	var cam := Camera2D.new()
	cam.name = "BulletinTourCamera"
	cam.position_smoothing_enabled = true
	cam.position_smoothing_speed = 8.0
	cam.process_mode = Node.PROCESS_MODE_ALWAYS
	if is_instance_valid(player_camera):
		cam.zoom = player_camera.zoom
	stage_root.add_child(cam)
	cam.global_position = start_position
	cam.make_current()
	return cam


func _pan_camera_to(cam: Camera2D, target_global_position: Vector2, duration: float) -> void:
	if cam == null:
		return
	var tween := create_tween()
	tween.tween_property(cam, "global_position", target_global_position, maxf(0.01, duration))
	await tween.finished


func _speak_lines(lines: PackedStringArray) -> void:
	var resource := _build_dialogue_resource(lines)
	if resource == null:
		return
	DialogueService.start_dialogue(resource, "start")
	await DialogueService.dialogue_ended


func _build_dialogue_resource(lines: PackedStringArray) -> Resource:
	if lines.is_empty():
		return null

	var compiled_text := "~ start\n"
	for line in lines:
		var text := line.strip_edges()
		if text.is_empty():
			continue
		compiled_text += "%s: %s\n" % [narrator_name, text]
	if compiled_text == "~ start\n":
		return null
	return DialogueManager.create_resource_from_text(compiled_text)


func _set_player_controls_enabled(player: Node2D, enabled: bool) -> void:
	if player == null:
		return
	player.set_physics_process(enabled)
	player.set_process_input(enabled)
	player.set_process_unhandled_input(enabled)


func _resolve_player() -> Node2D:
	if _nearby_player != null and is_instance_valid(_nearby_player):
		return _nearby_player
	for node in get_tree().get_nodes_in_group("player"):
		if node is Node2D:
			return node as Node2D
	return null


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
	var should_be_available := not _tour_running and _can_player_interact() and not get_tree().paused
	if should_be_available == _interaction_available:
		return

	_interaction_available = should_be_available
	if _interaction_available:
		InteractionManager.set_active_interactable(self)
	else:
		InteractionManager.clear_active_interactable(self)
