extends Node

func _ready():
	get_tree().connect("network_peer_connected", self, "_on_player_connected")
	get_tree().connect("network_peer_disconnected", self, "_on_player_disconnected")
	get_tree().connect("server_disconnected", self, "_on_server_disconnected")
	
	var new_player = _spawn_player(get_tree().get_network_unique_id())
	new_player.get_node("Smoothing2D/Camera2D").current = true

func _on_player_connected(network_id):
	_spawn_player(network_id)
	
func _on_player_disconnected(network_id):
	get_node(str(network_id)).queue_free()
	
func _on_server_disconnected():
	get_tree().change_scene("res://interface/Menu.tscn")

func _spawn_player(network_id):
	var new_player = load("res://Pp.tscn").instance()
	new_player.name = str(network_id)
	add_child(new_player)
	new_player.set_controlling_player(network_id)
	return new_player
