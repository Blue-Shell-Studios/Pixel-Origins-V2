extends Label

@export var default_text: String = "Press Enter to Interact"


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


func _on_dialogue_started(_resource: Resource) -> void:
	visible = false


func _on_dialogue_ended(_resource: Resource) -> void:
	_on_active_interactable_changed(InteractionManager.active_interactable)
