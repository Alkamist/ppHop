extends Node

var pp := load("res://PP/Pp.tscn")

func _ready():
	var new_player = pp.instance()
	add_child(new_player)
	new_player.get_node("Body").position = get_node("Spawn").position
	GameSaver.load_game()
	GameSaver.save_enabled = true
