extends Mover
class_name Pp

var _is_on_ground := false
var _was_on_ground := false

const GRAVITY := 1200.0
const MAXIMUM_GROUND_ANGLE := 0.7
const MAXIMUM_SLIDE_ANGLE := 1.0
const AIR_BOUNCE_THRESHOLD := 50.0
const GROUND_BOUNCE_THRESHOLD := 210.0

func _handle_collision(collision):
	#var impact_intensity := abs(velocity.dot(collision.normal))
	#var do_not_bounce := impact_intensity < AIR_BOUNCE_THRESHOLD or _is_on_ground and impact_intensity < GROUND_BOUNCE_THRESHOLD
	#if abs(collision.normal.angle_to(Vector2.UP)) < MAXIMUM_SLIDE_ANGLE or do_not_bounce:
	#if abs(collision.normal.angle_to(Vector2.UP)) < MAXIMUM_SLIDE_ANGLE:
		#return _handle_slide_collision(collision)
	#else:
	return _handle_elastic_collision(collision)

func _check_if_on_ground():
	var ground_test := move_and_collide(Vector2.DOWN, true, true, true)
	_was_on_ground = _is_on_ground
	_is_on_ground = ground_test and abs(ground_test.normal.angle_to(Vector2.UP)) < MAXIMUM_GROUND_ANGLE

func _physics_process(delta):
	_check_if_on_ground()
	velocity.y += GRAVITY * delta
	_handle_movement(delta)
