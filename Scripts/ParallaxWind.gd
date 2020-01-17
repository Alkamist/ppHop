extends ParallaxLayer

export var wind_speed := 1.0
export var image_width := 1000

func _process(delta):
	motion_offset.x = motion_offset.x + delta * wind_speed
	if motion_offset.x > image_width:
		motion_offset.x = 0
