extends Node2D

func post_import(scene):
	if scene.has_meta("normalmap"):
		var normal_map = load(scene.get_meta("normalmap"))
		for child in scene.get_children():
			var tile_set = child.tile_set
			for tile_id in tile_set.get_tiles_ids():
				tile_set.tile_set_normal_map(tile_id, normal_map)
	return scene
