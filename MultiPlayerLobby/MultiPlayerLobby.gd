extends Control

func _ready():
	if OS.get_name() == "HTML5":
		$VBoxContainer/Host.hide()

func _on_Join_pressed():
	Network.join_websocket($VBoxContainer/IP.text)
	get_tree().change_scene("res://Scenes/Game.tscn")

func _on_Host_pressed():
	Network.host_websocket()
	get_tree().change_scene("res://Scenes/Game.tscn")

func _on_Cancel_pressed():
	get_tree().change_scene("res://MainMenu/MainMenu.tscn")
