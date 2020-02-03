extends Node2D

func _ready():
	hide()

func _on_VisibilityEnabler2D_screen_entered():
	show()

func _on_VisibilityEnabler2D_screen_exited():
	hide()
