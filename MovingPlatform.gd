extends Mover

var _time := 0.0

func _physics_process(delta):
	#velocity.x += 2.0 * sin(_time)
	#_time += delta
	_handle_movement(delta)
