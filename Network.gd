extends Node

export puppet var tick := -1

const DEFAULT_IP = "127.0.0.1"
const DEFAULT_PORT = 31400
const MAX_PLAYERS = 8

func _ready():
	get_tree().connect("network_peer_connected", self, "_on_player_connected")

func _on_player_connected(network_id):
	if is_network_master():
		rset_id(network_id, "tick", tick)

func host_server():
	var peer = NetworkedMultiplayerENet.new()
	peer.create_server(DEFAULT_PORT, MAX_PLAYERS)
	get_tree().set_network_peer(peer)

func join_server(ip_address):
	var peer = NetworkedMultiplayerENet.new()
	peer.create_client(ip_address, DEFAULT_PORT)
	get_tree().set_network_peer(peer)

func _physics_process(delta):
	tick += 1
