extends Node2D

var pause_position := 0
var previous_song = null

func play(song_name = null):
	if song_name:
		if previous_song:
			previous_song.fade_out(2.0)
		var new_song = get_node(song_name)
		previous_song = new_song
		new_song.fade_in(0.0)

func pause():
	pause_position = previous_song.get_playback_position()
	previous_song.stop()

func resume():
	previous_song.fade_in(1.0)
	previous_song.seek(pause_position)
