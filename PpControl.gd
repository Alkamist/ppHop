extends Node2D

export var controlling_player := 0

onready var _camera := get_node("Body/Camera2D")
onready var _body := get_node("Body")

func initialize(starting_position):
	_body.position = starting_position
	#if is_controlling_player():
		#_camera.current = true

func is_controlling_player():
	return get_tree().get_network_unique_id() == controlling_player

func is_server():
	return get_tree().get_network_unique_id() == 1

func _jump(jump_direction):
	var jump_vector = jump_direction / 300.0
	jump_vector = jump_vector.clamped(1.0)
	var length = jump_vector.length()
	if length > 0.0:
		jump_vector *= 1.0 / pow(length, 0.5)
		#jump_vector.y = min(jump_vector.y, -0.20)
		jump_vector *= 300.0
	_body.jump(Vector2(jump_vector.x * 3.0, jump_vector.y * 3.0))

func _unhandled_input(event):
	if not is_controlling_player():
		return
	if event.is_action_pressed("jump"):
		_jump(get_global_mouse_position() - _body.global_position)
