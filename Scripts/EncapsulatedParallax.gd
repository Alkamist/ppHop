extends ParallaxBackground

export var fade_time := 1.0

var _alpha := 0.0
var _target_alpha := 0.0
var _alpha_difference := 0.0

func fade_alpha(value):
	_target_alpha = value
	_alpha_difference = (value - _alpha) * fade_time

func set_alpha(value):
	var children = get_children()
	for child in children:
		child.modulate.a = value

func _ready():
	set_alpha(0.0)

func _process(delta):
	scroll_base_offset = get_parent().position
	
	if _target_alpha != _alpha:
		_alpha += _alpha_difference * delta
		_alpha = clamp(_alpha, 0.0, 1.0)
		set_alpha(_alpha)

func _on_Area2D_body_entered(body):
	if body.has_method("is_controlling_player") and body.is_controlling_player():
		fade_alpha(1.0)

func _on_Area2D_body_exited(body):
	if body.has_method("is_controlling_player") and body.is_controlling_player():
		fade_alpha(0.0)
