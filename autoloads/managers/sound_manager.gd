extends Node

const MASTER_BUS_NAME := "Master"
const MUSIC_BUS_NAME := "Music"
const SFX_BUS_NAME := "SFX"

const SFX_UI_CLICK := &"ui_click"
const SFX_INTERACT := &"interact"
const SFX_DIALOGUE_ROLL := &"dialogue_roll"
const SFX_PLAYER_SWORD_ATTACK := &"player_sword_attack"
const SFX_PLAYER_BOW_ATTACK := &"player_bow_attack"
const SFX_PLAYER_HURT := &"player_hurt"
const SFX_ENEMY_ATTACK := &"enemy_attack"
const SFX_ENEMY_HIT := &"enemy_hit"
const SFX_ENEMY_DEFEAT := &"enemy_defeat"
const SFX_ENEMY_GOBLIN_ATTACK := &"enemy_goblin_attack"
const SFX_ENEMY_GOBLIN_HIT := &"enemy_goblin_hit"
const SFX_ENEMY_GOBLIN_DEFEAT := &"enemy_goblin_defeat"
const SFX_ENEMY_FOREST_WISP_ATTACK := &"enemy_forest_wisp_attack"
const SFX_ENEMY_FOREST_WISP_HIT := &"enemy_forest_wisp_hit"
const SFX_ENEMY_FOREST_WISP_DEFEAT := &"enemy_forest_wisp_defeat"
const SFX_COIN_PICKUP := &"coin_pickup"
const SFX_ITEM_PICKUP := &"item_pickup"

@export_range(1, 16, 1) var sfx_pool_size: int = 8
@export var bgm_volume_db: float = -8.0
@export var sfx_base_volume_db: float = -2.0
@export var bgm_fade_floor_db: float = -36.0
@export var stage_to_music_id: Dictionary[StringName, StringName] = {
	&"start_screen": &"start_screen",
	&"overworld": &"overworld",
	&"bramble_wilds": &"bramble_wilds",
	&"tauracre": &"tauracre",
	&"ancient_ruins": &"ancient_ruins",
}
@export var music_streams: Dictionary = {
	&"start_screen": null,
	&"overworld": preload("uid://dabirnowkj18w"),
	&"bramble_wilds": preload("uid://8b7girre5h8q"),
	&"tauracre": preload("uid://cfvoe38e6b3rh"),
	&"ancient_ruins": preload("uid://8b7girre5h8q"),
}
@export var sfx_streams: Dictionary = {
	SFX_UI_CLICK: preload("uid://dois0abwinu3q"),
	SFX_INTERACT: null,
	SFX_DIALOGUE_ROLL: preload("uid://0ykw0t4k166b"),
	SFX_PLAYER_SWORD_ATTACK: preload("uid://e2upxjqow44x"),
	SFX_PLAYER_BOW_ATTACK: null,
	SFX_PLAYER_HURT: null,
	SFX_ENEMY_ATTACK: null,
	SFX_ENEMY_HIT: preload("uid://bdcwmybx4cq3a"),
	SFX_ENEMY_DEFEAT: null,
	SFX_ENEMY_GOBLIN_ATTACK: preload("uid://c5vfarq2e01wq"),
	SFX_ENEMY_GOBLIN_HIT: null,
	SFX_ENEMY_GOBLIN_DEFEAT: preload("uid://dkspkw344r0sw"),
	SFX_ENEMY_FOREST_WISP_ATTACK: null,
	SFX_ENEMY_FOREST_WISP_HIT: null,
	SFX_ENEMY_FOREST_WISP_DEFEAT: null,
	SFX_COIN_PICKUP: preload("uid://u4dtcit8pexa"),
	SFX_ITEM_PICKUP: null,
}

var _bgm_player: AudioStreamPlayer
var _sfx_players: Array[AudioStreamPlayer] = []
var _dialogue_roll_player: AudioStreamPlayer
var _dialogue_roll_active: bool = false
var _current_music_id: StringName = &""
var _bgm_fade_tween: Tween


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_ensure_audio_buses()
	_build_players()


