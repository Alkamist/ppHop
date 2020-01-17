extends Node2D

func play(sound_name = null, bind_to = null):
	if sound_name:
		var sound = get_node(sound_name).duplicate(DUPLICATE_USE_INSTANCING)
		if bind_to:
			bind_to.add_child(sound)
		else:
			get_parent().add_child(sound)
		sound.play()
		yield(sound, "finished")
		sound.queue_free()
