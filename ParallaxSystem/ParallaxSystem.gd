extends Node2D

export var enter_alpha := 1.0
export var exit_alpha := 0.0
export var fade_time := 1.0

var alpha := 0.0
var previous_alpha := 0.0

onready var parallax := get_node("ParallaxBackground")
onready var tween := get_node("Tween")
onready var active_area := get_node("Area2D")

func _ready():
	parallax.scroll_base_offset = parallax.offset + get_parent().global_position
	parallax.offset = Vector2.ZERO
	active_area.connect("body_entered", self, "_on_body_entered")
	active_area.connect("body_exited", self, "_on_body_exited")

func set_alpha(value):
	var children = parallax.get_children()
	for child in children:
		if child is CanvasItem:
			child.modulate.a = value

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
