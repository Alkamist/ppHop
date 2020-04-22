extends AudioStreamPlayer

onready var tween := get_node("Tween")

var starting_volume := volume_db
var is_fading_in := false
var is_fading_out := false

func _ready():
	tween.connect("tween_completed", self, "_on_fade_completed")
	volume_db = -60

func fade_in(fade_time):
	is_fading_in = true
	is_fading_out = false
	tween.stop_all()
	tween.interpolate_property(self, "volume_db", -60, starting_volume, fade_time, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	tween.start()
	if not playing:
		play()

func fade_out(fade_time):
	is_fading_in = false
	is_fading_out = true
	tween.stop_all()
	tween.interpolate_property(self, "volume_db", volume_db, -60, fade_time, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	tween.start()

func _on_fade_completed(object: Object, key: NodePath):
	if playing and is_fading_out:
		stop()
	is_fading_in = false
	is_fading_out = false
