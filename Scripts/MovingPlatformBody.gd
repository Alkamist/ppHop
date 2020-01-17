extends "res://Scripts/NetworkedMover.gd"

export var target := Vector2.ZERO

onready var _previous_position := position

func update_state(delta):
	velocity = (position - _previous_position) / delta
	position = position.linear_interpolate(target, 0.075)
	_previous_position = position
