class_name Overlay
extends CanvasLayer
## Пауза (Esc), экран поражения со статистикой и список взятых улучшений.

enum Mode { NONE, PAUSE, DEAD }

var upgrade_system: UpgradeSystem

var _mode := Mode.NONE
var _root: Control
var _title: Label
var _stats: Label
var _button: Button
var _upgrades_view: Control
var _weapons_column: VBoxContainer
var _stats_column: VBoxContainer


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
	_button.pressed.connect(_on_button_pressed)
	box.add_child(_button)
	var upgrades_button := UiKit.button("Улучшения")
	upgrades_button.pressed.connect(_show_upgrades)
	box.add_child(upgrades_button)
	var menu_button := UiKit.button("В главное меню")
	menu_button.pressed.connect(Transition.change_scene.bind(Transition.MENU_SCENE))
	box.add_child(menu_button)
	add_child(_root)
	_root.hide()
	_build_upgrades_view()
	EventBus.player_died.connect(_show.bind(Mode.DEAD))


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"ui_cancel"):
		if _upgrades_view.visible:
			_hide_upgrades()
		elif _mode == Mode.NONE and not get_tree().paused:
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
	Transition.change_scene(Transition.RUN_SCENE)


func _build_upgrades_view() -> void:
	var parts := UiKit.modal()
	_upgrades_view = parts[0]
	var box: VBoxContainer = parts[1]
	box.add_child(UiKit.label("Улучшения", 16, HORIZONTAL_ALIGNMENT_CENTER))
	var columns := HBoxContainer.new()
	columns.add_theme_constant_override(&"separation", 24)
	box.add_child(columns)
	_weapons_column = _column(columns, "Оружие")
	_stats_column = _column(columns, "Характеристики")
	var back := UiKit.button("Назад (Esc)")
	back.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	back.pressed.connect(_hide_upgrades)
	box.add_child(back)
	add_child(_upgrades_view)
	_upgrades_view.hide()


func _show_upgrades() -> void:
	for column in [_weapons_column, _stats_column]:
		for child in column.get_children().slice(1):
			child.queue_free()
	_add_row(_weapons_column, SpriteLib.texture("flask_blue"), "Магический снаряд", "стартовое", false)
	for weapon in upgrade_system.upgrades:
		if weapon.kind != UpgradeData.Kind.NEW_WEAPON or upgrade_system.level_of(weapon) == 0:
			continue
		_add_row(_weapons_column, weapon.icon, weapon.title, "", false)
		for upgrade in upgrade_system.upgrades:
			if upgrade.kind == UpgradeData.Kind.WEAPON_STAT and upgrade.weapon == weapon.weapon and upgrade_system.level_of(upgrade) > 0:
				_add_row(_weapons_column, null, upgrade.title.get_slice(": ", 1).capitalize(), _level_text(upgrade), true)
	for upgrade in upgrade_system.upgrades:
		if upgrade.kind == UpgradeData.Kind.PLAYER_STAT and upgrade_system.level_of(upgrade) > 0:
			_add_row(_stats_column, upgrade.icon, upgrade.title, _level_text(upgrade), false)
	if _stats_column.get_child_count() == 1:
		_stats_column.add_child(UiKit.label("пока ничего", 9))
	var personal := upgrade_system.upgrades.filter(func(u: UpgradeData) -> bool:
		return u.kind == UpgradeData.Kind.PERSONAL and upgrade_system.level_of(u) > 0)
	if not personal.is_empty():
		var header := UiKit.label("Личные навыки", 11)
		header.add_theme_color_override(&"font_color", Color(0.8, 0.5, 1.0))
		_stats_column.add_child(header)
		for upgrade: UpgradeData in personal:
			_add_row(_stats_column, upgrade.icon, upgrade.title, _level_text(upgrade), false)
	_root.hide()
	_upgrades_view.show()
	(_upgrades_view.find_children("*", "Button", true, false)[0] as Button).grab_focus()


func _hide_upgrades() -> void:
	_upgrades_view.hide()
	_root.show()
	_button.grab_focus()


func _level_text(upgrade: UpgradeData) -> String:
	return "%d / %d" % [upgrade_system.level_of(upgrade), upgrade.max_level]


func _column(parent: Control, header: String) -> VBoxContainer:
	var column := VBoxContainer.new()
	column.custom_minimum_size = Vector2(170, 0)
	column.add_theme_constant_override(&"separation", 3)
	var title := UiKit.label(header, 11)
	title.add_theme_color_override(&"font_color", Color(1, 0.85, 0.4))
	column.add_child(title)
	parent.add_child(column)
	return column


func _add_row(column: VBoxContainer, icon: Texture2D, text: String, level: String, indent: bool) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override(&"separation", 6)
	var picture := TextureRect.new()
	picture.texture = icon
	picture.custom_minimum_size = Vector2(26 if indent else 16, 16)
	picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	row.add_child(picture)
	var name_label := UiKit.label(("· " if indent else "") + text, 10 if not indent else 9)
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(name_label)
	var level_label := UiKit.label(level, 9, HORIZONTAL_ALIGNMENT_RIGHT)
	level_label.add_theme_color_override(&"font_color", Color(1, 0.9, 0.6))
	row.add_child(level_label)
	column.add_child(row)
