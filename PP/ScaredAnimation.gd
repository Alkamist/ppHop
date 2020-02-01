extends AnimationPlayer

onready var body := get_node("../Body")
onready var idle := get_node("../Smoothing2D/Visuals/Jiggler/SpriteFlip/Idle")
onready var scared := get_node("../Smoothing2D/Visuals/Jiggler/SpriteFlip/Scared")

func become_scared():
	scared.show()
	idle.hide()

func become_idle():
	scared.hide()
	idle.show()

func _process(delta):
	if body.velocity.y >= 400.0:
		become_scared()
	else:
		become_idle()
