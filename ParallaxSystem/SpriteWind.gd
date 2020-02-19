extends Sprite

export var wind_speed := 40.0
onready var starting_position := position
onready var x_size := texture.get_width() * scale.x

func _process(delta):
	if wind_speed != 0.0:
		position.x = position.x + delta * wind_speed * scale.x
		if abs(position.x - starting_position.x) > x_size:
			position.x -= sign(wind_speed) * x_size
