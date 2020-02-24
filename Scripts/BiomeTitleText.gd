extends CanvasLayer

export var fade_time := 1.0

onready var title := get_node("RichTextLabel")
onready var fade_tween := get_node("FadeTween")
onready var clear_timer := get_node("ClearTimer")

func _ready():
	title.modulate.a = 0.0
	clear_timer.connect("timeout", self, "_on_clear_text")

func _on_clear_text():
	fade_tween.stop_all()
	fade_tween.interpolate_property(self, "title:modulate:a", 1.0, 0.0, fade_time, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	fade_tween.start()

func hide_text():
	title.modulate.a = 0.0

func display_title(title_text):
	title.parse_bbcode("[center]" + title_text + "[/center]")
	fade_tween.stop_all()
	fade_tween.interpolate_property(self, "title:modulate:a", 0.0, 1.0, fade_time, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	fade_tween.start()
	clear_timer.start()
