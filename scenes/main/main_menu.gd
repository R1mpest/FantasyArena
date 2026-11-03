extends Node2D
## Главное меню на фоне колизея: камера плывёт вдоль северной трибуны с императорской
## ложей, публика время от времени ликует, из ворот на песок выходят монстры,
## перед ложей стоит герой. Меню — на золотой панели слева.

const MONSTERS := ["goblin_run_anim", "skelet_run_anim", "orc_warrior_run_anim", "chort_run_anim", "masked_orc_run_anim", "imp_run_anim"]
## Камера смотрит на северную трибуну: ложа (она в x = 0) правее центра экрана,
## слева остаётся место под панель меню; камера лишь слегка покачивается.
const CAMERA_X := -96.0
const CAMERA_Y := -400.0
const CAMERA_SWAY := 40.0
const MARCH_TIME := 3.5

var _arena: ArenaBuilder
var _camera: Camera2D
var _crowd: Node2D
var _time := 0.0
var _next_parade := 0.3
var _cheer_until := 0.0
## [спрайт, скорость, сколько ещё идёт]
var _marchers: Array = []
var _help: Control
var _stats_view: Control
var _stats_grid: GridContainer
var _reset_button: Button
var _stats_back: Button
var _settings: SettingsPanel
var _settings_button: Button
var _play_button: Button


func _ready() -> void:
	RenderingServer.set_default_clear_color(Color("1b1520"))
	InputSetup.ensure()
	Music.play(&"menu")
	_arena = ArenaBuilder.new()
	add_child(_arena)
	_crowd = Node2D.new()
	_crowd.y_sort_enabled = true
	add_child(_crowd)

	var hero := SpriteLib.make_sprite({&"idle": "wizzard_m_idle_anim"})
	hero.position = Vector2(0, -262)
	hero.scale = Vector2(1.5, 1.5)
	_crowd.add_child(hero)

	_camera = Camera2D.new()
	_camera.position = Vector2(CAMERA_X, CAMERA_Y)
	var limits := _arena.camera_limits()
	_camera.limit_left = limits.position.x
	_camera.limit_top = limits.position.y
	_camera.limit_right = limits.end.x
	_camera.limit_bottom = limits.end.y
	add_child(_camera)
	_build_ui()


func _process(delta: float) -> void:
	_time += delta
	_camera.position.x = CAMERA_X + sin(_time * 0.2) * CAMERA_SWAY
	if _time >= _next_parade:
		_next_parade = _time + randf_range(4.0, 6.0)
		_parade()
	if _cheer_until > 0.0 and _time >= _cheer_until:
		_cheer_until = 0.0
		_arena.set_cheering(false)
		_arena.emperor_gesture(&"idle")
	for marcher in _marchers.duplicate():
		var sprite: AnimatedSprite2D = marcher[0]
		sprite.position += marcher[1] * delta
		marcher[2] -= delta
		sprite.modulate.a = clampf(marcher[2], 0.0, 1.0)
		if marcher[2] <= 0.0:
			_marchers.erase(marcher)
			sprite.queue_free()


## Главные ворота поднимаются, через секунду выходят несколько монстров, публика ликует.
func _parade() -> void:
	# Главные ворота — под ложей, в кадре; остальные северные ворота за панелью или за краем.
	var gate: ArenaGate = _arena.gates[0]
	gate.open()
	_arena.set_cheering(true)
	_arena.emperor_gesture(&"up" if randf() < 0.5 else &"down")
	_cheer_until = _time + 3.0
	var type: String = MONSTERS.pick_random()
	get_tree().create_timer(1.0).timeout.connect(func() -> void:
		for i in randi_range(4, 7):
			var sprite := SpriteLib.make_sprite({&"run": type})
			sprite.position = gate.spawn_point + Vector2(randf_range(-14.0, 14.0), randf_range(-4.0, 6.0))
			var velocity := Vector2(randf_range(-12.0, 12.0), randf_range(26.0, 40.0))
			sprite.flip_h = velocity.x < 0.0
			_crowd.add_child(sprite)
			_marchers.append([sprite, velocity, MARCH_TIME + randf() * 0.8])
		get_tree().create_timer(2.5).timeout.connect(gate.close))


