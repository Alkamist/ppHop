extends Node2D

onready var horizontal_movement := get_node("HorizontalMovement")

func _process(delta):
	var left = -1 if Input.is_action_pressed("left") else 0
	var right = 1 if Input.is_action_pressed("right") else 0
	horizontal_movement.movement_direction = left + right
