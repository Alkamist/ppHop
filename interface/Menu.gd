extends Control

var _player_name = ""
var _host_ip_address = "127.0.0.1"

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
	Network.join_server(_host_ip_address)
	_load_game()

func _on_CreateButton_button_down():
	Network.host_server()
	_load_game()
