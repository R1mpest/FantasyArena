class_name Overlay
extends CanvasLayer
## Пауза (Esc), экран поражения со статистикой и список взятых улучшений.
## Раскладка как в HoloCure: слева панель героя с итоговыми характеристиками, по центру меню.

enum Mode { NONE, PAUSE, DEAD, VICTORY }

## Пауза перед экраном победы, чтобы было видно, как падает финальный босс.
const VICTORY_DELAY := 1.5

var upgrade_system: UpgradeSystem

var _mode := Mode.NONE
var _root: Control
var _title: Label
var _stats: Label
var _button: Button
var _upgrades_view: Control
var _skills_column: VBoxContainer
var _weapons_column: VBoxContainer
var _items_column: VBoxContainer
var _settings: SettingsPanel
var _hero_stats: GridContainer


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
	var settings_button := UiKit.button("Настройки")
	settings_button.pressed.connect(_open_settings)
	box.add_child(settings_button)
	var menu_button := UiKit.button("В главное меню")
	menu_button.pressed.connect(Transition.change_scene.bind(Transition.MENU_SCENE))
	box.add_child(menu_button)
	_build_hero_panel()
	add_child(_root)
	_root.hide()
	_build_upgrades_view()
	_settings = SettingsPanel.new()
	_settings.closed.connect(_close_settings)
	add_child(_settings)
	EventBus.player_died.connect(_show.bind(Mode.DEAD))
	EventBus.victory.connect(func() -> void:
		await get_tree().create_timer(VICTORY_DELAY).timeout
		_show(Mode.VICTORY))


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"ui_cancel"):
		if _settings.is_open():
			_settings.close()
		elif _upgrades_view.visible:
			_hide_upgrades()
		elif _mode == Mode.NONE and not get_tree().paused:
			_show(Mode.PAUSE)
		elif _mode == Mode.PAUSE:
			_hide()
		get_viewport().set_input_as_handled()
	elif _mode in [Mode.DEAD, Mode.VICTORY] and event is InputEventKey and event.pressed and event.physical_keycode == KEY_R:
		_restart()


func _show(mode: Mode) -> void:
	_mode = mode
	get_tree().paused = true
	_title.text = {Mode.PAUSE: "Пауза", Mode.DEAD: "Поражение", Mode.VICTORY: "Победа!"}[mode]
	_title.add_theme_color_override(&"font_color", Color(1, 0.85, 0.4) if mode == Mode.VICTORY else Color.WHITE)
	_button.text = "Продолжить (Esc)" if mode == Mode.PAUSE else "Заново (R)"
	_stats.text = "Время: %s\nУровень: %d\nУбито: %d" % [GameState.format_time(), GameState.level, GameState.kills]
	_update_hero_stats()
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


func _build_hero_panel() -> void:
	var player := upgrade_system.player
	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER_LEFT)
	panel.offset_left = 16
	panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	panel.add_theme_stylebox_override(&"panel", UiKit.box(Color(0.13, 0.1, 0.16, 0.92), Color(0.55, 0.45, 0.65), 1))
	var column := VBoxContainer.new()
	column.add_theme_constant_override(&"separation", 4)
	panel.add_child(column)
	var hero := TextureRect.new()
	hero.texture = SpriteLib.frames({&"idle": player.character.anim_idle}).get_frame_texture(&"idle", 0)
	hero.custom_minimum_size = Vector2(0, 64)
	hero.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	hero.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	column.add_child(hero)
	var name_label := UiKit.label(player.character.display_name, 12, HORIZONTAL_ALIGNMENT_CENTER)
	name_label.add_theme_color_override(&"font_color", Color(1, 0.85, 0.4))
	column.add_child(name_label)
	_hero_stats = GridContainer.new()
	_hero_stats.columns = 2
	_hero_stats.add_theme_constant_override(&"h_separation", 10)
	_hero_stats.add_theme_constant_override(&"v_separation", 1)
	column.add_child(_hero_stats)
	_root.add_child(panel)


