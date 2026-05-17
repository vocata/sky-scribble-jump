extends Node2D

const GAME_WIDTH := 480.0
const GAME_HEIGHT := 720.0
const GRAVITY := 980.0
const JUMP_SPEED := -620.0
const SPRING_SPEED := -1120.0
const SPRING_HIT_RADIUS := 38.0
const LAUNCHER_SPEED := -1420.0
const LAUNCHER_SIDE_SPEED := 260.0
const LAUNCHER_HIT_RADIUS := 28.0
const LAUNCHER_ENTER_TIME := 0.20
const LAUNCHER_CHARGE_TIME := 0.48

const GAMEPLAY_BACKGROUND_TEXTURE := preload("res://assets/art/backgrounds/gameplay_background.png")
const PLAYER_SCENE := preload("res://scenes/actors/Player.tscn")
const PLATFORM_SCENE := preload("res://scenes/gameplay/JumpPlatform.tscn")
const BURST_PARTICLES_SCENE := preload("res://scenes/gameplay/BurstParticles.tscn")
const HUD_SCENE := preload("res://scenes/ui/GameHUD.tscn")
const START_SCREEN_SCENE := preload("res://scenes/ui/StartScreen.tscn")
const GAME_OVER_SCREEN_SCENE := preload("res://scenes/ui/GameOverScreen.tscn")

var rng := RandomNumberGenerator.new()
var world: Node2D
var camera: Camera2D
var player: Player
var effects: BurstParticles
var platforms: Array[JumpPlatform] = []
var highest_platform_y := 680.0
var camera_y := GAME_HEIGHT * 0.5
var start_y := 610.0
var max_height := 0.0
var score := 0
var best_score := 0
var game_started := false
var game_over := false
var paused := false
var launcher_sequence_active := false
var launcher_timer := 0.0
var launcher_start_pos := Vector2.ZERO
var launcher_entry_pos := Vector2.ZERO
var launcher_hidden_pos := Vector2.ZERO
var launcher_fire_dir := 1.0
var launcher_active_platform: JumpPlatform

var hud: GameHUD
var start_screen: StartScreen
var game_over_screen: GameOverScreen


func _ready() -> void:
	rng.randomize()
	_setup_view()
	_setup_background()
	_setup_world()
	_setup_ui()
	_show_start_page()


func _physics_process(delta: float) -> void:
	if not game_started or paused:
		return

	if game_over:
		effects.update_particles(delta, GRAVITY)
		return

	if launcher_sequence_active:
		_update_platforms(delta)
		_update_launcher_sequence(delta)
		player.update_visual(delta)
		_update_camera()
		_generate_platforms()
		_cleanup_world()
		_update_score()
		effects.update_particles(delta, GRAVITY)
		return

	var old_y: float = player.position.y
	player.handle_movement(delta, GAME_WIDTH)
	_update_platforms(delta)
	player.update_motion(delta, GRAVITY, GAME_WIDTH)
	_check_platform_landings(old_y)
	player.update_visual(delta)
	_update_camera()
	_generate_platforms()
	_cleanup_world()
	_update_score()
	effects.update_particles(delta, GRAVITY)

	if player.position.y > camera_y + GAME_HEIGHT * 0.58:
		_end_game()


func _unhandled_input(event: InputEvent) -> void:
	if not game_started:
		return

	if event is InputEventKey and event.pressed and not event.echo:
		if game_over:
			return

		if event.keycode == KEY_R:
			reset_game()
		elif event.keycode == KEY_P:
			paused = not paused
			hud.show_pause(paused)


func reset_game() -> void:
	_clear_run_nodes()

	player.reset_to(Vector2(GAME_WIDTH * 0.5, 610.0))
	start_y = player.position.y
	max_height = 0.0
	score = 0
	game_started = true
	game_over = false
	paused = false
	launcher_sequence_active = false
	launcher_timer = 0.0
	launcher_active_platform = null
	camera_y = GAME_HEIGHT * 0.5
	camera.position = Vector2(GAME_WIDTH * 0.5, camera_y)
	highest_platform_y = 680.0
	hud.hide_message()
	start_screen.hide_page()
	game_over_screen.hide_page()

	_create_platform(GAME_WIDTH * 0.5, 666.0, 108.0, JumpPlatform.TYPE_NORMAL, false, false)
	while highest_platform_y > -360.0:
		_spawn_next_platform()

	_update_ui()


func _setup_view() -> void:
	get_window().size = Vector2i(int(GAME_WIDTH), int(GAME_HEIGHT))


