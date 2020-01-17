extends Node

const DEFAULT_PORT := 31400
const MAXIMUM_PLAYERS := 8
var client
var server

func _check_ip(ip):
	if ip == "localhost" or not ip.is_valid_ip_address():
		return "127.0.0.1"
	return ip

func join_websocket(ip):
	client = WebSocketClient.new()
	var url = "ws://" + _check_ip(ip) + ":" + str(DEFAULT_PORT)
	var error = client.connect_to_url(url, PoolStringArray(), true)
	get_tree().set_network_peer(client)

func host_websocket():
	server = WebSocketServer.new()
	server.listen(DEFAULT_PORT, PoolStringArray(), true)
	get_tree().set_network_peer(server)

#func join_ENet(ip):
#	var peer = NetworkedMultiplayerENet.new()
#	peer.create_client(_check_ip(ip), DEFAULT_PORT)
#	get_tree().set_network_peer(peer)

#func host_ENet():
#	var peer = NetworkedMultiplayerENet.new()
#	peer.create_server(DEFAULT_PORT, MAXIMUM_PLAYERS)
#	get_tree().set_network_peer(peer)

func _process(_delta):
	if server and server.is_listening():
		server.poll()
	
	elif client and (client.get_connection_status() == NetworkedMultiplayerPeer.CONNECTION_CONNECTED 
				  || client.get_connection_status() == NetworkedMultiplayerPeer.CONNECTION_CONNECTING):
		client.poll()
