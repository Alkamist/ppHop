extends "res://NetworkedMover.gd"

onready var _previous_position := position
var _movement := Vector2.ZERO

func update_state(delta):
	#var time = (_tick + _ping) * delta
	var time = _tick * delta
	velocity = (position - _previous_position) / delta
	_movement.x = 500.0 * sin(time * 5.0) * delta
	_movement.y = -500.0 * sin(time * 5.0) * delta
	position += _movement
	_previous_position = position
	.update_state(delta)
