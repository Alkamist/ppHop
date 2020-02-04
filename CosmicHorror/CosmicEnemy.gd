extends Node2D

export var duration := 1.0
onready var animation := get_node("AnimationPlayer")
onready var path := get_node("Path2D")
onready var path_follow := get_node("Path2D/PathFollow2D")

func _ready():
	if duration > 0.0:
		var playback_speed = 1.0 / duration
		animation.play("Move", -1.0, playback_speed)
