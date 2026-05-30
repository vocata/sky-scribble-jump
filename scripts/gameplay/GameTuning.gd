extends Resource
class_name GameTuning

@export_group("Stage")
@export var game_width := 480.0
@export var game_height := 720.0
@export var player_start_pos := Vector2(240.0, 610.0)
@export var camera_follow_offset := 116.0
@export var death_margin_ratio := 0.58
@export var cleanup_margin := 180.0

@export_group("Physics")
@export var gravity := 980.0
@export var jump_speed := -620.0
@export var spring_speed := -1120.0
@export var spring_hit_radius := 38.0
@export var launcher_hit_radius := 28.0

@export_group("Launcher")
@export var launcher_speed := -1420.0
@export var launcher_side_speed := 260.0
@export var launcher_enter_time := 0.20
@export var launcher_charge_time := 0.48

@export_group("Fire Boots")
@export var fire_boots_duration := 1.8
@export var fire_boots_speed := -860.0
@export var fire_boots_hit_radius := 42.0

@export_group("Platforms")
@export var initial_highest_platform_y := 680.0
@export var starting_platform_y := 666.0
@export var starting_platform_width := 108.0
@export var initial_fill_top_y := -360.0
@export var generation_ahead := 760.0
@export var min_edge_padding := 10.0
@export var moving_platform_min_speed := 55.0
@export var moving_platform_max_speed := 105.0
@export var moving_platform_edge_padding := 8.0

@export_group("Scoring")
@export var difficulty_score_span := 2400.0
@export var score_scale := 0.55
