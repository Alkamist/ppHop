extends Control

func _on_SinglePlayer_pressed():
	var peer = NetworkedMultiplayerENet.new()
	peer.create_server(31400, 1)
	get_tree().set_network_peer(peer)
	get_tree().change_scene("res://Scenes/Game.tscn")

func _on_MultiPlayer_pressed():
	get_tree().change_scene("res://MultiPlayerLobby/MultiPlayerLobby.tscn")
