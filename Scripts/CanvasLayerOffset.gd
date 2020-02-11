extends CanvasLayer

var camera_y_skew := 350.0
var layer_darkening := 14.0

func _ready():
	offset = get_parent().global_position
	offset.y += round(camera_y_skew * (follow_viewport_scale - 1.0))
	for child in get_children():
		if child is CanvasItem:
			child.modulate = child.modulate.darkened(layer_darkening * (1.0 - follow_viewport_scale))
