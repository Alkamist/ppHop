extends Camera2D

#var look_ahead_speed := 100.0
#var x_maximum := 7.0
#var y_maximum := 7.0

#export var body_path : NodePath
#onready var body := get_node(body_path)

func _process(delta):
	#var destination = body.velocity * 0.02
	#var direction_to_destination = offset.direction_to(destination)
	#var distance_to_destination = offset.distance_to(destination)
	#var look_ahead_distance = look_ahead_speed * delta
	#var new_offset = offset
	#if distance_to_destination < look_ahead_distance:
	#	new_offset += direction_to_destination * distance_to_destination
	#else:
	#	new_offset += direction_to_destination * look_ahead_distance
	#new_offset.x = clamp(new_offset.x, -x_maximum, x_maximum)
	#new_offset.y = clamp(new_offset.y, -y_maximum, y_maximum)
	offset = offset
