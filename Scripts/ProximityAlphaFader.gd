extends Node2D

export var enter_alpha := 1.0
export var exit_alpha := 0.0
export var fade_time := 1.0

var alpha := 0.0
var previous_alpha := 0.0

onready var tween := get_node("Tween") 

signal alpha_changed

func _process(delta):
	if alpha != previous_alpha:
		emit_signal("alpha_changed", alpha)
	previous_alpha = alpha

func fade_alpha(value):
	tween.interpolate_property(self, "alpha", alpha, value, fade_time, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	tween.start()

func _on_Area2D_body_entered(body):
	if body.is_in_group("ppBody"):
		fade_alpha(enter_alpha)

func _on_Area2D_body_exited(body):
	if body.is_in_group("ppBody"):
		fade_alpha(exit_alpha)
