extends Node

signal dialogue_started(resource: Resource)
signal dialogue_ended(resource: Resource)


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	DialogueManager.process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	if not DialogueManager.dialogue_ended.is_connected(_on_dialogue_ended):
		DialogueManager.dialogue_ended.connect(_on_dialogue_ended)


func start_dialogue(resource: Resource, start_title: String = "start") -> Node:
	if resource == null:
		return null

	var balloon := DialogueManager.show_dialogue_balloon(resource, start_title)
	if balloon != null:
		balloon.process_mode = Node.PROCESS_MODE_WHEN_PAUSED

	get_tree().paused = true
	dialogue_started.emit(resource)
	return balloon


func _on_dialogue_ended(resource: Resource) -> void:
	get_tree().paused = false
	dialogue_ended.emit(resource)
