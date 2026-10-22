class_name UpgradeCard
extends Button
## Карта прокачки: шапка с названием, тип, иконка, уровень, описание и предупреждение.
## Появляется с подскоком, покачивается под курсором, при выборе подпрыгивает и исчезает.

const SIZE := Vector2(150, 190)

var offer: CardOffer

var _tween: Tween


func setup(card_offer: CardOffer, hotkey: int) -> void:
	offer = card_offer
	custom_minimum_size = SIZE
	pivot_offset = SIZE / 2.0
	focus_mode = Control.FOCUS_ALL
	var accent := _accent()
	add_theme_stylebox_override(&"normal", UiKit.box(Color(0.14, 0.11, 0.18), accent.darkened(0.35)))
	var hover := UiKit.box(Color(0.2, 0.15, 0.26), accent, 3)
	add_theme_stylebox_override(&"hover", hover)
	add_theme_stylebox_override(&"focus", hover)
	add_theme_stylebox_override(&"pressed", hover)

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 7)
	add_child(margin)
	var column := VBoxContainer.new()
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_theme_constant_override(&"separation", 3)
	margin.add_child(column)

	var header := PanelContainer.new()
	header.mouse_filter = Control.MOUSE_FILTER_IGNORE
	header.add_theme_stylebox_override(&"panel", UiKit.box(accent.darkened(0.55), accent, 1))
	var title := UiKit.label(offer.title, 11, HORIZONTAL_ALIGNMENT_CENTER)
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	header.add_child(title)
	column.add_child(header)

	column.add_child(_colored(UiKit.label(_category(), 8, HORIZONTAL_ALIGNMENT_CENTER), accent))

	var icon := TextureRect.new()
	icon.texture = offer.icon
	icon.custom_minimum_size = Vector2(0, 40)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(icon)

	var level_text := ""
	if offer.is_new():
		level_text = "Новое!"
	elif offer.max_level > 0:
		level_text = "Ур. %d / %d" % [offer.level, offer.max_level]
	column.add_child(_colored(UiKit.label(level_text, 9, HORIZONTAL_ALIGNMENT_CENTER), Color(1, 0.9, 0.6)))

	# Длинный текст — мельче шрифт, чтобы карта не переполнялась.
	var length := offer.description.length() + offer.warning.length()
	var description := UiKit.label(offer.description, 9 if length <= 95 else (8 if length <= 125 else 7), HORIZONTAL_ALIGNMENT_CENTER)
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(description)

	if offer.warning != "":
		var warning := UiKit.label(offer.warning, 8, HORIZONTAL_ALIGNMENT_CENTER)
		warning.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		column.add_child(_colored(warning, Color(1, 0.45, 0.4)))

	column.add_child(_colored(UiKit.label("[%d]" % hotkey, 8, HORIZONTAL_ALIGNMENT_CENTER), Color(0.6, 0.6, 0.7)))

	mouse_entered.connect(_wiggle)
	focus_entered.connect(_wiggle)


func play_in(delay: float) -> void:
	scale = Vector2.ZERO
	_restart_tween()
	_tween.tween_interval(delay)
	_tween.tween_property(self, "scale", Vector2.ONE * 1.15, 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_tween.tween_property(self, "scale", Vector2.ONE, 0.15)


## Выбранная карта: подскок с покачиванием и сжатие в точку.
func play_selected() -> Tween:
	_restart_tween()
	_tween.tween_property(self, "scale", Vector2.ONE * 1.2, 0.08)
	_tween.parallel().tween_property(self, "rotation", -0.17, 0.08)
	_tween.tween_property(self, "rotation", 0.09, 0.12)
	_tween.tween_property(self, "rotation", 0.0, 0.08)
	_tween.tween_property(self, "scale", Vector2.ZERO, 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	return _tween


func play_discard() -> void:
	_restart_tween()
	_tween.tween_property(self, "scale", Vector2.ZERO, 0.12)


func _wiggle() -> void:
	if scale != Vector2.ONE:
		return
	_restart_tween()
	_tween.tween_property(self, "rotation", -0.09, 0.06)
	_tween.tween_property(self, "rotation", 0.09, 0.06)
	_tween.tween_property(self, "rotation", 0.0, 0.06)


func _restart_tween() -> void:
	if _tween != null:
		_tween.kill()
	rotation = 0.0
	_tween = create_tween()


func _accent() -> Color:
	match offer.kind:
		CardOffer.Kind.SKILL:
			return Color(0.8, 0.5, 1.0)
		CardOffer.Kind.WEAPON:
			return Color(0.95, 0.75, 0.25) if offer.is_new() else Color(0.95, 0.5, 0.3)
		CardOffer.Kind.ITEM:
			return Color(1.0, 0.4, 0.55) if offer.is_style_item() else Color(0.45, 0.65, 1.0)
		CardOffer.Kind.XP:
			return Color(0.4, 0.85, 0.95)
	return Color(0.45, 0.85, 0.5)


func _category() -> String:
	match offer.kind:
		CardOffer.Kind.SKILL:
			return "ЛИЧНЫЙ НАВЫК"
		CardOffer.Kind.WEAPON:
			var class_weapon := (offer.data as WeaponData).pool == WeaponData.Pool.CLASS
			return ("НОВОЕ " if offer.is_new() else "") + ("КЛАССОВОЕ ОРУЖИЕ" if class_weapon else "ОРУЖИЕ")
		CardOffer.Kind.ITEM:
			return "МЕНЯЕТ СТИЛЬ ИГРЫ" if offer.is_style_item() else "ПРЕДМЕТ"
		CardOffer.Kind.XP:
			return "ОПЫТ"
	return "ЛЕЧЕНИЕ"


static func _colored(label: Label, color: Color) -> Label:
	label.add_theme_color_override(&"font_color", color)
	return label
