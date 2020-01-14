extends "res://NetworkedMover.gd"

export var movement_direction := 0
export var should_crouch := false
export var is_crouching := false

var _was_crouching := false
var _gravity := 1200.0
var _ground_friction := 0.01
var _air_resistance := 0.005
var _time := 0.0
var _launch_time := 0.0
var _friction_is_suspended := false
var _suspend_friction_time := 0.0
var _is_jumping := false
var _is_crouching := false
var _floor_normal := Vector2.UP
var _platform_snap := Vector2.ZERO
var _current_platform

onready var _jiggler := get_node("../Smoothing2D/Visuals/Jiggler")

signal just_jumped
signal just_crouched
signal just_uncrouched

func _unsnap_from_platform():
	_platform_snap.y = 0
	if _current_platform:
		velocity += _current_platform.velocity
		_current_platform = null

func _snap_to_platform(platform):
	_platform_snap.y = 50.0
	_current_platform = platform

func _suspend_friction():
	_friction_is_suspended = true
	_suspend_friction_time = _time

func jump(jump_vector):
	velocity.x += _add_to_velocity_component(velocity.x, jump_vector.x, 1400.0)
	velocity.y = jump_vector.y
	_is_jumping = true
	_unsnap_from_platform()
	_suspend_friction()
	emit_signal("just_jumped")

func launch_master(launch_vector):
	rpc("_launch_master", launch_vector)

master func _launch_master(launch_vector):
	if _time - _launch_time > 0.15:
		_launch_time = _time
		velocity.x = launch_vector.x
		velocity.y = launch_vector.y
		_unsnap_from_platform()
		_suspend_friction()
		_jiggler.jiggle(velocity.length())

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
			_jiggler.jiggle(velocity.length())
			if collider.is_in_group("ppBody"):
				var collider_velocity = collider.velocity
				collider.launch_master(velocity)
				velocity = collider_velocity
			else:
				velocity = velocity.bounce(collision.normal)
			break
		else:
			velocity = velocity.slide(collision.normal)
			#if collider.is_in_group("ice"):
			#	_ground_friction = 0.01
			#else:
			#	_ground_friction = 1.0
			if collider.is_in_group("platform"):
				_snap_to_platform(collider)

func _handle_crouching():
	_was_crouching = is_crouching
	is_crouching = should_crouch and is_on_floor()
	if is_crouching and not _was_crouching:
		emit_signal("just_crouched")
	if not is_crouching and _was_crouching:
		emit_signal("just_uncrouched")

func update_state(delta):
	if Input.is_action_pressed("up"):
		position = get_global_mouse_position()
		velocity = Vector2.ZERO
	
	_apply_gravity(delta)
	_handle_crouching()
	
	if is_on_floor():
		_apply_horizontal_movement(delta, _ground_friction, 2000.0, 200.0)
		if not _friction_is_suspended:
			_apply_friction(delta, _ground_friction)
	else:
		_unsnap_from_platform()
		_apply_horizontal_movement(delta, 0.0, 300.0, 140.0)
		_apply_friction(delta, _air_resistance)
	
	move_and_slide_with_snap(velocity, _platform_snap, _floor_normal)
	_handle_collisions()
	
	_is_jumping = false
	if _time - _suspend_friction_time > 0.2:
		_friction_is_suspended = false
	
	_time += delta
