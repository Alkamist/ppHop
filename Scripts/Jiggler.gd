extends Node2D

var speed := 50.0
var dampening := 3.0
var amplitude := 0.0
var phase := 0.0

const TWOPI := PI * 2.0

func jiggle(intensity):
	rpc("_jiggle", intensity)

remotesync func _jiggle(intensity):
	amplitude = intensity * 0.00025
	phase = 0.0

func _process(delta):
	var jiggle_scale = clamp(1.0 - sin(phase) * amplitude, 0.93, 1.07)
	if abs(1.0 - jiggle_scale) < 0.01:
		jiggle_scale = 1.0
	scale.x = jiggle_scale
	scale.y = jiggle_scale
	position.y = pow(12.0 * (1.0 - jiggle_scale), 2.0)
	amplitude -= dampening * amplitude * delta
	amplitude = max(amplitude, 0.0)
	phase += speed * delta
	if phase >= TWOPI:
		phase -= TWOPI
