extends Control
class_name GameOverScreen

signal retry_pressed

@onready var title_label: Label = $TitleLabel
@onready var game_over_score_label: Label = $ScoreLabel
@onready var game_over_best_label: Label = $BestLabel
@onready var retry_button: TextureRect = $RetryButton
@onready var retry_label: Label = $RetryButton/RetryLabel

var retry_button_tween: Tween
var retry_button_armed := false
var doodle_font: Font


func _ready() -> void:
	doodle_font = _create_doodle_font()
	_apply_text_style()
	retry_button.gui_input.connect(Callable(self, "_on_retry_button_gui_input"))
	retry_button.mouse_exited.connect(Callable(self, "_on_retry_button_mouse_exited"))
	hide_page()


func show_results(score: int, best_score: int) -> void:
	game_over_score_label.text = "Score " + str(score)
	game_over_best_label.text = "Best " + str(best_score)
	reset_button()
	visible = true


func hide_page() -> void:
	reset_button()
	visible = false


func reset_button() -> void:
	retry_button_armed = false
	if retry_button_tween != null and retry_button_tween.is_valid():
		retry_button_tween.kill()
	if retry_button != null:
		retry_button.scale = Vector2.ONE
		retry_button.rotation = 0.0


func _apply_text_style() -> void:
	title_label.add_theme_font_override("font", doodle_font)
	title_label.add_theme_font_size_override("font_size", 58)
	title_label.add_theme_color_override("font_color", Color("#E84D3D"))
	title_label.add_theme_color_override("font_outline_color", Color("#FFFFFF"))
	title_label.add_theme_constant_override("outline_size", 8)
	title_label.add_theme_color_override("font_shadow_color", Color(0.05, 0.08, 0.10, 0.25))
	title_label.add_theme_constant_override("shadow_offset_x", 3)
	title_label.add_theme_constant_override("shadow_offset_y", 4)

	game_over_score_label.add_theme_font_override("font", doodle_font)
	game_over_score_label.add_theme_font_size_override("font_size", 34)
	game_over_score_label.add_theme_color_override("font_color", Color("#159C83"))
	game_over_score_label.add_theme_color_override("font_outline_color", Color("#FFFFFF"))
	game_over_score_label.add_theme_constant_override("outline_size", 5)

	game_over_best_label.add_theme_font_override("font", doodle_font)
	game_over_best_label.add_theme_font_size_override("font_size", 24)
	game_over_best_label.add_theme_color_override("font_color", Color("#496780"))
	game_over_best_label.add_theme_color_override("font_outline_color", Color("#FFFFFF"))
	game_over_best_label.add_theme_constant_override("outline_size", 4)

	retry_label.add_theme_font_override("font", doodle_font)
	retry_label.add_theme_font_size_override("font_size", 27)
	retry_label.add_theme_color_override("font_color", Color("#23364A"))
	retry_label.add_theme_color_override("font_outline_color", Color("#FFFFFF"))
	retry_label.add_theme_constant_override("outline_size", 3)


func _on_retry_button_gui_input(event: InputEvent) -> void:
	if not visible or not event is InputEventMouseButton:
		return

	if event.button_index != MOUSE_BUTTON_LEFT:
		return

	if event.pressed:
		retry_button_armed = true
		_set_retry_button_pressed(true)
	else:
		var should_retry := retry_button_armed
		retry_button_armed = false
		_set_retry_button_pressed(false)
		if should_retry:
			retry_pressed.emit()


func _on_retry_button_mouse_exited() -> void:
	retry_button_armed = false
	_set_retry_button_pressed(false)


func _set_retry_button_pressed(pressed: bool) -> void:
	if retry_button == null:
		return

	if retry_button_tween != null and retry_button_tween.is_valid():
		retry_button_tween.kill()

	var target_scale := Vector2(0.92, 0.92) if pressed else Vector2.ONE
	var target_rotation := deg_to_rad(-2.5) if pressed else 0.0
	retry_button_tween = create_tween()
	retry_button_tween.set_parallel(true)
	retry_button_tween.tween_property(retry_button, "scale", target_scale, 0.06)
	retry_button_tween.tween_property(retry_button, "rotation", target_rotation, 0.06)


func _create_doodle_font() -> Font:
	var font := SystemFont.new()
	font.font_names = PackedStringArray(["Marker Felt", "Chalkboard SE", "Comic Sans MS"])
	return font
