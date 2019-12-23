extends Node2D
class_name Pp

export var can_jump := true
export var jump_power := 10.0
export var max_jump_speed := 1100.0
#export var min_jump_speed := 500.0

remotesync func _jump(jump_vector):
	get_body().velocity = jump_vector
	get_body().velocity_before_collision = get_body().velocity
	get_sprite().set_flip_h(get_body().velocity.x < 0)
	get_body().mark_launch()

func get_body():
	return get_node("KinematicBody2D")

func get_sprite():
	return get_node("Smoothing2D/Sprite")

func activate_camera():
	get_node("Smoothing2D/Camera2D").current = true

func _get_jump_vector():
	# Calculate the jump vector.
	var mouse_position = get_global_mouse_position()
	var body_position = get_body().position
	var raw_jump_vector = mouse_position - body_position
	
	# Clamp the jump vector's angle.
	raw_jump_vector.y = min(raw_jump_vector.y, tan(0.1) * -abs(raw_jump_vector.x))
	
	# Clamp the jump vector's length.
	raw_jump_vector = raw_jump_vector.clamped(200.0)
	#if jump_vector.length() > 0:
	#	jump_vector = jump_vector * max(min_jump_speed / jump_vector.length(), 1.0)

	return 23.0 * raw_jump_vector / pow(raw_jump_vector.length(), 0.3)

func _input(event):
	if not is_network_master():
		return
	if event.is_action_pressed("jump") and can_jump and get_body().is_on_floor():
		rpc("_jump", _get_jump_vector())

#func _draw():
#	if not is_network_master():
#		return
#	draw_line(_body_position, _body_position + _raw_jump_vector, Color(255, 0, 0), 1)
