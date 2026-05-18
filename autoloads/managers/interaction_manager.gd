extends Node

signal active_interactable_changed(interactable: Node)

var active_interactable: Node


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func set_active_interactable(interactable: Node) -> void:
	if active_interactable == interactable:
		return
	active_interactable = interactable
	active_interactable_changed.emit(active_interactable)


func clear_active_interactable(interactable: Node) -> void:
	if active_interactable != interactable:
		return
	active_interactable = null
	active_interactable_changed.emit(null)


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("ui_accept"):
		return
	if get_tree().paused:
		return
	if active_interactable == null:
		return
	if not active_interactable.has_method("interact"):
		return

	active_interactable.interact()
	get_viewport().set_input_as_handled()
