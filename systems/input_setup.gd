class_name InputSetup
extends RefCounted
## Действия управления: WASD, стрелки и левый стик геймпада.


static func ensure() -> void:
	_add(&"move_left", [KEY_A, KEY_LEFT], JOY_AXIS_LEFT_X, -1.0)
	_add(&"move_right", [KEY_D, KEY_RIGHT], JOY_AXIS_LEFT_X, 1.0)
	_add(&"move_up", [KEY_W, KEY_UP], JOY_AXIS_LEFT_Y, -1.0)
	_add(&"move_down", [KEY_S, KEY_DOWN], JOY_AXIS_LEFT_Y, 1.0)


static func _add(action: StringName, keys: Array, axis: JoyAxis, axis_value: float) -> void:
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
