class_name ScoutLyraNPC
extends BaseNPC

const NPC_ID: StringName = &"scout_lyra"
const CHOICE_QUEST: StringName = &"quest"
const CHOICE_BYE: StringName = &"bye"
const CHOICE_ACCEPT: StringName = &"accept"
const CHOICE_REJECT: StringName = &"reject"

const COLOR_YELLOW := Color(0.96, 0.86, 0.24, 1.0)
const COLOR_GRAY := Color(0.62, 0.62, 0.62, 1.0)

var _marker_label: Label
var _pending_choice: StringName = &""


func _ready() -> void:
	super._ready()
	_ensure_marker()
	_refresh_marker()
	if not QuestManager.npc_quest_state_changed.is_connected(_on_npc_quest_state_changed):
		QuestManager.npc_quest_state_changed.connect(_on_npc_quest_state_changed)


func interact() -> void:
	if not _can_player_interact():
		return

	_record_npc_talk_event()
	var state := QuestManager.get_npc_quest_state(NPC_ID)
	match state:
		QuestManager.STATE_AVAILABLE:
			await _run_available_quest_flow()
		QuestManager.STATE_READY_TO_TURN_IN:
			await _speak_lines(QuestManager.turn_in_npc_quest(NPC_ID, _nearby_player))
		QuestManager.STATE_IN_PROGRESS, QuestManager.STATE_TURNED_IN:
			await _speak_lines(QuestManager.get_npc_quest_status_lines(NPC_ID))
		_:
			super.interact()
	_refresh_marker()


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


func choose_quest_flow_option(choice_id: String) -> void:
	_pending_choice = StringName(choice_id.strip_edges())


func _run_available_quest_flow() -> void:
	var intro_lines := PackedStringArray()
	var usual_line := fallback_line.strip_edges()
	if not usual_line.is_empty():
		intro_lines.append(usual_line)
	intro_lines.append("I do have a request, if you're willing to hear it.")
	await _speak_lines(intro_lines)

	var quest_name := QuestManager.get_npc_quest_name(NPC_ID).strip_edges()
	if quest_name.is_empty():
		return

	_pending_choice = &""
	var offer_dialogue := _build_offer_choice_dialogue(quest_name)
	DialogueService.start_dialogue(offer_dialogue, dialogue_start, [self])
	await DialogueService.dialogue_ended
	if _pending_choice != CHOICE_QUEST:
		return

	await _speak_lines(QuestManager.get_npc_quest_briefing(NPC_ID))

	_pending_choice = &""
	var accept_dialogue := _build_accept_choice_dialogue()
	DialogueService.start_dialogue(accept_dialogue, dialogue_start, [self])
	await DialogueService.dialogue_ended
	if _pending_choice == CHOICE_ACCEPT:
		await _speak_lines(QuestManager.accept_npc_quest(NPC_ID))
	else:
		await _speak_lines(QuestManager.reject_npc_quest(NPC_ID))


func _build_offer_choice_dialogue(quest_name: String) -> Resource:
	var compiled_text := "~ %s\n" % dialogue_start
	compiled_text += "%s: If you're interested, ask and I'll explain.\n" % npc_name
	compiled_text += "- %s\n" % quest_name
	compiled_text += "\tdo choose_quest_flow_option(\"%s\")\n" % String(CHOICE_QUEST)
	compiled_text += "\t=> END\n"
	compiled_text += "- Bye\n"
	compiled_text += "\tdo choose_quest_flow_option(\"%s\")\n" % String(CHOICE_BYE)
	compiled_text += "\t=> END\n"
	return DialogueManager.create_resource_from_text(compiled_text)


func _build_accept_choice_dialogue() -> Resource:
	var compiled_text := "~ %s\n" % dialogue_start
	compiled_text += "%s: Are you up for it?\n" % npc_name
	compiled_text += "- Yes, I'll do it\n"
	compiled_text += "\tdo choose_quest_flow_option(\"%s\")\n" % String(CHOICE_ACCEPT)
	compiled_text += "\t=> END\n"
	compiled_text += "- Not right now\n"
	compiled_text += "\tdo choose_quest_flow_option(\"%s\")\n" % String(CHOICE_REJECT)
	compiled_text += "\t=> END\n"
	return DialogueManager.create_resource_from_text(compiled_text)


func _speak_lines(lines: PackedStringArray) -> void:
	var resource := _build_dialogue_resource_from_lines(lines)
	if resource == null:
		return
	DialogueService.start_dialogue(resource, dialogue_start)
	await DialogueService.dialogue_ended


func _build_dialogue_resource_from_lines(lines: PackedStringArray) -> Resource:
	if lines.is_empty():
		return null

	var compiled_text := "~ %s\n" % dialogue_start
	for line in lines:
		compiled_text += "%s: %s\n" % [npc_name, line]
	return DialogueManager.create_resource_from_text(compiled_text)
