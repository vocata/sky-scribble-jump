extends Node2D

const GAME_WIDTH := 480.0
const GAME_HEIGHT := 720.0
const PLAYER_HALF_W := 24.0
const PLAYER_HALF_H := 28.0
const GRAVITY := 980.0
const AIR_CONTROL := 2300.0
const GROUND_AIR_BRAKE := 3600.0
const BASE_SPEED_X := 230.0
const SPEED_TILT_REF := 520.0
const HOLD_LOG_GROWTH := 14.0
const HOLD_LOG_BOOST := 185.0
const JUMP_SPEED := -590.0
const SPRING_SPEED := -1120.0
const SPRING_HIT_RADIUS := 38.0
const PLATFORM_SPRITE_WIDTH := 128.0
const PLATFORM_SPRITE_HEIGHT := 40.0
const PLAYER_BASE_SCALE := Vector2(0.92, 0.92)
const SPRING_BASE_SCALE := Vector2(0.58, 0.58)
const SPRING_VISUAL_HEIGHT := 31.9
const SPRING_SEAT_Y := 7.0
const SPRING_BASE_Y := -8.95
const SPRING_TOP_OFFSET := -25.0
const HUD_HEIGHT := 58.0

const PLAYER_TEXTURE := preload("res://assets/generated/sprites/player.png")
const PLATFORM_NORMAL_TEXTURE := preload("res://assets/generated/sprites/platform_normal.png")
const PLATFORM_MOVING_TEXTURE := preload("res://assets/generated/sprites/platform_moving.png")
const PLATFORM_FRAGILE_TEXTURE := preload("res://assets/generated/sprites/platform_fragile.png")
const SPRING_TEXTURE := preload("res://assets/generated/sprites/spring.png")
const SPARKLE_TEXTURE := preload("res://assets/generated/sprites/sparkle.png")
const GAME_OVER_TEXTURE := preload("res://assets/generated/sprites/game_over.png")
const GAME_OVER_PANEL_TEXTURE := preload("res://assets/generated/sprites/game_over_panel.png")
const RETRY_BUTTON_TEXTURE := preload("res://assets/generated/sprites/retry_button.png")

var rng := RandomNumberGenerator.new()
var world: Node2D
var camera: Camera2D
var player: Node2D
var player_pos := Vector2(GAME_WIDTH * 0.5, 610.0)
var player_velocity := Vector2.ZERO
var platforms: Array = []
var particles: Array = []
var highest_platform_y := 680.0
var camera_y := GAME_HEIGHT * 0.5
var start_y := 610.0
var max_height := 0.0
var score := 0
var best_score := 0
var game_over := false
var paused := false
var player_art: Sprite2D
var player_squash_time := 0.0
var move_hold_time := 0.0
var move_hold_dir := 0.0

var score_label: Label
var best_label: Label
var message_label: Label
var game_over_page: Control
var game_over_score_label: Label
var game_over_best_label: Label
var doodle_font: Font


func _ready() -> void:
	rng.randomize()
	_setup_view()
	_setup_background()
	_setup_world()
	_setup_ui()
	reset_game()


func _physics_process(delta: float) -> void:
	if paused:
		return

	if game_over:
		_update_particles(delta)
		return

	var old_y: float = player_pos.y
	_handle_movement(delta)
	_update_platforms(delta)
	_update_player(delta)
	_check_platform_landings(old_y)
	_update_player_visual(delta)
	_update_camera()
	_generate_platforms()
	_cleanup_world()
	_update_score()
	_update_particles(delta)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if game_over:
			if event.keycode == KEY_R:
				reset_game()
			return

		if event.keycode == KEY_R:
			reset_game()
		elif event.keycode == KEY_P:
			paused = not paused
			message_label.visible = paused
			message_label.text = "PAUSED\nPress P to continue"

	if game_over and event is InputEventMouseButton and event.pressed:
		reset_game()


func _setup_view() -> void:
	get_window().size = Vector2i(int(GAME_WIDTH), int(GAME_HEIGHT))


