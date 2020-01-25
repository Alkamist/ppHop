extends Light2D

onready var starting_energy := energy

func _on_ProximityAlphaFader_alpha_changed(value):
	energy = value * starting_energy
