extends Control

onready var eNetButton := get_node("VBoxContainer/ENet")

func _ready():
	if OS.get_name() == "HTML5":
		$VBoxContainer/Host.hide()
		eNetButton.hide()

func _on_Join_pressed():
	if eNetButton.pressed:
		Network.join_ENet($VBoxContainer/IP.text)
	else:
		Network.join_websocket($VBoxContainer/IP.text)
	get_tree().change_scene("res://Scenes/Game.tscn")

func _on_Host_pressed():
	if eNetButton.pressed:
		Network.host_ENet()
	else:
		Network.host_websocket()
	get_tree().change_scene("res://Scenes/Game.tscn")

func _on_Cancel_pressed():
	get_tree().change_scene("res://MainMenu/MainMenu.tscn")
