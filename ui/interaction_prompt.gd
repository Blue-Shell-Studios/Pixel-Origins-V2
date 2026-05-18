extends Label

@export var default_text: String = "Press Interact to Interact"


func _ready() -> void:
	visible = false
	text = default_text
	InteractionManager.active_interactable_changed.connect(_on_active_interactable_changed)
	DialogueService.dialogue_started.connect(_on_dialogue_started)
	DialogueService.dialogue_ended.connect(_on_dialogue_ended)


func _on_active_interactable_changed(interactable: Node) -> void:
	if get_tree().paused:
		visible = false
		return

	visible = interactable != null
	if not visible:
		text = default_text
		return

	if interactable != null and interactable.has_method("get_interaction_prompt_text"):
		var prompt_text := String(interactable.get_interaction_prompt_text()).strip_edges()
		text = prompt_text if not prompt_text.is_empty() else default_text
	else:
		text = default_text


func _on_dialogue_started(_resource: Resource) -> void:
	visible = false


func _on_dialogue_ended(_resource: Resource) -> void:
	_on_active_interactable_changed(InteractionManager.active_interactable)
