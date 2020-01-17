extends Node

var pp := load("res://Scenes/Pp.tscn")

func _ready():
	get_tree().connect("network_peer_connected", self, "_on_player_connected")
	get_tree().connect("network_peer_disconnected", self, "_on_player_disconnected")
	get_tree().connect("server_disconnected", self, "_on_server_disconnected")
	get_tree().connect("connected_to_server", self, "_on_connected_to_server")
	if get_tree().get_network_unique_id() == 1:
		_spawn_player(1)

func _on_connected_to_server():
	_spawn_player(get_tree().get_network_unique_id())

func _on_player_connected(network_id):
	_spawn_player(network_id)
	
func _on_player_disconnected(network_id):
	get_node(str(network_id)).queue_free()
	
func _on_server_disconnected():
	get_tree().change_scene("res://MainMenu/MainMenu.tscn")

func _spawn_player(player_id):
	var new_player = pp.instance()
	new_player.set_network_master(player_id, true)
	new_player.name = str(player_id)
	add_child(new_player)
	new_player.set_controlling_player(player_id)
	new_player.initialize(get_node("Spawn").position)
	return new_player
