extends Control

func _on_SinglePlayer_pressed():
	get_tree().change_scene("res://Scenes/Game.tscn")

func _on_Exit_pressed():
	get_tree().quit()
