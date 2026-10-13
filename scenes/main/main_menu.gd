extends Node2D
## Главное меню: пол арены, по которому бродят монстры, герой и кнопки.

const MONSTERS := ["goblin_run_anim", "skelet_run_anim", "ogre_run_anim", "chort_run_anim", "orc_warrior_run_anim", "imp_run_anim"]
const WIDTH := 640.0
const HEIGHT := 360.0

## [спрайт, скорость в пикселях в секунду; знак — направление]
var _walkers: Array = []
var _help: Control
var _play_button: Button


func _ready() -> void:
	RenderingServer.set_default_clear_color(Color("1b1520"))
	InputSetup.ensure()
	add_child(FloorBuilder.build())
	for i in 14:
		_add_walker(randf_range(0.0, WIDTH))
	var hero := SpriteLib.make_sprite({&"idle": "wizzard_m_idle_anim"})
	hero.position = Vector2(170, 270)
	hero.scale = Vector2(4, 4)
	add_child(hero)
	_build_ui()


func _process(delta: float) -> void:
	for walker in _walkers:
		var sprite: AnimatedSprite2D = walker[0]
		sprite.position.x += walker[1] * delta
		if sprite.position.x > WIDTH + 40.0 or sprite.position.x < -40.0:
			sprite.position = Vector2(-30.0 if walker[1] > 0 else WIDTH + 30.0, randf_range(40.0, HEIGHT - 10.0))


func _add_walker(x: float) -> void:
	var sprite := SpriteLib.make_sprite({&"run": MONSTERS.pick_random()})
	var speed := randf_range(18.0, 45.0) * (1.0 if randf() < 0.5 else -1.0)
	sprite.flip_h = speed < 0.0
	sprite.position = Vector2(x, randf_range(40.0, HEIGHT - 10.0))
	sprite.scale = Vector2(2, 2)
	sprite.modulate = Color(0.75, 0.7, 0.8)
	add_child(sprite)
	_walkers.append([sprite, speed])


func _build_ui() -> void:
	var ui := CanvasLayer.new()
	add_child(ui)
	var shade := ColorRect.new()
	shade.color = Color(0.03, 0.02, 0.06, 0.45)
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	ui.add_child(shade)

	var right := MarginContainer.new()
	right.set_anchors_preset(Control.PRESET_FULL_RECT)
	right.add_theme_constant_override(&"margin_left", 300)
	ui.add_child(right)
	var center := CenterContainer.new()
	right.add_child(center)
	var column := VBoxContainer.new()
	column.add_theme_constant_override(&"separation", 8)
	center.add_child(column)

	var title := UiKit.label("Fantasy Arena", 34, HORIZONTAL_ALIGNMENT_CENTER)
	title.add_theme_color_override(&"font_color", Color(1, 0.82, 0.35))
	title.add_theme_constant_override(&"outline_size", 8)
	column.add_child(title)
	column.add_child(UiKit.label("Продержись 15 минут на арене", 10, HORIZONTAL_ALIGNMENT_CENTER))
	column.add_child(Control.new())

	_play_button = _menu_button(column, "Играть", Transition.change_scene.bind(Transition.RUN_SCENE))
	_menu_button(column, "Как играть", _toggle_help.bind(true))
	_menu_button(column, "Выход", get_tree().quit)
	_play_button.grab_focus.call_deferred()

	var parts := UiKit.modal()
	_help = parts[0]
	var box: VBoxContainer = parts[1]
	box.add_child(UiKit.label("Как играть", 16, HORIZONTAL_ALIGNMENT_CENTER))
	box.add_child(UiKit.label(
		"WASD, стрелки или геймпад — движение\n" +
		"Оружие стреляет само\n" +
		"Собирайте кристаллы опыта с врагов\n" +
		"На новом уровне выберите 1 из 3 карт\n" +
		"Esc — пауза", 10))
	var back := _menu_button(box, "Назад", _toggle_help.bind(false))
	back.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	ui.add_child(_help)
	_help.hide()


func _menu_button(parent: Control, text: String, action: Callable) -> Button:
	var button := UiKit.button(text, 180.0)
	button.pressed.connect(action)
	parent.add_child(button)
	return button


func _toggle_help(visible_now: bool) -> void:
	_help.visible = visible_now
	if visible_now:
		(_help.find_children("*", "Button", true, false)[0] as Button).grab_focus()
	else:
		_play_button.grab_focus()


func _unhandled_input(event: InputEvent) -> void:
	if _help.visible and event.is_action_pressed(&"ui_cancel"):
		_toggle_help(false)
		get_viewport().set_input_as_handled()
