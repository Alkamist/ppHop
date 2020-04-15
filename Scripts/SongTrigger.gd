extends Area2D

export var song_name : String

func _ready():
	connect("body_entered", self, "_on_body_entered")

func _on_TitleInactiveTimer_timeout():
	monitoring = true

func _on_body_entered(body):
	if body.is_in_group("ppBody"):
		Songs.play(song_name)