func _setup_background() -> void:
	var layer := CanvasLayer.new()
	layer.layer = -10
	add_child(layer)

	var texture_rect := TextureRect.new()
	texture_rect.texture = load("res://assets/notebook_background.png")
	texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	texture_rect.stretch_mode = TextureRect.STRETCH_SCALE
	texture_rect.size = Vector2(GAME_WIDTH, GAME_HEIGHT)
	texture_rect.position = Vector2.ZERO
	layer.add_child(texture_rect)

	var wash := ColorRect.new()
	wash.color = Color(1.0, 1.0, 1.0, 0.18)
	wash.size = Vector2(GAME_WIDTH, GAME_HEIGHT)
	layer.add_child(wash)


func _setup_world() -> void:
	world = Node2D.new()
	add_child(world)

	camera = Camera2D.new()
	camera.position = Vector2(GAME_WIDTH * 0.5, camera_y)
	camera.enabled = true
	add_child(camera)

	player = _create_player_visual()
	player.z_index = 20
	world.add_child(player)


func _setup_ui() -> void:
	doodle_font = _create_doodle_font()

	var layer := CanvasLayer.new()
	layer.layer = 10
	add_child(layer)

	var hud_back := ColorRect.new()
	hud_back.color = Color(1.0, 1.0, 1.0, 0.72)
	hud_back.size = Vector2(GAME_WIDTH, HUD_HEIGHT)
	layer.add_child(hud_back)

	score_label = Label.new()
	score_label.position = Vector2(18, 14)
	score_label.size = Vector2(220, 42)
	score_label.add_theme_font_size_override("font_size", 30)
	score_label.add_theme_color_override("font_color", Color("#23364A"))
	layer.add_child(score_label)

	best_label = Label.new()
	best_label.position = Vector2(260, 18)
	best_label.size = Vector2(200, 34)
	best_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	best_label.add_theme_font_size_override("font_size", 18)
	best_label.add_theme_color_override("font_color", Color("#496780"))
	layer.add_child(best_label)

	message_label = Label.new()
	message_label.position = Vector2(34, 250)
	message_label.size = Vector2(412, 180)
	message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	message_label.add_theme_font_size_override("font_size", 26)
	message_label.add_theme_color_override("font_color", Color("#23364A"))
	message_label.add_theme_color_override("font_shadow_color", Color(1, 1, 1, 0.8))
	message_label.add_theme_constant_override("shadow_offset_x", 2)
	message_label.add_theme_constant_override("shadow_offset_y", 2)
	layer.add_child(message_label)

	_setup_game_over_page(layer)


