extends Node2D

var time := 0.0
var controlling_player := -1
var jump_input_time := 0.0
var should_jump := false
var jump_direction := Vector2.ZERO
onready var smoothing := get_node("Smoothing2D")
onready var camera := get_node("Smoothing2D/Camera2D")
onready var body := get_node("Body")
onready var sprite := get_node("Smoothing2D/Visuals/Jiggler/Sprite")
onready var tween := get_node("Tween")
onready var visuals := get_node("Smoothing2D/Visuals")
onready var jiggler := get_node("Smoothing2D/Visuals/Jiggler")

func initialize(starting_position):
	body.position = starting_position
	if is_controlling_player():
		camera.current = true

func set_controlling_player(id):
	controlling_player = id
	body.set_controlling_player(id)

func is_controlling_player():
	return get_tree().get_network_unique_id() == controlling_player

func _jump(direction):
	rpc_unreliable("_set_sprite_facing_right", direction.x >= 0.0)
	jump_input_time = time
	should_jump = true
	jump_direction = direction

func _process(delta):
	if is_controlling_player():
		var left = -1 if Input.is_action_pressed("left") else 0
		var right = 1 if Input.is_action_pressed("right") else 0
		body.movement_direction = left + right
	
		if body.movement_direction == -1 and sprite.scale.x >= 0.0:
			rpc_unreliable("_set_sprite_facing_right", false)
		elif body.movement_direction == 1 and sprite.scale.x < 0.0:
			rpc_unreliable("_set_sprite_facing_right", true)
	
		if should_jump:
			body.jump(jump_direction)
	
		if time - jump_input_time > 0.067:
			should_jump = false
	
	update()
	
	time += delta

func _draw():
	if is_controlling_player() and body.is_on_ground and not Input.is_action_pressed("jump"):
		var direction = get_global_mouse_position() - body.global_position
		var jump_vector = direction / 300.0
		jump_vector = jump_vector.clamped(1.0)
		var length = jump_vector.length()
		if length > 0.0:
			jump_vector.y = min(jump_vector.y, -0.20)
			jump_vector *= 300.0
		jump_vector.x += body.velocity.x / 3.0
		var end_position = smoothing.position + jump_vector - jump_vector.normalized() * 8.0
		draw_line(smoothing.position, end_position, Color(0.6, 0.1, 0), 6)

func _unhandled_input(event):
	if not is_controlling_player():
		return
	if event.is_action_pressed("jump"):
		_jump(get_global_mouse_position() - body.global_position)
	elif event.is_action_pressed("down"):
		body.should_crouch = true
	elif event.is_action_released("down"):
		body.should_crouch = false

remotesync func _set_sprite_facing_right(value):
	if value:
		if sprite.scale.x < 0.0:
			sprite.scale.x *= -1.0
	else:
		if sprite.scale.x >= 0.0:
			sprite.scale.x *= -1.0

remotesync func _play_networked_sound(sound_name):
	SFX.play(sound_name, body)

remotesync func _land_visually():
	if not body.should_crouch:
		tween.interpolate_property(visuals, "scale", Vector2(visuals.scale.x, 1.0), Vector2(visuals.scale.x, 0.9), 0.07, Tween.TRANS_SINE, Tween.EASE_OUT)
		tween.interpolate_property(visuals, "position", Vector2(visuals.position.x, 0.0), Vector2(visuals.position.x, 2.0), 0.07, Tween.TRANS_SINE, Tween.EASE_OUT)
		tween.start()
		yield(tween, "tween_completed")
		tween.interpolate_property(visuals, "scale", Vector2(visuals.scale.x, 0.9), Vector2(visuals.scale.x, 1.0), 0.07, Tween.TRANS_SINE, Tween.EASE_OUT)
		tween.interpolate_property(visuals, "position", Vector2(visuals.position.x, 2.0), Vector2(visuals.position.x, 0.0), 0.07, Tween.TRANS_SINE, Tween.EASE_OUT)
		tween.start()

remotesync func _jump_visually():
	tween.interpolate_property(visuals, "scale", Vector2(visuals.scale.x, 0.65), Vector2(visuals.scale.x, 1.0), 0.4, Tween.TRANS_ELASTIC, Tween.EASE_OUT)
	tween.interpolate_property(visuals, "position", Vector2(visuals.position.x, 6.0), Vector2(visuals.position.x, 0.0), 0.4, Tween.TRANS_ELASTIC, Tween.EASE_OUT)
	tween.start()

remotesync func _crouch_visually():
	tween.interpolate_property(visuals, "scale", Vector2(visuals.scale.x, 1.0), Vector2(visuals.scale.x, 0.65), 0.2, Tween.TRANS_ELASTIC, Tween.EASE_OUT)
	tween.interpolate_property(visuals, "position", Vector2(visuals.position.x, 0.0), Vector2(visuals.position.x, 6.0), 0.2, Tween.TRANS_ELASTIC, Tween.EASE_OUT)
	tween.start()

remotesync func _uncrouch_visually():
	tween.interpolate_property(visuals, "scale", Vector2(visuals.scale.x, 0.65), Vector2(visuals.scale.x, 1.0), 0.2, Tween.TRANS_ELASTIC, Tween.EASE_OUT)
	tween.interpolate_property(visuals, "position", Vector2(visuals.position.x, 6.0), Vector2(visuals.position.x, 0.0), 0.2, Tween.TRANS_ELASTIC, Tween.EASE_OUT)
	tween.start()

func _on_Body_just_crouched():
	rpc("_crouch_visually")

func _on_Body_just_uncrouched():
	rpc("_uncrouch_visually")

func _on_Body_just_landed():
	rpc_unreliable("_land_visually")

func _on_Body_just_jumped():
	should_jump = false
	rpc_unreliable("_play_networked_sound", "PPJump")
	rpc_unreliable("_jump_visually")

func _on_Body_just_got_launched():
	jiggler.jiggle(body.velocity.length())

func _on_Body_just_bounced():
	var impact_speed = body.velocity.length()
	if impact_speed > 200.0:
		rpc_unreliable("_play_networked_sound", "PPBounce")
		jiggler.jiggle(impact_speed)
