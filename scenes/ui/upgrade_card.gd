class_name UpgradeCard
extends Button
## Карта прокачки: шапка с названием, иконка, уровень, описание.
## Появляется с подскоком, покачивается под курсором, при выборе подпрыгивает и исчезает.

const SIZE := Vector2(150, 190)

var upgrade: UpgradeData

var _tween: Tween


## level — уровень, который получит улучшение (0 — новое оружие или лечение).
func setup(card_upgrade: UpgradeData, level: int, hotkey: int) -> void:
	upgrade = card_upgrade
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
	column.add_theme_constant_override(&"separation", 4)
	margin.add_child(column)

	var header := PanelContainer.new()
	header.mouse_filter = Control.MOUSE_FILTER_IGNORE
	header.add_theme_stylebox_override(&"panel", UiKit.box(accent.darkened(0.55), accent, 1))
	var title := UiKit.label(upgrade.title, 11, HORIZONTAL_ALIGNMENT_CENTER)
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	header.add_child(title)
	column.add_child(header)

	column.add_child(_colored(UiKit.label(_category(), 8, HORIZONTAL_ALIGNMENT_CENTER), accent))

	var icon := TextureRect.new()
	icon.texture = upgrade.icon
	icon.custom_minimum_size = Vector2(0, 48)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(icon)

	var level_text := "Новое!" if level == 0 else "Ур. %d / %d" % [level, upgrade.max_level]
	column.add_child(_colored(UiKit.label(level_text, 9, HORIZONTAL_ALIGNMENT_CENTER), Color(1, 0.9, 0.6)))

	var description := UiKit.label(upgrade.description_for(level), 9, HORIZONTAL_ALIGNMENT_CENTER)
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(description)

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
	match upgrade.kind:
		UpgradeData.Kind.NEW_WEAPON:
			return Color(0.95, 0.75, 0.25)
		UpgradeData.Kind.WEAPON_STAT:
			return Color(0.95, 0.5, 0.3)
		UpgradeData.Kind.PERSONAL:
			return Color(0.8, 0.5, 1.0)
	return Color(0.45, 0.85, 0.5) if upgrade.stat == &"heal" else Color(0.45, 0.65, 1.0)


func _category() -> String:
	match upgrade.kind:
		UpgradeData.Kind.NEW_WEAPON:
			return "НОВОЕ ОРУЖИЕ"
		UpgradeData.Kind.WEAPON_STAT:
			return "УЛУЧШЕНИЕ ОРУЖИЯ"
		UpgradeData.Kind.PERSONAL:
			return "ЛИЧНЫЙ НАВЫК"
	return "ЛЕЧЕНИЕ" if upgrade.stat == &"heal" else "ХАРАКТЕРИСТИКА"


static func _colored(label: Label, color: Color) -> Label:
	label.add_theme_color_override(&"font_color", color)
	return label
