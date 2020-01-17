extends KinematicBody2D

export var velocity := Vector2.ZERO

var _target_transform := Transform2D()

func update_state(delta):
	pass

func _physics_process(delta):
	if is_network_master():
		update_state(delta)
		rpc_unreliable("_update_clients", transform, velocity)
	else:
		var distance = position.distance_to(_target_transform.origin)
		if distance > 0.0:
			position = position.linear_interpolate(_target_transform.origin, 0.5)
		else:
			position = _target_transform.origin

remote func _update_clients(new_transform, new_velocity):
	velocity = new_velocity
	_target_transform = new_transform
