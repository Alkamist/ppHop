extends KinematicBody2D
class_name Pp

export var controlling_player := 0
export var ground_friction := 1.0
export var velocity := Vector2.ZERO
export var velocity_before_collision := Vector2.ZERO

onready var _camera = get_node("../Smoothing2D/Camera2D")
onready var _visuals = get_node("../Smoothing2D/Visuals")
onready var _jiggle = get_node("../Smoothing2D/Visuals/Jiggle")

var _maximum_collisions_per_frame := 4
var _movement_direction := 0
var _target_transform := Transform2D()
var _jump_direction := Vector2.ZERO
var _is_on_ground := false
var _was_on_ground := false
var _should_jump := false
var _should_crouch := false
var _is_crouching := false
var _was_crouching := false
var _just_jumped := false
var _friction_is_suspended := false
var _cant_launch_pp := false

var _time := 0.0
var _launched_pp_time := 0.0
var _suspend_friction_time := 0.0
var _jump_time := 0.0

const twoPI := 2.0 * PI
var _jiggle_phase := 0.0
var _jiggle_amplitude := 0.0

func initialize(starting_position):
	position = starting_position
	if is_controlling_player():
		_camera.current = true

func is_controlling_player():
	return get_tree().get_network_unique_id() == controlling_player

func is_server():
	return get_tree().get_network_unique_id() == 1

func suspend_friction():
	_friction_is_suspended = true
	_suspend_friction_time = _time

func launch(new_velocity):
	rpc_unreliable("_launch_master", new_velocity)

func _add_to_velocity_component(adder, velocity_component, maximum):
	if adder > 0.0:
		return min(adder, clamp(maximum - velocity_component, 0.0, maximum))
	elif adder < 0.0:
		return max(adder, clamp(-maximum - velocity_component, -maximum, 0.0))
	return 0.0

func _handle_jumping(delta, power, maximum_speed):
	if _should_jump and _is_on_ground and _time - _jump_time > 0.15:
		var jump_vector = _jump_direction / 300.0
		jump_vector = jump_vector.clamped(1.0)
		var length = jump_vector.length()
		if length > 0.0:
			jump_vector *= 1.0 / pow(length, 0.5)
			jump_vector.y = min(jump_vector.y, -0.20)
			jump_vector *= 300.0
		velocity.x += _add_to_velocity_component(jump_vector.x * power, velocity.x, maximum_speed)
		velocity.y = jump_vector.y * power
		_jump_time = _time
		suspend_friction()
		rpc_unreliable("_play_networked_sound", "PPJump")
		_just_jumped = true
	else:
		_just_jumped = false

func _check_if_on_ground(delta):
	var collision = move_and_collide(Vector2.DOWN, true, true, true)
	_was_on_ground = _is_on_ground
	_is_on_ground = collision and abs(collision.normal.angle_to(Vector2.UP)) < 0.7

func _apply_gravity(delta, gravity):
	velocity.y += 60.0 * gravity * delta

func _apply_horizontal_movement(delta, friction, acceleration, maximum_speed):
	if _movement_direction != 0 and not _is_crouching:
		velocity.x += _add_to_velocity_component(_movement_direction * acceleration * delta, velocity.x, maximum_speed)
		if sign(_movement_direction) == sign(velocity.x) or velocity.x == 0.0:
			_friction_is_suspended = true
			if abs(velocity.x) > maximum_speed:
				velocity.x = lerp(velocity.x, sign(velocity.x) * maximum_speed, 60.0 * friction * delta)
	elif _is_crouching:
		var acceleration_component = acceleration * delta
		if abs(velocity.x) > acceleration_component:
			velocity.x += -sign(velocity.x) * acceleration * delta
		else:
			velocity.x = 0.0

func _apply_friction(delta, friction):
	velocity = lerp(velocity, Vector2.ZERO, 60.0 * friction * delta)

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
			if collider.is_in_group("ice"):
				ground_friction = 0.01
			else:
				ground_friction = 1.0
			velocity = velocity.slide(collision.normal)
			var slide_movement = collision.remainder.slide(collision.normal)
			collision = move_and_collide(slide_movement)
		
		# Collide with other pps.
		elif collider.is_in_group("ppBody"):
			rpc_unreliable("_jiggle", velocity.length())
			velocity = collider.velocity_before_collision * bounciness
			if not _cant_launch_pp:
				collider.launch(velocity_before_collision * bounciness)
				_cant_launch_pp = true
				_launched_pp_time = _time
		
		# Bounce off walls.
		else:
			velocity = velocity.bounce(collision.normal) * bounciness
			rpc_unreliable("_jiggle", velocity.length())
			var bounce_movement = collision.remainder.bounce(collision.normal)
			collision = move_and_collide(bounce_movement)
			rpc_unreliable("_play_networked_sound", "PPBounce")
		
		collision_count += 1

func _handle_crouching(delta):
	_was_crouching = _is_crouching
	_is_crouching = _is_on_ground and _should_crouch

func update_state(delta):
	_check_if_on_ground(delta)
	if _is_on_ground:
		_apply_horizontal_movement(delta, ground_friction, 2000.0, 200.0)
		if not _friction_is_suspended:
			_apply_friction(delta, ground_friction)
	else:
		_apply_horizontal_movement(delta, 0.0, 300.0, 140.0)
		_apply_friction(delta, 0.005)
	_handle_crouching(delta)
	_handle_jumping(delta, 3.0, 1400.0)
	_apply_gravity(delta, 20.0)
	_handle_movement_and_collisions(delta, 0.8)
	_time += delta
	if _time - _suspend_friction_time > 0.2:
		_friction_is_suspended = false
	if _time - _launched_pp_time > 0.15:
		_cant_launch_pp = false

