extends Node2D

const PLAYER_SCENE := preload("res://scenes/actors/Player.tscn")
const BURST_PARTICLES_SCENE := preload("res://scenes/gameplay/BurstParticles.tscn")

@export var tuning: GameTuning = preload("res://resources/game_tuning.tres")

@onready var world: Node2D = $World
@onready var camera: Camera2D = $Camera2D
@onready var platform_spawner: PlatformSpawner = $PlatformSpawner
@onready var launcher_sequence: LauncherSequence = $LauncherSequence
@onready var hud: GameHUD = $UILayer/GameHUD
@onready var start_screen: StartScreen = $UILayer/StartScreen
@onready var game_over_screen: GameOverScreen = $UILayer/GameOverScreen

var rng := RandomNumberGenerator.new()
var player: Player
var effects: BurstParticles
var camera_y := 360.0
var start_y := 610.0
var max_height := 0.0
var score := 0
var best_score := 0
var game_started := false
var game_over := false
var paused := false


func _ready() -> void:
	rng.randomize()
	_setup_view()
	_setup_runtime_nodes()
	_wire_signals()
	_show_start_page()


func _physics_process(delta: float) -> void:
	if not game_started or paused:
		return

	if game_over:
		effects.update_particles(delta, tuning.gravity)
		return

	if launcher_sequence.active:
		platform_spawner.update_platforms(delta)
		launcher_sequence.update_sequence(delta)
		player.update_visual(delta)
		_after_world_step(delta)
		return

	var old_y: float = player.position.y
	player.handle_movement(delta, tuning.game_width)
	platform_spawner.update_platforms(delta)
	player.update_fire_boots(delta, tuning.fire_boots_speed)
	player.update_motion(delta, tuning.gravity, tuning.game_width)
	_check_fire_boots_pickups()
	if not player.is_fire_boots_active():
		_check_platform_landings(old_y)
	player.update_visual(delta)
	_after_world_step(delta)

	if player.position.y > camera_y + tuning.game_height * tuning.death_margin_ratio:
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
	platform_spawner.reset()
	effects.clear_particles()
	launcher_sequence.reset()

	player.reset_to(tuning.player_start_pos)
	start_y = player.position.y
	max_height = 0.0
	score = 0
	game_started = true
	game_over = false
	paused = false
	camera_y = tuning.game_height * 0.5
	camera.position = Vector2(tuning.game_width * 0.5, camera_y)
	hud.hide_message()
	start_screen.hide_page()
	game_over_screen.hide_page()

	platform_spawner.spawn_starting_platform()
	platform_spawner.fill_initial(score)
	_update_ui()


func _setup_view() -> void:
	get_window().size = Vector2i(int(tuning.game_width), int(tuning.game_height))


func _setup_runtime_nodes() -> void:
	camera_y = tuning.game_height * 0.5
	camera.position = Vector2(tuning.game_width * 0.5, camera_y)
	platform_spawner.setup(world, rng, tuning)

	effects = BURST_PARTICLES_SCENE.instantiate() as BurstParticles
	world.add_child(effects)

	player = PLAYER_SCENE.instantiate() as Player
	player.z_index = 20
	world.add_child(player)

	launcher_sequence.setup(player, tuning)


func _wire_signals() -> void:
	start_screen.start_pressed.connect(Callable(self, "reset_game"))
	game_over_screen.retry_pressed.connect(Callable(self, "reset_game"))
	launcher_sequence.entered.connect(Callable(self, "_on_launcher_entered"))
	launcher_sequence.fired.connect(Callable(self, "_on_launcher_fired"))


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


func _after_world_step(delta: float) -> void:
	_update_camera()
	platform_spawner.generate_for_camera(camera_y, score)
	platform_spawner.cleanup(camera_y + tuning.game_height * 0.5 + tuning.cleanup_margin)
	_update_score()
	effects.update_particles(delta, tuning.gravity)


func _check_platform_landings(old_y: float) -> void:
	if player.velocity.y <= 0.0:
		return

	var old_feet: float = old_y + Player.HALF_H
	var new_feet: float = player.position.y + Player.HALF_H

	for platform in platform_spawner.platforms:
		if platform.broken:
			continue

		var platform_y: float = platform.position.y
		var platform_x: float = platform.position.x
		var horizontal_hit: bool = abs(player.position.x - platform_x) <= platform.platform_width * 0.5 + Player.HALF_W * 0.55
		var vertical_hit: bool = old_feet <= platform_y and new_feet >= platform_y and player.position.y < platform_y

		if platform.has_spring:
			var spring_top := platform.get_spring_top_position()
			var spring_horizontal_hit: bool = abs(player.position.x - spring_top.x) < tuning.spring_hit_radius
			var spring_vertical_hit: bool = old_feet <= spring_top.y and new_feet >= spring_top.y and player.position.y < spring_top.y
			if spring_horizontal_hit and spring_vertical_hit:
				player.bounce(tuning.spring_speed, 0.24)
				platform.compress_spring()
				effects.spawn_burst(spring_top, rng, 24, 1.75)
				player.set_feet_y(spring_top.y)
				return

		if platform.has_launcher:
			var launcher_entry := platform.get_launcher_entry_position()
			var launcher_horizontal_hit: bool = abs(player.position.x - launcher_entry.x) < tuning.launcher_hit_radius
			var launcher_vertical_hit: bool = old_feet <= launcher_entry.y and new_feet >= launcher_entry.y and player.position.y < launcher_entry.y
			if launcher_horizontal_hit and launcher_vertical_hit:
				launcher_sequence.start(platform, launcher_entry, platform.launcher_dir)
				return

		if horizontal_hit and vertical_hit:
			if platform.is_fragile():
				platform.break_platform()
				player.bounce(tuning.jump_speed, 0.12)
				effects.spawn_burst(Vector2(platform_x, platform_y), rng, 12, 0.95)
			else:
				player.bounce(tuning.jump_speed, 0.10)
				effects.spawn_burst(Vector2(player.position.x, platform_y - 6.0), rng, 5, 0.65)
				player.set_feet_y(platform_y)
			return


func _check_fire_boots_pickups() -> void:
	if player.is_fire_boots_active():
		return

	for platform in platform_spawner.platforms:
		if platform.broken or not platform.has_fire_boots:
			continue

		var pickup_pos := platform.get_fire_boots_pickup_position()
		if player.position.distance_to(pickup_pos) <= tuning.fire_boots_hit_radius:
			platform.consume_fire_boots()
			player.activate_fire_boots(tuning.fire_boots_duration)
			player.velocity.y = tuning.fire_boots_speed
			effects.spawn_burst(pickup_pos, rng, 26, 1.55)
			return


func _update_camera() -> void:
	var target_y := player.position.y + tuning.camera_follow_offset
	if target_y < camera_y:
		camera_y = lerp(camera_y, target_y, 0.18)
	camera.position = Vector2(tuning.game_width * 0.5, camera_y)


func _update_score() -> void:
	max_height = max(max_height, start_y - player.position.y)
	score = int(max_height * tuning.score_scale)
	_update_ui()


func _update_ui() -> void:
	hud.set_scores(score, best_score)


func _end_game() -> void:
	game_over = true
	best_score = max(best_score, score)
	_update_ui()
	game_over_screen.show_results(score, best_score)
	effects.spawn_burst(player.position, rng, 18, 1.3)


func _on_launcher_entered(entry_pos: Vector2) -> void:
	effects.spawn_burst(entry_pos, rng, 10, 0.8)


func _on_launcher_fired(entry_pos: Vector2) -> void:
	effects.spawn_burst(entry_pos, rng, 34, 2.1)
