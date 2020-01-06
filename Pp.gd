extends KinematicBody2D
class_name Pp

export var controlling_player := 0
export var velocity := Vector2.ZERO
export var velocity_before_collision := Vector2.ZERO

var _maximum_collisions_per_frame := 4
var _movement_direction := 0
var _target_transform := Transform2D()
var _jump_direction := Vector2.ZERO
var _is_on_ground := false
var _should_jump := false
var _is_charging_jump := false
var _friction_is_suspended := false
var _cant_launch_pp := false

var _time := 0.0
var _launched_pp_time := 0.0
var _suspend_friction_time := 0.0
var _jump_time := 0.0

const twoPI := 2.0 * PI
var _jiggle_phase := 0.0
var _jiggle_amplitude := 0.0

func initialize():
	if is_controlling_player():
		get_node("../Smoothing2D/Camera2D").current = true

func is_controlling_player():
	return get_tree().get_network_unique_id() == controlling_player

func is_server():
	return get_tree().get_network_unique_id() == 1

func suspend_friction():
	_friction_is_suspended = true
	_suspend_friction_time = _time

func launch(new_velocity):
	rpc_unreliable("_launch_master", new_velocity)

func jiggle(intensity):
	_jiggle_amplitude = intensity * 0.00025
	_jiggle_phase = 0.0

master func _launch_master(new_velocity):
	suspend_friction()
	velocity = new_velocity

func _get_contribution_component(contributor, component, maximum):
	if contributor > 0.0:
		return min(contributor, clamp(maximum - component, 0.0, maximum))
	elif contributor < 0.0:
		return max(contributor, clamp(-maximum - component, -maximum, 0.0))

func _handle_jumping(delta, power, maximum_speed):
	if _should_jump and _is_on_ground and _time - _jump_time > 0.15:
		var jump_vector = _jump_direction / 300.0
		jump_vector = jump_vector.clamped(1.0)
		var length = jump_vector.length()
		if length > 0.0:
			jump_vector.y += 0.25
			jump_vector.y = min(jump_vector.y, 0.0)
			jump_vector *= 1.0 / pow(length, 0.5)
			jump_vector.y -= 0.25
			jump_vector *= 300.0
		velocity.x += _get_contribution_component(jump_vector.x * power, velocity.x, maximum_speed)
		velocity.y = jump_vector.y * power
		_jump_time = _time
		suspend_friction()
		play_sound("PPJump")
		#jiggle(velocity.length())

func _check_if_on_ground(delta):
	var collision = move_and_collide(Vector2.DOWN, true, true, true)
	_is_on_ground = collision and abs(collision.normal.angle_to(Vector2.UP)) < 0.78

func _apply_gravity(delta, gravity):
	velocity.y += 60.0 * gravity * delta

func _apply_air_resistance(delta, resistance):
	velocity = lerp(velocity, Vector2.ZERO, 60.0 * resistance * delta)

func _apply_horizontal_movement(delta, friction, acceleration, maximum_speed):
	if not _is_charging_jump and _movement_direction != 0:
		var target_speed = _movement_direction * maximum_speed
		if abs(velocity.x) < maximum_speed:
			velocity.x = lerp(velocity.x, target_speed, 60.0 * acceleration * delta)
		elif not _friction_is_suspended:
			velocity.x = lerp(velocity.x, target_speed, 60.0 * friction * delta)
	elif not _friction_is_suspended:
		velocity.x = lerp(velocity.x, 0.0, 60.0 * friction * delta)

