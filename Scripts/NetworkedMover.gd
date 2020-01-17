extends KinematicBody2D

var velocity := Vector2.ZERO
var target_transform := Transform2D()

func update_state(delta):
	pass

func _physics_process(delta):
	if is_network_master():
		update_state(delta)
		rpc_unreliable("_update_clients", transform, velocity)
	else:
		var distance = position.distance_to(target_transform.origin)
		if distance > 0.0:
			position = position.linear_interpolate(target_transform.origin, 0.5)
		else:
			position = target_transform.origin

remote func _update_clients(new_transform, new_velocity):
	velocity = new_velocity
	target_transform = new_transform
