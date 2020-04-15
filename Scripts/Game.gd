extends Node

var pp := load("res://PP/Pp.tscn")

func _ready():
	var new_player = pp.instance()
	var pp_body = new_player.get_node("Body")
	add_child(new_player)
	pp_body.position = get_node("Spawn").position
	GameSaver.load_game()
	GameSaver.save_enabled = true
