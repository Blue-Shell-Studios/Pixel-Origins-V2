extends Node

const QUEST_MAYOR_GOBLIN := "mayor_goblin_hunt"

const QUEST_DEFINITIONS := {
	QUEST_MAYOR_GOBLIN: {
		"title": "Goblin Cleanup",
		"description": "Defeat 1 goblin for the Village Mayor.",
		"target": 1,
		"gold_reward": 10,
		"enemy_type": "goblin",
		"repeatable": true
	}
}

var active_quests: Dictionary = {}
var tracked_quest_id := ""
var total_gold := 0

func _ready() -> void:
	SignalBus.enemy_killed.connect(_on_enemy_killed)
	SignalBus.player_gold_changed.emit(total_gold)
	_emit_changed()

func has_active_quest(quest_id: String) -> bool:
	return active_quests.has(quest_id)

func grant_quest(quest_id: String) -> bool:
	if not QUEST_DEFINITIONS.has(quest_id):
		return false

	if active_quests.has(quest_id):
		return false

	var definition: Dictionary = QUEST_DEFINITIONS[quest_id]
	active_quests[quest_id] = {
		"id": quest_id,
		"title": definition["title"],
		"description": definition["description"],
		"target": int(definition["target"]),
		"progress": 0,
		"ready_to_turn_in": false,
		"gold_reward": int(definition.get("gold_reward", 0)),
		"enemy_type": definition["enemy_type"],
		"repeatable": bool(definition["repeatable"])
	}

	if tracked_quest_id.is_empty():
		tracked_quest_id = quest_id

	_emit_changed()
	return true

func grant_mayor_goblin_quest() -> bool:
	return grant_quest(QUEST_MAYOR_GOBLIN)

func toggle_tracked_quest(quest_id: String) -> void:
	if not active_quests.has(quest_id):
		return

	if tracked_quest_id == quest_id:
		tracked_quest_id = ""
	else:
		tracked_quest_id = quest_id

	_emit_changed()

func get_active_quests() -> Array:
	var quests: Array = active_quests.values().duplicate(true)
	quests.sort_custom(func(a: Dictionary, b: Dictionary): return String(a.get("title", "")) < String(b.get("title", "")))
	return quests

func get_tracked_quest() -> Dictionary:
	if tracked_quest_id.is_empty():
		return {}
	if not active_quests.has(tracked_quest_id):
		return {}
	return active_quests[tracked_quest_id]

func get_total_gold() -> int:
	return total_gold

func set_total_gold(value: int) -> void:
	total_gold = max(0, value)
	SignalBus.player_gold_changed.emit(total_gold)

func is_quest_ready_to_turn_in(quest_id: String) -> bool:
	if not active_quests.has(quest_id):
		return false
	return bool(active_quests[quest_id].get("ready_to_turn_in", false))

func complete_quest_turn_in(quest_id: String) -> bool:
	if not is_quest_ready_to_turn_in(quest_id):
		return false

	_complete_quest(quest_id)
	_emit_changed()
	return true

func _on_enemy_killed(enemy_type: String) -> void:
	for quest_id in active_quests.keys():
		var quest: Dictionary = active_quests[quest_id]
		if String(quest.get("enemy_type", "")) != enemy_type:
			continue

		var target := int(quest.get("target", 0))
		var progress := int(quest.get("progress", 0))
		progress = min(progress + 1, target)
		quest["progress"] = progress
		if progress >= target and not bool(quest.get("ready_to_turn_in", false)):
			quest["ready_to_turn_in"] = true
			SignalBus.print_text.emit("Objective complete. Return to the mayor.", Util.TextPos.BOTTOM)

		active_quests[quest_id] = quest

	_emit_changed()

func _complete_quest(quest_id: String) -> void:
	if not active_quests.has(quest_id):
		return

	var quest: Dictionary = active_quests[quest_id]
	var quest_title := String(quest.get("title", "Quest"))
	var gold_reward := int(quest.get("gold_reward", 0))
	active_quests.erase(quest_id)

	if tracked_quest_id == quest_id:
		tracked_quest_id = ""

	_grant_gold(gold_reward)
	SignalBus.print_text.emit("Quest Complete: %s" % quest_title, Util.TextPos.BOTTOM)

func _emit_changed() -> void:
	SignalBus.quests_changed.emit(get_active_quests(), tracked_quest_id)

func _grant_gold(amount: int) -> void:
	if amount <= 0:
		return

	total_gold += amount
	SignalBus.player_gold_changed.emit(total_gold)
	SignalBus.print_text.emit("+%d Gold" % amount, Util.TextPos.BOTTOM)
