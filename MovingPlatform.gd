extends Node2D

export var move_to := Vector2.ZERO
export var speed := 300.0

onready var _body := get_node("Body")
onready var _tween := get_node("Tween")

func _ready():
	var duration = move_to.length() / speed
	_tween.interpolate_property(_body, "target", Vector2.ZERO, move_to, duration, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	_tween.interpolate_property(_body, "target", move_to, Vector2.ZERO, duration, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT, duration)
	_tween.start()
