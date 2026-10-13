class_name LevelUpPanel
extends CanvasLayer
## Окно повышения уровня: пауза и выбор 1 из 3 улучшений (мышь, стрелки+Enter или 1–3).

var upgrade_system: UpgradeSystem

var _pending := 0
var _options: Array[UpgradeData] = []
var _root: Control
var _title: Label
var _buttons: VBoxContainer


func _ready() -> void:
	layer = 20
	process_mode = Node.PROCESS_MODE_ALWAYS
	var parts := UiKit.modal()
	_root = parts[0]
	var box: VBoxContainer = parts[1]
	_title = UiKit.label("", 14, HORIZONTAL_ALIGNMENT_CENTER)
	box.add_child(_title)
	box.add_child(UiKit.label("Выберите улучшение", 9, HORIZONTAL_ALIGNMENT_CENTER))
	_buttons = VBoxContainer.new()
	_buttons.add_theme_constant_override(&"separation", 4)
	box.add_child(_buttons)
	add_child(_root)
	_root.hide()
	EventBus.level_up.connect(_on_level_up)


func is_open() -> bool:
	return _root.visible


func option_count() -> int:
	return _options.size()


func choose(index: int) -> void:
	if not is_open() or index < 0 or index >= _options.size():
		return
	upgrade_system.apply(_options[index])
	_pending -= 1
	if _pending > 0:
		_show_choices()
	else:
		_root.hide()
		get_tree().paused = false


func _on_level_up(level: int) -> void:
	_pending += 1
	_title.text = "Уровень %d!" % level
	if not is_open():
		_show_choices()


func _show_choices() -> void:
	get_tree().paused = true
	_options = upgrade_system.roll(3)
	for child in _buttons.get_children():
		_buttons.remove_child(child)
		child.queue_free()
	for i in _options.size():
		var upgrade := _options[i]
		var level_text := ""
		if upgrade.max_level > 0:
			var next_level := upgrade_system.level_of(upgrade) + 1
			level_text = "  [ур. %d/%d]" % [next_level, upgrade.max_level]
		var button := UiKit.button("%d. %s%s\n    %s" % [i + 1, upgrade.title, level_text, upgrade.description])
		button.pressed.connect(choose.bind(i))
		_buttons.add_child(button)
	_root.show()
	(_buttons.get_child(0) as Button).grab_focus()


func _unhandled_input(event: InputEvent) -> void:
	if not is_open():
		return
	var key := event as InputEventKey
	if key != null and key.pressed and not key.echo:
		var index := key.physical_keycode - KEY_1
		if index >= 0 and index < _options.size():
			get_viewport().set_input_as_handled()
			choose(index)
