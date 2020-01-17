extends "res://Scripts/NetworkedMover.gd"

export var bounciness := 0.8
export var movement_direction := 0
export var should_crouch := false
export var is_crouching := false

var _controlling_player := -1
var _is_on_ground := false
var _was_on_ground := false
var _was_crouching := false
var _gravity := 1200.0
var _ground_friction := 1.0
var _air_resistance := 0.005
var _time := 0.0
var _launch_time := 0.0
var _friction_is_suspended := false
var _suspend_friction_time := 0.0
var _is_jumping := false
var _is_crouching := false
var _should_jump := false
var _jump_direction := Vector2.ZERO
var _floor_normal := Vector2.UP
var _platform_snap := Vector2.ZERO
var _current_platform

signal just_jumped
signal just_crouched
signal just_uncrouched
signal just_landed
signal just_became_airborne
signal just_got_launched
signal just_bounced

func set_controlling_player(id):
	_controlling_player = id

func is_controlling_player():
	return get_tree().get_network_unique_id() == _controlling_player

func _unsnap_from_platform():
	_platform_snap.y = 0
	if _current_platform:
		#velocity += _current_platform.velocity
		_current_platform = null

func _snap_to_platform(platform):
	_platform_snap.y = 50.0
	_current_platform = platform

func _suspend_friction():
	_friction_is_suspended = true
	_suspend_friction_time = _time

func jump(jump_direction):
	if _is_on_ground:
		_should_jump = true
		_jump_direction = jump_direction

func launch_master(launch_vector):
	rpc("_launch_master", launch_vector)

master func _launch_master(launch_vector):
	if _time - _launch_time > 0.15:
		_launch_time = _time
		velocity.x = launch_vector.x
		velocity.y = launch_vector.y
		_unsnap_from_platform()
		_suspend_friction()
		emit_signal("just_got_launched")

func _check_if_on_ground():
	var collision = move_and_collide(Vector2.DOWN, true, true, true)
	_was_on_ground = _is_on_ground
	_is_on_ground = collision and abs(collision.normal.angle_to(Vector2.UP)) < 0.7

func _handle_jumping():
	if _should_jump:
		var jump_vector = _jump_direction / 300.0
		jump_vector = jump_vector.clamped(1.0)
		var length = jump_vector.length()
		if length > 0.0:
			jump_vector *= 1.0 / pow(length, 0.5)
			jump_vector.y = min(jump_vector.y, -0.20)
			jump_vector *= 3.0 * 300.0
		velocity.x += _add_to_velocity_component(velocity.x, jump_vector.x, 1400.0)
		velocity.y = jump_vector.y
		_is_jumping = true
		_unsnap_from_platform()
		_suspend_friction()
		emit_signal("just_jumped")
		_should_jump = false

func _add_to_velocity_component(velocity_component, adder, maximum):
	if adder > 0.0:
		return min(adder, clamp(maximum - velocity_component, 0.0, maximum))
	elif adder < 0.0:
		return max(adder, clamp(-maximum - velocity_component, -maximum, 0.0))
	return 0.0

func _apply_friction(delta, friction):
	velocity = lerp(velocity, Vector2.ZERO, 60.0 * friction * delta)

func _apply_gravity(delta):
	velocity.y += _gravity * delta

func _apply_horizontal_movement(delta, friction, acceleration, maximum_speed):
	if movement_direction != 0 and not is_crouching:
		velocity.x += _add_to_velocity_component(velocity.x, movement_direction * acceleration * delta, maximum_speed)
		if sign(movement_direction) == sign(velocity.x) or velocity.x == 0.0:
			_friction_is_suspended = true
			if not _is_jumping and abs(velocity.x) > maximum_speed:
				velocity.x = lerp(velocity.x, sign(velocity.x) * maximum_speed, 60.0 * friction * delta)
	
	elif is_crouching:
		var acceleration_component = acceleration * delta
		if abs(velocity.x) > acceleration_component:
			velocity.x += -sign(velocity.x) * acceleration * delta
		else:
			velocity.x = 0.0

func _handle_collisions():
	for i in get_slide_count():
		var collision = get_slide_collision(i)
		var collider = collision.collider
		if abs(collision.normal.angle_to(Vector2.UP)) > 1.0:
			if collider.is_in_group("ppBody"):
				var collider_velocity = collider.velocity
				collider.launch_master(velocity * bounciness)
				velocity = collider_velocity * bounciness
			else:
				emit_signal("just_bounced")
				velocity = velocity.bounce(collision.normal) * bounciness
			break
		else:
			velocity = velocity.slide(collision.normal)
			if collider.is_in_group("ice"):
				_ground_friction = 0.01
			else:
				_ground_friction = 1.0
			if collider.is_in_group("platform"):
				_snap_to_platform(collider)

func _handle_crouching():
	_was_crouching = is_crouching
	is_crouching = should_crouch and _is_on_ground
	if is_crouching and not _was_crouching:
		emit_signal("just_crouched")
	if not is_crouching and _was_crouching:
		emit_signal("just_uncrouched")

func _handle_floor_signals():
	if _is_on_ground and not _was_on_ground:
		emit_signal("just_landed")
	if not _is_on_ground and _was_on_ground:
		emit_signal("just_became_airborne")
	_was_on_ground = _is_on_ground

func _handle_physics(delta):
	_check_if_on_ground()
	_apply_gravity(delta)
	
	if _is_on_ground:
		_apply_horizontal_movement(delta, _ground_friction, 2000.0, 200.0)
		if not _friction_is_suspended:
			_apply_friction(delta, _ground_friction)
	else:
		_unsnap_from_platform()
		_apply_horizontal_movement(delta, 0.0, 300.0, 140.0)
		_apply_friction(delta, _air_resistance)
	
	_handle_crouching()
	_handle_jumping()
	move_and_slide_with_snap(velocity, _platform_snap, _floor_normal, false, 4, 0.7)
	_handle_collisions()
	_handle_floor_signals()
	
	_is_jumping = false
	if _time - _suspend_friction_time > 0.2:
		_friction_is_suspended = false
	
	_time += delta

func update_state(delta):
	if is_controlling_player() and Input.is_action_pressed("up"):
		position = lerp(position, get_global_mouse_position(), 0.1)
		velocity = Vector2.ZERO
	else:
		_handle_physics(delta)