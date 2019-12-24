extends KinematicBody2D
class_name PpBody

export var friction := 20.0
export var bounciness := 0.8
export var terminal_fall_velocity := 1400.0
export var gravity := 1500.0
export var velocity := Vector2.ZERO
export var velocity_before_collision := Vector2.ZERO

var _friction_is_suspended := false
var _suspend_friction_timer := 0.0
var _is_on_ground := false

func suspend_friction():
	_friction_is_suspended = true
	_suspend_friction_timer = 0.0

func jump(raw_jump_vector):
	if not _is_on_ground:
		return
	raw_jump_vector.y = min(raw_jump_vector.y, tan(0.1) * -abs(raw_jump_vector.x))
	raw_jump_vector = raw_jump_vector.clamped(200.0)
	var jump_vector = 23.0 * raw_jump_vector / pow(raw_jump_vector.length(), 0.3)
	velocity = jump_vector
	velocity_before_collision = velocity
	get_node("../Smoothing2D/Sprite").set_flip_h(jump_vector.x < 0)
	suspend_friction()

func _bounce_off_walls(collision):
	if abs(collision.normal.x) > 0.90:
		velocity = velocity_before_collision.bounce(collision.normal) * bounciness

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

func _calculate_is_on_ground():
	var raycast = get_node("RayCast2D")
	var slope_is_ok = raycast.is_colliding() and raycast.get_collision_normal().y < -0.8
	_is_on_ground = slope_is_ok and test_move(transform.translated(get_node("../").position), Vector2(0, 5))

func _handle_friction(dt):
	if _is_on_ground and not _friction_is_suspended:
		velocity = lerp(velocity, Vector2.ZERO, clamp(friction * dt, -1.0, 1.0))
		if velocity.length() < 20.0:
			velocity.y = 0

func _handle_gravity(dt):
	velocity.y += gravity * dt
	velocity.y = min(velocity.y, terminal_fall_velocity)

func _handle_collisions():
	for i in get_slide_count():
		var collision = get_slide_collision(i)
		var collider = collision.collider
		if collider.is_in_group("ppBody"):
			_collide_with_other_pp(collision, collider)
		else:
			_bounce_off_walls(collision)

func _handle_physics(dt):
	velocity_before_collision = velocity
	velocity = move_and_slide(velocity, Vector2.UP)
	_calculate_is_on_ground()
	_handle_gravity(dt)
	_handle_friction(dt)
	_handle_collisions()
	_suspend_friction_timer += dt
	if _suspend_friction_timer > 0.15:
		_friction_is_suspended = false

remote func _update_clients(new_position, new_velocity, new_velocity_before_collision):
	position = new_position
	velocity = new_velocity
	velocity_before_collision = new_velocity_before_collision

func _physics_process(dt):
	_handle_physics(dt)
	if is_network_master():
		rpc_unreliable("_update_clients", position, velocity, velocity_before_collision)
