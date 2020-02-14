extends Node2D

export var enter_alpha := 1.0
export var exit_alpha := 0.0
export var fade_time := 0.1

var alpha := 0.0
var previous_alpha := 0.0

onready var visuals := get_node("Visuals")
onready var tween := get_node("Tween")
onready var active_area := get_node("Area2D")

func _ready():
	active_area.connect("body_entered", self, "_on_body_entered")
	active_area.connect("body_exited", self, "_on_body_exited")
	var pp_is_present = false
	for body in active_area.get_overlapping_bodies():
		if body.is_in_group("ppBody"):
			pp_is_present = true
	if pp_is_present:
		set_alpha(enter_alpha)
	else:
		set_alpha(exit_alpha)

func set_alpha(value):
	for child in visuals.get_children():
		if child is ParallaxBackground:
			for parallax_child in child.get_children():
				if parallax_child is CanvasItem:
					parallax_child.modulate.a = value

func _process(delta):
	if alpha != previous_alpha:
		set_alpha(alpha)
	previous_alpha = alpha

func fade_alpha(value):
	tween.interpolate_property(self, "alpha", alpha, value, fade_time, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	tween.start()

func _on_body_entered(body):
	if body.is_in_group("ppBody"):
		fade_alpha(enter_alpha)

func _on_body_exited(body):
	if body.is_in_group("ppBody"):
		fade_alpha(exit_alpha)
