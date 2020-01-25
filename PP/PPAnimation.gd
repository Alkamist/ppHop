extends AnimationPlayer

onready var body := get_node("../Body")
onready var idle := get_node("../Smoothing2D/Visuals/Jiggler/SpriteFlip/Idle")
onready var scared := get_node("../Smoothing2D/Visuals/Jiggler/SpriteFlip/Scared")

func become_scared():
	scared.show()
	idle.hide()
	play("Scared")

func become_idle():
	scared.hide()
	idle.show()

func _process(delta):
	if body.velocity.y >= 1300.0:
		become_scared()
	else:
		become_idle()

func _on_Body_just_jumped():
	become_idle()
	play("Jump")
	yield(self, "animation_finished")
	if body.is_crouching:
		play("Crouch")

func _on_Body_just_crouched():
	become_idle()
	play("Crouch")

func _on_Body_just_uncrouched():
	become_idle()
	play("Uncrouch")
