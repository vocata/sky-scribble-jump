extends Control
class_name GameHUD

@onready var score_label: Label = $ScoreLabel
@onready var best_label: Label = $BestLabel
@onready var message_label: Label = $MessageLabel


func _ready() -> void:
	score_label.add_theme_font_size_override("font_size", 30)
	score_label.add_theme_color_override("font_color", Color("#23364A"))

	best_label.add_theme_font_size_override("font_size", 18)
	best_label.add_theme_color_override("font_color", Color("#496780"))

	message_label.add_theme_font_size_override("font_size", 26)
	message_label.add_theme_color_override("font_color", Color("#23364A"))
	message_label.add_theme_color_override("font_shadow_color", Color(1, 1, 1, 0.8))
	message_label.add_theme_constant_override("shadow_offset_x", 2)
	message_label.add_theme_constant_override("shadow_offset_y", 2)
	hide_message()


func set_scores(score: int, best_score: int) -> void:
	score_label.text = str(score)
	best_label.text = "BEST " + str(best_score)


func show_pause(paused: bool) -> void:
	message_label.visible = paused
	message_label.text = "PAUSED\nPress P to continue"


func hide_message() -> void:
	message_label.visible = false
