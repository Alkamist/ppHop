extends Node2D

export var controlling_player := 0

onready var _camera := get_node("Smoothing2D/Camera2D")
onready var _body := get_node("Body")
onready var _sprite := get_node("Smoothing2D/Visuals/Jiggler/Sprite")
onready var _tween := get_node("Tween")
onready var _visuals := get_node("Smoothing2D/Visuals")

func initialize(starting_position):
	_body.position = starting_position
	#if is_controlling_player():
		#_camera.current = true

func is_controlling_player():
	return get_tree().get_network_unique_id() == controlling_player

func is_server():
	return get_tree().get_network_unique_id() == 1

func _jump(jump_direction):
	var jump_vector = jump_direction / 300.0
	jump_vector = jump_vector.clamped(1.0)
	var length = jump_vector.length()
	if length > 0.0:
		jump_vector *= 1.0 / pow(length, 0.5)
		jump_vector.y = min(jump_vector.y, -0.20)
		jump_vector *= 300.0
	_body.jump(Vector2(jump_vector.x * 3.0, jump_vector.y * 3.0))

func _process(delta):
	if is_controlling_player():
		var left = -1 if Input.is_action_pressed("left") else 0
		var right = 1 if Input.is_action_pressed("right") else 0
		_body.movement_direction = left + right
	
		if _body.movement_direction == -1 and _sprite.scale.x >= 0.0:
			rpc_unreliable("_set_sprite_facing_right", false)
		elif _body.movement_direction == 1 and _sprite.scale.x < 0.0:
			rpc_unreliable("_set_sprite_facing_right", true)

func _unhandled_input(event):
	if not is_controlling_player():
		return
	if event.is_action_pressed("jump"):
		var jump_direction = get_global_mouse_position() - _body.global_position
		rpc_unreliable("_set_sprite_facing_right", jump_direction.x >= 0.0)
		_jump(get_global_mouse_position() - _body.global_position)
	elif event.is_action_pressed("down"):
		_body.should_crouch = true
	elif event.is_action_released("down"):
		_body.should_crouch = false

remotesync func _set_sprite_facing_right(value):
	if value:
		if _sprite.scale.x < 0.0:
			_sprite.scale.x *= -1.0
	else:
		if _sprite.scale.x >= 0.0:
			_sprite.scale.x *= -1.0

remotesync func _crouch_visually():
	_tween.interpolate_property(_visuals, "scale", Vector2(_visuals.scale.x, 1.0), Vector2(_visuals.scale.x, 0.65), 0.2, Tween.TRANS_ELASTIC, Tween.EASE_OUT)
	_tween.interpolate_property(_visuals, "position", Vector2(_visuals.position.x, 0.0), Vector2(_visuals.position.x, 6.0), 0.2, Tween.TRANS_ELASTIC, Tween.EASE_OUT)
	_tween.start()

remotesync func _uncrouch_visually():
	_tween.interpolate_property(_visuals, "scale", Vector2(_visuals.scale.x, 0.65), Vector2(_visuals.scale.x, 1.0), 0.2, Tween.TRANS_ELASTIC, Tween.EASE_OUT)
	_tween.interpolate_property(_visuals, "position", Vector2(_visuals.position.x, 6.0), Vector2(_visuals.position.x, 0.0), 0.2, Tween.TRANS_ELASTIC, Tween.EASE_OUT)
	_tween.start()

func _on_Body_just_crouched():
	rpc("_crouch_visually")

func _on_Body_just_uncrouched():
	rpc("_uncrouch_visually")
