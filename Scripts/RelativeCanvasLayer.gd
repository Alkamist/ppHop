extends CanvasLayer

func _ready():
	offset += get_parent().global_position