func _setup_background() -> void:
	var layer := CanvasLayer.new()
	layer.layer = -10
	add_child(layer)

	var texture_rect := TextureRect.new()
	texture_rect.texture = GAMEPLAY_BACKGROUND_TEXTURE
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

	effects = BURST_PARTICLES_SCENE.instantiate() as BurstParticles
	world.add_child(effects)

	player = PLAYER_SCENE.instantiate() as Player
	player.z_index = 20
	world.add_child(player)


func _setup_ui() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 10
	add_child(layer)

	hud = HUD_SCENE.instantiate() as GameHUD
	layer.add_child(hud)

	game_over_screen = GAME_OVER_SCREEN_SCENE.instantiate() as GameOverScreen
	game_over_screen.retry_pressed.connect(Callable(self, "reset_game"))
	layer.add_child(game_over_screen)

	start_screen = START_SCREEN_SCENE.instantiate() as StartScreen
	start_screen.start_pressed.connect(Callable(self, "reset_game"))
	layer.add_child(start_screen)


func _show_start_page() -> void:
	game_started = false
	game_over = false
	paused = false
	score = 0
	max_height = 0.0
	hud.set_scores(score, best_score)
	hud.hide_message()
	game_over_screen.hide_page()
	if player != null:
		player.visible = false
	start_screen.show_page()


func _clear_run_nodes() -> void:
	for platform in platforms:
		if is_instance_valid(platform):
			platform.queue_free()
	platforms.clear()
	effects.clear_particles()


func _check_platform_landings(old_y: float) -> void:
	if player.velocity.y <= 0.0:
		return

	var old_feet: float = old_y + Player.HALF_H
	var new_feet: float = player.position.y + Player.HALF_H

	for platform in platforms:
		if platform.broken:
			continue

		var platform_y: float = platform.position.y
		var platform_x: float = platform.position.x
		var horizontal_hit: bool = abs(player.position.x - platform_x) <= platform.platform_width * 0.5 + Player.HALF_W * 0.55
		var vertical_hit: bool = old_feet <= platform_y and new_feet >= platform_y and player.position.y < platform_y

		if platform.has_spring:
			var spring_top := platform.get_spring_top_position()
			var spring_horizontal_hit: bool = abs(player.position.x - spring_top.x) < SPRING_HIT_RADIUS
			var spring_vertical_hit: bool = old_feet <= spring_top.y and new_feet >= spring_top.y and player.position.y < spring_top.y
			if spring_horizontal_hit and spring_vertical_hit:
				player.bounce(SPRING_SPEED, 0.24)
				platform.compress_spring()
				effects.spawn_burst(spring_top, rng, 24, 1.75)
				player.set_feet_y(spring_top.y)
				return

		if platform.has_launcher:
			var launcher_entry := platform.get_launcher_entry_position()
			var launcher_horizontal_hit: bool = abs(player.position.x - launcher_entry.x) < LAUNCHER_HIT_RADIUS
			var launcher_vertical_hit: bool = old_feet <= launcher_entry.y and new_feet >= launcher_entry.y and player.position.y < launcher_entry.y
			if launcher_horizontal_hit and launcher_vertical_hit:
				_trigger_launcher(platform, launcher_entry, platform.launcher_dir)
				return

		if horizontal_hit and vertical_hit:
			if platform.is_fragile():
				platform.break_platform()
				player.bounce(JUMP_SPEED, 0.12)
				effects.spawn_burst(Vector2(platform_x, platform_y), rng, 12, 0.95)
			else:
				player.bounce(JUMP_SPEED, 0.10)
				effects.spawn_burst(Vector2(player.position.x, platform_y - 6.0), rng, 5, 0.65)
				player.set_feet_y(platform_y)
			return


func _trigger_launcher(platform: JumpPlatform, entry_pos: Vector2, launch_dir: float) -> void:
	launcher_sequence_active = true
	launcher_timer = 0.0
	launcher_start_pos = player.position
	launcher_entry_pos = entry_pos
	launcher_hidden_pos = entry_pos + Vector2(launch_dir * 7.0, 17.0)
	launcher_fire_dir = launch_dir
	launcher_active_platform = platform
	launcher_active_platform.set_launcher_charge(0.0)
	player.begin_launcher_entry()
	effects.spawn_burst(entry_pos, rng, 10, 0.8)


