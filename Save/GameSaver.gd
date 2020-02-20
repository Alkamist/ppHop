extends Node

var save_enabled := false

func save_game():
	var save_game = File.new()
	save_game.open("user://savegame.save", File.WRITE)
	var save_nodes = get_tree().get_nodes_in_group("save")
	for node in save_nodes:
		if node.has_method("save_game"):
			var node_data = node.call("save_game")
			save_game.store_line(to_json(node_data))
	save_game.close()

func load_game():
	var save_game = File.new()
	if not save_game.file_exists("user://savegame.save"):
		return
	var save_nodes = get_tree().get_nodes_in_group("save")
	save_game.open("user://savegame.save", File.READ)
	while save_game.get_position() < save_game.get_len():
		var node_data = parse_json(save_game.get_line())
		for save_node in save_nodes:
			if save_node.name == node_data.node_name:
				if save_node.has_method("load_game"):
					save_node.call("load_game", node_data)
	save_game.close()

func _physics_process(delta):
	if save_enabled:
		save_game()
