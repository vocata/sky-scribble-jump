extends Control
class_name GameHUD

const GAME_WIDTH := 480.0
const HUD_HEIGHT := 58.0

var score_label: Label
var best_label: Label
var message_label: Label


func _ready() -> void:
	size = Vector2(GAME_WIDTH, 720.0)
	_build_hud()


func set_scores(score: int, best_score: int) -> void:
	score_label.text = str(score)
	best_label.text = "BEST " + str(best_score)


func show_pause(paused: bool) -> void:
	message_label.visible = paused
	message_label.text = "PAUSED\nPress P to continue"


func hide_message() -> void:
	message_label.visible = false


func _build_hud() -> void:
	var hud_back := ColorRect.new()
	hud_back.color = Color(1.0, 1.0, 1.0, 0.72)
	hud_back.size = Vector2(GAME_WIDTH, HUD_HEIGHT)
	add_child(hud_back)

	score_label = Label.new()
	score_label.position = Vector2(18, 14)
	score_label.size = Vector2(220, 42)
	score_label.add_theme_font_size_override("font_size", 30)
	score_label.add_theme_color_override("font_color", Color("#23364A"))
	add_child(score_label)

	best_label = Label.new()
	best_label.position = Vector2(260, 18)
	best_label.size = Vector2(200, 34)
	best_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	best_label.add_theme_font_size_override("font_size", 18)
	best_label.add_theme_color_override("font_color", Color("#496780"))
	add_child(best_label)

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
	add_child(message_label)
	hide_message()