func _update_launcher_sequence(delta: float) -> void:
	launcher_timer += delta

	if is_instance_valid(launcher_active_platform) and not launcher_active_platform.broken:
		launcher_entry_pos = launcher_active_platform.get_launcher_entry_position()
		launcher_hidden_pos = launcher_entry_pos + Vector2(launcher_fire_dir * 7.0, 17.0)

	if launcher_timer <= LAUNCHER_ENTER_TIME:
		var t: float = clamp(launcher_timer / LAUNCHER_ENTER_TIME, 0.0, 1.0)
		var eased: float = t * t * (3.0 - 2.0 * t)
		player.show_launcher_entry(
			launcher_start_pos.lerp(launcher_hidden_pos, eased),
			Vector2.ONE.lerp(Vector2(0.20, 0.20), eased),
			lerp(player.rotation, deg_to_rad(launcher_fire_dir * 18.0), 0.34),
			6 if t < 0.62 else 4
		)
		return

	player.hide_inside_launcher()

	var charge_t: float = clamp((launcher_timer - LAUNCHER_ENTER_TIME) / LAUNCHER_CHARGE_TIME, 0.0, 1.0)
	var charge_eased: float = charge_t * charge_t * (3.0 - 2.0 * charge_t)
	if is_instance_valid(launcher_active_platform):
		launcher_active_platform.set_launcher_charge(charge_eased)

	if charge_t >= 1.0:
		_fire_from_launcher()


func _fire_from_launcher() -> void:
	launcher_sequence_active = false
	player.fire_from_launcher(
		launcher_entry_pos + Vector2(launcher_fire_dir * 14.0, -8.0),
		Vector2(launcher_fire_dir * LAUNCHER_SIDE_SPEED, LAUNCHER_SPEED),
		deg_to_rad(launcher_fire_dir * 16.0)
	)
	if is_instance_valid(launcher_active_platform):
		launcher_active_platform.set_launcher_charge(1.0)
	effects.spawn_burst(launcher_entry_pos, rng, 34, 2.1)


func _update_camera() -> void:
	var target_y := player.position.y + 116.0
	if target_y < camera_y:
		camera_y = lerp(camera_y, target_y, 0.18)
	camera.position = Vector2(GAME_WIDTH * 0.5, camera_y)


func _update_score() -> void:
	max_height = max(max_height, start_y - player.position.y)
	score = int(max_height * 0.55)
	_update_ui()


func _update_ui() -> void:
	hud.set_scores(score, best_score)


func _end_game() -> void:
	game_over = true
	best_score = max(best_score, score)
	_update_ui()
	game_over_screen.show_results(score, best_score)
	effects.spawn_burst(player.position, rng, 18, 1.3)


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
	var platform_type := JumpPlatform.TYPE_NORMAL
	if score > 350 and roll < 0.18:
		platform_type = JumpPlatform.TYPE_MOVING
	elif score > 700 and roll < 0.31:
		platform_type = JumpPlatform.TYPE_FRAGILE

	var has_launcher: bool = platform_type != JumpPlatform.TYPE_FRAGILE and score > 220 and rng.randf() < 0.055 + difficulty * 0.035
	var has_spring: bool = not has_launcher and platform_type != JumpPlatform.TYPE_FRAGILE and rng.randf() < 0.11 + difficulty * 0.04
	_create_platform(x, highest_platform_y, width, platform_type, has_spring, has_launcher)


func _create_platform(x: float, y: float, width: float, platform_type: String, has_spring: bool, has_launcher: bool) -> void:
	var speed := 0.0
	if platform_type == JumpPlatform.TYPE_MOVING:
		speed = rng.randf_range(55.0, 105.0) * (-1.0 if rng.randf() < 0.5 else 1.0)

	var launch_dir := 1.0 if x < GAME_WIDTH * 0.5 else -1.0
	var platform := PLATFORM_SCENE.instantiate() as JumpPlatform
	world.add_child(platform)
	platform.setup(Vector2(x, y), width, platform_type, has_spring, has_launcher, speed, launch_dir)
	platforms.append(platform)


func _update_platforms(delta: float) -> void:
	for platform in platforms:
		platform.update_platform(delta, GAME_WIDTH, GRAVITY)


func _cleanup_world() -> void:
	var bottom_edge := camera_y + GAME_HEIGHT * 0.5 + 180.0
	for index in range(platforms.size() - 1, -1, -1):
		var platform := platforms[index]
		if not is_instance_valid(platform):
			platforms.remove_at(index)
			continue

		if platform.position.y > bottom_edge:
			platform.queue_free()
			platforms.remove_at(index)
