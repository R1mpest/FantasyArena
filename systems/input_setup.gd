class_name InputSetup
extends RefCounted
## Действия управления: WASD, стрелки, крестовина и левый стик геймпада. Кнопки геймпада
## для интерфейса: в Godot 4.7 у ui_accept и ui_cancel по умолчанию есть только клавиши,
## поэтому A, B и Start добавляем сами (A — нажать, B — назад, Start — пауза).


static func ensure() -> void:
	_add(&"move_left", [KEY_A, KEY_LEFT], JOY_AXIS_LEFT_X, -1.0, JOY_BUTTON_DPAD_LEFT)
	_add(&"move_right", [KEY_D, KEY_RIGHT], JOY_AXIS_LEFT_X, 1.0, JOY_BUTTON_DPAD_RIGHT)
	_add(&"move_up", [KEY_W, KEY_UP], JOY_AXIS_LEFT_Y, -1.0, JOY_BUTTON_DPAD_UP)
	_add(&"move_down", [KEY_S, KEY_DOWN], JOY_AXIS_LEFT_Y, 1.0, JOY_BUTTON_DPAD_DOWN)
	_add_button(&"ui_accept", JOY_BUTTON_A)
	_add_button(&"ui_cancel", JOY_BUTTON_B)
	_add_button(&"ui_cancel", JOY_BUTTON_START)


static func _add(action: StringName, keys: Array, axis: JoyAxis, axis_value: float, dpad: JoyButton) -> void:
	if InputMap.has_action(action):
		return
	InputMap.add_action(action, 0.2)
	for key: Key in keys:
		var key_event := InputEventKey.new()
		key_event.physical_keycode = key
		InputMap.action_add_event(action, key_event)
	var joy_event := InputEventJoypadMotion.new()
	joy_event.axis = axis
	joy_event.axis_value = axis_value
	InputMap.action_add_event(action, joy_event)
	_add_button(action, dpad)


## Кнопка геймпада (любого: device = -1) на действие; повторный вызов ничего не добавляет.
static func _add_button(action: StringName, button: JoyButton) -> void:
	var event := InputEventJoypadButton.new()
	event.button_index = button
	event.device = -1
	if not InputMap.action_has_event(action, event):
		InputMap.action_add_event(action, event)
