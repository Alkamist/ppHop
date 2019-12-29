extends KinematicBody2D
class_name Pp

export var controlling_player := 0
export var friction := 20.0
export var bounciness := 0.8
export var maximum_fall_velocity := 1400.0
export var gravity := 1500.0
export var velocity := Vector2.ZERO
export var velocity_before_collision := Vector2.ZERO

var _time := 0.0
var _jump_buffer := []
var _jump_buffer_time := 0.066
var _just_jumped := false
var _friction_is_suspended := false
var _time_since_jump := 0.0
var _jump_cooldown := 0.05
var _suspend_friction_timer := 0.0

func initialize():
	if is_controlling_player():
		get_node("../Smoothing2D/Camera2D").current = true

func is_controlling_player():
	return get_tree().get_network_unique_id() == controlling_player

func suspend_friction():
	_friction_is_suspended = true
	_suspend_friction_timer = 0.0

func update_state(delta):
	_handle_jumping()
	_handle_friction(delta)
	_handle_gravity(delta)
	velocity_before_collision = velocity
	velocity = move_and_slide(velocity, Vector2.UP)
	_handle_collisions()
	_time_since_jump += delta
	_suspend_friction_timer += delta
	if _suspend_friction_timer > 0.15:
		_friction_is_suspended = false

func _queue_jump(direction):
	var jump = {
		time = _time,
		direction = direction
	}
	_jump_buffer.push_back(jump)

func _clear_old_jumps():
	if _jump_buffer.size() > 0:
		if _time >= _jump_buffer[0].time + _jump_buffer_time:
			_jump_buffer.pop_front()

func _handle_jumping():
	if is_on_floor() and _time_since_jump >= _jump_cooldown:
		if _jump_buffer.size() > 0:
			var jump_vector = _jump_buffer[0].direction
			jump_vector = jump_vector.clamped(200.0)
			jump_vector = pow(200.0, 0.3) * jump_vector / pow(jump_vector.length(), 0.3)
			jump_vector.y = min(jump_vector.y, -50.0)
			velocity = jump_vector * 5.0
			_just_jumped = true
			_time_since_jump = 0.0
			#get_node("Sprite").set_flip_h(jump_vector.x < 0)
			suspend_friction()
			_jump_buffer.pop_front()

func _handle_collisions():
	for i in get_slide_count():
		var collision = get_slide_collision(i)
		var collider = collision.collider
		if collider.is_in_group("ppBody"):
			_collide_with_other_pp(collision, collider)
		else:
			_bounce_off_walls(collision)

func _handle_gravity(delta):
	velocity.y += gravity * delta
	velocity.y = min(velocity.y, maximum_fall_velocity)

func _handle_friction(delta):
	if is_on_floor() and not _friction_is_suspended:
		velocity = lerp(velocity, Vector2.ZERO, clamp(friction * delta, -1.0, 1.0))

func _collide_with_other_pp(collision, collider):
	collider.suspend_friction()
	var vector_to_collider = global_position - collider.global_position
	var collider_velocity = collision.collider_velocity
	var collider_velocity_length = collider_velocity.length()
	var collider_is_stationary = collider_velocity_length == 0
	var collider_is_moving_away = not collider_is_stationary and vector_to_collider.dot(collider_velocity) / collider_velocity_length < 0
	if not collider_is_moving_away and not collider_is_stationary:
		collider.velocity = velocity_before_collision * bounciness
		velocity = collider.velocity_before_collision * bounciness
	else:
		collider.velocity = velocity_before_collision * bounciness

func _bounce_off_walls(collision):
	if abs(collision.normal.x) > 0.90:
		velocity = velocity_before_collision.bounce(collision.normal) * bounciness

func _unhandled_input(event):
	if not is_controlling_player():
		return
	if event.is_action_pressed("jump"):
		_queue_jump(get_global_mouse_position() - global_position)

func _process(delta):
	_time += delta

remote func _update_clients(new_position, new_velocity):
	position = new_position
	velocity = new_velocity

func _physics_process(delta):
	if is_network_master():
		update_state(delta)
		_clear_old_jumps()
		rpc_unreliable("_update_clients", position, velocity)
