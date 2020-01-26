extends Area2D

onready var path_follow := get_node("../Path2D/PathFollow2D")

func _process(delta):
	position.y = path_follow.position.y
