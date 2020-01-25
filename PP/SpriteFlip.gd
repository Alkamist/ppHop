extends Node2D

onready var body := get_node("../../Body")

func _process(delta):
	var movement_direction = body.movement_direction
	if movement_direction != 0:
		scale.x = movement_direction

func _on_Body_just_jumped():
	scale.x = 1.0 if body.jump_direction.x >= 0.0 else -1.0
