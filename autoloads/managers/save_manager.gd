extends Node

var _has_session_state := false
var _player_state: Dictionary = {}


func has_player_state() -> bool:
	return _has_session_state


func capture_player_state(player: Node) -> void:
	if player == null:
		return

	if player.has_method("get_session_state"):
		_player_state = player.get_session_state()
	else:
		_player_state = _capture_player_state_fallback(player)
	_has_session_state = true


func apply_player_state(player: Node) -> void:
	if not _has_session_state:
		return
	if player == null:
		return

	if player.has_method("apply_session_state"):
		player.apply_session_state(_player_state)
	else:
		_apply_player_state_fallback(player, _player_state)


func clear_session_state() -> void:
	_has_session_state = false
	_player_state = {}


func _capture_player_state_fallback(player: Node) -> Dictionary:
	var state := {}
	if "health" in player:
		state["health"] = player.health
	if "coins" in player:
		state["coins"] = player.coins
	if "selected_slot" in player:
		state["selected_slot"] = player.selected_slot
	if "equipped_weapon" in player:
		state["equipped_weapon"] = String(player.equipped_weapon)
	if "owned_weapons" in player:
		state["owned_weapons"] = player.owned_weapons.duplicate(true)
	return state


func _apply_player_state_fallback(player: Node, state: Dictionary) -> void:
	if state.has("health") and "health" in player:
		player.health = int(state["health"])
	if state.has("coins") and "coins" in player:
		player.coins = int(state["coins"])
	if state.has("owned_weapons") and "owned_weapons" in player:
		player.owned_weapons = (state["owned_weapons"] as Dictionary).duplicate(true)
	if state.has("selected_slot") and player.has_method("_select_slot"):
		player._select_slot(int(state["selected_slot"]))
	elif player.has_method("_refresh_hud"):
		player._refresh_hud()
