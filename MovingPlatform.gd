extends "res://NetworkedMover.gd"

onready var _previous_position := position
var _movement := Vector2.ZERO
var _time := 0.0

func update_state(delta):
	velocity = (position - _previous_position) / delta
	_movement.x = 500.0 * sin(_time * 5.0) * delta
	_movement.y = -500.0 * sin(_time * 5.0) * delta
	position += _movement
	_previous_position = position
	_time += delta
