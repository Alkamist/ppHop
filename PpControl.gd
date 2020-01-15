extends Node2D

onready var _camera := get_node("Smoothing2D/Camera2D")
onready var _body := get_node("Body")
onready var _sprite := get_node("Smoothing2D/Visuals/Jiggler/Sprite")
onready var _tween := get_node("Tween")
onready var _visuals := get_node("Smoothing2D/Visuals")
onready var _jiggler := get_node("Smoothing2D/Visuals/Jiggler")

var _time := 0.0
var _controlling_player := 0
var _jump_input_time := 0.0
var _should_jump := false
var _jump_direction := Vector2.ZERO

func initialize(starting_position):
	_body.position = starting_position
	if is_controlling_player():
		_camera.current = true

func set_controlling_player(id):
	_controlling_player = id
	_body.set_controlling_player(id)

func is_controlling_player():
	return get_tree().get_network_unique_id() == _controlling_player

func is_server():
	return get_tree().get_network_unique_id() == 1

func _jump(jump_direction):
	_jump_input_time = _time
	_should_jump = true
	_jump_direction = jump_direction
	#_body.jump(jump_direction)

func _process(delta):
	if is_controlling_player():
		var left = -1 if Input.is_action_pressed("left") else 0
		var right = 1 if Input.is_action_pressed("right") else 0
		_body.movement_direction = left + right
	
		if _body.movement_direction == -1 and _sprite.scale.x >= 0.0:
			rpc_unreliable("_set_sprite_facing_right", false)
		elif _body.movement_direction == 1 and _sprite.scale.x < 0.0:
			rpc_unreliable("_set_sprite_facing_right", true)
		
		if _should_jump:
			_body.jump(_jump_direction)
		
		if _time - _jump_input_time > 0.067:
			_should_jump = false
	
	_time += delta

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

remotesync func _play_networked_sound(sound_name):
	SFX.play(sound_name, _body)

remotesync func _land_visually():
	if not _body.should_crouch:
		_tween.interpolate_property(_visuals, "scale", Vector2(_visuals.scale.x, 1.0), Vector2(_visuals.scale.x, 0.9), 0.07, Tween.TRANS_SINE, Tween.EASE_OUT)
		_tween.interpolate_property(_visuals, "position", Vector2(_visuals.position.x, 0.0), Vector2(_visuals.position.x, 2.0), 0.07, Tween.TRANS_SINE, Tween.EASE_OUT)
		_tween.start()
		yield(_tween, "tween_completed")
		_tween.interpolate_property(_visuals, "scale", Vector2(_visuals.scale.x, 0.9), Vector2(_visuals.scale.x, 1.0), 0.07, Tween.TRANS_SINE, Tween.EASE_OUT)
		_tween.interpolate_property(_visuals, "position", Vector2(_visuals.position.x, 2.0), Vector2(_visuals.position.x, 0.0), 0.07, Tween.TRANS_SINE, Tween.EASE_OUT)
		_tween.start()

remotesync func _jump_visually():
	_tween.interpolate_property(_visuals, "scale", Vector2(_visuals.scale.x, 0.65), Vector2(_visuals.scale.x, 1.0), 0.4, Tween.TRANS_ELASTIC, Tween.EASE_OUT)
	_tween.interpolate_property(_visuals, "position", Vector2(_visuals.position.x, 6.0), Vector2(_visuals.position.x, 0.0), 0.4, Tween.TRANS_ELASTIC, Tween.EASE_OUT)
	_tween.start()

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

func _on_Body_just_landed():
	rpc_unreliable("_land_visually")

func _on_Body_just_jumped():
	_should_jump = false
	rpc_unreliable("_play_networked_sound", "PPJump")
	rpc_unreliable("_jump_visually")

func _on_Body_just_got_launched():
	_jiggler.jiggle(_body.velocity.length())

func _on_Body_just_bounced():
	var impact_speed = _body.velocity.length()
	if impact_speed > 200.0:
		rpc_unreliable("_play_networked_sound", "PPBounce")
		_jiggler.jiggle(impact_speed)
