extends "res://Scripts/NetworkedMover.gd"

var target := Vector2.ZERO
onready var previous_position := position

func update_state(delta):
	velocity = (position - previous_position) / delta
	position = position.linear_interpolate(target, 0.075)
	previous_position = position
