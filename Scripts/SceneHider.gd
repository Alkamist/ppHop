extends Node2D

onready var visibility_enabler := get_node("VisibilityEnabler2D")

func _ready():
	hide()
	visibility_enabler.connect("screen_entered", self, "on_screen_entered")
	visibility_enabler.connect("screen_exited", self, "on_screen_exited")

func on_screen_entered():
	show()

func on_screen_exited():
	hide()
