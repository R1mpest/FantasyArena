class_name SettingsPanel
extends CanvasLayer
## Окно настроек: экран, звук, прицеливание. Изменения применяются и сохраняются сразу.

signal closed

const WINDOW_MODES := ["В окне", "Полный экран", "Окно без рамки"]
const BUS_TITLES := {&"Master": "Общая громкость", &"Music": "Музыка", &"SFX": "Эффекты"}
const AIM_MODES := ["Автоматически — в ближайшего врага", "По направлению мыши"]

var _root: Control
var _window_mode: OptionButton
var _resolution: OptionButton
var _resolutions: Array = []
var _aim: OptionButton
var _first_focus: Control


func _ready() -> void:
	layer = 40
	process_mode = Node.PROCESS_MODE_ALWAYS
	var parts := UiKit.modal()
	_root = parts[0]
	var box: VBoxContainer = parts[1]
	box.add_child(UiKit.label("Настройки", 16, HORIZONTAL_ALIGNMENT_CENTER))
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override(&"h_separation", 14)
	grid.add_theme_constant_override(&"v_separation", 6)
	box.add_child(grid)

	_section(grid, "Экран")
	_window_mode = _option(grid, "Режим окна", WINDOW_MODES)
	_window_mode.item_selected.connect(func(index: int) -> void:
		SaveManager.set_window_mode(index)
		_refresh())
	_resolutions = SaveManager.available_resolutions()
	_resolution = _option(grid, "Разрешение", _resolutions.map(func(size: Vector2i) -> String: return "%d × %d" % [size.x, size.y]))
	_resolution.item_selected.connect(func(index: int) -> void: SaveManager.set_resolution(_resolutions[index]))

	_section(grid, "Звук")
	for bus in SaveManager.BUSES:
		_slider(grid, bus)

	_section(grid, "Управление")
	_aim = _option(grid, "Прицеливание", AIM_MODES)
	_aim.item_selected.connect(func(index: int) -> void: SaveManager.set_aim_mode(index))

	var back := UiKit.button("Назад (Esc)")
	back.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	back.pressed.connect(close)
	box.add_child(back)
	add_child(_root)
	_root.hide()


func is_open() -> bool:
	return _root.visible


func open() -> void:
	_refresh()
	_root.show()
	_first_focus.grab_focus.call_deferred()


func close() -> void:
	_root.hide()
	closed.emit()


func _refresh() -> void:
	_window_mode.select(SaveManager.window_mode)
	var index := _resolutions.find(SaveManager.resolution)
	_resolution.select(index if index >= 0 else 0)
	# В полноэкранных режимах игра идёт в разрешении экрана.
	_resolution.disabled = SaveManager.window_mode != SaveManager.WindowMode.WINDOWED
	_aim.select(SaveManager.aim_mode)


func _section(grid: GridContainer, title: String) -> void:
	var label := UiKit.label(title, 11)
	label.add_theme_color_override(&"font_color", Color(1, 0.85, 0.4))
	grid.add_child(label)
	grid.add_child(Control.new())


func _option(grid: GridContainer, title: String, items: Array) -> OptionButton:
	grid.add_child(UiKit.label(title, 10))
	var option := OptionButton.new()
	option.custom_minimum_size = Vector2(210, 22)
	option.add_theme_font_size_override(&"font_size", 10)
	option.get_popup().add_theme_font_size_override(&"font_size", 10)
	for item in items:
		option.add_item(item)
	grid.add_child(option)
	if _first_focus == null:
		_first_focus = option
	return option


func _slider(grid: GridContainer, bus: StringName) -> void:
	grid.add_child(UiKit.label(BUS_TITLES[bus], 10))
	var row := HBoxContainer.new()
	var slider := HSlider.new()
	slider.custom_minimum_size = Vector2(170, 16)
	slider.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	slider.max_value = 100
	slider.step = 5
	slider.value = roundi(SaveManager.volumes[bus] * 100.0)
	var value_label := UiKit.label("%d%%" % slider.value, 9, HORIZONTAL_ALIGNMENT_RIGHT)
	value_label.custom_minimum_size = Vector2(34, 0)
	slider.value_changed.connect(func(value: float) -> void:
		value_label.text = "%d%%" % value
		SaveManager.set_volume(bus, value / 100.0))
	row.add_child(slider)
	row.add_child(value_label)
	grid.add_child(row)
