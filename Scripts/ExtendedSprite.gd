extends Sprite

var dimension_size := 1500

func _ready():
	var boundary = get_rect()
	region_enabled = true
	region_rect = Rect2(0.5 * (boundary.size.x - dimension_size), 0.5 * (boundary.size.y - dimension_size), dimension_size, dimension_size)
