class_name LevelUpPanel
extends CanvasLayer
## Окно повышения уровня: пауза и выбор 1 из 3 карт (мышь, стрелки+Enter или 1–3).

var upgrade_system: UpgradeSystem

var _pending := 0
var _level := 1
var _busy := false
var _options: Array[CardOffer] = []
var _cards: Array[UpgradeCard] = []
var _dim: ColorRect
var _title: Label
var _subtitle: Label
var _row: HBoxContainer


func _ready() -> void:
	layer = 20
	process_mode = Node.PROCESS_MODE_ALWAYS
	_dim = ColorRect.new()
	_dim.color = Color(0.03, 0.02, 0.06, 0.7)
	_dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	_dim.add_child(center)
	var column := VBoxContainer.new()
	column.add_theme_constant_override(&"separation", 8)
	center.add_child(column)
	_title = UiKit.label("", 20, HORIZONTAL_ALIGNMENT_CENTER)
	_title.add_theme_color_override(&"font_color", Color(1, 0.85, 0.4))
	column.add_child(_title)
	_subtitle = UiKit.label("", 10, HORIZONTAL_ALIGNMENT_CENTER)
	column.add_child(_subtitle)
	_row = HBoxContainer.new()
	_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_row.add_theme_constant_override(&"separation", 14)
	_row.custom_minimum_size = Vector2(0, UpgradeCard.SIZE.y + 10)
	column.add_child(_row)
	column.add_child(UiKit.label("Мышь · стрелки и Enter · клавиши 1–3", 8, HORIZONTAL_ALIGNMENT_CENTER))
	_dim.hide()
	EventBus.level_up.connect(_on_level_up)


func is_open() -> bool:
	return _dim.visible


func options() -> Array[CardOffer]:
	return _options


## Возвращает false, если выбрать сейчас нельзя (окно закрыто или идёт анимация).
func choose(index: int) -> bool:
	if not is_open() or _busy or index < 0 or index >= _options.size():
		return false
	_busy = true
	_play_choice(index)
	return true


func _play_choice(index: int) -> void:
	for i in _cards.size():
		if i != index:
			_cards[i].play_discard()
	await _cards[index].play_selected().finished
	upgrade_system.apply(_options[index])
	_pending -= 1
	if _pending > 0:
		_show_choices()
	else:
		var fade := create_tween()
		fade.tween_property(_dim, "modulate:a", 0.0, 0.12)
		await fade.finished
		_dim.hide()
		get_tree().paused = false
	_busy = false


func _on_level_up(level: int) -> void:
	_pending += 1
	_level = level
	if not is_open():
		_dim.modulate.a = 0.0
		create_tween().tween_property(_dim, "modulate:a", 1.0, 0.15)
		_show_choices()


func _show_choices() -> void:
	get_tree().paused = true
	var level := _level - _pending + 1
	_title.text = "Уровень %d!" % level
	_options = upgrade_system.roll(level)
	var special := _options.any(func(offer: CardOffer) -> bool: return offer.is_style_item())
	_subtitle.text = "Особый выбор: предмет, меняющий стиль игры" if level in UpgradeSystem.SPECIAL_LEVELS and special else "Выберите карту"
	for card in _cards:
		_row.remove_child(card)
		card.queue_free()
	_cards.clear()
	for i in _options.size():
		var card := UpgradeCard.new()
		card.setup(_options[i], i + 1)
		card.pressed.connect(choose.bind(i))
		_row.add_child(card)
		card.play_in(0.12 * i)
		_cards.append(card)
	_dim.show()
	_cards[0].grab_focus.call_deferred()


func _unhandled_input(event: InputEvent) -> void:
	if not is_open():
		return
	var key := event as InputEventKey
	if key != null and key.pressed and not key.echo:
		var index := key.physical_keycode - KEY_1
		if index >= 0 and index < _options.size():
			get_viewport().set_input_as_handled()
			choose(index)
