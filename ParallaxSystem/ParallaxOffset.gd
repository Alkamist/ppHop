extends ParallaxBackground

func _ready():
	scroll_base_offset = offset + get_parent().global_position
	offset = Vector2.ZERO
