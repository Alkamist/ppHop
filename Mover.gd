extends KinematicBody2D
class_name Mover

export var velocity := Vector2.ZERO
export var bounciness := 1.0
export var has_infinite_inertia := false

const MAXIMUM_COLLISIONS_PER_FRAME := 4

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

func _handle_collision(collision):
	var collider = collision.collider
	var self_component = collision.normal * velocity.dot(collision.normal)
	if "velocity" in collider:
		var collision_bounce = bounciness * collider.bounciness
		var collider_component = collision.normal * collider.velocity.dot(collision.normal)
		collider.velocity += collision_bounce * self_component - collider_component
		velocity += collision_bounce * collider_component - self_component
		return move_and_collide(collision.remainder.slide(collision.normal))
	else:
		velocity = velocity.bounce(collision.normal) + self_component * (1.0 - bounciness)
		return move_and_collide(collision.remainder.slide(collision.normal))

func _move(distance):
	var collision := move_and_collide(distance, true, true, true)
	if collision:
		if collision.travel.length() > 0.08:
			position += collision.travel * 0.95
	else:
		position += distance
	return collision

func _handle_movement(delta):
	var collision = _move(velocity * delta)
	var collision_count := 0
	while collision and collision_count < MAXIMUM_COLLISIONS_PER_FRAME and collision.remainder.length() > 0.0:
		var remaining_movement := Vector2.ZERO
		collision = _handle_collision(collision)
		collision_count += 1
