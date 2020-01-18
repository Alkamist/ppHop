extends "res://Scripts/NetworkedMover.gd"

var target := Vector2.ZERO

func update_state(delta):
	var movement = target - position
	velocity = movement / delta
	position += movement
