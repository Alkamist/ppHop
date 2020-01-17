extends "res://Scripts/NetworkedMover.gd"

var target := Vector2.ZERO
var movement := Vector2.ZERO

func update_state(delta):
	movement = target - position
	velocity = movement / delta
	position += movement
