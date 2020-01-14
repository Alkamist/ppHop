extends KinematicBody2D

export var velocity := Vector2.ZERO
export var use_dead_reckoning := false

onready var _network_id := get_tree().get_network_unique_id()
var _ping := 0
var _ping_tick := 0
var _tick := 0
var _target_transform := Transform2D()

func update_state(delta):
	_tick += 1

func _physics_process(delta):
	if is_network_master():
		print(_tick)
		update_state(delta)
		rpc_unreliable("_update_clients", _tick, transform, velocity)
	else:
		rpc_unreliable("_ping_master", _ping_tick, _network_id)
		var distance = position.distance_to(_target_transform.origin)
		if distance > 0.0:
			position = position.linear_interpolate(_target_transform.origin, 0.5)
		else:
			position = _target_transform.origin
	_ping_tick += 1

master func _ping_master(tick, network_id):
	rpc_unreliable_id(network_id, "_set_client_ping", tick)

puppet func _set_client_ping(tick):
	_ping = _ping_tick - tick

remote func _update_clients(tick, new_transform, new_velocity):
	_tick = tick
	velocity = new_velocity
	if use_dead_reckoning:
		var old_position := position
		position = new_transform.origin
		var delta := get_physics_process_delta_time()
		for i in range(_ping):
			update_state(delta)
		_target_transform = transform
		position = old_position
	else:
		_target_transform = new_transform
