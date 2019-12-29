extends Position2D

onready var _target := get_node("../KinematicBody2D")

func _process(delta):
	position = lerp(_target.previous_position, _target.position, Engine.get_physics_interpolation_fraction())
