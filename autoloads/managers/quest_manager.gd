extends Node

signal npc_quest_state_changed(npc_id: StringName)
signal quest_progressed(quest_id: StringName, progress: int, required: int)

const QUEST_LYRA_GOBLIN_HUNT: StringName = &"lyra_goblin_hunt"
const NPC_SCOUT_LYRA: StringName = &"scout_lyra"

const STATE_AVAILABLE: StringName = &"available"
const STATE_IN_PROGRESS: StringName = &"in_progress"
const STATE_READY_TO_TURN_IN: StringName = &"ready_to_turn_in"
const STATE_TURNED_IN: StringName = &"turned_in"
const STATE_NONE: StringName = &"none"

var _quest_states := {
	QUEST_LYRA_GOBLIN_HUNT: STATE_AVAILABLE,
}

var _quest_progress := {
	QUEST_LYRA_GOBLIN_HUNT: 0,
}

var _quest_required := {
	QUEST_LYRA_GOBLIN_HUNT: 5,
}

var _quest_reward_coins := {
	QUEST_LYRA_GOBLIN_HUNT: 10,
}

var _quest_target_enemy := {
	QUEST_LYRA_GOBLIN_HUNT: &"goblin",
}

var _npc_quest := {
	NPC_SCOUT_LYRA: QUEST_LYRA_GOBLIN_HUNT,
}

var _active_npc_quest: StringName = &""


func get_npc_quest_state(npc_id: StringName) -> StringName:
	var quest_id := _npc_quest.get(npc_id, &"") as StringName
	if quest_id.is_empty():
		return STATE_NONE
	return _quest_states.get(quest_id, STATE_NONE)


func get_npc_quest_progress(npc_id: StringName) -> Dictionary:
	var quest_id := _npc_quest.get(npc_id, &"") as StringName
	if quest_id.is_empty():
		return {"current": 0, "required": 0}
	return {
		"current": int(_quest_progress.get(quest_id, 0)),
		"required": int(_quest_required.get(quest_id, 0)),
	}


func interact_with_npc_quest(npc_id: StringName, player: Node) -> PackedStringArray:
	var quest_id := _npc_quest.get(npc_id, &"") as StringName
	if quest_id.is_empty():
		return PackedStringArray()

	var state := _quest_states.get(quest_id, STATE_NONE) as StringName
	match state:
		STATE_AVAILABLE:
			if not _active_npc_quest.is_empty() and _active_npc_quest != quest_id:
				return PackedStringArray([
					"I cannot focus on a new request until your current one is done.",
				])
			_active_npc_quest = quest_id
			_quest_states[quest_id] = STATE_IN_PROGRESS
			EventsManager.mark_quest_started(quest_id)
			npc_quest_state_changed.emit(npc_id)
			return PackedStringArray([
				"Bramble Wilds has been crawling with goblins lately.",
				"Can you help me thin them out?",
				"Please defeat 5 goblins. I can pay you 10 coins.",
			])
		STATE_IN_PROGRESS:
			var progress := get_npc_quest_progress(npc_id)
			return PackedStringArray([
				"Keep at it. Goblins defeated: %d/%d." % [int(progress.current), int(progress.required)],
			])
		STATE_READY_TO_TURN_IN:
			var reward := int(_quest_reward_coins.get(quest_id, 0))
			if player != null and player.has_method("add_coins"):
				player.add_coins(reward)
			_quest_states[quest_id] = STATE_TURNED_IN
			EventsManager.mark_quest_completed(quest_id)
			if _active_npc_quest == quest_id:
				_active_npc_quest = &""
			npc_quest_state_changed.emit(npc_id)
			return PackedStringArray([
				"You did it. The path already feels safer.",
				"Here, take %d coins as promised." % reward,
			])
		STATE_TURNED_IN:
			return PackedStringArray([
				"Thanks again. Tauracre owes you.",
			])

	return PackedStringArray()


func record_enemy_kill(enemy_type: StringName) -> void:
	for quest_id in _quest_states.keys():
		if _quest_states[quest_id] != STATE_IN_PROGRESS:
			continue
		var target_enemy := _quest_target_enemy.get(quest_id, &"") as StringName
		if target_enemy != enemy_type:
			continue

		var current := int(_quest_progress.get(quest_id, 0)) + 1
		var required := int(_quest_required.get(quest_id, 0))
		_quest_progress[quest_id] = min(current, required)
		quest_progressed.emit(quest_id, _quest_progress[quest_id], required)

		if _quest_progress[quest_id] >= required:
			_quest_states[quest_id] = STATE_READY_TO_TURN_IN
			EventsManager.mark_task_completed(quest_id)
			EventsManager.mark_event(StringName("quest_ready_to_turn_in/%s" % String(quest_id)))
			var owner := _find_owner_npc(quest_id)
			if not owner.is_empty():
				npc_quest_state_changed.emit(owner)


func get_active_quest_summary() -> String:
	if _active_npc_quest.is_empty():
		return ""

	if _active_npc_quest == QUEST_LYRA_GOBLIN_HUNT:
		var state := _quest_states.get(_active_npc_quest, STATE_NONE) as StringName
		var current := int(_quest_progress.get(_active_npc_quest, 0))
		var required := int(_quest_required.get(_active_npc_quest, 0))
		match state:
			STATE_IN_PROGRESS:
				return "Scout Lyra: Defeat goblins %d/%d" % [current, required]
			STATE_READY_TO_TURN_IN:
				return "Scout Lyra: Return for reward"
			_:
				return ""

	return ""


func _find_owner_npc(quest_id: StringName) -> StringName:
	for npc_id in _npc_quest.keys():
		if _npc_quest[npc_id] == quest_id:
			return npc_id
	return &""
