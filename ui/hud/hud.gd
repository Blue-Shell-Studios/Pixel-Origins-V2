class_name HUD extends CanvasLayer

@onready var bottom_label: Label = $Bottom/Label
@onready var game_over_root: Control = $GameOver
@onready var health_bar: ProgressBar = $TopLeft/VBoxContainer/HealthBar
@onready var health_label: Label = $TopLeft/VBoxContainer/HealthLabel
@onready var gold_label: Label = $TackedQuest/GoldLabel
@onready var tracked_quest_label: Label = $TackedQuest/Label
@onready var quest_modal: Control = $QuestModal
@onready var quest_list_container: VBoxContainer = $QuestModal/Center/Panel/Margin/VBox/QuestList

var is_game_over := false
var active_quests: Array = []
var tracked_quest_id := ""

func _ready() -> void:
	SignalBus.print_text.connect(print_text)
	SignalBus.player_health_changed.connect(_on_player_health_changed)
	SignalBus.player_gold_changed.connect(_on_player_gold_changed)
	SignalBus.player_died.connect(_on_player_died)
	SignalBus.quests_changed.connect(_on_quests_changed)
	game_over_root.visible = false
	quest_modal.visible = false
	health_bar.max_value = 100
	health_bar.value = 100
	health_label.text = "HP 100/100"
	gold_label.text = "Gold: 0"
	tracked_quest_label.text = "Quest: None"
	_on_player_gold_changed(QuestManager.get_total_gold())

	_on_quests_changed(QuestManager.get_active_quests(), QuestManager.tracked_quest_id)

func _unhandled_input(event: InputEvent) -> void:
	if not is_game_over:
		return
	if event.is_action_pressed("ui_accept"):
		get_tree().reload_current_scene()

func print_text(text: String, text_pos: Util.TextPos) -> void:
	match text_pos:
		Util.TextPos.BOTTOM:
			$Bottom/Label.text = text

func _on_player_died() -> void:
	is_game_over = false
	game_over_root.visible = false
	bottom_label.text = ""

	if not StageManager.load_last_save():
		StageManager.switch_stage(Util.StageName.START_SCREEN)

func _on_player_health_changed(current: int, max: int) -> void:
	health_bar.max_value = max
	health_bar.value = current
	health_label.text = "HP %d/%d" % [current, max]

func _on_player_gold_changed(total: int) -> void:
	gold_label.text = "Gold: %d" % total

func _on_quest_button_pressed() -> void:
	quest_modal.visible = true

func _on_quest_close_button_pressed() -> void:
	quest_modal.visible = false

func _on_quests_changed(next_active_quests: Array, next_tracked_quest_id: String) -> void:
	active_quests = next_active_quests.duplicate(true)
	tracked_quest_id = next_tracked_quest_id
	_refresh_quest_modal()
	_refresh_tracked_quest_label()

func _refresh_quest_modal() -> void:
	for child in quest_list_container.get_children():
		child.queue_free()

	if active_quests.is_empty():
		var empty_label := Label.new()
		empty_label.text = "No active quests."
		empty_label.add_theme_font_size_override("font_size", 14)
		quest_list_container.add_child(empty_label)
		return

	for quest in active_quests:
		var quest_id := String(quest.get("id", ""))
		var title := String(quest.get("title", "Quest"))
		var progress := int(quest.get("progress", 0))
		var target := int(quest.get("target", 0))
		var ready_to_turn_in := bool(quest.get("ready_to_turn_in", false))
		var is_tracked := tracked_quest_id == quest_id
		var prefix := "[x] " if is_tracked else "[ ] "
		var suffix := " - Ready to turn in" if ready_to_turn_in else ""

		var button := Button.new()
		button.text = "%s%s (%d/%d)%s" % [prefix, title, progress, target, suffix]
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.custom_minimum_size = Vector2(0, 30)
		button.pressed.connect(_on_quest_entry_pressed.bind(quest_id))
		quest_list_container.add_child(button)

func _refresh_tracked_quest_label() -> void:
	if tracked_quest_id.is_empty():
		tracked_quest_label.text = "Quest: None"
		return

	for quest in active_quests:
		if String(quest.get("id", "")) != tracked_quest_id:
			continue

		var title := String(quest.get("title", "Quest"))
		var progress := int(quest.get("progress", 0))
		var target := int(quest.get("target", 0))
		var ready_to_turn_in := bool(quest.get("ready_to_turn_in", false))
		var status := " - Turn in to mayor" if ready_to_turn_in else ""
		tracked_quest_label.text = "Quest: %s (%d/%d)%s" % [title, progress, target, status]
		return

	tracked_quest_label.text = "Quest: None"

func _on_quest_entry_pressed(quest_id: String) -> void:
	QuestManager.toggle_tracked_quest(quest_id)
