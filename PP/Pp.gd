extends Node2D

onready var body := get_node("Body")
	
func save_game():
	var save_data = {
		"node_name" : name,
		"x_position" : body.position.x,
		"y_position" : body.position.y,
		"x_velocity" : body.velocity.x,
		"y_velocity" : body.velocity.y,
	}
	return save_data

func load_game(node_data):
	body.position.x = node_data.x_position
	body.position.y = node_data.y_position
	body.velocity.x = node_data.x_velocity
	body.velocity.y = node_data.y_velocity
