extends AnimationPlayer

export var body_path : NodePath
export var idle_path : NodePath
export var scared_path : NodePath
onready var body := get_node(body_path)
onready var idle := get_node(idle_path)
onready var scared := get_node(scared_path)

var time := 0.0
var time_of_becoming_airborne := 0.0
var time_until_scared := 1.0
var scared_y_velocity := 400.0

func become_scared():
	scared.show()
	idle.hide()

func become_idle():
	scared.hide()
	idle.show()

func _process(delta):
	if not body.is_on_ground and (body.velocity.y >= scared_y_velocity or time - time_of_becoming_airborne > time_until_scared):
		become_scared()
	time += delta

func _on_Body_just_landed():
	become_idle()

func _on_Body_just_became_airborne():
	time_of_becoming_airborne = time