func _setup_game_over_page(layer: CanvasLayer) -> void:
	game_over_page = Control.new()
	game_over_page.visible = false
	game_over_page.mouse_filter = Control.MOUSE_FILTER_STOP
	game_over_page.size = Vector2(GAME_WIDTH, GAME_HEIGHT)
	game_over_page.gui_input.connect(Callable(self, "_on_game_over_page_gui_input"))
	layer.add_child(game_over_page)

	var page_background := TextureRect.new()
	page_background.texture = GAME_OVER_TEXTURE
	page_background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	page_background.stretch_mode = TextureRect.STRETCH_SCALE
	page_background.size = Vector2(GAME_WIDTH, GAME_HEIGHT)
	page_background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	game_over_page.add_child(page_background)

	var panel := TextureRect.new()
	panel.texture = GAME_OVER_PANEL_TEXTURE
	panel.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	panel.stretch_mode = TextureRect.STRETCH_SCALE
	panel.position = Vector2(34, 132)
	panel.size = Vector2(412, 282)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	game_over_page.add_child(panel)

	var title_label := Label.new()
	title_label.text = "Oops!"
	title_label.position = Vector2(72, 176)
	title_label.size = Vector2(336, 68)
	title_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title_label.add_theme_font_override("font", doodle_font)
	title_label.add_theme_font_size_override("font_size", 58)
	title_label.add_theme_color_override("font_color", Color("#E84D3D"))
	title_label.add_theme_color_override("font_outline_color", Color("#FFFFFF"))
	title_label.add_theme_constant_override("outline_size", 8)
	title_label.add_theme_color_override("font_shadow_color", Color(0.05, 0.08, 0.10, 0.25))
	title_label.add_theme_constant_override("shadow_offset_x", 3)
	title_label.add_theme_constant_override("shadow_offset_y", 4)
	game_over_page.add_child(title_label)

	game_over_score_label = Label.new()
	game_over_score_label.position = Vector2(76, 254)
	game_over_score_label.size = Vector2(328, 56)
	game_over_score_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	game_over_score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	game_over_score_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	game_over_score_label.add_theme_font_override("font", doodle_font)
	game_over_score_label.add_theme_font_size_override("font_size", 34)
	game_over_score_label.add_theme_color_override("font_color", Color("#159C83"))
	game_over_score_label.add_theme_color_override("font_outline_color", Color("#FFFFFF"))
	game_over_score_label.add_theme_constant_override("outline_size", 5)
	game_over_page.add_child(game_over_score_label)

	game_over_best_label = Label.new()
	game_over_best_label.position = Vector2(76, 314)
	game_over_best_label.size = Vector2(328, 42)
	game_over_best_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	game_over_best_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	game_over_best_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	game_over_best_label.add_theme_font_override("font", doodle_font)
	game_over_best_label.add_theme_font_size_override("font_size", 24)
	game_over_best_label.add_theme_color_override("font_color", Color("#496780"))
	game_over_best_label.add_theme_color_override("font_outline_color", Color("#FFFFFF"))
	game_over_best_label.add_theme_constant_override("outline_size", 4)
	game_over_page.add_child(game_over_best_label)

	var retry_button := TextureRect.new()
	retry_button.texture = RETRY_BUTTON_TEXTURE
	retry_button.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	retry_button.stretch_mode = TextureRect.STRETCH_SCALE
	retry_button.position = Vector2(126, 438)
	retry_button.size = Vector2(228, 82)
	retry_button.mouse_filter = Control.MOUSE_FILTER_STOP
	retry_button.gui_input.connect(Callable(self, "_on_retry_button_gui_input"))
	game_over_page.add_child(retry_button)

	var retry_label := Label.new()
	retry_label.text = "Try Again"
	retry_label.size = retry_button.size
	retry_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	retry_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	retry_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	retry_label.add_theme_font_override("font", doodle_font)
	retry_label.add_theme_font_size_override("font_size", 27)
	retry_label.add_theme_color_override("font_color", Color("#23364A"))
	retry_label.add_theme_color_override("font_outline_color", Color("#FFFFFF"))
	retry_label.add_theme_constant_override("outline_size", 3)
	retry_button.add_child(retry_label)


func _create_doodle_font() -> Font:
	var font := SystemFont.new()
	font.font_names = PackedStringArray(["Marker Felt", "Chalkboard SE", "Comic Sans MS"])
	return font


func _on_game_over_page_gui_input(event: InputEvent) -> void:
	if game_over and event is InputEventMouseButton and event.pressed:
		reset_game()


func _on_retry_button_gui_input(event: InputEvent) -> void:
	if game_over and event is InputEventMouseButton and event.pressed:
		reset_game()


func reset_game() -> void:
	for platform in platforms:
		platform["node"].queue_free()
	for particle in particles:
		particle.queue_free()

	platforms.clear()
	particles.clear()
	player_pos = Vector2(GAME_WIDTH * 0.5, 610.0)
	player_velocity = Vector2.ZERO
	player_squash_time = 0.0
	move_hold_time = 0.0
	move_hold_dir = 0.0
	start_y = player_pos.y
	max_height = 0.0
	score = 0
	game_over = false
	paused = false
	camera_y = GAME_HEIGHT * 0.5
	camera.position = Vector2(GAME_WIDTH * 0.5, camera_y)
	highest_platform_y = 680.0
	message_label.visible = false
	game_over_page.visible = false

	_create_platform(GAME_WIDTH * 0.5, 666.0, 108.0, "normal", false)
	while highest_platform_y > -360.0:
		_spawn_next_platform()

	player.position = player_pos
	_update_player_visual(0.0)
	_update_ui()


