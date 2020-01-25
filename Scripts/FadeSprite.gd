extends Node2D

onready var sprite := get_node("Sprite")
onready var proximity_fader := get_node("ProximityAlphaFader")

func _ready():
	proximity_fader.alpha = modulate.a

func _on_ProximityAlphaFader_alpha_changed(value):
	sprite.modulate.a = value
