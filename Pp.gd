extends KinematicBody2D
class_name Pp

export var maximum_collisions_per_frame := 4
export var controlling_player := 0
export var friction := 1.0
export var bounciness := 1.0
export var maximum_fall_velocity := 1400.0
export var gravity := 1500.0
export var velocity := Vector2.ZERO
export var velocity_before_collision := Vector2.ZERO

var _server_transform := Transform2D()
var _input_history := []
var _client_tick := -1
puppet var _server_tick := -1
var _should_jump := false
var _jump_direction := Vector2.ZERO
var _time := 0.0
var _just_jumped := false
var _friction_is_suspended := false
var _time_since_jump := 0.0
var _jump_cooldown := 0.05
var _suspend_friction_timer := 0.0

#func initialize():
	#if is_controlling_player():
		#get_node("Camera2D").current = true

func is_controlling_player():
	return get_tree().get_network_unique_id() == controlling_player

func suspend_friction():
	_friction_is_suspended = true
	_suspend_friction_timer = 0.0

func _jump_if_needed(delta):
	#if is_on_floor() and _time_since_jump >= _jump_cooldown:
	if _should_jump:
		var jump_vector = _jump_direction
		jump_vector = jump_vector.clamped(200.0)
		jump_vector = pow(200.0, 0.3) * jump_vector / pow(jump_vector.length(), 0.3)
		#jump_vector.y = min(jump_vector.y, -50.0)
		velocity = jump_vector * 5.0
		_just_jumped = true
		_time_since_jump = 0.0
		#get_node("Sprite").set_flip_h(jump_vector.x < 0)
		#suspend_friction()

func _apply_gravity(delta):
	velocity.y += gravity * delta
	velocity.y = min(velocity.y, maximum_fall_velocity)

func _apply_friction(delta):
	if is_on_floor() and not _friction_is_suspended:
		velocity = lerp(velocity, Vector2.ZERO, clamp(friction * delta, -1.0, 1.0))

func _handle_movement_and_collisions(delta):
	velocity_before_collision = velocity
	var collision = move_and_collide(velocity * delta)
	var collision_count = 0
	while collision and collision_count < maximum_collisions_per_frame and collision.remainder.length() > 0.0:
		var collider = collision.collider
		
		# Slide on the floor or a pp head.
		if abs(collision.normal.angle_to(Vector2.UP)) < 0.78:
			velocity = velocity.slide(collision.normal)
			var slide_movement = collision.remainder.slide(collision.normal)
			collision = move_and_collide(slide_movement)
			
		elif collider.is_in_group("ppBody"):
			collider.suspend_friction()
			collider.velocity = velocity_before_collision * bounciness
			velocity = collider.velocity_before_collision * bounciness
			
		# Bounce off walls.
		else:
			velocity = velocity.bounce(collision.normal) * bounciness
			var bounce_movement = collision.remainder.bounce(collision.normal)
			collision = move_and_collide(bounce_movement)
		
		collision_count += 1

func update_state(delta):
	_jump_if_needed(delta)
	_apply_gravity(delta)
	#_apply_friction(delta)
	_handle_movement_and_collisions(delta)
	_time_since_jump += delta
	_suspend_friction_timer += delta
	if _suspend_friction_timer > 0.15:
		_friction_is_suspended = false

func _physics_process(delta):
	if is_controlling_player():
		if Input.is_action_pressed("jump"):
			_should_jump = true
			_jump_direction = get_global_mouse_position() - global_position
		else:
			_should_jump = false
			_jump_direction = Vector2.ZERO
		
		if not is_network_master():
			_input_history.push_back({
				tick = _client_tick,
				delta = delta,
				should_jump = _should_jump,
				jump_direction = _jump_direction
			})
			rpc_unreliable("_update_server", _should_jump, _jump_direction)
	
	if is_network_master():
		rpc_unreliable("_update_clients", _client_tick, transform, velocity)
	else:
		rpc_unreliable("_ping_server", get_tree().get_network_unique_id(), _client_tick)
		
		var distance = position.distance_to(_server_transform.origin)
		if distance > 0.0:
			position = position.linear_interpolate(_server_transform.origin, 0.1)
		else:
			position = _server_transform.origin
		
		_client_tick += 1
	
	update_state(delta)
	
	_time += delta

master func _ping_server(network_id, tick):
	if tick > _client_tick:
		_client_tick = tick
		rset_unreliable_id(network_id, "_server_tick", tick)

master func _update_server(should_jump, jump_direction):
	_should_jump = should_jump
	_jump_direction = jump_direction

remote func _update_clients(tick, new_transform, new_velocity):
	if tick < _server_tick:
		return
	
	velocity = new_velocity
	
	if is_controlling_player():
		var old_transform = transform
		transform = new_transform
		
		while _input_history.size() > 0 and _input_history[0].tick < tick:
			_input_history.pop_front()
		
		for i in range(_input_history.size() - 1):
			var input = _input_history[i]
			_should_jump = input.should_jump
			_jump_direction = input.jump_direction
			update_state(input.delta)
		
		_server_transform = transform
		transform = old_transform
	else:
		_server_transform = new_transform
