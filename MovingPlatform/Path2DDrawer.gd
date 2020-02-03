extends Path2D

onready var points := curve.get_baked_points()
var line_color := Color(1.0, 1.0, 1.0, 0.2)

func _process(delta):
	update()

func _draw():
	var previous_point
	for point in points:
		if previous_point:
			draw_line(previous_point, point, line_color, 3)
		previous_point = point
