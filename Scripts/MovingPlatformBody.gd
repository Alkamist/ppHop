extends KinematicBody2D

var velocity := Vector2.ZERO
onready var previous_position := position

func _physics_process(delta):
	velocity = (position - previous_position) / delta
	previous_position = position
