class_name NPC extends CharacterBody2D

@export var dialogue: DialogueResource
@export var dialogue_title := "start"

var active_dialogue_balloon: Node

func interact() -> bool:
	if dialogue == null:
		return false

	if is_instance_valid(active_dialogue_balloon):
		return false

	active_dialogue_balloon = DialogueManager.show_dialogue_balloon(dialogue, dialogue_title, [self])
	if is_instance_valid(active_dialogue_balloon):
		active_dialogue_balloon.tree_exited.connect(_on_dialogue_balloon_tree_exited, CONNECT_ONE_SHOT)
		return true

	return false

func _on_dialogue_balloon_tree_exited() -> void:
	active_dialogue_balloon = null