func _handle_movement(delta: float) -> void:
	var input_dir := 0.0
	if Input.is_key_pressed(KEY_LEFT) or Input.is_key_pressed(KEY_A):
		input_dir -= 1.0
	if Input.is_key_pressed(KEY_RIGHT) or Input.is_key_pressed(KEY_D):
		input_dir += 1.0

	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		var mouse_x := get_viewport().get_mouse_position().x
		input_dir = sign(mouse_x - GAME_WIDTH * 0.5)

	if input_dir != 0.0:
		if input_dir == move_hold_dir:
			move_hold_time += delta
		else:
			move_hold_dir = input_dir
			move_hold_time = 0.0
	else:
		move_hold_dir = 0.0
		move_hold_time = 0.0

	var target_speed: float = BASE_SPEED_X + log(1.0 + move_hold_time * HOLD_LOG_GROWTH) * HOLD_LOG_BOOST
	var accel: float = AIR_CONTROL
	if input_dir == 0.0:
		accel = GROUND_AIR_BRAKE
	elif sign(player_velocity.x) != input_dir and abs(player_velocity.x) > 12.0:
		accel = GROUND_AIR_BRAKE
	player_velocity.x = move_toward(player_velocity.x, input_dir * target_speed, accel * delta)


func _update_player(delta: float) -> void:
	player_velocity.y += GRAVITY * delta
	player_pos += player_velocity * delta

	if player_pos.x < -PLAYER_HALF_W:
		player_pos.x = GAME_WIDTH + PLAYER_HALF_W
	elif player_pos.x > GAME_WIDTH + PLAYER_HALF_W:
		player_pos.x = -PLAYER_HALF_W

	player.position = player_pos
	player.rotation = lerp(player.rotation, clamp(player_velocity.x / SPEED_TILT_REF, -1.0, 1.0) * 0.10, 0.18)

	if player_pos.y > camera_y + GAME_HEIGHT * 0.58:
		_end_game()


func _check_platform_landings(old_y: float) -> void:
	if player_velocity.y <= 0.0:
		return

	var old_feet: float = old_y + PLAYER_HALF_H
	var new_feet: float = player_pos.y + PLAYER_HALF_H

	for platform in platforms:
		if bool(platform["broken"]):
			continue

		var platform_y: float = platform["y"]
		var platform_x: float = platform["x"]
		var platform_width: float = platform["width"]
		var horizontal_hit: bool = abs(player_pos.x - platform_x) <= platform_width * 0.5 + PLAYER_HALF_W * 0.55
		var vertical_hit: bool = old_feet <= platform_y and new_feet >= platform_y and player_pos.y < platform_y

		if bool(platform["has_spring"]):
			var spring_x: float = platform_x - platform_width * 0.24
			var spring_top_y: float = platform_y + SPRING_TOP_OFFSET
			var spring_horizontal_hit: bool = abs(player_pos.x - spring_x) < SPRING_HIT_RADIUS
			var spring_vertical_hit: bool = old_feet <= spring_top_y and new_feet >= spring_top_y and player_pos.y < spring_top_y
			if spring_horizontal_hit and spring_vertical_hit:
				player_velocity.y = SPRING_SPEED
				player_squash_time = 0.24
				platform["spring_compress"] = 1.0
				_spawn_burst(Vector2(spring_x, spring_top_y), 24, 1.75)
				player_pos.y = spring_top_y - PLAYER_HALF_H
				player.position = player_pos
				return

		if horizontal_hit and vertical_hit:
			if String(platform["type"]) == "fragile":
				_break_platform(platform)
				player_velocity.y = JUMP_SPEED
				player_squash_time = 0.12
				_spawn_burst(Vector2(platform_x, platform_y), 12, 0.95)
			else:
				player_velocity.y = JUMP_SPEED
				player_squash_time = 0.10
				_spawn_burst(Vector2(player_pos.x, platform_y - 6.0), 5, 0.65)
				player_pos.y = platform_y - PLAYER_HALF_H
				player.position = player_pos
			return


func _update_camera() -> void:
	var target_y := player_pos.y + 116.0
	if target_y < camera_y:
		camera_y = lerp(camera_y, target_y, 0.18)
	camera.position = Vector2(GAME_WIDTH * 0.5, camera_y)


func _update_score() -> void:
	max_height = max(max_height, start_y - player_pos.y)
	score = int(max_height * 0.55)
	_update_ui()


func _update_ui() -> void:
	score_label.text = str(score)
	best_label.text = "BEST " + str(best_score)


func _end_game() -> void:
	game_over = true
	best_score = max(best_score, score)
	_update_ui()
	game_over_score_label.text = "Score " + str(score)
	game_over_best_label.text = "Best " + str(best_score)
	game_over_page.visible = true
	_spawn_burst(player_pos, 18, 1.3)


