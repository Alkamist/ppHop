extends CanvasLayer

func _ready():
	offset = get_parent().global_position
	offset.y += round(300.0 * (follow_viewport_scale - 1.0))
	for child in get_children():
		if child is CanvasItem:
			child.modulate = child.modulate.darkened(10.0 * (1.0 - follow_viewport_scale))

func _process(delta):
	offset = get_parent().global_position
	offset.y += round(300.0 * (follow_viewport_scale - 1.0))
