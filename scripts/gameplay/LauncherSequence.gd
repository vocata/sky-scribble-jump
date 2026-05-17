extends Node
class_name LauncherSequence

signal entered(entry_pos: Vector2)
signal fired(entry_pos: Vector2)

var active := false
var timer := 0.0
var player: Player
var tuning: GameTuning
var start_pos := Vector2.ZERO
var entry_pos := Vector2.ZERO
var hidden_pos := Vector2.ZERO
var fire_dir := 1.0
var active_platform: JumpPlatform


func setup(controlled_player: Player, game_tuning: GameTuning) -> void:
	player = controlled_player
	tuning = game_tuning


func reset() -> void:
	active = false
	timer = 0.0
	active_platform = null


func start(platform: JumpPlatform, launcher_entry_pos: Vector2, launch_dir: float) -> void:
	active = true
	timer = 0.0
	start_pos = player.position
	entry_pos = launcher_entry_pos
	hidden_pos = entry_pos + Vector2(launch_dir * 7.0, 17.0)
	fire_dir = launch_dir
	active_platform = platform
	active_platform.set_launcher_charge(0.0)
	player.begin_launcher_entry()
	entered.emit(entry_pos)


func update_sequence(delta: float) -> void:
	timer += delta

	if is_instance_valid(active_platform) and not active_platform.broken:
		entry_pos = active_platform.get_launcher_entry_position()
		hidden_pos = entry_pos + Vector2(fire_dir * 7.0, 17.0)

	if timer <= tuning.launcher_enter_time:
		var t: float = clamp(timer / tuning.launcher_enter_time, 0.0, 1.0)
		var eased: float = t * t * (3.0 - 2.0 * t)
		player.show_launcher_entry(
			start_pos.lerp(hidden_pos, eased),
			Vector2.ONE.lerp(Vector2(0.20, 0.20), eased),
			lerp(player.rotation, deg_to_rad(fire_dir * 18.0), 0.34),
			6 if t < 0.62 else 4
		)
		return

	player.hide_inside_launcher()

	var charge_t: float = clamp((timer - tuning.launcher_enter_time) / tuning.launcher_charge_time, 0.0, 1.0)
	var charge_eased: float = charge_t * charge_t * (3.0 - 2.0 * charge_t)
	if is_instance_valid(active_platform):
		active_platform.set_launcher_charge(charge_eased)

	if charge_t >= 1.0:
		_fire()


func _fire() -> void:
	active = false
	player.fire_from_launcher(
		entry_pos + Vector2(fire_dir * 14.0, -8.0),
		Vector2(fire_dir * tuning.launcher_side_speed, tuning.launcher_speed),
		deg_to_rad(fire_dir * 16.0)
	)
	if is_instance_valid(active_platform):
		active_platform.set_launcher_charge(1.0)
	fired.emit(entry_pos)
