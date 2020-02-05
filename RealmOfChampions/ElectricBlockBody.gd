extends Area2D

export var launch_vector := Vector2.ZERO

func _physics_process(delta):
	for body in get_overlapping_bodies():
		if body.is_in_group("ppBody"):
			body.velocity = Vector2.ZERO
			body.launch(launch_vector)
