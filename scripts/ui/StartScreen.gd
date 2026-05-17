extends Control
class_name StartScreen

signal start_pressed

const GAME_WIDTH := 480.0
const GAME_HEIGHT := 720.0
const START_SCREEN_TEXTURE := preload("res://assets/art/screens/start_screen.png")
const START_BUTTON_TEXTURE := preload("res://assets/art/ui/button_start.png")

var start_button: TextureRect
var start_button_tween: Tween
var start_button_armed := false
var doodle_font: Font


func _ready() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_STOP
	size = Vector2(GAME_WIDTH, GAME_HEIGHT)
	doodle_font = _create_doodle_font()
	_build_screen()


func show_page() -> void:
	reset_button()
	visible = true


func hide_page() -> void:
	reset_button()
	visible = false


func reset_button() -> void:
	start_button_armed = false
	if start_button_tween != null and start_button_tween.is_valid():
		start_button_tween.kill()
	if start_button != null:
		start_button.scale = Vector2.ONE
		start_button.rotation = 0.0


func _build_screen() -> void:
	var page_background := TextureRect.new()
	page_background.texture = START_SCREEN_TEXTURE
	page_background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	page_background.stretch_mode = TextureRect.STRETCH_SCALE
	page_background.size = Vector2(GAME_WIDTH, GAME_HEIGHT)
	page_background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(page_background)

	var title_label := Label.new()
	title_label.text = "Sky Scribble\nJump"
	title_label.position = Vector2(42, 126)
	title_label.size = Vector2(396, 132)
	title_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title_label.add_theme_font_override("font", doodle_font)
	title_label.add_theme_font_size_override("font_size", 46)
	title_label.add_theme_color_override("font_color", Color("#E84D3D"))
	title_label.add_theme_color_override("font_outline_color", Color("#FFFFFF"))
	title_label.add_theme_constant_override("outline_size", 8)
	title_label.add_theme_color_override("font_shadow_color", Color(0.05, 0.08, 0.10, 0.25))
	title_label.add_theme_constant_override("shadow_offset_x", 3)
	title_label.add_theme_constant_override("shadow_offset_y", 4)
	add_child(title_label)

	start_button = TextureRect.new()
	start_button.texture = START_BUTTON_TEXTURE
	start_button.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	start_button.stretch_mode = TextureRect.STRETCH_SCALE
	start_button.position = Vector2(90, 416)
	start_button.size = Vector2(300, 112)
	start_button.pivot_offset = start_button.size * 0.5
	start_button.mouse_filter = Control.MOUSE_FILTER_STOP
	start_button.gui_input.connect(Callable(self, "_on_start_button_gui_input"))
	start_button.mouse_exited.connect(Callable(self, "_on_start_button_mouse_exited"))
	add_child(start_button)

	var start_label := Label.new()
	start_label.text = "Start"
	start_label.size = start_button.size
	start_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	start_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	start_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	start_label.add_theme_font_override("font", doodle_font)
	start_label.add_theme_font_size_override("font_size", 34)
	start_label.add_theme_color_override("font_color", Color("#23364A"))
	start_label.add_theme_color_override("font_outline_color", Color("#FFFFFF"))
	start_label.add_theme_constant_override("outline_size", 4)
	start_button.add_child(start_label)


func _on_start_button_gui_input(event: InputEvent) -> void:
	if not visible or not event is InputEventMouseButton:
		return

	if event.button_index != MOUSE_BUTTON_LEFT:
		return

	if event.pressed:
		start_button_armed = true
		_set_start_button_pressed(true)
	else:
		var should_start := start_button_armed
		start_button_armed = false
		_set_start_button_pressed(false)
		if should_start:
			start_pressed.emit()


func _on_start_button_mouse_exited() -> void:
	start_button_armed = false
	_set_start_button_pressed(false)


func _set_start_button_pressed(pressed: bool) -> void:
	if start_button == null:
		return

	if start_button_tween != null and start_button_tween.is_valid():
		start_button_tween.kill()

	var target_scale := Vector2(0.92, 0.92) if pressed else Vector2.ONE
	var target_rotation := deg_to_rad(2.5) if pressed else 0.0
	start_button_tween = create_tween()
	start_button_tween.set_parallel(true)
	start_button_tween.tween_property(start_button, "scale", target_scale, 0.06)
	start_button_tween.tween_property(start_button, "rotation", target_rotation, 0.06)


func _create_doodle_font() -> Font:
	var font := SystemFont.new()
	font.font_names = PackedStringArray(["Marker Felt", "Chalkboard SE", "Comic Sans MS"])
	return font