func play_sfx(id: StringName, volume_db: float = 0.0, pitch_scale: float = 1.0) -> void:
	var stream := _lookup_dictionary_value(sfx_streams, id, null) as AudioStream
	if stream == null:
		push_warning("SoundManager: Missing SFX stream for id '%s'." % String(id))
		return

	var player := _acquire_sfx_player()
	if player == null:
		return

	player.stream = stream
	player.volume_db = sfx_base_volume_db + volume_db
	player.pitch_scale = maxf(0.01, pitch_scale)
	player.play()


func play_ui_click() -> void:
	play_sfx(SFX_UI_CLICK)


func play_interact() -> void:
	play_sfx(SFX_INTERACT)


func play_dialogue_roll() -> void:
	play_sfx(SFX_DIALOGUE_ROLL, -4.0, randf_range(0.97, 1.03))


func start_dialogue_roll() -> void:
	var stream := _lookup_dictionary_value(sfx_streams, SFX_DIALOGUE_ROLL, null) as AudioStream
	if stream == null:
		push_warning("SoundManager: Missing SFX stream for id '%s'." % String(SFX_DIALOGUE_ROLL))
		return

	_dialogue_roll_active = true
	_dialogue_roll_player.stream = stream
	_dialogue_roll_player.volume_db = sfx_base_volume_db - 4.0
	if not _dialogue_roll_player.playing:
		_dialogue_roll_player.play()


func stop_dialogue_roll() -> void:
	_dialogue_roll_active = false
	if _dialogue_roll_player.playing:
		_dialogue_roll_player.stop()


func play_player_attack() -> void:
	play_player_sword_attack()


func play_player_sword_attack() -> void:
	play_sfx(SFX_PLAYER_SWORD_ATTACK)


func play_player_bow_attack() -> void:
	play_sfx(SFX_PLAYER_BOW_ATTACK)


func play_player_hurt() -> void:
	play_sfx(SFX_PLAYER_HURT)


func play_enemy_attack() -> void:
	play_sfx(SFX_ENEMY_ATTACK)


func play_enemy_hit() -> void:
	play_sfx(SFX_ENEMY_HIT)


func play_enemy_defeat() -> void:
	play_sfx(SFX_ENEMY_DEFEAT)


func play_coin_pickup() -> void:
	play_sfx(SFX_COIN_PICKUP)


func play_item_pickup() -> void:
	play_sfx(SFX_ITEM_PICKUP)


func play_music_for_stage(stage_id: StringName, fade_time: float = 0.25) -> void:
	var raw_music_id: StringName = _lookup_dictionary_value(stage_to_music_id, stage_id, &"")
	var music_id := _normalize_id(raw_music_id)
	if music_id.is_empty():
		stop_music(fade_time)
		return
	play_music(music_id, fade_time)


func play_music(music_id: StringName, fade_time: float = 0.25) -> void:
	var stream := _lookup_dictionary_value(music_streams, music_id, null) as AudioStream
	if stream == null:
		push_warning("SoundManager: Missing music stream for id '%s'." % String(music_id))
		stop_music(fade_time)
		return

	if _current_music_id == music_id and _bgm_player.playing:
		return

	_current_music_id = music_id
	_transition_music_stream(stream, fade_time)


func stop_music(fade_time: float = 0.25) -> void:
	_current_music_id = &""
	_stop_bgm_tween()

	if not _bgm_player.playing:
		return

	if fade_time <= 0.0:
		_bgm_player.stop()
		_bgm_player.stream = null
		_bgm_player.volume_db = bgm_volume_db
		return

	_bgm_fade_tween = create_tween()
	_bgm_fade_tween.tween_property(_bgm_player, "volume_db", bgm_fade_floor_db, fade_time)
	_bgm_fade_tween.tween_callback(func():
		_bgm_player.stop()
		_bgm_player.stream = null
		_bgm_player.volume_db = bgm_volume_db
	)


