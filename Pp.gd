extends KinematicBody2D
class_name Pp

export var maximum_collisions_per_frame := 4
export var controlling_player := 0
export var friction := 60.0
export var bounciness := 0.8
export var maximum_fall_velocity := 1400.0
export var minimum_bounce_normal := 250.0
export var gravity := 1500.0
export var velocity := Vector2.ZERO
export var velocity_before_collision := Vector2.ZERO

var _tick := 0
var _ping := 0
var _target_transform := Transform2D()
var _should_jump := false
var _jump_direction := Vector2.ZERO
var _jump_power := 0.0
var _time := 0.0
var _just_jumped := false
var _friction_is_suspended := false
var _time_since_jump := 0.0
var _jump_cooldown := 0.1
var _suspend_friction_timer := 0.0
var _is_on_ground := false
var _cant_launch_pp := false
var _cant_launch_pp_timer := 0.0

func initialize():
	if is_controlling_player():
		get_node("../Smoothing2D/Camera2D").current = true

func is_controlling_player():
	return get_tree().get_network_unique_id() == controlling_player

func is_server():
	return get_tree().get_network_unique_id() == 1

func suspend_friction():
	_friction_is_suspended = true
	_suspend_friction_timer = 0.0

func launch(new_velocity):
	rpc_unreliable("_launch_master", new_velocity)

master func _launch_master(new_velocity):
	suspend_friction()
	velocity = new_velocity

func _jump_if_needed(delta):
	if _should_jump and _is_on_ground and _time_since_jump >= _jump_cooldown:
		var jump_vector = _jump_direction / 300.0
		jump_vector = jump_vector.clamped(1.0)
		var length = jump_vector.length()
		if length > 0.0:
			jump_vector.y += 0.25
			jump_vector.y = min(jump_vector.y, 0.0)
			jump_vector *= 1.0 / pow(length, 0.5)
			jump_vector.y -= 0.25
			jump_vector *= 300.0
		velocity = jump_vector * 3.3
		_just_jumped = true
		_time_since_jump = 0.0
		suspend_friction()
		play_sound("PPJump")

func _collision_is_ground(collision):
	return abs(collision.normal.angle_to(Vector2.UP)) < 0.78

func _check_if_on_ground(delta):
	var collision = move_and_collide(Vector2.DOWN, true, true, true)
	_is_on_ground = collision and _collision_is_ground(collision)

func _apply_gravity(delta):
	velocity.y += gravity * delta
	velocity.y = min(velocity.y, maximum_fall_velocity)

func _apply_friction(delta):
	if _is_on_ground and not _friction_is_suspended:
		velocity = lerp(velocity, Vector2.ZERO, clamp(friction * delta, -1.0, 1.0))

func _handle_movement_and_collisions(delta):
	velocity_before_collision = velocity
	var collision = move_and_collide(velocity * delta)
	var collision_count = 0
	while collision and collision_count < maximum_collisions_per_frame and collision.remainder.length() > 0.0:
		var collider = collision.collider
		
		# Slide on the floor or a pp head.
		if _collision_is_ground(collision):
			velocity = velocity.slide(collision.normal)
			var slide_movement = collision.remainder.slide(collision.normal)
			collision = move_and_collide(slide_movement)

		# Collide with other pps.
		elif collider.is_in_group("ppBody"):
			velocity = collider.velocity_before_collision * bounciness
			if not _cant_launch_pp:
				collider.launch(velocity_before_collision * bounciness)
				_cant_launch_pp = true
				_cant_launch_pp_timer = 0.0

		# Bounce off walls.
		else:
			var bounce_vector = velocity.bounce(collision.normal) * bounciness
			var original_bounce_normal_length = bounce_vector.dot(collision.normal)
			var bounce_normal_scale = clamp(0.5 * PI - abs(collision.normal.angle_to(Vector2.UP)), 0.0, 1.0)
			var bounce_normal_multiplier = max(0.0, minimum_bounce_normal - original_bounce_normal_length) * bounce_normal_scale
			velocity = bounce_vector + collision.normal * bounce_normal_multiplier
			var bounce_movement = collision.remainder.bounce(collision.normal)
			collision = move_and_collide(bounce_movement)
			play_sound("PPBounce")

		collision_count += 1

remotesync func _set_sprite_direction(jump_direction):
	get_node("../Smoothing2D/Sprite").set_flip_h(jump_direction.x < 0)

func update_state(delta):
	_check_if_on_ground(delta)
	_jump_if_needed(delta)
	_apply_gravity(delta)
	_apply_friction(delta)
	_handle_movement_and_collisions(delta)
	_time_since_jump += delta
	_suspend_friction_timer += delta
	_cant_launch_pp_timer += delta
	if _suspend_friction_timer > 0.15:
		_friction_is_suspended = false
	if _cant_launch_pp_timer > 0.15:
		_cant_launch_pp = false

#func _process(delta):
#	update()

#func _draw():
#	if is_controlling_player():
#		var jump_vector = _jump_direction / 300.0
#		jump_vector = jump_vector.clamped(1.0)
#		var length = jump_vector.length()
#		if length > 0.0:
#			jump_vector.y = min(jump_vector.y, -0.25)
#			jump_vector *= 300.0
#			draw_line(Vector2(0,0), jump_vector, Color(255, 0, 0), 1)

func _physics_process(delta):
	if not is_server():
		rpc_unreliable_id(1, "_ping_server", get_tree().get_network_unique_id(), _tick)

	if is_controlling_player():
		_jump_direction = get_global_mouse_position() - global_position
		_should_jump = Input.is_action_pressed("jump")

	if is_network_master():
		if Input.is_action_pressed("down"):
			position = position.linear_interpolate(get_global_mouse_position(), 0.1)
			velocity = Vector2.ZERO
			velocity_before_collision = Vector2.ZERO
		else:
			update_state(delta)
		rpc_unreliable("_set_sprite_direction", _jump_direction)
		rpc_unreliable("_update_clients", transform, velocity, velocity_before_collision)
	else:
		var distance = position.distance_to(_target_transform.origin)
		if distance > 0.0:
			position = position.linear_interpolate(_target_transform.origin, 0.5)
		else:
			position = _target_transform.origin

	_time += delta
	_tick += 1

func play_sound(sound_name):
	rpc_unreliable("_play_networked_sound", sound_name)

remotesync func _play_networked_sound(sound_name):
	SFX.play(sound_name, self)

remote func _ping_server(network_id, tick):
	rpc_unreliable_id(network_id, "_update_ping", tick)

remote func _update_ping(tick):
	_ping = _tick - tick

remote func _update_clients(new_transform, new_velocity, new_velocity_before_collision):
	velocity = new_velocity
	velocity_before_collision = new_velocity_before_collision
	_target_transform = new_transform
