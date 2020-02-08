extends ParallaxBackground

export var enter_alpha := 1.0
export var exit_alpha := 0.0
export var fade_time := 1.0

var alpha := 0.0
var previous_alpha := 0.0

onready var tween := get_node("Tween")

func _ready():
	scroll_base_offset = offset + get_parent().global_position
	offset = Vector2.ZERO

func set_alpha(value):
	var children = get_children()
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

func _on_VisibilityEnabler2D_screen_entered():
	fade_alpha(enter_alpha)

func _on_VisibilityEnabler2D_screen_exited():
	fade_alpha(exit_alpha)
