extends Area2D

var space_modifier := 0.34
var applied_space_modifier := false

func _ready():
	connect("body_entered", self, "_on_body_entered")
	connect("body_exited", self, "_on_body_exited")

func _on_body_entered(body):
	if body.is_in_group("ppBody") and not applied_space_modifier:
		applied_space_modifier = true
		body.jump_power *= space_modifier * 2.3
		body.gravity *= space_modifier
		body.maximum_fall_speed *= space_modifier
		body.air_drift_control *= space_modifier * 1.0

func _on_body_exited(body):
	if body.is_in_group("ppBody") and applied_space_modifier:
		applied_space_modifier = false
		body.jump_power /= space_modifier * 2.3
		body.gravity /= space_modifier
		body.maximum_fall_speed /= space_modifier
		body.air_drift_control /= space_modifier * 1.0
