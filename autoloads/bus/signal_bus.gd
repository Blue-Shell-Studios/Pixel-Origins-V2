extends Node

signal print_text(text: String, text_pos: Util.TextPos)
signal player_health_changed(current: int, max: int)
signal player_gold_changed(total: int)
signal player_died
signal dialogue_started
signal dialogue_finished
signal enemy_killed(enemy_type: String)
signal quests_changed(active_quests: Array, tracked_quest_id: String)

func _ready() -> void:
	if not DialogueManager.dialogue_started.is_connected(_on_dialogue_started):
		DialogueManager.dialogue_started.connect(_on_dialogue_started)

	if not DialogueManager.dialogue_ended.is_connected(_on_dialogue_finished):
		DialogueManager.dialogue_ended.connect(_on_dialogue_finished)

func _on_dialogue_started(_resource: DialogueResource) -> void:
	dialogue_started.emit()

func _on_dialogue_finished(_resource: DialogueResource) -> void:
	dialogue_finished.emit()
