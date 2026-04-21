extends Node

const SAVE_PATH := "user://savegame.json"
const SAVE_VERSION := 1

func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)

func clear_save() -> void:
	if has_save():
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))

func save_progress(stage_name: String, position: Vector2, health: int, gold: int) -> bool:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_warning("SaveManager failed to open save file for writing.")
		return false

	var payload := {
		"version": SAVE_VERSION,
		"stage": stage_name,
		"position": {
			"x": position.x,
			"y": position.y
		},
		"health": health,
		"gold": gold
	}

	file.store_string(JSON.stringify(payload))
	return true

func load_progress() -> Dictionary:
	if not has_save():
		return {}

	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		push_warning("SaveManager failed to open save file for reading.")
		return {}

	var raw := file.get_as_text()
	var parsed = JSON.parse_string(raw)
	if not (parsed is Dictionary):
		push_warning("SaveManager found invalid JSON save data.")
		return {}

	return parsed
