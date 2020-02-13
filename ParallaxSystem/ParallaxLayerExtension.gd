extends ParallaxBackground

export var distance_tint := Color(0.0, 0.0, 0.0, 1.0)
export var depth := 4
export var spacing := 0.8
export var tinting := 0.08
export var desaturation := 0.08
export var x_variation := 0.0
export var y_skew := 40.0

var layers := []
onready var base_layer := get_node("ParallaxLayer")
onready var base_sprite := get_node("ParallaxLayer/Sprite")

func _add_depth_layer(at_depth):
	var scale_value = pow(spacing, at_depth)
	var new_scale = Vector2(base_layer.motion_scale.x * scale_value, base_layer.motion_scale.y * scale_value)
	var new_layer = ParallaxLayer.new()
	add_child(new_layer)
	new_layer.z_index = -1
	new_layer.motion_scale = new_scale
	new_layer.motion_offset.y = -sqrt(at_depth) * y_skew
	var layer_sprite = base_sprite.duplicate()
	layer_sprite.scale *= scale_value
	layer_sprite.modulate = layer_sprite.modulate.linear_interpolate(distance_tint, at_depth * tinting)
	layer_sprite.material = layer_sprite.material.duplicate()
	layer_sprite.material.set_shader_param("desaturation", at_depth * desaturation)
	layer_sprite.position.x += new_scale.x * x_variation * (randf() * 2.0 - 1.0)
	layer_sprite.region_rect.size.x /= scale_value
	new_layer.add_child(layer_sprite)
	return new_layer

func _ready():
	for i in range(depth, 0, -1):
		layers.push_back(_add_depth_layer(i))
