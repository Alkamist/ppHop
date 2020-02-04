extends Area2D

export var launch_vector := Vector2(0.0, 600.0)

var time := 0.0
var eat_time := 0.0

func _physics_process(delta):
	for body in get_overlapping_bodies():
		if body.is_in_group("ppBody"):
			if time - eat_time > 0.5:
				eat_time = time
				body.global_position = global_position
				body.velocity = Vector2.ZERO
				body.launch(launch_vector)
	time += delta
