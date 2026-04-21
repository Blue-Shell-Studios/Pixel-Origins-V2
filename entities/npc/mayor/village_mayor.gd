extends NPC

func interact() -> bool:
	return super.interact()

func has_active_mayor_quest() -> bool:
	return QuestManager.has_active_quest(QuestManager.QUEST_MAYOR_GOBLIN)

func is_mayor_quest_ready_to_turn_in() -> bool:
	return QuestManager.is_quest_ready_to_turn_in(QuestManager.QUEST_MAYOR_GOBLIN)

func accept_mayor_quest() -> void:
	if QuestManager.grant_mayor_goblin_quest():
		SignalBus.print_text.emit("New Quest: Goblin Cleanup (0/1)", Util.TextPos.BOTTOM)
	else:
		SignalBus.print_text.emit("You already have this quest.", Util.TextPos.BOTTOM)

func turn_in_mayor_quest() -> void:
	if QuestManager.complete_quest_turn_in(QuestManager.QUEST_MAYOR_GOBLIN):
		SignalBus.print_text.emit("Mayor: Thank you for helping Tauracre!", Util.TextPos.BOTTOM)