func _update_hero_stats() -> void:
	var player := upgrade_system.player
	var rows := [
		["Здоровье", "%d / %d" % [ceili(player.hp), roundi(player.max_hp)]],
		["Урон", _percent(player.damage_mult() - 1.0)],
		["Перезарядка", _percent(player.cooldown_factor() - 1.0)],
		["Скорость бега", _percent(player.mods[&"move_speed_mult"] - 1.0)],
		["Размер атак", _percent(player.area() - 1.0)],
		["Радиус сбора", _percent(player.mods[&"pickup_mult"] - 1.0)],
		["Получаемый урон", _percent(player.mods[&"damage_taken_mult"] - 1.0)],
		["Регенерация", "%s/с" % String.num(player.regen, 1)],
	]
	for child in _hero_stats.get_children():
		child.queue_free()
	for row in rows:
		_hero_stats.add_child(UiKit.label(row[0], 9))
		var value := UiKit.label(row[1], 9, HORIZONTAL_ALIGNMENT_RIGHT)
		value.add_theme_color_override(&"font_color", Color(1, 0.9, 0.6))
		_hero_stats.add_child(value)


static func _percent(value: float) -> String:
	var rounded := roundi(value * 100.0)
	return "0%" if rounded == 0 else "%+d%%" % rounded


func _open_settings() -> void:
	_root.hide()
	_settings.open()


func _close_settings() -> void:
	_root.show()
	_button.grab_focus()


func _build_upgrades_view() -> void:
	var parts := UiKit.modal()
	_upgrades_view = parts[0]
	var box: VBoxContainer = parts[1]
	box.add_child(UiKit.label("Улучшения", 16, HORIZONTAL_ALIGNMENT_CENTER))
	var columns := HBoxContainer.new()
	columns.add_theme_constant_override(&"separation", 16)
	box.add_child(columns)
	_skills_column = _column(columns, "Навыки")
	_weapons_column = _column(columns, "Оружие")
	_items_column = _column(columns, "Предметы")
	var back := UiKit.button("Назад (Esc)")
	back.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	back.pressed.connect(_hide_upgrades)
	box.add_child(back)
	add_child(_upgrades_view)
	_upgrades_view.hide()


func _show_upgrades() -> void:
	var player := upgrade_system.player
	for column in [_skills_column, _weapons_column, _items_column]:
		for child in column.get_children().slice(1):
			child.queue_free()
	(_skills_column.get_child(0) as Label).text = "Навыки %d/%d" % [player.perks.size(), upgrade_system.skills.size()]
	(_weapons_column.get_child(0) as Label).text = "Оружие %d/%d" % [player.weapons.size(), UpgradeSystem.CLASS_SLOTS + UpgradeSystem.GENERAL_SLOTS]
	(_items_column.get_child(0) as Label).text = "Предметы %d/%d" % [player.items.size(), UpgradeSystem.ITEM_SLOTS]
	for skill in upgrade_system.skills:
		var level := player.skill_level(skill)
		if level > 0:
			_add_row(_skills_column, skill.icon, skill.title, "%d / %d" % [level, skill.max_level], false)
	for weapon: Weapon in player.weapons.values():
		_add_row(_weapons_column, weapon.data.icon, weapon.data.title, "%d / %d" % [weapon.level, weapon.data.max_level()], false)
	for id in player.items:
		var item: ItemData = player.item_data[id]
		var note := " (не действует)" if player.item_disabled(id) else (" (сработало)" if player.spent_items.has(id) else "")
		_add_row(_items_column, item.icon, item.title + note, "%d / %d" % [player.items[id], item.max_level()], false)
	for column in [_skills_column, _weapons_column, _items_column]:
		if column.get_child_count() == 1:
			column.add_child(UiKit.label("пусто", 9))
	_root.hide()
	_upgrades_view.show()
	(_upgrades_view.find_children("*", "Button", true, false)[0] as Button).grab_focus()


func _hide_upgrades() -> void:
	_upgrades_view.hide()
	_root.show()
	_button.grab_focus()


func _column(parent: Control, header: String) -> VBoxContainer:
	var column := VBoxContainer.new()
	column.custom_minimum_size = Vector2(150, 0)
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