func _handle_movement_and_collisions(delta, bounciness):
	velocity_before_collision = velocity
	var collision = move_and_collide(velocity * delta)
	var collision_count = 0
	while collision and collision_count < _maximum_collisions_per_frame and collision.remainder.length() > 0.0:
		var collider = collision.collider
		var impact_intensity = abs(velocity.dot(collision.normal))
		var do_not_bounce = impact_intensity < 50.0 or _is_on_ground and impact_intensity < 210.0
		
		# Handle sliding.
		if abs(collision.normal.angle_to(Vector2.UP)) < 1.0 or do_not_bounce:
			velocity = velocity.slide(collision.normal)
			var slide_movement = collision.remainder.slide(collision.normal)
			collision = move_and_collide(slide_movement)
		
		# Collide with other pps.
		elif collider.is_in_group("ppBody"):
			velocity = collider.velocity_before_collision * bounciness
			jiggle(velocity.length())
			if not _cant_launch_pp:
				collider.launch(velocity_before_collision * bounciness)
				_cant_launch_pp = true
				_launched_pp_time = _time
		
		# Bounce off walls.
		else:
			velocity = velocity.bounce(collision.normal) * bounciness
			jiggle(velocity.length())
			var bounce_movement = collision.remainder.bounce(collision.normal)
			collision = move_and_collide(bounce_movement)
			play_sound("PPBounce")
		
		collision_count += 1

func update_state(delta):
	_check_if_on_ground(delta)
	_handle_jumping(delta, 3.35, 1400.0)
	_apply_gravity(delta, 20.0)
	_apply_air_resistance(delta, 0.005)
	if _is_on_ground:
		_apply_horizontal_movement(delta, 1.0, 0.3, 200.0)
	else:
		_apply_horizontal_movement(delta, 0.0, 0.1, 140.0)
	_handle_movement_and_collisions(delta, 0.8)
	_time += delta
	if _time - _suspend_friction_time > 0.2:
		_friction_is_suspended = false
	if _time - _launched_pp_time > 0.15:
		_cant_launch_pp = false

remotesync func _set_sprite_facing_right(value):
	get_node("../Smoothing2D/Position2D/Sprite").set_flip_h(not value)

func _handle_jiggle(delta, speed, dampening):
	var appearance = get_node("../Smoothing2D/Position2D")
	var jiggle_scale = clamp(1.0 - sin(_jiggle_phase) * _jiggle_amplitude, 0.85, 1.15)
	if abs(1.0 - jiggle_scale) < 0.01:
		jiggle_scale = 1.0
	appearance.scale.x = jiggle_scale
	appearance.scale.y = jiggle_scale
	appearance.position.y = 10.0 * (1.0 - jiggle_scale)
	_jiggle_amplitude -= dampening * _jiggle_amplitude * delta
	_jiggle_amplitude = max(_jiggle_amplitude, 0.0)
	_jiggle_phase += speed * delta
	if _jiggle_phase >= twoPI:
		_jiggle_phase -= twoPI

func _process(delta):
	_handle_jiggle(delta, 30.0, 2.0)

func _physics_process(delta):
	if is_controlling_player():
		_jump_direction = get_global_mouse_position() - global_position
		_should_jump = Input.is_action_pressed("jump")
		var left = -1 if Input.is_action_pressed("left") else 0
		var right = 1 if Input.is_action_pressed("right") else 0
		_movement_direction = left + right

	if is_network_master():
		if Input.is_action_pressed("down"):
			position = position.linear_interpolate(get_global_mouse_position(), 0.1)
			velocity = Vector2.ZERO
			velocity_before_collision = Vector2.ZERO
		else:
			update_state(delta)
		if _movement_direction == -1:
			rpc_unreliable("_set_sprite_facing_right", false)
		elif _movement_direction == 1:
			rpc_unreliable("_set_sprite_facing_right", true)
		else:
			rpc_unreliable("_set_sprite_facing_right", _jump_direction.x >= 0.0)
		rpc_unreliable("_update_clients", transform, velocity, velocity_before_collision)
	else:
		var distance = position.distance_to(_target_transform.origin)
		if distance > 0.0:
			position = position.linear_interpolate(_target_transform.origin, 0.5)
		else:
			position = _target_transform.origin

func play_sound(sound_name):
	rpc_unreliable("_play_networked_sound", sound_name)

remotesync func _play_networked_sound(sound_name):
	SFX.play(sound_name, self)

remote func _update_clients(new_transform, new_velocity, new_velocity_before_collision):
	velocity = new_velocity
	velocity_before_collision = new_velocity_before_collision
	_target_transform = new_transform
