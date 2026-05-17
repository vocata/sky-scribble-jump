extends Control
class_name GameOverScreen

signal retry_pressed

const GAME_WIDTH := 480.0
const GAME_HEIGHT := 720.0
const GAME_OVER_TEXTURE := preload("res://assets/art/screens/game_over_screen.png")
const GAME_OVER_PANEL_TEXTURE := preload("res://assets/art/ui/panel_game_over.png")
const RETRY_BUTTON_TEXTURE := preload("res://assets/art/ui/button_retry.png")

var game_over_score_label: Label
var game_over_best_label: Label
var retry_button: TextureRect
var retry_button_tween: Tween
var retry_button_armed := false
var doodle_font: Font


func _ready() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_STOP
	size = Vector2(GAME_WIDTH, GAME_HEIGHT)
	doodle_font = _create_doodle_font()
	_build_screen()


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


func _build_screen() -> void:
	var page_background := TextureRect.new()
	page_background.texture = GAME_OVER_TEXTURE
	page_background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	page_background.stretch_mode = TextureRect.STRETCH_SCALE
	page_background.size = Vector2(GAME_WIDTH, GAME_HEIGHT)
	page_background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(page_background)

	var panel := TextureRect.new()
	panel.texture = GAME_OVER_PANEL_TEXTURE
	panel.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	panel.stretch_mode = TextureRect.STRETCH_SCALE
	panel.position = Vector2(34, 132)
	panel.size = Vector2(412, 282)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(panel)

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
	add_child(title_label)

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
	add_child(game_over_score_label)

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
	add_child(game_over_best_label)

	retry_button = TextureRect.new()
	retry_button.texture = RETRY_BUTTON_TEXTURE
	retry_button.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	retry_button.stretch_mode = TextureRect.STRETCH_SCALE
	retry_button.position = Vector2(126, 438)
	retry_button.size = Vector2(228, 82)
	retry_button.pivot_offset = retry_button.size * 0.5
	retry_button.mouse_filter = Control.MOUSE_FILTER_STOP
	retry_button.gui_input.connect(Callable(self, "_on_retry_button_gui_input"))
	retry_button.mouse_exited.connect(Callable(self, "_on_retry_button_mouse_exited"))
	add_child(retry_button)

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
