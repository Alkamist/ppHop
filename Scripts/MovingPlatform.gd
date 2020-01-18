extends Node2D

export var duration := 5.0
onready var animation := get_node("AnimationPlayer")
onready var path := get_node("Path2D")
onready var path_follow := get_node("Path2D/PathFollow2D")

func _physics_process(delta):
	if is_network_master():
		rpc_unreliable("_sync_clients", animation.current_animation_position)

func _ready():
	if duration > 0.0:
		var playback_speed = 1.0 / duration
		animation.play("Move", -1.0, playback_speed)

remote func _sync_clients(at_time):
	animation.seek(at_time)
