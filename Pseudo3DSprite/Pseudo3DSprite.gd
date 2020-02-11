extends Sprite

export var depth := 2
export var spacing := 0.01
export var darkening := 0.3
export var y_skew := 350.0

var background_layers := []
var foreground_layers := []

func _add_depth_layer(at_depth):
	var viewport_scale = 1.0 + spacing * at_depth
	var new_canvas_layer = CanvasLayer.new()
	add_child(new_canvas_layer)
	new_canvas_layer.layer = at_depth
	new_canvas_layer.scale = scale
	new_canvas_layer.follow_viewport_enable = true
	new_canvas_layer.follow_viewport_scale = viewport_scale
	var layer_sprite = Sprite.new()
	layer_sprite.texture = texture
	var darken_scale = float(depth - at_depth) / float(2.0 * depth)
	layer_sprite.modulate = layer_sprite.modulate.darkened(darken_scale * darkening)
	new_canvas_layer.add_child(layer_sprite)
	return new_canvas_layer

func _ready():
	modulate = modulate.darkened(darkening * 0.5)
	for i in range(-depth, 0):
		background_layers.push_back(_add_depth_layer(i))
	for i in range(depth):
		foreground_layers.push_back(_add_depth_layer(i + 1))

func _process(delta):
	for canvas_layer in foreground_layers:
		canvas_layer.offset = global_position
		var viewport_scale = canvas_layer.follow_viewport_scale
		canvas_layer.offset.y += y_skew * (viewport_scale - 1.0) / viewport_scale
	for canvas_layer in background_layers:
		canvas_layer.offset = global_position
		var viewport_scale = canvas_layer.follow_viewport_scale
		canvas_layer.offset.y += y_skew * (viewport_scale - 1.0) / viewport_scale
