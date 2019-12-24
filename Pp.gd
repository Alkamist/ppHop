extends KinematicBody2D
class_name Pp

export var friction := 20.0
export var bounciness := 0.8
export var maximum_fall_velocity := 1400.0
export var gravity := 1500.0
export var velocity := Vector2.ZERO
export var velocity_before_collision := Vector2.ZERO

var _controlling_player_id
var _mouse_position := Vector2.ZERO
var _should_jump := false
var _just_jumped := false
var _is_on_ground := false
var _friction_is_suspended := false
var _time_since_jump := 0.0
var _jump_cooldown := 0.05
var _suspend_friction_timer := 0.0

func set_controlling_player(player_id):
	_controlling_player_id = player_id

func is_controlling_player():
	return _controlling_player_id != null and get_tree().get_network_unique_id() == _controlling_player_id

func suspend_friction():
	_friction_is_suspended = true
	_suspend_friction_timer = 0.0

func update_state(dt):
	_time_since_jump += dt
	_handle_jumping(dt)
	_handle_gravity(dt)
	_handle_friction(dt)
	var collision = move_and_collide(velocity * dt)
	_handle_collision(collision)
	_suspend_friction_timer += dt
	if _suspend_friction_timer > 0.15:
		_friction_is_suspended = false

func _handle_jumping(dt):
	if _is_on_ground and _should_jump and _time_since_jump >= _jump_cooldown:
		var jump_vector = _mouse_position - global_position
		jump_vector = jump_vector.clamped(200.0)
		jump_vector = pow(200.0, 0.3) * jump_vector / pow(jump_vector.length(), 0.3)
		jump_vector.y = min(jump_vector.y, -50.0)
		velocity = jump_vector * 5.0
		_just_jumped = true
		_time_since_jump = 0.0
		get_node("Sprite").set_flip_h(jump_vector.x < 0)
		suspend_friction()

func _handle_collision(collision):
	if collision:
		var collider = collision.collider
		velocity_before_collision = velocity
		velocity = velocity.slide(collision.normal)
		if collider.is_in_group("ppBody"):
			_collide_with_other_pp(collision, collider)
		else:
			_bounce_off_walls(collision)
		_is_on_ground = abs(collision.normal.angle_to(Vector2.UP)) < 0.78
	else:
		_is_on_ground = false
	

func _handle_gravity(dt):
	velocity.y += gravity * dt
	velocity.y = min(velocity.y, maximum_fall_velocity)

func _handle_friction(dt):
	if _is_on_ground and not _friction_is_suspended:
		velocity = lerp(velocity, Vector2.ZERO, clamp(friction * dt, -1.0, 1.0))
		if velocity.length() < 20.0:
			velocity.y = 0

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

master func _update_server(should_jump, mouse_position):
	_should_jump = should_jump
	_mouse_position = mouse_position

remote func _update_clients(dt, new_position, new_velocity):
	position = new_position
	velocity = new_velocity
	if is_controlling_player():
		update_state(dt)

#func _draw():
#	var jump_vector = _mouse_position - global_position
#	jump_vector = jump_vector.clamped(200.0)
#	jump_vector = pow(200.0, 0.3) * jump_vector / pow(jump_vector.length(), 0.3)
#	jump_vector.y = min(jump_vector.y, -50.0)
#	draw_line(Vector2.ZERO, jump_vector, Color(255, 0, 0), 1)

#func _process(dt):
#	update()

func _physics_process(dt):
	if is_controlling_player():
		_should_jump = Input.is_action_pressed("jump")
		_mouse_position = get_global_mouse_position()
		rpc_unreliable("_update_server", _should_jump, _mouse_position)
		if not is_network_master():
			update_state(dt)

	if is_network_master():
		update_state(dt)
		rpc_unreliable("_update_clients", dt, position, velocity)
