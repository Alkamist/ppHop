extends AudioStreamPlayer

export var fade_tween_path : NodePath
onready var fade_tween = get_node(fade_tween_path)
var is_chasing := false
var starting_volume := volume_db

func _on_ChaseTrigger_body_entered(body):
	if body.is_in_group("ppBody") and not is_chasing:
		is_chasing = true
		fade_tween.stop_all()
		volume_db = starting_volume
		play(0.0)
		Songs.pause()

func _on_StopChaseTrigger_body_exited(body):
	if body.is_in_group("ppBody"):
		Songs.resume()
		is_chasing = false
		if get_playback_position() < 2.7:
			fade_tween.interpolate_property(self, "volume_db", volume_db, -80.0, 2.0, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
			fade_tween.start()
