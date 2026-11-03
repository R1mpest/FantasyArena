class_name TouchControls
extends CanvasLayer
## Управление с сенсорного экрана: плавающий джойстик движения (палец в левой половине
## экрана), в ручном прицеливании — второй джойстик в правой половине, и кнопка паузы
## в правом нижнем углу. Джойстик движения нажимает те же действия move_*, что
## и клавиатура, поэтому герой о нём ничего не знает. Системная кнопка «Назад» Android
## работает как Esc.

const RADIUS := 26.0
const DEAD_ZONE := 6.0
const RING_COLOR := Color(1, 1, 1, 0.35)
const KNOB_COLOR := Color(1, 0.85, 0.4, 0.55)
const AIM_COLOR := Color(0.85, 0.95, 1.0, 0.55)
const ACTIONS := [&"move_right", &"move_left", &"move_down", &"move_up"]

## Направление правого джойстика (ZERO — палец не держит прицел). Читает магический снаряд.
static var aim := Vector2.ZERO

## Индекс пальца, который держит джойстик (-1 — никто).
var _finger := -1
var _origin := Vector2.ZERO
var _knob := Vector2.ZERO
var _aim_finger := -1
var _aim_origin := Vector2.ZERO
var _aim_knob := Vector2.ZERO
var _pad: Control
var _pause: Button


## Сенсорное управление нужно на телефоне; ключ --touch включает его на компьютере для проверки.
static func wanted() -> bool:
	return OS.has_feature("mobile") or "--touch" in OS.get_cmdline_user_args()


func _ready() -> void:
	layer = 15
	_pad = Control.new()
	_pad.set_anchors_preset(Control.PRESET_FULL_RECT)
	_pad.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_pad.draw.connect(_draw_pad)
	add_child(_pad)

	_pause = UiKit.button("II")
	_pause.custom_minimum_size = Vector2(30, 26)
	_pause.focus_mode = Control.FOCUS_NONE
	_pause.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	_pause.position = Vector2(-38, -34)
	_pause.pressed.connect(_send_cancel)
	_pad.add_child(_pause)
	aim = Vector2.ZERO


func _exit_tree() -> void:
	aim = Vector2.ZERO


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		_send_cancel()
	elif what == NOTIFICATION_PAUSED:
		_release()
		_release_aim()


func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		var left := touch.position.x < _pad.size.x * 0.5
		if touch.pressed and _finger < 0 and left:
			_finger = touch.index
			_origin = touch.position
			_knob = touch.position
			_pad.queue_redraw()
		elif touch.pressed and _aim_finger < 0 and not left and _manual_aim() \
				and not _pause.get_global_rect().has_point(touch.position):
			_aim_finger = touch.index
			_aim_origin = touch.position
			_aim_knob = touch.position
			_pad.queue_redraw()
		elif not touch.pressed and touch.index == _finger:
			_release()
		elif not touch.pressed and touch.index == _aim_finger:
			_release_aim()
	elif event is InputEventScreenDrag:
		var drag := event as InputEventScreenDrag
		if drag.index == _finger:
			_steer(drag.position)
		elif drag.index == _aim_finger:
			_aim_at(drag.position)


func _steer(at: Vector2) -> void:
	var offset := (at - _origin).limit_length(RADIUS)
	_knob = _origin + offset
	_pad.queue_redraw()
	if offset.length() < DEAD_ZONE:
		_press(Vector2.ZERO)
		return
	# Обе оси растягиваем так, чтобы бо́льшая была 1: герой всегда бежит в полную силу,
	# а меньшая ось реже проваливается в мёртвую зону действий (0,2).
	var direction := offset / maxf(absf(offset.x), absf(offset.y))
	_press(direction)


## Прицел держит последнее направление, пока палец не отпущен; мёртвая зона — как у движения.
func _aim_at(at: Vector2) -> void:
	var offset := (at - _aim_origin).limit_length(RADIUS)
	_aim_knob = _aim_origin + offset
	_pad.queue_redraw()
	if offset.length() >= DEAD_ZONE:
		aim = offset.normalized()


func _release_aim() -> void:
	_aim_finger = -1
	aim = Vector2.ZERO
	_pad.queue_redraw()


func _manual_aim() -> bool:
	return SaveManager.aim_mode == SaveManager.AimMode.MOUSE


func _press(direction: Vector2) -> void:
	var values := [direction.x, -direction.x, direction.y, -direction.y]
	for i in ACTIONS.size():
		if values[i] > 0.0:
			Input.action_press(ACTIONS[i], minf(values[i], 1.0))
		else:
			Input.action_release(ACTIONS[i])


func _release() -> void:
	_finger = -1
	_press(Vector2.ZERO)
	_pad.queue_redraw()


func _send_cancel() -> void:
	var event := InputEventAction.new()
	event.action = &"ui_cancel"
	event.pressed = true
	Input.parse_input_event(event)


func _draw_pad() -> void:
	if _finger >= 0:
		_pad.draw_arc(_origin, RADIUS, 0.0, TAU, 32, RING_COLOR, 1.0)
		_pad.draw_circle(_knob, 8.0, KNOB_COLOR)
	if _aim_finger >= 0:
		_pad.draw_arc(_aim_origin, RADIUS, 0.0, TAU, 32, RING_COLOR, 1.0)
		_pad.draw_circle(_aim_knob, 8.0, AIM_COLOR)
