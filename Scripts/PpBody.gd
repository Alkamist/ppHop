extends KinematicBody2D

var jump_power := 3.6
var jump_mouse_length := 260.0
var bounciness := 0.98
var gravity := 1500.0
var maximum_fall_speed := 2000.0
var normal_ground_friction := 9999999999999.9
var ice_friction := 0.7
var air_resistance := 0.0
var jump_y_clamp := -0.2
var maximum_jump_speed := 1400.0
var maximum_walk_speed := 160.0
var walk_control := 10.0
var maximum_air_drift_speed := 160.0
var air_drift_control := 4.0
var minimum_bounce_angle := 0.8

var velocity := Vector2.ZERO
var target_transform := Transform2D()
var controlling_player := -1
var should_crouch := false
var is_crouching := false
var was_crouching := false
var is_on_ground := false
var was_on_ground := false
var friction_is_suspended := false
var is_jumping := false
var should_jump := false
var movement_direction := 0
var ground_friction := normal_ground_friction
var time := 0.0
var launch_time := 0.0
var suspend_friction_time := 0.0
var jump_direction := Vector2.ZERO
var maximum_move_recursions := 4
var current_move_recursions := 0
var current_platform

signal just_jumped
signal just_crouched
signal just_uncrouched
signal just_landed
signal just_became_airborne
signal just_got_launched
signal just_bounced

func set_controlling_player(id):
	controlling_player = id

func is_controlling_player():
	return get_tree().get_network_unique_id() == controlling_player

func _unsnap_from_platform():
	if current_platform:
		current_platform = null

func _snap_to_platform(platform):
	current_platform = platform

func _suspend_friction():
	friction_is_suspended = true
	suspend_friction_time = time

func jump(direction):
	if is_on_ground:
		should_jump = true
		jump_direction = direction

func launch_master(launch_vector):
	rpc("_launch_master", launch_vector)

master func _launch_master(launch_vector):
	if time - launch_time > 0.15:
		launch_time = time
		velocity.x = launch_vector.x
		velocity.y = launch_vector.y
		_unsnap_from_platform()
		_suspend_friction()
		emit_signal("just_got_launched")

func _check_if_on_ground():
	var collision = move_and_collide(Vector2.DOWN, true, true, true)
	was_on_ground = is_on_ground
	is_on_ground = collision and abs(collision.normal.angle_to(Vector2.UP)) < 0.7

func _handle_jumping():
	if should_jump:
		var jump_vector = jump_direction / jump_mouse_length
		var length = jump_vector.length()
		if length > 0.0:
			jump_vector *= 1.0 / pow(length, 0.5)
			if jump_vector.clamped(1.0).y > jump_y_clamp:
				var x_clamp := cos(-jump_y_clamp)
				jump_vector.x = clamp(jump_vector.x, -x_clamp, x_clamp)
				jump_vector.y = jump_y_clamp
			else:
				jump_vector = jump_vector.clamped(1.0)
			jump_vector *= jump_power * jump_mouse_length
		velocity.x += _add_to_velocity_component(velocity.x, jump_vector.x, maximum_jump_speed)
		velocity.y = jump_vector.y
		is_jumping = true
		_unsnap_from_platform()
		#_suspend_friction()
		emit_signal("just_jumped")
		should_jump = false

func _add_to_velocity_component(velocity_component, adder, maximum):
	if adder > 0.0:
		return min(adder, clamp(maximum - velocity_component, 0.0, maximum))
	elif adder < 0.0:
		return max(adder, clamp(-maximum - velocity_component, -maximum, 0.0))
	return 0.0

func _dampen(delta, value, target, dampening):
	return lerp(value, target, 1.0 - exp(-dampening * delta))

func _apply_friction(delta, target_velocity, friction):
	velocity = _dampen(delta, velocity, target_velocity, friction)

