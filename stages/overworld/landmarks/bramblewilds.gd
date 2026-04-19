extends Landmark

func _ready() -> void:
	connected_stage = Util.StageName.BRAMBLEWILDS
	spawn_name = "SouthEntrance"
	
func _on_body_entered(body: Node2D) -> void:
	if not body is Player: return
	is_active = true
	SignalBus.print_text.emit(name, Util.TextPos.BOTTOM)

func _on_body_exited(body: Node2D) -> void:
	if not body is Player: return
	is_active = false
	SignalBus.print_text.emit("", Util.TextPos.BOTTOM)
