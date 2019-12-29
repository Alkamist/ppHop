extends Position2D

onready var _target := get_node("../KinematicBody2D")

func _process(delta):
	position += _target.velocity * delta
	#position = _target.position + delta * _target.velocity * Engine.get_physics_interpolation_fraction()
	#position = lerp(_target.previous_position, _target.position, Engine.get_physics_interpolation_fraction())

func _physics_process(delta):
	position = _target.position
