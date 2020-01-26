extends Node2D

onready var tween := get_node("Tween")
onready var path_follow := get_node("Path2D/PathFollow2D")
onready var sprite := get_node("Path2D/PathFollow2D/Sprite")

onready var previous_position = path_follow.position
var is_chasing := false
var is_attacking := false
var attack_speed := 4000.0
var attack_target

func _launch_target(launch_speed, launch_x_direction):
	attack_target.launch(Vector2(launch_x_direction * launch_speed, 0.0))
	is_chasing = false
	is_attacking = false
	attack_target = null

func _process(delta):
	if attack_target:
		var vector_to_target = attack_target.global_position - path_follow.global_position
		var direction_to_target = vector_to_target.normalized()
		var maximum_move = attack_speed * delta * direction_to_target
		if vector_to_target.length() < maximum_move.length():
			path_follow.global_position += vector_to_target
		else:
			path_follow.global_position += maximum_move
		if path_follow.global_position.distance_to(attack_target.global_position) < 50.0:
			_launch_target(1600.0, direction_to_target.x)
	sprite.flip_h = path_follow.position < previous_position
	previous_position = path_follow.position

func _on_ChaseTrigger_body_entered(body):
	if body.is_in_group("ppBody") and not is_chasing and not is_attacking:
		is_chasing = true
		tween.interpolate_property(path_follow, "unit_offset", 0.0, 1.0, 3.4, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
		tween.start()
		yield(tween, "tween_completed")
		is_chasing = false

func _on_AttackTrigger_body_entered(body):
	if body.is_in_group("ppBody") and is_chasing:
		is_attacking = true
		is_chasing = false
		tween.stop_all()
		attack_target = body
