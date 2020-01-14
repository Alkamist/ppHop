extends "res://NetworkedMover.gd"

var _floor_normal := Vector2.UP
var _platform_snap := Vector2.ZERO
var _current_platform

const GRAVITY := 1200.0

func _unsnap_from_platform():
	_platform_snap.y = 0
	if _current_platform:
		velocity += _current_platform.velocity
		_current_platform = null

func _snap_to_platform(platform):
	_platform_snap.y = 50.0
	_current_platform = platform

func jump(jump_vector):
	#add_x_velocity(jump_vector.x, 1400.0)
	velocity.x = jump_vector.x
	velocity.y = jump_vector.y
	_unsnap_from_platform()

func add_x_velocity(value, maximum):
	var adder := 0.0
	if value > 0.0:
		adder = min(value, clamp(maximum - velocity.x, 0.0, maximum))
	elif value < 0.0:
		adder = max(value, clamp(-maximum - velocity.x, -maximum, 0.0))
	velocity.x += adder

func add_y_velocity(value, maximum):
	var adder := 0.0
	if value > 0.0:
		adder = min(value, clamp(maximum - velocity.y, 0.0, maximum))
	elif value < 0.0:
		adder = max(value, clamp(-maximum - velocity.y, -maximum, 0.0))
	velocity.y += adder

func update_state(delta):
	if Input.is_action_pressed("up"):
		position = get_global_mouse_position()
		velocity = Vector2.ZERO
	velocity.y += GRAVITY * delta
	move_and_slide_with_snap(velocity, _platform_snap, _floor_normal)
	if not is_on_floor():
		_unsnap_from_platform()
	for i in get_slide_count():
		var collision = get_slide_collision(i)
		if abs(collision.normal.angle_to(Vector2.UP)) > 1.0:
			velocity = velocity.bounce(collision.normal)
			break
		else:
			velocity = velocity.slide(collision.normal)
			var collider = collision.collider
			if collider.is_in_group("platform"):
				_snap_to_platform(collider)
	.update_state(delta)
