extends Node2D

export var enter_alpha := 1.0
export var exit_alpha := 0.0
export var fade_time := 1.0

var alpha := 0.0
var previous_alpha := 0.0

onready var parallax := get_node("ParallaxBackground")
onready var tween := get_node("Tween")
onready var visibility_area := get_node("VisibilityNotifier2D")

func _ready():
	parallax.scroll_base_offset = parallax.offset + get_parent().global_position
	parallax.offset = Vector2.ZERO
	visibility_area.connect("screen_entered", self, "_on_screen_entered")
	visibility_area.connect("screen_exited", self, "_on_screen_exited")
	if visibility_area.is_on_screen():
		set_alpha(enter_alpha)
	else:
		set_alpha(exit_alpha)

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

func _on_screen_entered():
	fade_alpha(enter_alpha)

func _on_screen_exited():
	fade_alpha(exit_alpha)
