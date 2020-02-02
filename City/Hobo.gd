extends Node2D

var launch_x_speed := 800.0
var launch_y_speed := 200.0
var movement_speed := 195.0
var attack_cooldown := 1.0
var attack_speed := 1000.0

onready var tween := get_node("Tween")
onready var path_follow := get_node("Path2D/PathFollow2D")
onready var path := get_node("Path2D")
onready var sprite := get_node("Path2D/PathFollow2D/Sprite")
onready var attack_trigger := get_node("AttackTrigger")
onready var chase_trigger := get_node("ChaseTrigger")
onready var previous_position = path_follow.position

var time := 0.0
var time_of_attack := 0.0
var attack_target
var attack_starting_point := Vector2.ZERO

func _attack_target_if_possible(delta):
	if attack_target and time - time_of_attack > attack_cooldown:
		if not chase_trigger.overlaps_body(attack_target):
			attack_target = null
			_go_back_to_start()
			return
		var vector_to_target = attack_target.global_position - path_follow.global_position
		var direction_to_target = vector_to_target.normalized()
		var maximum_move = attack_speed * delta * direction_to_target
		if vector_to_target.length() < maximum_move.length():
			path_follow.global_position += vector_to_target
		else:
			path_follow.global_position += maximum_move
		if path_follow.global_position.distance_to(attack_target.global_position) < 20.0:
			attack_target.launch(Vector2(direction_to_target.x * launch_x_speed, launch_y_speed))
			time_of_attack = time

func _process(delta):
	_attack_target_if_possible(delta)
	sprite.flip_h = path_follow.position < previous_position
	previous_position = path_follow.position
	time += delta

func _follow_the_path():
	tween.stop_all()
	var rate = (1.0 - path_follow.unit_offset) * path.curve.get_baked_length() / movement_speed
	if rate > 0.0:
		tween.interpolate_property(path_follow, "unit_offset", path_follow.unit_offset, 1.0, rate, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
		tween.start()

func _go_back_to_start():
	tween.stop_all()
	var rate = path.curve.get_baked_length() * path_follow.unit_offset / movement_speed
	if rate > 0.0:
		tween.interpolate_property(path_follow, "unit_offset", path_follow.unit_offset, 0.0, rate, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
		tween.start()

func _go_back_to_where_attack_started():
	tween.stop_all()
	var rate = path_follow.global_position.distance_to(attack_starting_point) / movement_speed
	if rate > 0.0:
		tween.interpolate_property(path_follow, "global_position", path_follow.global_position, attack_starting_point, rate, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
		tween.start()

func _get_pp_in_attack_range():
	for body_in_trigger in attack_trigger.get_overlapping_bodies():
		if body_in_trigger.is_in_group("ppBody"):
			return body_in_trigger

func _on_ChaseTrigger_body_entered(body):
	if body.is_in_group("ppBody"):
		var pp_in_range = _get_pp_in_attack_range()
		if pp_in_range:
			_on_AttackTrigger_body_entered(pp_in_range)
		else:
			_follow_the_path()

func _on_ChaseTrigger_body_exited(body):
	if body.is_in_group("ppBody"):
		if attack_target:
			_go_back_to_where_attack_started()
			yield(tween, "tween_completed")
		_go_back_to_start()
		attack_target = null

func _on_AttackTrigger_body_entered(body):
	if body.is_in_group("ppBody") and chase_trigger.overlaps_body(body):
		tween.stop_all()
		attack_starting_point = path_follow.global_position
		attack_target = body
