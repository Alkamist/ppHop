extends Node2D

export var speed := 50.0
export var dampening := 3.0

var _jiggle_amplitude := 0.0
var _jiggle_phase := 0.0

const TWOPI := PI * 2.0

func jiggle(intensity):
	rpc("_jiggle", intensity)

remotesync func _jiggle(intensity):
	_jiggle_amplitude = intensity * 0.00025
	_jiggle_phase = 0.0

func _process(delta):
	var jiggle_scale = clamp(1.0 - sin(_jiggle_phase) * _jiggle_amplitude, 0.93, 1.07)
	if abs(1.0 - jiggle_scale) < 0.01:
		jiggle_scale = 1.0
	scale.x = jiggle_scale
	scale.y = jiggle_scale
	position.y = pow(12.0 * (1.0 - jiggle_scale), 2.0)
	_jiggle_amplitude -= dampening * _jiggle_amplitude * delta
	_jiggle_amplitude = max(_jiggle_amplitude, 0.0)
	_jiggle_phase += speed * delta
	if _jiggle_phase >= TWOPI:
		_jiggle_phase -= TWOPI