func _handle_jiggle(delta, speed, dampening):
	var jiggle_scale = clamp(1.0 - sin(_jiggle_phase) * _jiggle_amplitude, 0.93, 1.07)
	if abs(1.0 - jiggle_scale) < 0.01:
		jiggle_scale = 1.0
	_jiggle.scale.x = jiggle_scale
	_jiggle.scale.y = jiggle_scale
	_jiggle.position.y = pow(12.0 * (1.0 - jiggle_scale), 2.0)
	_jiggle_amplitude -= dampening * _jiggle_amplitude * delta
	_jiggle_amplitude = max(_jiggle_amplitude, 0.0)
	_jiggle_phase += speed * delta
	if _jiggle_phase >= twoPI:
		_jiggle_phase -= twoPI

func _process(delta):
	if is_controlling_player():
		_jump_direction = get_global_mouse_position() - global_position
		var left = -1 if Input.is_action_pressed("left") else 0
		var right = 1 if Input.is_action_pressed("right") else 0
		_movement_direction = left + right
		
	_handle_jiggle(delta, 50.0, 3.0)

func _unhandled_input(event):
	if not is_controlling_player():
		return
	if event.is_action_pressed("jump"):
		_should_jump = true
	elif event.is_action_released("jump"):
		_should_jump = false
	elif event.is_action_pressed("down"):
		_should_crouch = true
	elif event.is_action_released("down"):
		_should_crouch = false

func _physics_process(delta):
	if is_network_master():
		if Input.is_action_pressed("up"):
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
			if _just_jumped:
				rpc_unreliable("_set_sprite_facing_right", _jump_direction.x >= 0.0)
		
		if _is_crouching != _was_crouching:
			rpc("_set_crouch_visually", _is_crouching)
		
		if _is_on_ground and not _was_on_ground:
			rpc_unreliable("_land_visually")
		
		if _just_jumped:
			rpc_unreliable("_jump_visually")
		
		rpc_unreliable("_update_clients", transform, velocity, velocity_before_collision)
	else:
		var distance = position.distance_to(_target_transform.origin)
		if distance > 0.0:
			position = position.linear_interpolate(_target_transform.origin, 0.5)
		else:
			position = _target_transform.origin

remotesync func _play_networked_sound(sound_name):
	SFX.play(sound_name, self)

remote func _update_clients(new_transform, new_velocity, new_velocity_before_collision):
	velocity = new_velocity
	velocity_before_collision = new_velocity_before_collision
	_target_transform = new_transform

remotesync func _set_sprite_facing_right(value):
	if value:
		if _visuals.scale.x < 0:
			_visuals.scale.x *= -1
	else:
		if _visuals.scale.x >= 0:
			_visuals.scale.x *= -1

remotesync func _set_crouch_visually(value):
	var tween = get_node("../Tween")
	if value:
		tween.interpolate_property(_visuals, "scale", Vector2(_visuals.scale.x, 1.0), Vector2(_visuals.scale.x, 0.65), 0.2, Tween.TRANS_ELASTIC, Tween.EASE_OUT)
		tween.interpolate_property(_visuals, "position", Vector2(_visuals.position.x, 0.0), Vector2(_visuals.position.x, 6.0), 0.2, Tween.TRANS_ELASTIC, Tween.EASE_OUT)
		tween.start()
	else:
		tween.interpolate_property(_visuals, "scale", Vector2(_visuals.scale.x, 0.65), Vector2(_visuals.scale.x, 1.0), 0.2, Tween.TRANS_ELASTIC, Tween.EASE_OUT)
		tween.interpolate_property(_visuals, "position", Vector2(_visuals.position.x, 6.0), Vector2(_visuals.position.x, 0.0), 0.2, Tween.TRANS_ELASTIC, Tween.EASE_OUT)
		tween.start()

remotesync func _jump_visually():
	var tween = get_node("../Tween")
	tween.interpolate_property(_visuals, "scale", Vector2(_visuals.scale.x, 0.65), Vector2(_visuals.scale.x, 1.0), 0.4, Tween.TRANS_ELASTIC, Tween.EASE_OUT)
	tween.interpolate_property(_visuals, "position", Vector2(_visuals.position.x, 6.0), Vector2(_visuals.position.x, 0.0), 0.4, Tween.TRANS_ELASTIC, Tween.EASE_OUT)
	tween.start()

remotesync func _land_visually():
	var tween = get_node("../Tween")
	tween.interpolate_property(_visuals, "scale", Vector2(_visuals.scale.x, 1.0), Vector2(_visuals.scale.x, 0.9), 0.07, Tween.TRANS_SINE, Tween.EASE_OUT)
	tween.interpolate_property(_visuals, "position", Vector2(_visuals.position.x, 0.0), Vector2(_visuals.position.x, 2.0), 0.07, Tween.TRANS_SINE, Tween.EASE_OUT)
	tween.start()
	yield(tween, "tween_completed")
	tween.interpolate_property(_visuals, "scale", Vector2(_visuals.scale.x, 0.9), Vector2(_visuals.scale.x, 1.0), 0.07, Tween.TRANS_SINE, Tween.EASE_OUT)
	tween.interpolate_property(_visuals, "position", Vector2(_visuals.position.x, 2.0), Vector2(_visuals.position.x, 0.0), 0.07, Tween.TRANS_SINE, Tween.EASE_OUT)
	tween.start()

remotesync func _jiggle(intensity):
	_jiggle_amplitude = intensity * 0.00025
	_jiggle_phase = 0.0

master func _launch_master(new_velocity):
	suspend_friction()
	rpc_unreliable("jiggle", new_velocity.length())
	velocity = new_velocity
