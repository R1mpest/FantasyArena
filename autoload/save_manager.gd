extends Node
## Настройки игры: экран, громкость, прицеливание. Хранятся в user://settings.cfg
## и применяются при запуске. Позже сюда же ляжет статистика забегов (Ф16).

signal settings_changed

const PATH := "user://settings.cfg"
const RESOLUTIONS := [Vector2i(1280, 720), Vector2i(1366, 768), Vector2i(1600, 900), Vector2i(1920, 1080), Vector2i(2560, 1440)]
const BUSES := [&"Master", &"Music", &"SFX"]

enum WindowMode { WINDOWED, FULLSCREEN, BORDERLESS }
enum AimMode { AUTO, MOUSE }

var resolution := Vector2i(1280, 720)
var window_mode := WindowMode.WINDOWED
## Громкость шины, 0..1.
var volumes := {&"Master": 0.8, &"Music": 0.7, &"SFX": 0.8}
var aim_mode := AimMode.AUTO


func _ready() -> void:
	_ensure_buses()
	load_from(PATH)
	apply_all()


func save() -> void:
	save_to(PATH)


func save_to(path: String) -> void:
	var config := ConfigFile.new()
	config.set_value("display", "resolution", resolution)
	config.set_value("display", "window_mode", window_mode)
	for bus in BUSES:
		config.set_value("audio", bus, volumes[bus])
	config.set_value("controls", "aim_mode", aim_mode)
	config.save(path)


func load_from(path: String) -> void:
	var config := ConfigFile.new()
	if config.load(path) != OK:
		return
	resolution = config.get_value("display", "resolution", resolution)
	window_mode = clampi(config.get_value("display", "window_mode", window_mode), 0, WindowMode.size() - 1)
	for bus in BUSES:
		volumes[bus] = clampf(config.get_value("audio", bus, volumes[bus]), 0.0, 1.0)
	aim_mode = clampi(config.get_value("controls", "aim_mode", aim_mode), 0, AimMode.size() - 1)


func apply_all() -> void:
	apply_display()
	for bus in BUSES:
		_apply_volume(bus)
	settings_changed.emit()


## Разрешения, которые помещаются на текущий экран.
func available_resolutions() -> Array:
	if DisplayServer.get_name() == "headless":
		return RESOLUTIONS
	var screen := DisplayServer.screen_get_size(DisplayServer.window_get_current_screen())
	return RESOLUTIONS.filter(func(size: Vector2i) -> bool: return size.x <= screen.x and size.y <= screen.y)


func set_window_mode(mode: WindowMode) -> void:
	window_mode = mode
	apply_display()
	_changed()


func set_resolution(size: Vector2i) -> void:
	resolution = size
	apply_display()
	_changed()


func set_volume(bus: StringName, value: float) -> void:
	volumes[bus] = clampf(value, 0.0, 1.0)
	_apply_volume(bus)
	_changed()


func set_aim_mode(mode: AimMode) -> void:
	aim_mode = mode
	_changed()


func apply_display() -> void:
	if DisplayServer.get_name() == "headless":
		return
	match window_mode:
		WindowMode.FULLSCREEN:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)
		WindowMode.BORDERLESS:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		_:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
			DisplayServer.window_set_size(resolution)
			var screen := DisplayServer.window_get_current_screen()
			var origin := DisplayServer.screen_get_position(screen)
			var free_space := DisplayServer.screen_get_size(screen) - resolution
			DisplayServer.window_set_position(origin + free_space / 2)


func _changed() -> void:
	save()
	settings_changed.emit()


func _apply_volume(bus: StringName) -> void:
	var index := AudioServer.get_bus_index(bus)
	var value: float = volumes[bus]
	AudioServer.set_bus_mute(index, value <= 0.001)
	AudioServer.set_bus_volume_db(index, linear_to_db(maxf(value, 0.001)))


## Шины Music и SFX создаются в коде, чтобы не держать отдельный файл раскладки.
func _ensure_buses() -> void:
	for bus in BUSES:
		if AudioServer.get_bus_index(bus) == -1:
			AudioServer.add_bus()
			var index := AudioServer.bus_count - 1
			AudioServer.set_bus_name(index, bus)
			AudioServer.set_bus_send(index, &"Master")
