extends AudioStreamPlayer

export var fade_tween_path : NodePath
onready var fade_tween = get_node(fade_tween_path)

func _on_ChaseTrigger_body_entered(body):
	if body.is_in_group("ppBody"):
		fade_tween.stop_all()
		volume_db = 0.0
		play(0.0)

func _on_ChaseTrigger_body_exited(body):
	if body.is_in_group("ppBody"):
		if get_playback_position() < 3.0:
			fade_tween.interpolate_property(self, "volume_db", volume_db, -80.0, 2.0, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
			fade_tween.start()
