extends Node2D

onready var _animation_player := get_node("AnimationPlayer")

func _ready():
	_animation_player.play("Platform")
