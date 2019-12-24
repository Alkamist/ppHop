extends KinematicBody2D
class_name Pp

export var friction := 20.0
export var bounciness := 1.0
export var maximum_fall_velocity := 1400.0
export var gravity := 1500.0

var _controlling_player_id
var _velocity := Vector2.ZERO
var _velocity_before_collision := Vector2.ZERO
var _mouse_position := Vector2.ZERO
var _should_jump := false
var _just_jumped := false
var _is_on_ground := false
var _time_since_jump := 0.0
var _jump_cooldown := 0.05

func set_controlling_player(player_id):
	_controlling_player_id = player_id

func is_controlling_player():
	return _controlling_player_id != null and get_tree().get_network_unique_id() == _controlling_player_id

func update_state(dt):
	_time_since_jump += dt
	
	if _is_on_ground and _should_jump and _time_since_jump >= _jump_cooldown:
		var jump_vector = _mouse_position - global_position
		#jump_vector.y = min(jump_vector.y, tan(0.5) * -abs(jump_vector.x))
		jump_vector = jump_vector.clamped(200.0)
		jump_vector = 23.0 * jump_vector / pow(jump_vector.length(), 0.3)
		_velocity = jump_vector
		_just_jumped = true
		_time_since_jump = 0.0
		get_node("Sprite").set_flip_h(jump_vector.x < 0)
	
	_velocity.y += gravity * dt
	_velocity.y = min(_velocity.y, maximum_fall_velocity)
	
	var collision = move_and_collide(_velocity * dt)
	if collision:
		_velocity_before_collision = _velocity
		_velocity = _velocity.slide(collision.normal)
		_bounce_off_walls(collision)
		_is_on_ground = abs(collision.normal.angle_to(Vector2.UP)) < 0.78
	else:
		_is_on_ground = false

func _bounce_off_walls(collision):
	if abs(collision.normal.x) > 0.90:
		_velocity = _velocity_before_collision.bounce(collision.normal)

master func _update_server(should_jump, mouse_position):
	_should_jump = should_jump
	_mouse_position = mouse_position

remote func _update_clients(dt, new_position, new_velocity):
	position = new_position
	_velocity = new_velocity
	if is_controlling_player():
		update_state(dt)

func _physics_process(dt):
	if is_controlling_player():
		_should_jump = Input.is_action_pressed("jump")
		_mouse_position = get_global_mouse_position()
		rpc_unreliable("_update_server", _should_jump, _mouse_position)
		if not is_network_master():
			update_state(dt)
	
	if is_network_master():
		update_state(dt)
		rpc_unreliable("_update_clients", dt, position, _velocity)
