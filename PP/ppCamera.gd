extends Camera2D

var look_speed := 10.0
var maximum_look_distance := 550.0

func _process(delta):
	offset = offset
	if Input.is_action_pressed("look_around"):
		offset = lerp(offset, get_local_mouse_position() - offset, 1.0 - exp(-look_speed * delta)).clamped(maximum_look_distance)
	else:
		if offset.length() < 1.0:
			offset = Vector2.ZERO
		else:
			offset = lerp(offset, Vector2.ZERO, 1.0 - exp(-look_speed * delta))
