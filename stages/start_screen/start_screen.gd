extends Stage

@onready var continue_button: Button = $CanvasLayer/Buttons/VBox/ContinueButton
@onready var overwrite_confirm_dialog: ConfirmationDialog = $CanvasLayer/OverwriteConfirmDialog

func _ready() -> void:
	type = Type.UI
	continue_button.disabled = not SaveManager.has_save()

func _on_start_button_pressed() -> void:
	if SaveManager.has_save():
		overwrite_confirm_dialog.popup_centered()
		return

	_start_new_game()

func _start_new_game() -> void:
	SaveManager.clear_save()
	StageManager.switch_stage(Util.StageName.OVERWORLD, "Start")

func _on_continue_button_pressed() -> void:
	if not StageManager.load_last_save():
		StageManager.switch_stage(Util.StageName.OVERWORLD, "Start")

func _on_quit_button_pressed() -> void:
	get_tree().quit()

func _on_overwrite_confirm_dialog_confirmed() -> void:
	_start_new_game()
