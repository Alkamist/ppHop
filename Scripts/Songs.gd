extends Node2D

var previous_song = null

func play(song_name = null):
	if song_name:
		if previous_song:
			previous_song.fade_out()
		var new_song = get_node(song_name)
		previous_song = new_song
		new_song.fade_in()
