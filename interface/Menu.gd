extends Control

var _player_name = ""
var _host_ip_address = "127.0.0.1"

const DEFAULT_IP = "127.0.0.1"
const DEFAULT_PORT = 31400
const MAX_PLAYERS = 8

func _load_game():
	get_tree().change_scene("res://Game.tscn")

func _on_NameField_text_changed(new_text):
	_player_name = new_text

func _on_IPField_text_changed(new_text):
	_host_ip_address = new_text

func _on_JoinButton_button_down():
	if _host_ip_address == "localhost":
		_host_ip_address = "127.0.0.1"
	if not _host_ip_address.is_valid_ip_address():
		return
	var peer = NetworkedMultiplayerENet.new()
	peer.create_client(_host_ip_address, DEFAULT_PORT)
	get_tree().set_network_peer(peer)
	_load_game()

func _on_CreateButton_button_down():
	var peer = NetworkedMultiplayerENet.new()
	peer.create_server(DEFAULT_PORT, MAX_PLAYERS)
	get_tree().set_network_peer(peer)
	_load_game()
