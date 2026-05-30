extends Node2D
class_name Player

const HALF_W := 24.0
const HALF_H := 28.0
const BASE_SCALE := Vector2(0.92, 0.92)
const AIR_CONTROL := 2300.0
const GROUND_AIR_BRAKE := 3600.0
const BASE_SPEED_X := 230.0
const SPEED_TILT_REF := 520.0
const HOLD_LOG_GROWTH := 14.0
const HOLD_LOG_BOOST := 185.0
const SPRING_SPEED_REF := -1120.0
const TEXTURE := preload("res://assets/art/characters/player.png")
const FIRE_BOOTS_TEXTURES := [
	preload("res://assets/art/characters/player_fire_boots_flame_short.png"),
	preload("res://assets/art/characters/player_fire_boots_flame_long.png"),
]
const FIRE_BOOTS_BASE_SCALE := BASE_SCALE
const FIRE_BOOTS_ART_OFFSET := Vector2(-1.0, 22.0)
const FIRE_BOOTS_FRAME_TIME := 0.08

var velocity := Vector2.ZERO
var squash_time := 0.0
var move_hold_time := 0.0
var move_hold_dir := 0.0
var fire_boots_time := 0.0
var fire_boots_anim_time := 0.0

var art: Sprite2D


func _ready() -> void:
	art = SpriteShadow.add_pair(self, TEXTURE, Vector2(3.0, 5.0), 0.18)
	art.scale = BASE_SCALE


func reset_to(start_position: Vector2) -> void:
	position = start_position
	velocity = Vector2.ZERO
	squash_time = 0.0
	move_hold_time = 0.0
	move_hold_dir = 0.0
	fire_boots_time = 0.0
	fire_boots_anim_time = 0.0
	scale = Vector2.ONE
	rotation = 0.0
	z_index = 20
	visible = true
	_set_player_texture(TEXTURE)
	update_visual(0.0)


func clear_input_hold() -> void:
	move_hold_time = 0.0
	move_hold_dir = 0.0


func handle_movement(delta: float, game_width: float) -> void:
	var input_dir := 0.0
	if Input.is_key_pressed(KEY_LEFT) or Input.is_key_pressed(KEY_A):
		input_dir -= 1.0
	if Input.is_key_pressed(KEY_RIGHT) or Input.is_key_pressed(KEY_D):
		input_dir += 1.0

	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		var mouse_x := get_viewport().get_mouse_position().x
		input_dir = sign(mouse_x - game_width * 0.5)

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
	elif sign(velocity.x) != input_dir and abs(velocity.x) > 12.0:
		accel = GROUND_AIR_BRAKE
	velocity.x = move_toward(velocity.x, input_dir * target_speed, accel * delta)


func update_motion(delta: float, gravity: float, game_width: float) -> void:
	velocity.y += gravity * delta
	position += velocity * delta

	if position.x < -HALF_W:
		position.x = game_width + HALF_W
	elif position.x > game_width + HALF_W:
		position.x = -HALF_W

	rotation = lerp(rotation, clamp(velocity.x / SPEED_TILT_REF, -1.0, 1.0) * 0.10, 0.18)


func bounce(vertical_speed: float, squash_duration: float) -> void:
	velocity.y = vertical_speed
	squash_time = squash_duration


func activate_fire_boots(duration: float) -> void:
	fire_boots_time = max(fire_boots_time, duration)
	fire_boots_anim_time = 0.0
	squash_time = 0.0
	_set_fire_boots_frame()


func update_fire_boots(delta: float, thrust_speed: float) -> void:
	if fire_boots_time <= 0.0:
		return

	fire_boots_time = max(0.0, fire_boots_time - delta)
	if fire_boots_time <= 0.0:
		_set_player_texture(TEXTURE)
		return

	fire_boots_anim_time += delta
	velocity.y = thrust_speed
	_set_fire_boots_frame()


func is_fire_boots_active() -> bool:
	return fire_boots_time > 0.0


func set_feet_y(feet_y: float) -> void:
	position.y = feet_y - HALF_H


func begin_launcher_entry() -> void:
	velocity = Vector2.ZERO
	clear_input_hold()
	fire_boots_time = 0.0
	_set_player_texture(TEXTURE)
	scale = Vector2.ONE
	z_index = 6
	visible = true


func show_launcher_entry(entry_position: Vector2, entry_scale: Vector2, entry_rotation: float, entry_z_index: int) -> void:
	position = entry_position
	scale = entry_scale
	rotation = entry_rotation
	z_index = entry_z_index
	visible = true


func hide_inside_launcher() -> void:
	visible = false
	scale = Vector2.ONE


func fire_from_launcher(start_position: Vector2, launch_velocity: Vector2, launch_rotation: float) -> void:
	visible = true
	scale = Vector2.ONE
	z_index = 20
	position = start_position
	velocity = launch_velocity
	rotation = launch_rotation
	squash_time = 0.28


func update_visual(delta: float) -> void:
	if art == null:
		return

	squash_time = max(0.0, squash_time - delta)
	var squash_strength: float = squash_time / 0.16
	var velocity_stretch: float = clamp(-velocity.y / abs(SPRING_SPEED_REF), -0.18, 0.18)
	var base_scale := FIRE_BOOTS_BASE_SCALE if is_fire_boots_active() else BASE_SCALE
	SpriteShadow.set_pair_position(art, FIRE_BOOTS_ART_OFFSET if is_fire_boots_active() else Vector2.ZERO)
	SpriteShadow.set_pair_scale(art, base_scale * Vector2(
		1.0 + squash_strength * 0.10 - velocity_stretch * 0.08,
		1.0 - squash_strength * 0.12 + velocity_stretch * 0.10
	))


func _set_fire_boots_frame() -> void:
	var frame_index := int(floor(fire_boots_anim_time / FIRE_BOOTS_FRAME_TIME)) % FIRE_BOOTS_TEXTURES.size()
	_set_player_texture(FIRE_BOOTS_TEXTURES[frame_index])


func _set_player_texture(texture: Texture2D) -> void:
	if art == null:
		return
	SpriteShadow.set_pair_texture(art, texture)
