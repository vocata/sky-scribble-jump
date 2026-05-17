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

var velocity := Vector2.ZERO
var squash_time := 0.0
var move_hold_time := 0.0
var move_hold_dir := 0.0

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
	scale = Vector2.ONE
	rotation = 0.0
	z_index = 20
	visible = true
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


func set_feet_y(feet_y: float) -> void:
	position.y = feet_y - HALF_H


func begin_launcher_entry() -> void:
	velocity = Vector2.ZERO
	clear_input_hold()
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
	SpriteShadow.set_pair_scale(art, BASE_SCALE * Vector2(
		1.0 + squash_strength * 0.10 - velocity_stretch * 0.08,
		1.0 - squash_strength * 0.12 + velocity_stretch * 0.10
	))
