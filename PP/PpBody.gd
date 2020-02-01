extends KinematicBody2D

var bounciness := 0.8
var gravity := 600.0
var maximum_fall_speed := 480.0
var ground_friction := 99999999999.9
var minimum_y_velocity_on_slope := 20.0
var slide_friction := 2.0
var air_resistance := 0.1
var maximum_walk_speed := 50.0
var maximum_air_drift_speed := 50.0
var walk_control := 99999999999.9
var slide_control := 10.0
var air_drift_control := 5.0
var maximum_ground_angle := 0.7
var minimum_bounce_angle := 0.8
var minimum_bounce_velocity := 15.0
var jump_power := 4.0
var jump_mouse_length := 70.0
var jump_y_clamp := -0.3
var maximum_jump_speed := 480.0

var time := 0.0
var time_of_jump_input := 0.0
var time_of_becoming_airborne := 0.0
var time_of_last_bounce_sound := 0.0
var jump_buffer_time := 0.067
var jump_time_lenience := 0.067
var movement_direction := 0
var jump_direction := Vector2.ZERO
var velocity := Vector2.ZERO
var should_jump := false
var can_jump := false
var is_on_ground := false
var is_crouching := false
var current_ground_normal
var is_launching := false
var time_of_launch := 0.0
var launch_helpless_time := 0.5
var move_recursion_count := 0

signal just_landed
signal just_became_airborne
signal just_jumped
signal just_crouched
signal just_uncrouched
signal just_bounced

func launch(launch_vector):
	is_launching = true
	time_of_launch = time
	velocity += launch_vector

func move(distance):
	move_recursion_count = 0
	_move(distance)

func _handle_bounce(collision):
	var normal = collision.normal
	var remainder = collision.remainder
	if time - time_of_last_bounce_sound > 0.1:
		SFX.play("PPBounce", self)
		time_of_last_bounce_sound = time
	velocity = velocity.bounce(normal) * bounciness
	emit_signal("just_bounced", self, collision)
	_move_recursion(remainder.bounce(normal) * bounciness)

func _handle_ground_slide(collision):
	var normal = collision.normal
	var remainder = collision.remainder
	velocity = velocity.slide(normal)
	_move_recursion(remainder.slide(normal))

func _handle_wall_slide(collision):
	var normal = collision.normal
	var remainder = collision.remainder
	velocity = velocity.slide(normal)
	_move_recursion(remainder.slide(normal))

func _check_if_on_ground():
	var collision = move_and_collide(Vector2.DOWN, true, true, true)
	var was_on_ground := is_on_ground
	is_on_ground = collision and abs(collision.normal.angle_to(Vector2.UP)) < maximum_ground_angle
	if collision:
		current_ground_normal = collision.normal
	else:
		current_ground_normal = null
	if is_on_ground:
		can_jump = true
		if not was_on_ground:
			emit_signal("just_landed")
	elif not is_on_ground and was_on_ground:
		emit_signal("just_became_airborne")
		time_of_becoming_airborne = time

func _move_recursion(distance):
	move_recursion_count += 1
	if move_recursion_count < 4:
		_move(distance)

func _move(distance):
	var collision := move_and_collide(distance, true, true, true)
	var collision_count = 0
	if collision:
		position += collision.travel
		if abs(collision.normal.angle_to(Vector2.UP)) > minimum_bounce_angle:
			var impact_intensity := abs(velocity.dot(collision.normal))
			if impact_intensity > minimum_bounce_velocity:
				_handle_bounce(collision)
			else:
				_handle_wall_slide(collision)
		else:
			_handle_ground_slide(collision)
	else:
		position += distance
	_check_if_on_ground()

func _dampen(delta, value, target, dampening):
	return lerp(value, target, 1.0 - exp(-dampening * delta))

func _apply_gravity(delta):
	velocity.y += _add_to_velocity_component(velocity.y, gravity * delta, maximum_fall_speed)

func _add_to_velocity_component(velocity_component, adder, maximum):
	if adder > 0.0:
		return min(adder, clamp(maximum - velocity_component, 0.0, maximum))
	elif adder < 0.0:
		return max(adder, clamp(-maximum - velocity_component, -maximum, 0.0))
	return 0.0

func _apply_horizontal_movement(delta, friction, control, maximum_speed):
	var control_scale = 1.0 - exp(-control * delta)
	if movement_direction != 0:
		if sign(movement_direction) != sign(velocity.x):
			velocity.x = _dampen(delta, velocity.x, 0.0, friction)
		if current_ground_normal:
			velocity += -current_ground_normal.tangent() * _add_to_velocity_component(velocity.x, control_scale * movement_direction * maximum_speed, maximum_speed)
		else:
			velocity.x += _add_to_velocity_component(velocity.x, control_scale * movement_direction * maximum_speed, maximum_speed)
		if abs(velocity.x) > maximum_speed:
			velocity.x = _dampen(delta, velocity.x, sign(movement_direction) * maximum_speed, friction)
	else:
		velocity.x = _dampen(delta, velocity.x, 0.0, friction)

func _handle_jumping():
	if should_jump and can_jump:
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
		should_jump = false
		can_jump = false
		SFX.play("PPJump", self)
		emit_signal("just_jumped")

func _unhandled_input(event):
	if event.is_action_pressed("jump"):
		time_of_jump_input = time
		jump_direction = get_global_mouse_position() - global_position
		should_jump = true

func _process(delta):
	var was_crouching = is_crouching
	is_crouching = Input.is_action_pressed("down")
	if is_crouching and not was_crouching:
		emit_signal("just_crouched")
	elif not is_crouching and was_crouching:
		emit_signal("just_uncrouched")
	var left = -1 if Input.is_action_pressed("left") else 0
	var right = 1 if Input.is_action_pressed("right") else 0
	movement_direction = left + right
	if not is_on_ground and time - time_of_becoming_airborne > jump_time_lenience:
		can_jump = false
	time += delta

func _physics_process(delta):
	#if OS.is_debug_build() and Input.is_action_pressed("up"):
	if Input.is_action_pressed("up"):
		position = lerp(position, get_global_mouse_position(), 10.0 * delta)
		velocity = Vector2.ZERO
	else:
		_apply_gravity(delta)
		if not is_launching:
			if is_on_ground:
				if is_crouching:
					_apply_horizontal_movement(delta, slide_friction, slide_control, maximum_walk_speed)
				else:
					_apply_horizontal_movement(delta, ground_friction, walk_control, maximum_walk_speed)
					if movement_direction == 0 and velocity.y < minimum_y_velocity_on_slope:
						velocity.y = 0.0
			else:
				velocity.y = _dampen(delta, velocity.y, 0.0, air_resistance)
				_apply_horizontal_movement(delta, air_resistance, air_drift_control, maximum_air_drift_speed)
		else:
			if is_on_ground:
				velocity.x = _dampen(delta, velocity.x, 0.0, slide_friction)
			else:
				velocity = _dampen(delta, velocity, Vector2.ZERO, air_resistance)
		_handle_jumping()
		move(velocity * delta)
		if time - time_of_jump_input > jump_buffer_time:
			should_jump = false
		if time - time_of_launch > launch_helpless_time:
			is_launching = false
