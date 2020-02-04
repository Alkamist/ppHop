extends Node2D

export var phase := 0.0
export var chomp_vector := Vector2(0.0, -140.0)
export var chomp_time := 1.0

onready var tween := get_node("Tween")
onready var body := get_node("Body")

var cycle_time := 0.0

func _ready():
	cycle_time += chomp_time * phase

func _chomp():
	tween.interpolate_property(body, "position", Vector2.ZERO, chomp_vector, 0.3 * chomp_time, Tween.TRANS_BOUNCE, Tween.EASE_OUT)
	tween.start()
	yield(tween, "tween_completed")
	tween.interpolate_property(body, "position", body.position, Vector2.ZERO, 0.1 * chomp_time, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	tween.start()

func _process(delta):
	if cycle_time > chomp_time:
		_chomp()
		cycle_time -= chomp_time
	cycle_time += delta
