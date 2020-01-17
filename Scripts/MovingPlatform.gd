extends Node2D

export var move_to := Vector2.ZERO
export var speed := 300.0
onready var body := get_node("Body")
onready var tween := get_node("Tween")

func _ready():
	var duration = move_to.length() / speed
	tween.interpolate_property(body, "target", Vector2.ZERO, move_to, duration, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	tween.interpolate_property(body, "target", move_to, Vector2.ZERO, duration, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT, duration)
	tween.start()
