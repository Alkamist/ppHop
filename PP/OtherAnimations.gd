extends AnimationPlayer

onready var body := get_node("../Body")

func _on_Body_just_jumped():
	play("Jump")
	yield(self, "animation_finished")
	if body.is_crouching:
		play("Crouch")

func _on_Body_just_crouched():
	play("Crouch")

func _on_Body_just_uncrouched():
	play("Uncrouch")