func _ensure_audio_buses() -> void:
	_ensure_bus(MUSIC_BUS_NAME, MASTER_BUS_NAME)
	_ensure_bus(SFX_BUS_NAME, MASTER_BUS_NAME)


func _ensure_bus(bus_name: String, send_to: String) -> void:
	if AudioServer.get_bus_index(bus_name) != -1:
		return
	AudioServer.add_bus()
	var bus_index := AudioServer.get_bus_count() - 1
	AudioServer.set_bus_name(bus_index, bus_name)
	AudioServer.set_bus_send(bus_index, send_to)


func _build_players() -> void:
	_bgm_player = AudioStreamPlayer.new()
	_bgm_player.name = "BGMPlayer"
	_bgm_player.bus = MUSIC_BUS_NAME
	_bgm_player.volume_db = bgm_volume_db
	_bgm_player.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_bgm_player)

	var desired_size := maxi(1, sfx_pool_size)
	for i in range(desired_size):
		var player := AudioStreamPlayer.new()
		player.name = "SFXPlayer%d" % i
		player.bus = SFX_BUS_NAME
		player.volume_db = sfx_base_volume_db
		player.process_mode = Node.PROCESS_MODE_ALWAYS
		add_child(player)
		_sfx_players.append(player)

	_dialogue_roll_player = AudioStreamPlayer.new()
	_dialogue_roll_player.name = "DialogueRollPlayer"
	_dialogue_roll_player.bus = SFX_BUS_NAME
	_dialogue_roll_player.volume_db = sfx_base_volume_db - 4.0
	_dialogue_roll_player.process_mode = Node.PROCESS_MODE_ALWAYS
	_dialogue_roll_player.finished.connect(_on_dialogue_roll_finished)
	add_child(_dialogue_roll_player)


func _acquire_sfx_player() -> AudioStreamPlayer:
	for player in _sfx_players:
		if not player.playing:
			return player
	return _sfx_players.front()


func _transition_music_stream(stream: AudioStream, fade_time: float) -> void:
	_stop_bgm_tween()
	if _bgm_player.stream == stream and _bgm_player.playing:
		_bgm_player.volume_db = bgm_volume_db
		return

	var safe_fade_time := maxf(0.0, fade_time)
	if not _bgm_player.playing or safe_fade_time <= 0.0:
		_bgm_player.stop()
		_bgm_player.stream = stream
		_bgm_player.volume_db = bgm_volume_db
		_bgm_player.play()
		return

	var half_fade := safe_fade_time * 0.5
	_bgm_fade_tween = create_tween()
	_bgm_fade_tween.tween_property(_bgm_player, "volume_db", bgm_fade_floor_db, half_fade)
	_bgm_fade_tween.tween_callback(func():
		_bgm_player.stop()
		_bgm_player.stream = stream
		_bgm_player.volume_db = bgm_fade_floor_db
		_bgm_player.play()
	)
	_bgm_fade_tween.tween_property(_bgm_player, "volume_db", bgm_volume_db, half_fade)


func _stop_bgm_tween() -> void:
	if _bgm_fade_tween != null and _bgm_fade_tween.is_running():
		_bgm_fade_tween.kill()
	_bgm_fade_tween = null


func _normalize_id(value: Variant) -> StringName:
	var token := String(value).strip_edges()
	if token.is_empty():
		return &""
	return StringName(token)


func _lookup_dictionary_value(dict: Dictionary, key: StringName, default_value: Variant) -> Variant:
	if dict.has(key):
		return dict[key]
	var key_string := String(key)
	if dict.has(key_string):
		return dict[key_string]
	return default_value


func _on_dialogue_roll_finished() -> void:
	if _dialogue_roll_active and _dialogue_roll_player.stream != null:
		_dialogue_roll_player.play()
