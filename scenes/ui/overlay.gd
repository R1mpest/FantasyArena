class_name Overlay
extends CanvasLayer
## Пауза (Esc) и экран поражения со статистикой забега.

enum Mode { NONE, PAUSE, DEAD }

var _mode := Mode.NONE
var _root: Control
var _title: Label
var _stats: Label
var _button: Button


func _ready() -> void:
	layer = 30
	process_mode = Node.PROCESS_MODE_ALWAYS
	var parts := UiKit.modal()
	_root = parts[0]
	var box: VBoxContainer = parts[1]
	_title = UiKit.label("", 16, HORIZONTAL_ALIGNMENT_CENTER)
	box.add_child(_title)
	_stats = UiKit.label("", 10, HORIZONTAL_ALIGNMENT_CENTER)
	box.add_child(_stats)
	_button = UiKit.button("")
	_button.alignment = HORIZONTAL_ALIGNMENT_CENTER
	_button.pressed.connect(_on_button_pressed)
	box.add_child(_button)
	add_child(_root)
	_root.hide()
	EventBus.player_died.connect(_show.bind(Mode.DEAD))


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"ui_cancel"):
		if _mode == Mode.NONE and not get_tree().paused:
			_show(Mode.PAUSE)
		elif _mode == Mode.PAUSE:
			_hide()
		get_viewport().set_input_as_handled()
	elif _mode == Mode.DEAD and event is InputEventKey and event.pressed and event.physical_keycode == KEY_R:
		_restart()


func _show(mode: Mode) -> void:
	_mode = mode
	get_tree().paused = true
	_title.text = "Пауза" if mode == Mode.PAUSE else "Поражение"
	_button.text = "Продолжить (Esc)" if mode == Mode.PAUSE else "Заново (R)"
	_stats.text = "Время: %s\nУровень: %d\nУбито: %d" % [GameState.format_time(), GameState.level, GameState.kills]
	_root.show()
	_button.grab_focus()


func _hide() -> void:
	_mode = Mode.NONE
	_root.hide()
	get_tree().paused = false


func _on_button_pressed() -> void:
	if _mode == Mode.PAUSE:
		_hide()
	else:
		_restart()


func _restart() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()
