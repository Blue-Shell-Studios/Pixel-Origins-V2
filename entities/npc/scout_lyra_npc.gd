class_name ScoutLyraNPC
extends BaseNPC

const NPC_ID: StringName = &"scout_lyra"

const COLOR_YELLOW := Color(0.96, 0.86, 0.24, 1.0)
const COLOR_GRAY := Color(0.62, 0.62, 0.62, 1.0)

var _marker_label: Label


func _ready() -> void:
	super._ready()
	_ensure_marker()
	_refresh_marker()
	if not QuestManager.npc_quest_state_changed.is_connected(_on_npc_quest_state_changed):
		QuestManager.npc_quest_state_changed.connect(_on_npc_quest_state_changed)


func interact() -> void:
	if not _can_player_interact():
		return

	var lines := QuestManager.interact_with_npc_quest(NPC_ID, _nearby_player)
	if lines.is_empty():
		super.interact()
		return

	_refresh_marker()
	var resource := _build_dialogue_resource_from_lines(lines)
	if resource == null:
		return
	DialogueService.start_dialogue(resource, dialogue_start)


func _on_npc_quest_state_changed(npc_id: StringName) -> void:
	if npc_id != NPC_ID:
		return
	_refresh_marker()


func _refresh_marker() -> void:
	if _marker_label == null:
		return
	var state := QuestManager.get_npc_quest_state(NPC_ID)
	match state:
		QuestManager.STATE_AVAILABLE:
			_marker_label.visible = true
			_marker_label.text = "!"
			_marker_label.modulate = COLOR_YELLOW
		QuestManager.STATE_IN_PROGRESS:
			_marker_label.visible = true
			_marker_label.text = "?"
			_marker_label.modulate = COLOR_GRAY
		QuestManager.STATE_READY_TO_TURN_IN:
			_marker_label.visible = true
			_marker_label.text = "?"
			_marker_label.modulate = COLOR_YELLOW
		_:
			_marker_label.visible = false


func _ensure_marker() -> void:
	_marker_label = get_node_or_null("QuestMarker") as Label
	if _marker_label != null:
		return

	_marker_label = Label.new()
	_marker_label.name = "QuestMarker"
	_marker_label.position = Vector2(-6, -20)
	_marker_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_marker_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_marker_label.z_index = 30
	_marker_label.text = "!"
	_marker_label.visible = false
	add_child(_marker_label)


func _build_dialogue_resource_from_lines(lines: PackedStringArray) -> Resource:
	if lines.is_empty():
		return null

	var compiled_text := "~ %s\n" % dialogue_start
	for line in lines:
		compiled_text += "%s: %s\n" % [npc_name, line]
	return DialogueManager.create_resource_from_text(compiled_text)
