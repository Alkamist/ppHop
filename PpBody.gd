extends KinematicBody2D
class_name PpBody

export var friction := 0.0
export var bounciness := 0.8
export var terminal_fall_velocity := 1400.0
export var gravity := 1500.0
export var velocity := Vector2.ZERO
export var velocity_before_collision := Vector2.ZERO

var _just_launched := false
var _time_since_launch := 0.0

func mark_launch():
	_just_launched = true
	_time_since_launch = 0

puppet func _update_position(value):
	position = value

puppet func _update_velocity(value):
	velocity = value

func _bounce_off_walls(collision):
	if abs(collision.normal.x) > 0.90:
		velocity = velocity_before_collision.bounce(collision.normal) * bounciness

func _collide_with_other_pp(collision, collider):
	collider.mark_launch()
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

func _physics_process(dt):
	_time_since_launch += dt
	
	if is_on_floor() and not _just_launched:
		velocity.x = lerp(velocity.x, 0, clamp(friction, -1.0, 1.0))
	velocity.y += gravity * dt
	velocity.y = min(velocity.y, terminal_fall_velocity)
	velocity_before_collision = velocity
	velocity = move_and_slide(velocity, Vector2.UP)

	for i in get_slide_count():
		var collision = get_slide_collision(i)
		var collider = collision.collider
		if collider.is_in_group("ppBody"):
			_collide_with_other_pp(collision, collider)
		else:
			_bounce_off_walls(collision)

	if _time_since_launch > 0.03:
		_just_launched = false

	if is_network_master():
		rpc_unreliable("_update_position", position)
		rpc_unreliable("_update_velocity", velocity)
