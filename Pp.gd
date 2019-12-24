extends Node2D
class_name Pp

var _controlling_player_id

func set_controlling_player(player_id):
	_controlling_player_id = player_id

func is_controlling_player():
	return _controlling_player_id != null and get_tree().get_network_unique_id() == _controlling_player_id

func get_body():
	return get_node("KinematicBody2D")

remotesync func _jump(raw_jump_vector):
	get_body().jump(raw_jump_vector)

func _input(event):
	if not is_controlling_player():
		return
	if event.is_action_pressed("jump"):
		rpc("_jump", get_global_mouse_position() - (global_position + get_body().position))