func _build_ui() -> void:
	var ui := CanvasLayer.new()
	add_child(ui)
	var shade := ColorRect.new()
	shade.color = Color(0.03, 0.02, 0.06, 0.2)
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(shade)

	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER_LEFT)
	panel.offset_left = 20
	# Чуть ниже центра, чтобы панель не закрывала трибуны.
	panel.offset_top = 40
	panel.offset_bottom = 40
	panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	panel.add_theme_stylebox_override(&"panel", UiKit.pack_panel(true))
	ui.add_child(panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override(&"separation", 5)
	panel.add_child(column)

	var title := UiKit.label("Fantasy Arena", 24, HORIZONTAL_ALIGNMENT_CENTER)
	title.add_theme_color_override(&"font_color", Color(1, 0.82, 0.35))
	title.add_theme_constant_override(&"outline_size", 8)
	column.add_child(title)
	column.add_child(UiKit.label("Колизей ждёт своего героя", 10, HORIZONTAL_ALIGNMENT_CENTER))
	column.add_child(UiKit.label("Продержись 15 минут и победи трёх чемпионов", 8, HORIZONTAL_ALIGNMENT_CENTER))
	column.add_child(Control.new())

	_play_button = _menu_button(column, "Играть", Transition.change_scene.bind(Transition.RUN_SCENE))
	_menu_button(column, "Как играть", _toggle_help.bind(true))
	_menu_button(column, "Статистика", _toggle_stats.bind(true))
	_settings_button = _menu_button(column, "Настройки", _open_settings)
	_menu_button(column, "Выход", get_tree().quit)
	_play_button.grab_focus.call_deferred()

	var parts := UiKit.modal()
	_help = parts[0]
	var box: VBoxContainer = parts[1]
	box.add_child(UiKit.label("Как играть", 16, HORIZONTAL_ALIGNMENT_CENTER))
	box.add_child(UiKit.label(
		"WASD, стрелки или геймпад — движение\n" +
		"Оружие стреляет само: в ближайшего врага\nили по мыши (см. «Настройки»)\n" +
		"Монстров выпускают из ворот арены,\nсобытия объявляются надписью\n" +
		"Собирайте кристаллы опыта с врагов\n" +
		"На новом уровне выберите 1 из 3 карт\n" +
		"Esc — пауза", 10))
	var back := _menu_button(box, "Назад", _toggle_help.bind(false))
	back.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	ui.add_child(_help)
	_help.hide()
	_build_stats(ui)
	_settings = SettingsPanel.new()
	_settings.closed.connect(_settings_button.grab_focus)
	add_child(_settings)


func _menu_button(parent: Control, text: String, action: Callable) -> Button:
	var button := UiKit.button(text, 150.0)
	button.pressed.connect(action)
	parent.add_child(button)
	return button


func _toggle_help(visible_now: bool) -> void:
	_help.visible = visible_now
	if visible_now:
		(_help.find_children("*", "Button", true, false)[0] as Button).grab_focus()
	else:
		_play_button.grab_focus()


## Окно статистики: рекорды одного забега и итоги за всё время (Stats).
func _build_stats(ui: Node) -> void:
	var parts := UiKit.modal()
	_stats_view = parts[0]
	var box: VBoxContainer = parts[1]
	box.add_child(UiKit.label("Статистика", 16, HORIZONTAL_ALIGNMENT_CENTER))
	_stats_grid = GridContainer.new()
	_stats_grid.columns = 2
	_stats_grid.add_theme_constant_override(&"h_separation", 24)
	_stats_grid.add_theme_constant_override(&"v_separation", 2)
	box.add_child(_stats_grid)
	var buttons := HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons.add_theme_constant_override(&"separation", 8)
	box.add_child(buttons)
	_reset_button = _menu_button(buttons, "Сбросить", _reset_stats)
	_stats_back = _menu_button(buttons, "Назад", _toggle_stats.bind(false))
	ui.add_child(_stats_view)
	_stats_view.hide()


func _fill_stats() -> void:
	for child in _stats_grid.get_children():
		child.queue_free()
	# У рекордов без забегов — прочерк, у итогов — ноль.
	var totals := {}
	for id in Stats.TOTALS:
		totals[id] = Stats.totals.get(id, 0)
	for section in [["Рекорды забега", Stats.RECORDS, Stats.records], ["За всё время", Stats.TOTALS, totals]]:
		var header := UiKit.label(section[0], 11)
		header.add_theme_color_override(&"font_color", Color(1, 0.85, 0.4))
		_stats_grid.add_child(header)
		_stats_grid.add_child(Control.new())
		for id: StringName in section[1]:
			var title: String = section[1][id][0] if section[1][id] is Array else section[1][id]
			_stats_grid.add_child(UiKit.label(title, 10))
			_stats_grid.add_child(UiKit.label(Stats.format_value(id, section[2].get(id)), 10, HORIZONTAL_ALIGNMENT_RIGHT))


func _toggle_stats(visible_now: bool) -> void:
	_stats_view.visible = visible_now
	_reset_button.text = "Сбросить"
	if visible_now:
		_fill_stats()
		_stats_back.grab_focus()
	else:
		_play_button.grab_focus()


## Сброс — в два нажатия, чтобы не стереть статистику случайно.
func _reset_stats() -> void:
	if _reset_button.text == "Сбросить":
		_reset_button.text = "Точно?"
		return
	Stats.reset()
	_reset_button.text = "Сбросить"
	_fill_stats()
	_stats_back.grab_focus()


func _open_settings() -> void:
	_settings.open()


## Кнопка «Назад» Android: закрывает открытое окно, а в самом меню — выходит из игры.
func _notification(what: int) -> void:
	if what != NOTIFICATION_WM_GO_BACK_REQUEST:
		return
	if _settings.is_open():
		_settings.close()
	elif _help.visible:
		_toggle_help(false)
	elif _stats_view.visible:
		_toggle_stats(false)
	else:
		get_tree().quit()


func _unhandled_input(event: InputEvent) -> void:
	if _settings.is_open() and event.is_action_pressed(&"ui_cancel"):
		_settings.close()
		get_viewport().set_input_as_handled()
	elif _help.visible and event.is_action_pressed(&"ui_cancel"):
		_toggle_help(false)
		get_viewport().set_input_as_handled()
	elif _stats_view.visible and event.is_action_pressed(&"ui_cancel"):
		_toggle_stats(false)
		get_viewport().set_input_as_handled()
