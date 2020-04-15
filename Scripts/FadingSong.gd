extends AudioStreamPlayer

onready var tween := get_node("Tween")

var starting_volume := volume_db

func _ready():
	tween.connect("tween_completed", self, "_on_fade_out")
	volume_db = -80

func fade_in():
	tween.stop_all()
	volume_db = starting_volume
	if not playing:
		play()

func fade_out():
	tween.stop_all()
	tween.interpolate_property(self, "volume_db", volume_db, -80, 1.0, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	tween.start()

func _on_fade_out(object: Object, key: NodePath):
	if playing:
		stop()
