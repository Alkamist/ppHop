extends KinematicBody2D

onready var previous_position := position

signal just_moved

func _physics_process(delta):
	var movement = position - previous_position
	if movement.length() > 0.0:
		emit_signal("just_moved", movement)
	previous_position = position
