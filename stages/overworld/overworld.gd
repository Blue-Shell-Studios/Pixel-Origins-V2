extends Node2D

const EntranceTrigger = preload("res://entities/triggers/entrance_trigger.gd")

var active_entrance: EntranceTrigger

@onready var prompt_label: Label = $CanvasLayer/Prompt


func _ready() -> void:
	prompt_label.visible = false

	for trigger in get_tree().get_nodes_in_group("entrance_trigger"):
		if not $Landmarks.is_ancestor_of(trigger):
			continue
		trigger.player_entered.connect(_on_landmark_player_entered)
		trigger.player_exited.connect(_on_landmark_player_exited)


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("interact"):
		return
	if active_entrance == null:
		return

	active_entrance.try_enter()


func _on_landmark_player_entered(trigger: EntranceTrigger) -> void:
	active_entrance = trigger
	prompt_label.text = trigger.prompt_text
	prompt_label.visible = true


func _on_landmark_player_exited(trigger: EntranceTrigger) -> void:
	if active_entrance != trigger:
		return
	active_entrance = null
	prompt_label.visible = false
