extends ParallaxBackground

func _ready():
	scroll_base_offset = offset + get_parent().global_position
	offset = Vector2.ZERO

func set_alpha(value):
	var children = get_children()
	for child in children:
		child.modulate.a = value

func _on_ProximityAlphaFader_alpha_changed(value):
	set_alpha(value)
