extends RichTextLabel

onready var fade_tween := get_node("FadeTween")
onready var clear_timer := get_node("ClearTimer")
onready var cooldown_timer := get_node("CooldownTimer")

func _ready():
	clear()
	clear_timer.connect("timeout", self, "_on_clear_text")

func say_phrase(phrase: String, fade_time: float):
	parse_bbcode("[center]" + phrase + "[/center]")
	fade_tween.stop_all()
	fade_tween.interpolate_property(self, "modulate:a", 0.0, 1.0, fade_time, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	fade_tween.start()
	cooldown_timer.start()
	clear_timer.start()

func _on_clear_text():
	fade_tween.stop_all()
	fade_tween.interpolate_property(self, "modulate:a", 1.0, 0.0, 1.0, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	fade_tween.start()
