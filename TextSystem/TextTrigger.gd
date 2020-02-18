extends Area2D

export var should_interrupt := false
export var fade_in_time := 1.0

export var label_path : NodePath
onready var label := get_node(label_path)

export var phrases := []

var current_phrase_number := -1

func _ready():
	connect("body_entered", self, "_on_body_entered")

func _on_body_entered(body: Node):
	if body.is_in_group("ppBody") and (label.cooldown_timer.is_stopped() or should_interrupt):
		current_phrase_number += 1
		if current_phrase_number >= phrases.size():
			current_phrase_number = 0
		label.say_phrase(phrases[current_phrase_number], fade_in_time)
