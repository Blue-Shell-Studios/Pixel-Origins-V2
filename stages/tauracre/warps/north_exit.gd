extends WarpArea

func _ready() -> void:
	connected_stage = Util.StageName.OVERWORLD
	spawn_name = "Tauracre"

func _on_body_entered(body: Node2D) -> void:
	if not body is Player: return
	
	activate()
