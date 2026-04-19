class_name EnemyCamp extends Node2D

var monsters: Array[Monster]
var player : Player

func _ready() -> void:
	var children := get_children()
	
	for node in children:
		if node is Monster:
			monsters.append(node)

func alert_camp() -> void:
	for monster in monsters:
		if monster is Goblin:
			var goblin = monster as Goblin
			goblin.target_player(player)
			goblin.change_state(Goblin.State.RUNNING)

func retreat() -> void:
	for monster in monsters:
		if monster is Goblin:
			var goblin = monster as Goblin
			goblin.target_player(null)
			goblin.set_target_position(goblin.camp_position)
			goblin.change_state(Goblin.State.WALKING)

func _on_vision_body_entered(body: Node2D) -> void:
	if not body is Player: return
	player = body
	
	alert_camp()

func _on_agro_zone_body_exited(body: Node2D) -> void:
	if not body is Monster: return
	
	retreat()
