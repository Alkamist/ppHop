extends Node2D

export var body_path : NodePath
onready var body := get_node(body_path)

var line_mouse_offset := 10.0
var line_thickness := 7

func _draw():
	if body.can_jump and not Input.is_action_pressed("jump"):
		var direction = get_global_mouse_position() - global_position
		var jump_vector = direction / body.jump_mouse_length
		var length = jump_vector.length()
		if length > 0.0:
			if jump_vector.clamped(1.0).y > body.jump_y_clamp:
				var x_clamp := cos(-body.jump_y_clamp)
				jump_vector.x = clamp(jump_vector.x, -x_clamp, x_clamp)
				jump_vector.y = body.jump_y_clamp
			else:
				jump_vector = jump_vector.clamped(1.0)
			jump_vector *= body.jump_mouse_length
		var end_position = jump_vector - jump_vector.normalized() * line_mouse_offset
		draw_line(Vector2.ZERO, end_position, Color(0.6, 0.1, 0), line_thickness)

func _process(delta):
	update()
