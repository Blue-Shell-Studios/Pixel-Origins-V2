class_name BaseNPC
extends StaticBody2D

const DialogueResource = preload("res://addons/dialogue_manager/dialogue_resource.gd")

signal interaction_entered(npc: BaseNPC)
signal interaction_exited(npc: BaseNPC)

@export var npc_name: String = "Villager"
@export_multiline var fallback_line: String = ""
@export var dialogue_resource: DialogueResource
@export var dialogue_start: String = "start"

@onready var interact_area: Area2D = $InteractArea

var _runtime_dialogue_resource: DialogueResource
var _nearby_player: Node2D
var _interaction_available := false


func _ready() -> void:
	interact_area.body_entered.connect(_on_body_entered)
	interact_area.body_exited.connect(_on_body_exited)
	add_to_group("npc")


func _process(_delta: float) -> void:
	_refresh_interaction_state()


func interact() -> void:
	if not _can_player_interact():
		return

	var resource := _get_or_build_dialogue_resource()
	if resource == null:
		return

	DialogueService.start_dialogue(resource, dialogue_start)


func _on_body_entered(body: Node) -> void:
	if not body.is_in_group("player"):
		return
	_nearby_player = body as Node2D
	_refresh_interaction_state()


func _on_body_exited(body: Node) -> void:
	if not body.is_in_group("player"):
		return
	if body == _nearby_player:
		_nearby_player = null
	_refresh_interaction_state()


func _can_player_interact() -> bool:
	if _nearby_player == null:
		return false
	if not _nearby_player.has_method("is_facing_point"):
		return true
	return _nearby_player.is_facing_point(global_position)


func _refresh_interaction_state() -> void:
	var should_be_available := _can_player_interact() and not get_tree().paused
	if should_be_available == _interaction_available:
		return

	_interaction_available = should_be_available
	if _interaction_available:
		InteractionManager.set_active_interactable(self)
		interaction_entered.emit(self)
	else:
		InteractionManager.clear_active_interactable(self)
		interaction_exited.emit(self)


func _get_or_build_dialogue_resource() -> DialogueResource:
	if dialogue_resource != null:
		return dialogue_resource

	if _runtime_dialogue_resource != null:
		return _runtime_dialogue_resource

	var line := fallback_line.strip_edges()
	if line.is_empty():
		return null

	var compiled_text := "~ %s\n%s: %s\n" % [dialogue_start, npc_name, line]
	_runtime_dialogue_resource = DialogueManager.create_resource_from_text(compiled_text)
	return _runtime_dialogue_resource
