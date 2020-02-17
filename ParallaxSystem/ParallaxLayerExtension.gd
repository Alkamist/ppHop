extends ParallaxBackground

export var distance_tint := Color(0.0, 0.0, 0.0, 1.0)
export var depth := 32
export var spacing := 1.0
export var tinting := 1.0
export var x_variation := 1.0
export var y_skew := 40.0

var layers := []
onready var base_layer := get_node("ParallaxLayer")
onready var base_sprite := get_node("ParallaxLayer/Sprite")

func _add_depth_layer(at_depth):
	var scale_value = 1.0 / pow(at_depth + 1, spacing)
	var new_scale = Vector2(base_layer.motion_scale.x * scale_value, base_layer.motion_scale.y * scale_value)
	var new_layer = ParallaxLayer.new()
	add_child(new_layer)
	new_layer.z_index = -1
	new_layer.motion_scale = new_scale
	new_layer.motion_offset.y = -(1.0 - scale_value) * 100.0
	var layer_sprite = base_sprite.duplicate()
	layer_sprite.scale *= scale_value
	layer_sprite.material = layer_sprite.material.duplicate()
	layer_sprite.material.set_shader_param("fade_color", distance_tint)
	#layer_sprite.material.set_shader_param("tint_strength", at_depth * tinting / depth)
	layer_sprite.material.set_shader_param("tint_strength", tinting * pow(float(at_depth) / float(depth), 0.8))
	layer_sprite.position.x += round(x_variation * randf() * layer_sprite.texture.get_width())
	layer_sprite.region_rect.size.x /= scale_value
	new_layer.add_child(layer_sprite)
	return new_layer

func _ready():
	scroll_base_offset += offset + get_parent().global_position
	offset = Vector2.ZERO
	for i in range(depth, 0, -1):
		layers.push_back(_add_depth_layer(i))