func _apply_gravity(delta):
	velocity.y += _add_to_velocity_component(velocity.y, gravity * delta, maximum_fall_speed)

func _apply_horizontal_movement(delta, friction, control, maximum_speed):
	var control_scale = 1.0 - exp(-friction * delta * control)
	if movement_direction != 0 and not is_crouching:
		velocity.x += _add_to_velocity_component(velocity.x, control_scale * movement_direction * maximum_speed, maximum_speed)
	#elif is_crouching:
	#	var acceleration_component = control_scale * maximum_speed
	#	if abs(velocity.x) > acceleration_component:
	#		velocity.x += -sign(velocity.x) * acceleration_component
	#	else:
	#		velocity.x = 0.0

func _handle_crouching():
	was_crouching = is_crouching
	is_crouching = should_crouch and is_on_ground
	if is_crouching and not was_crouching:
		emit_signal("just_crouched")
	if not is_crouching and was_crouching:
		emit_signal("just_uncrouched")

func _handle_floor_signals():
	if is_on_ground and not was_on_ground:
		emit_signal("just_landed")
	if not is_on_ground and was_on_ground:
		emit_signal("just_became_airborne")
	was_on_ground = is_on_ground

func move(distance):
	var delta := get_physics_process_delta_time()
	var collision := move_and_collide(distance, true, true, true)
	var collision_count = 0
	if collision:
		position += collision.travel
		current_move_recursions += 1
		if current_move_recursions < maximum_move_recursions:
			var collider = collision.collider
			# Handle bouncing.
			if abs(collision.normal.angle_to(Vector2.UP)) > minimum_bounce_angle:
				if collider.is_in_group("platform"):
					emit_signal("just_bounced")
					velocity = collider.velocity * bounciness
					move((collider.velocity * delta) + collision.remainder.bounce(collision.normal) * bounciness)
				elif collider.is_in_group("ppBody"):
					var collider_velocity = collider.velocity
					collider.launch_master(velocity * bounciness)
					velocity = collider_velocity * bounciness
				else:
					var impact_intensity := abs(velocity.dot(collision.normal))
					# Prevent sticking to walls in the air.
					if impact_intensity > 50.0:
						emit_signal("just_bounced")
						velocity = velocity.bounce(collision.normal) * bounciness
						move(collision.remainder.bounce(collision.normal) * bounciness)
					else:
						velocity = velocity.slide(collision.normal)
						move(collision.remainder.slide(collision.normal))
			# Handle sliding.
			else:
				if collider.is_in_group("platform"):
					_snap_to_platform(collider)
				if collider.is_in_group("ice"):
					ground_friction = ice_friction
				else:
					ground_friction = normal_ground_friction
				velocity = velocity.slide(collision.normal)
				move(collision.remainder.slide(collision.normal))
	else:
		position += distance
		current_move_recursions = 0

func _handle_physics(delta):
	current_move_recursions = 0
	_check_if_on_ground()
	_apply_gravity(delta)

	if is_on_ground:
		_apply_friction(delta, Vector2.ZERO, ground_friction)
		_apply_horizontal_movement(delta, ground_friction, walk_control, maximum_walk_speed)
	else:
		_unsnap_from_platform()
		_apply_friction(delta, Vector2.ZERO, air_resistance)
		_apply_horizontal_movement(delta, 1.0, air_drift_control, maximum_air_drift_speed)

	_handle_crouching()
	_handle_jumping()
	move(velocity * delta)
	if current_platform:
		position += current_platform.velocity * delta
	_handle_floor_signals()

	is_jumping = false
	if time - suspend_friction_time > 0.2:
		friction_is_suspended = false

	time += delta

func update_state(delta):
	if OS.is_debug_build() and is_controlling_player() and Input.is_action_pressed("up"):
		position = lerp(position, get_global_mouse_position(), 10.0 * delta)
		velocity = Vector2.ZERO
	else:
		_handle_physics(delta)

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
