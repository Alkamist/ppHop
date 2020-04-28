extends Node2D

var time := 0.0

var pause_position := 0
var previous_song = null
var current_song = null
var is_paused := false

func _process(delta):
	time += delta
	if time > 1.0 and not is_paused and current_song and not current_song.playing:
		if previous_song:
			previous_song.stop()
		current_song.play()
		previous_song = current_song

func play(song_name = null):
	if song_name:
		current_song = get_node(song_name)

func pause():
	is_paused = true
	pause_position = current_song.get_playback_position()
	current_song.stop()

func resume():
	is_paused = false
	current_song.play()
	current_song.seek(pause_position)
