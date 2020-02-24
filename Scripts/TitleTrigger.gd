extends Area2D

export var title : String

var first_time := true

func _ready():
	connect("body_entered", self, "_on_body_entered")

func _on_TitleInactiveTimer_timeout():
	monitoring = true

func _on_body_entered(body):
	if first_time and body.is_in_group("ppBody"):
		first_time = false
		BiomeTitleText.display_title(title)
