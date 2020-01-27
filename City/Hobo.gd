extends Node2D

onready var tween := get_node("Tween")
onready var path_follow := get_node("Path2D/PathFollow2D")
onready var path := get_node("Path2D")
onready var sprite := get_node("Path2D/PathFollow2D/Sprite")
onready var attack_trigger := get_node("AttackTrigger")

onready var previous_position = path_follow.position
var movement_speed := 490.0
var time := 0.0
var attack_cooldown := 1.0
var time_of_attack := 0.0
var is_chasing := false
var attack_speed := 4000.0
var attack_target
var attack_starting_point := Vector2.ZERO

func _launch_target(launch_speed, launch_x_direction):
	attack_target.launch(Vector2(launch_x_direction * launch_speed, 600.0))
	is_chasing = false
	time_of_attack = time

func _process(delta):
	if attack_target and time - time_of_attack > attack_cooldown:
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
	time += delta

func _on_ChaseTrigger_body_entered(body):
	if body.is_in_group("ppBody") and not is_chasing and not attack_target:
		is_chasing = true
		for body_in_trigger in attack_trigger.get_overlapping_bodies():
			if body_in_trigger.is_in_group("ppBody"):
				_on_AttackTrigger_body_entered(body_in_trigger)
				return
		tween.stop_all()
		var rate = (1.0 - path_follow.unit_offset) * path.curve.get_baked_length() / movement_speed
		if rate > 0.0:
			tween.interpolate_property(path_follow, "unit_offset", path_follow.unit_offset, 1.0, rate, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
			tween.start()
			yield(tween, "tween_completed")
		is_chasing = false

func _on_AttackTrigger_body_entered(body):
	if body.is_in_group("ppBody") and is_chasing:
		tween.stop_all()
		attack_starting_point = path_follow.global_position
		is_chasing = false
		attack_target = body

func _on_ChaseTrigger_body_exited(body):
	if body.is_in_group("ppBody"):
		is_chasing = false
		tween.stop_all()
		var rate = 0.1
		if attack_target:
			rate = path_follow.global_position.distance_to(attack_starting_point) / movement_speed
			if rate > 0.0:
				tween.interpolate_property(path_follow, "global_position", path_follow.global_position, attack_starting_point, rate, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
				tween.start()
				yield(tween, "tween_completed")
		attack_target = null
		rate = path.curve.get_baked_length() * path_follow.unit_offset / movement_speed
		if rate > 0.0:
			tween.interpolate_property(path_follow, "unit_offset", path_follow.unit_offset, 0.0, rate, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
			tween.start()
