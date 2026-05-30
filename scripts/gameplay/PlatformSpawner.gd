extends Node
class_name PlatformSpawner

const PLATFORM_SCENE := preload("res://scenes/gameplay/JumpPlatform.tscn")

var platforms: Array[JumpPlatform] = []
var highest_platform_y := 680.0
var rng: RandomNumberGenerator
var world: Node2D
var tuning: GameTuning


func setup(world_node: Node2D, random: RandomNumberGenerator, game_tuning: GameTuning) -> void:
	world = world_node
	rng = random
	tuning = game_tuning


func reset() -> void:
	clear_platforms()
	highest_platform_y = tuning.initial_highest_platform_y


func clear_platforms() -> void:
	for platform in platforms:
		if is_instance_valid(platform):
			platform.queue_free()
	platforms.clear()


func spawn_starting_platform() -> void:
	create_platform(tuning.game_width * 0.5, tuning.starting_platform_y, tuning.starting_platform_width, JumpPlatform.TYPE_NORMAL, false, false, false)


func fill_initial(score: int) -> void:
	while highest_platform_y > tuning.initial_fill_top_y:
		spawn_next_platform(score)


func generate_for_camera(camera_y: float, score: int) -> void:
	var top_edge: float = camera_y - tuning.game_height * 0.5
	while highest_platform_y > top_edge - tuning.generation_ahead:
		spawn_next_platform(score)


func update_platforms(delta: float) -> void:
	for platform in platforms:
		platform.update_platform(delta, tuning.game_width, tuning.gravity, tuning.moving_platform_edge_padding)


func cleanup(bottom_edge: float) -> void:
	for index in range(platforms.size() - 1, -1, -1):
		var platform := platforms[index]
		if not is_instance_valid(platform):
			platforms.remove_at(index)
			continue

		if platform.position.y > bottom_edge:
			platform.queue_free()
			platforms.remove_at(index)


func spawn_next_platform(score: int) -> void:
	var difficulty: float = clamp(float(score) / tuning.difficulty_score_span, 0.0, 1.0)
	var gap := rng.randf_range(78.0, 118.0 + difficulty * 38.0)
	var width := rng.randf_range(88.0 - difficulty * 22.0, 116.0 - difficulty * 26.0)
	width = clamp(width, 64.0, 116.0)
	highest_platform_y -= gap

	var x := rng.randf_range(width * 0.5 + tuning.min_edge_padding, tuning.game_width - width * 0.5 - tuning.min_edge_padding)
	var roll := rng.randf()
	var platform_type := JumpPlatform.TYPE_NORMAL
	if score > 350 and roll < 0.18:
		platform_type = JumpPlatform.TYPE_MOVING
	elif score > 700 and roll < 0.31:
		platform_type = JumpPlatform.TYPE_FRAGILE

	var has_launcher: bool = platform_type != JumpPlatform.TYPE_FRAGILE and score > 220 and rng.randf() < 0.055 + difficulty * 0.035
	var has_spring: bool = not has_launcher and platform_type != JumpPlatform.TYPE_FRAGILE and rng.randf() < 0.11 + difficulty * 0.04
	var has_fire_boots: bool = not has_launcher and not has_spring and platform_type != JumpPlatform.TYPE_FRAGILE and score > 120 and rng.randf() < 0.06 + difficulty * 0.035
	create_platform(x, highest_platform_y, width, platform_type, has_spring, has_launcher, has_fire_boots)


func create_platform(x: float, y: float, width: float, platform_type: String, has_spring: bool, has_launcher: bool, has_fire_boots: bool = false) -> JumpPlatform:
	var speed := 0.0
	if platform_type == JumpPlatform.TYPE_MOVING:
		speed = rng.randf_range(tuning.moving_platform_min_speed, tuning.moving_platform_max_speed) * (-1.0 if rng.randf() < 0.5 else 1.0)

	var launch_dir := 1.0 if x < tuning.game_width * 0.5 else -1.0
	var platform := PLATFORM_SCENE.instantiate() as JumpPlatform
	world.add_child(platform)
	platform.setup(Vector2(x, y), width, platform_type, has_spring, has_launcher, speed, launch_dir)
	platform.set_fire_boots(has_fire_boots)
	platforms.append(platform)
	return platform
