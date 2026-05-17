extends Node2D
class_name JumpPlatform

const TYPE_NORMAL := "normal"
const TYPE_MOVING := "moving"
const TYPE_FRAGILE := "fragile"

const SPRITE_WIDTH := 128.0
const SPRITE_HEIGHT := 40.0
const SPRING_BASE_SCALE := Vector2(0.58, 0.58)
const LAUNCHER_BASE_SCALE := Vector2(0.46, 0.46)
const SPRING_VISUAL_HEIGHT := 31.9
const SPRING_SEAT_Y := 7.0
const SPRING_BASE_Y := -8.95
const SPRING_TOP_OFFSET := -25.0
const LAUNCHER_BASE_Y := -17.0
const LAUNCHER_ENTRY_OFFSET_Y := -36.0
const LAUNCHER_MOUTH_SIDE_OFFSET := 4.0

const PLATFORM_NORMAL_TEXTURE := preload("res://assets/art/platforms/platform_green.png")
const PLATFORM_MOVING_TEXTURE := preload("res://assets/art/platforms/platform_blue_moving.png")
const PLATFORM_FRAGILE_TEXTURE := preload("res://assets/art/platforms/platform_red_fragile.png")
const SPRING_TEXTURE := preload("res://assets/art/props/spring.png")
const LAUNCHER_TEXTURE := preload("res://assets/art/props/launcher.png")

var platform_width := 108.0
var platform_type := TYPE_NORMAL
var speed := 0.0
var broken := false
var fall_speed := 0.0
var has_spring := false
var has_launcher := false
var launcher_dir := 1.0
var launcher_offset := 0.0
var spring_compress := 0.0
var launcher_charge := 0.0

var body_art: Sprite2D
var spring_node: Node2D
var launcher_node: Node2D


func setup(
	platform_position: Vector2,
	width: float,
	type_name: String,
	contains_spring: bool,
	contains_launcher: bool,
	move_speed: float,
	launch_direction: float
) -> void:
	position = platform_position
	platform_width = width
	platform_type = type_name
	speed = move_speed
	has_spring = contains_spring
	has_launcher = contains_launcher
	launcher_dir = launch_direction
	launcher_offset = clamp(launcher_dir * platform_width * 0.24, -platform_width * 0.26, platform_width * 0.26)

	_build_body()
	_build_props()


func update_platform(delta: float, game_width: float, gravity: float, edge_padding: float = 8.0) -> void:
	if broken:
		fall_speed += gravity * delta * 0.65
		position.y += fall_speed * delta
		rotation += delta * 2.8
		modulate.a = max(0.0, modulate.a - delta * 1.5)
		return

	if platform_type == TYPE_MOVING:
		position.x += speed * delta
		var half_width: float = platform_width * 0.5
		if position.x < half_width + edge_padding or position.x > game_width - half_width - edge_padding:
			speed *= -1.0
			position.x = clamp(position.x, half_width + edge_padding, game_width - half_width - edge_padding)

	_update_spring(delta)
	_update_launcher(delta)


func break_platform() -> void:
	broken = true
	fall_speed = 70.0


func is_fragile() -> bool:
	return platform_type == TYPE_FRAGILE


func get_spring_top_position() -> Vector2:
	return Vector2(position.x - platform_width * 0.24, position.y + SPRING_TOP_OFFSET)


func compress_spring() -> void:
	spring_compress = 1.0


func get_launcher_entry_position() -> Vector2:
	var launcher_x := position.x + launcher_offset
	return Vector2(
		launcher_x + launcher_dir * LAUNCHER_MOUTH_SIDE_OFFSET,
		position.y + LAUNCHER_ENTRY_OFFSET_Y
	)


func set_launcher_charge(charge: float) -> void:
	launcher_charge = charge


func _build_body() -> void:
	var texture := PLATFORM_NORMAL_TEXTURE
	if platform_type == TYPE_MOVING:
		texture = PLATFORM_MOVING_TEXTURE
	elif platform_type == TYPE_FRAGILE:
		texture = PLATFORM_FRAGILE_TEXTURE

	body_art = SpriteShadow.add_pair(self, texture, Vector2(2.0, 4.0), 0.16)
	SpriteShadow.set_pair_position(body_art, Vector2(0.0, SPRITE_HEIGHT * 0.5))
	SpriteShadow.set_pair_scale(body_art, Vector2(platform_width / SPRITE_WIDTH, 0.88))


func _build_props() -> void:
	if has_spring:
		spring_node = Node2D.new()
		SpriteShadow.add_pair(spring_node, SPRING_TEXTURE, Vector2(2.0, 3.0), 0.18)
		spring_node.scale = SPRING_BASE_SCALE
		spring_node.position = Vector2(-platform_width * 0.24, SPRING_BASE_Y)
		spring_node.z_index = 4
		add_child(spring_node)

	if has_launcher:
		launcher_node = Node2D.new()
		SpriteShadow.add_pair(launcher_node, LAUNCHER_TEXTURE, Vector2(3.0, 4.0), 0.16)
		launcher_node.scale = Vector2(-launcher_dir * LAUNCHER_BASE_SCALE.x, LAUNCHER_BASE_SCALE.y)
		launcher_node.position = Vector2(launcher_offset, LAUNCHER_BASE_Y)
		launcher_node.z_index = 5
		add_child(launcher_node)


func _update_spring(delta: float) -> void:
	if not has_spring or spring_node == null:
		return

	spring_compress = max(0.0, spring_compress - delta * 5.2)
	spring_node.scale = Vector2(
		SPRING_BASE_SCALE.x * (1.0 + spring_compress * 0.22),
		SPRING_BASE_SCALE.y * (1.0 - spring_compress * 0.52)
	)
	var current_height := SPRING_VISUAL_HEIGHT * (1.0 - spring_compress * 0.52)
	spring_node.position.y = SPRING_SEAT_Y - current_height * 0.5


func _update_launcher(delta: float) -> void:
	if not has_launcher or launcher_node == null:
		return

	launcher_charge = max(0.0, launcher_charge - delta * 4.0)
	var shake: float = sin(launcher_charge * TAU * 3.0) * launcher_charge
	launcher_node.position.y = LAUNCHER_BASE_Y + launcher_charge * 8.0
	launcher_node.scale = Vector2(
		-launcher_dir * LAUNCHER_BASE_SCALE.x * (1.0 + launcher_charge * 0.16),
		LAUNCHER_BASE_SCALE.y * (1.0 - launcher_charge * 0.22)
	)
	launcher_node.rotation = deg_to_rad(launcher_dir * shake * 3.5)
