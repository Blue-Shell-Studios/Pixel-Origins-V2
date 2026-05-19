extends Node

signal dialogue_started(resource: Resource)
signal dialogue_ended(resource: Resource)

const DIALOGUE_SECONDS_PER_STEP := 0.03


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	DialogueManager.process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	if not DialogueManager.dialogue_ended.is_connected(_on_dialogue_ended):
		DialogueManager.dialogue_ended.connect(_on_dialogue_ended)


func start_dialogue(resource: Resource, start_title: String = "start", extra_game_states: Array = []) -> Node:
	if resource == null:
		return null

	var balloon := DialogueManager.show_dialogue_balloon(resource, start_title, extra_game_states)
	if balloon != null:
		balloon.process_mode = Node.PROCESS_MODE_WHEN_PAUSED
		_configure_dialogue_balloon(balloon)

	get_tree().paused = true
	dialogue_started.emit(resource)
	return balloon


func _on_dialogue_ended(resource: Resource) -> void:
	SoundManager.stop_dialogue_roll()
	get_tree().paused = false
	dialogue_ended.emit(resource)


func _configure_dialogue_balloon(balloon: Node) -> void:
	var dialogue_label := _find_dialogue_label(balloon)
	if dialogue_label == null:
		return

	dialogue_label.set("seconds_per_step", DIALOGUE_SECONDS_PER_STEP)
	var started_typing_callable := Callable(self, "_on_dialogue_typing_started")
	if not dialogue_label.is_connected("started_typing", started_typing_callable):
		dialogue_label.connect("started_typing", started_typing_callable)
	var finished_typing_callable := Callable(self, "_on_dialogue_typing_finished")
	if not dialogue_label.is_connected("finished_typing", finished_typing_callable):
		dialogue_label.connect("finished_typing", finished_typing_callable)
	var skipped_typing_callable := Callable(self, "_on_dialogue_typing_finished")
	if not dialogue_label.is_connected("skipped_typing", skipped_typing_callable):
		dialogue_label.connect("skipped_typing", skipped_typing_callable)


func _find_dialogue_label(root: Node) -> Node:
	if root == null:
		return null
	if root.has_signal("spoke"):
		return root
	for child in root.get_children():
		var found := _find_dialogue_label(child)
		if found != null:
			return found
	return null


func _on_dialogue_typing_started() -> void:
	SoundManager.start_dialogue_roll()


func _on_dialogue_typing_finished() -> void:
	SoundManager.stop_dialogue_roll()
