extends Node2D

var time := 0.0
onready var original_position := position

func _process(delta):
	position.y = original_position.y + sin(time * 2.0) * 10.0
	time += delta
