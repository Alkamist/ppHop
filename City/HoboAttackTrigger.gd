extends Area2D

export var label_path : NodePath
onready var label := get_node(label_path)
export var normal_trigger_path : NodePath
onready var normal_trigger := get_node(normal_trigger_path)

export var phrases := []

func _ready():
	connect("body_entered", self, "_on_body_entered")

func _on_body_entered(body: Node):
	if body.is_in_group("ppBody"):
		if normal_trigger.current_phrase_number != 1:
			label.say_phrase(phrases[0], 0.0)
		else:
			label.say_phrase(phrases[1], 0.0)