func _generate_platforms() -> void:
	var top_edge: float = camera_y - GAME_HEIGHT * 0.5
	while highest_platform_y > top_edge - 760.0:
		_spawn_next_platform()


func _spawn_next_platform() -> void:
	var difficulty: float = clamp(float(score) / 2400.0, 0.0, 1.0)
	var gap := rng.randf_range(78.0, 118.0 + difficulty * 38.0)
	var width := rng.randf_range(88.0 - difficulty * 22.0, 116.0 - difficulty * 26.0)
	width = clamp(width, 64.0, 116.0)
	highest_platform_y -= gap

	var x := rng.randf_range(width * 0.5 + 10.0, GAME_WIDTH - width * 0.5 - 10.0)
	var roll := rng.randf()
	var platform_type := "normal"
	if score > 350 and roll < 0.18:
		platform_type = "moving"
	elif score > 700 and roll < 0.31:
		platform_type = "fragile"

	var has_spring: bool = platform_type != "fragile" and rng.randf() < 0.11 + difficulty * 0.04
	_create_platform(x, highest_platform_y, width, platform_type, has_spring)


func _create_platform(x: float, y: float, width: float, platform_type: String, has_spring: bool) -> void:
	var node := Node2D.new()
	node.position = Vector2(x, y)
	world.add_child(node)

	var texture := PLATFORM_NORMAL_TEXTURE
	if platform_type == "moving":
		texture = PLATFORM_MOVING_TEXTURE
	elif platform_type == "fragile":
		texture = PLATFORM_FRAGILE_TEXTURE

	var body := _add_sprite_with_shadow(node, texture, Vector2(2.0, 4.0), 0.16)
	_set_sprite_pair_position(body, Vector2(0.0, PLATFORM_SPRITE_HEIGHT * 0.5))
	_set_sprite_pair_scale(body, Vector2(width / PLATFORM_SPRITE_WIDTH, 0.88))

	var spring_node: Node2D = null
	if has_spring:
		spring_node = _create_spring_visual()
		spring_node.position = Vector2(-width * 0.24, SPRING_BASE_Y)
		spring_node.z_index = 4
		node.add_child(spring_node)

	var speed := 0.0
	if platform_type == "moving":
		speed = rng.randf_range(55.0, 105.0) * (-1.0 if rng.randf() < 0.5 else 1.0)

	platforms.append({
		"node": node,
		"x": x,
		"y": y,
		"width": width,
		"type": platform_type,
		"speed": speed,
			"has_spring": has_spring,
			"spring_node": spring_node,
			"spring_base_y": SPRING_BASE_Y,
			"spring_compress": 0.0,
			"broken": false,
			"fall_speed": 0.0,
		})


func _update_platforms(delta: float) -> void:
	for platform in platforms:
		var node: Node2D = platform["node"]
		if bool(platform["broken"]):
			platform["fall_speed"] += GRAVITY * delta * 0.65
			platform["y"] += platform["fall_speed"] * delta
			node.position.y = platform["y"]
			node.rotation += delta * 2.8
			node.modulate.a = max(0.0, node.modulate.a - delta * 1.5)
			continue

		if String(platform["type"]) == "moving":
			platform["x"] += platform["speed"] * delta
			var half_width: float = platform["width"] * 0.5
			if float(platform["x"]) < half_width + 8.0 or float(platform["x"]) > GAME_WIDTH - half_width - 8.0:
				platform["speed"] *= -1.0
				platform["x"] = clamp(platform["x"], half_width + 8.0, GAME_WIDTH - half_width - 8.0)
			node.position.x = platform["x"]

		if bool(platform["has_spring"]) and platform["spring_node"] != null:
			var spring: Node2D = platform["spring_node"]
			var compression: float = platform["spring_compress"]
			compression = max(0.0, compression - delta * 5.2)
			platform["spring_compress"] = compression
			spring.scale = Vector2(
				SPRING_BASE_SCALE.x * (1.0 + compression * 0.22),
				SPRING_BASE_SCALE.y * (1.0 - compression * 0.52)
			)
			var current_height := SPRING_VISUAL_HEIGHT * (1.0 - compression * 0.52)
			spring.position.y = SPRING_SEAT_Y - current_height * 0.5


func _break_platform(platform: Dictionary) -> void:
	platform["broken"] = true
	platform["fall_speed"] = 70.0


func _cleanup_world() -> void:
	var bottom_edge := camera_y + GAME_HEIGHT * 0.5 + 180.0
	for index in range(platforms.size() - 1, -1, -1):
		if platforms[index]["y"] > bottom_edge:
			platforms[index]["node"].queue_free()
			platforms.remove_at(index)

	for index in range(particles.size() - 1, -1, -1):
		if not is_instance_valid(particles[index]):
			particles.remove_at(index)


func _create_player_visual() -> Node2D:
	var node := Node2D.new()
	player_art = _add_sprite_with_shadow(node, PLAYER_TEXTURE, Vector2(3.0, 5.0), 0.18)
	player_art.scale = PLAYER_BASE_SCALE

	return node


func _create_spring_visual() -> Node2D:
	var node := Node2D.new()
	_add_sprite_with_shadow(node, SPRING_TEXTURE, Vector2(2.0, 3.0), 0.18)
	node.scale = SPRING_BASE_SCALE

	return node


func _update_player_visual(delta: float) -> void:
	if player_art == null:
		return

	player_squash_time = max(0.0, player_squash_time - delta)
	var squash_strength: float = player_squash_time / 0.16
	var velocity_stretch: float = clamp(-player_velocity.y / abs(SPRING_SPEED), -0.18, 0.18)
	_set_sprite_pair_scale(player_art, PLAYER_BASE_SCALE * Vector2(
		1.0 + squash_strength * 0.10 - velocity_stretch * 0.08,
		1.0 - squash_strength * 0.12 + velocity_stretch * 0.10
	))


func _add_sprite_with_shadow(parent: Node, texture: Texture2D, shadow_offset: Vector2, shadow_alpha: float) -> Sprite2D:
	var shadow := Sprite2D.new()
	shadow.texture = texture
	shadow.position = shadow_offset
	shadow.modulate = Color(0.05, 0.08, 0.10, shadow_alpha)
	shadow.z_index = -1
	parent.add_child(shadow)

	var sprite := Sprite2D.new()
	sprite.texture = texture
	sprite.set_meta("shadow_node", shadow)
	sprite.set_meta("shadow_offset", shadow_offset)
	parent.add_child(sprite)
	return sprite


func _set_sprite_pair_scale(sprite: Sprite2D, scale_value: Vector2) -> void:
	sprite.scale = scale_value
	var shadow: Sprite2D = sprite.get_meta("shadow_node")
	shadow.scale = scale_value


func _set_sprite_pair_position(sprite: Sprite2D, position_value: Vector2) -> void:
	sprite.position = position_value
	var shadow: Sprite2D = sprite.get_meta("shadow_node")
	var shadow_offset: Vector2 = sprite.get_meta("shadow_offset")
	shadow.position = position_value + shadow_offset


func _spawn_burst(origin: Vector2, amount: int = 10, force: float = 1.0) -> void:
	for i in amount:
		var dot := Sprite2D.new()
		dot.texture = SPARKLE_TEXTURE
		dot.position = origin
		dot.rotation = rng.randf_range(0.0, TAU)
		dot.scale = Vector2.ONE * rng.randf_range(0.45, 1.05) * force
		dot.z_index = 30
		world.add_child(dot)
		dot.set_meta("velocity", Vector2(rng.randf_range(-120.0, 120.0), rng.randf_range(-180.0, -30.0)) * force)
		dot.set_meta("life", rng.randf_range(0.35, 0.7))
		particles.append(dot)


func _update_particles(delta: float) -> void:
	for index in range(particles.size() - 1, -1, -1):
		var dot: Sprite2D = particles[index]
		if not is_instance_valid(dot):
			particles.remove_at(index)
			continue

		var velocity: Vector2 = dot.get_meta("velocity")
		var life: float = dot.get_meta("life")
		velocity.y += GRAVITY * 0.45 * delta
		life -= delta
		dot.position += velocity * delta
		dot.rotation += delta * 5.0
		dot.modulate.a = clamp(life * 2.2, 0.0, 1.0)
		dot.set_meta("velocity", velocity)
		dot.set_meta("life", life)

		if life <= 0.0:
			dot.queue_free()
			particles.remove_at(index)
