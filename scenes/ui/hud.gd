class_name Hud
extends CanvasLayer
## HUD по раскладке HoloCure: слева сверху портрет героя, ОЗ и щит, под ними
## ряд из 6 слотов оружия и ряд из 6 слотов предметов; таймер по центру;
## уровень, убийства и «Поток» справа; полоса опыта во всю ширину сверху.

const SLOT := 16
const SLOT_GAP := 2
const SLOTS_X := 40.0
const HP_WIDTH := 106.0

var player: Player
var experience: Experience

var _hp_bar: ProgressBar
var _hp_label: Label
var _shield_bar: ProgressBar
var _flow_label: Label
var _xp_bar: ProgressBar
var _level_label: Label
var _time_label: Label
var _kills_label: Label
var _weapon_slots: Array[Control] = []
var _item_slots: Array[Control] = []
## Состояние слотов в прошлый раз: перестраиваем иконки, только когда оно меняется.
var _slots_signature := ""


func _ready() -> void:
	layer = 10
	# Обновляется и на паузе, чтобы уровень и ОЗ были верными под окном выбора карт.
	process_mode = Node.PROCESS_MODE_ALWAYS
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	_xp_bar = UiKit.bar(Color(0.35, 0.6, 1.0))
	_xp_bar.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_xp_bar.offset_bottom = 5
	root.add_child(_xp_bar)

	var portrait := PanelContainer.new()
	portrait.position = Vector2(6, 9)
	portrait.custom_minimum_size = Vector2(30, 30)
	portrait.size = Vector2(30, 30)
	portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var portrait_style := UiKit.box(Color(0.12, 0.1, 0.16, 0.85), Color(0.95, 0.75, 0.3), 1)
	portrait_style.set_content_margin_all(1)
	portrait.add_theme_stylebox_override(&"panel", portrait_style)
	var face := TextureRect.new()
	face.texture = SpriteLib.frames({&"idle": player.character.anim_idle}).get_frame_texture(&"idle", 0)
	face.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	face.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait.add_child(face)
	root.add_child(portrait)

	_hp_bar = UiKit.bar(Color(0.85, 0.2, 0.25))
	_hp_bar.position = Vector2(SLOTS_X, 10)
	_hp_bar.size = Vector2(HP_WIDTH, 8)
	root.add_child(_hp_bar)
	_hp_label = UiKit.label("", 8)
	_hp_label.position = Vector2(SLOTS_X + HP_WIDTH + 4, 7)
	root.add_child(_hp_label)

	_shield_bar = UiKit.bar(Color(0.45, 0.8, 1.0))
	_shield_bar.position = Vector2(SLOTS_X, 19)
	_shield_bar.size = Vector2(HP_WIDTH, 3)
	root.add_child(_shield_bar)

	for i in UpgradeSystem.CLASS_SLOTS + UpgradeSystem.GENERAL_SLOTS:
		var accent := Color(0.95, 0.75, 0.3) if i < UpgradeSystem.CLASS_SLOTS else Color(0.55, 0.6, 0.75)
		_weapon_slots.append(_make_slot(root, Vector2(SLOTS_X + i * (SLOT + SLOT_GAP), 25), accent))
	for i in UpgradeSystem.ITEM_SLOTS:
		_item_slots.append(_make_slot(root, Vector2(SLOTS_X + i * (SLOT + SLOT_GAP), 44), Color(0.45, 0.65, 1.0)))

	_time_label = UiKit.label("", 14, HORIZONTAL_ALIGNMENT_CENTER)
	_time_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_time_label.offset_top = 8
	_time_label.grow_horizontal = Control.GROW_DIRECTION_BOTH
	root.add_child(_time_label)

	_level_label = _right_label(root, 10, 8)
	_level_label.add_theme_color_override(&"font_color", Color(1, 0.85, 0.4))
	_kills_label = _right_label(root, 9, 22)
	_flow_label = _right_label(root, 8, 35)
	_flow_label.add_theme_color_override(&"font_color", Color(1, 0.85, 0.4))


func _process(_delta: float) -> void:
	_hp_bar.max_value = player.max_hp
	_hp_bar.value = player.hp
	_hp_label.text = "%d / %d" % [ceili(player.hp), roundi(player.max_hp)]
	_shield_bar.visible = player.shield_max > 0.0
	_shield_bar.max_value = maxf(player.shield_max, 1.0)
	_shield_bar.value = player.shield
	_flow_label.text = "Поток +%d%%" % roundi(player.attack_speed_bonus * 100.0) if player.attack_speed_bonus > 0.0 else ""
	_xp_bar.max_value = experience.to_next
	_xp_bar.value = experience.xp
	_level_label.text = "Ур. %d" % experience.level
	_time_label.text = GameState.format_time()
	_kills_label.text = "Убито: %d" % GameState.kills
	_update_slots()


func _update_slots() -> void:
	var class_weapons: Array[Weapon] = []
	var general_weapons: Array[Weapon] = []
	for weapon: Weapon in player.weapons.values():
		(class_weapons if weapon.data.pool == WeaponData.Pool.CLASS else general_weapons).append(weapon)
	var signature := ""
	for weapon in class_weapons + general_weapons:
		signature += "%s%d," % [weapon.data.id, weapon.level]
	signature += "|%s|%s|%s" % [player.items, player.spent_items, player.healing_blocked()]
	if signature == _slots_signature:
		return
	_slots_signature = signature
	for i in UpgradeSystem.CLASS_SLOTS:
		_fill_slot(_weapon_slots[i], class_weapons[i].data.icon if i < class_weapons.size() else null, class_weapons[i].level if i < class_weapons.size() else 0)
	for i in UpgradeSystem.GENERAL_SLOTS:
		_fill_slot(_weapon_slots[UpgradeSystem.CLASS_SLOTS + i], general_weapons[i].data.icon if i < general_weapons.size() else null, general_weapons[i].level if i < general_weapons.size() else 0)
	var ids := player.items.keys()
	for i in UpgradeSystem.ITEM_SLOTS:
		var item: ItemData = player.item_data[ids[i]] if i < ids.size() else null
		_fill_slot(_item_slots[i], item.icon if item != null else null, player.items[ids[i]] if item != null else 0)
		if item != null and (player.item_disabled(item.id) or player.spent_items.has(item.id)):
			_item_slots[i].modulate = Color(0.4, 0.4, 0.4)


func _make_slot(root: Control, at: Vector2, accent: Color) -> Control:
	var slot := Panel.new()
	slot.position = at
	slot.size = Vector2(SLOT, SLOT)
	slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	slot.add_theme_stylebox_override(&"panel", UiKit.box(Color(0.08, 0.06, 0.1, 0.75), accent.darkened(0.3), 1))
	var icon := TextureRect.new()
	icon.set_anchors_preset(Control.PRESET_FULL_RECT)
	icon.offset_left = 2
	icon.offset_top = 2
	icon.offset_right = -2
	icon.offset_bottom = -2
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	slot.add_child(icon)
	var level := UiKit.label("", 6, HORIZONTAL_ALIGNMENT_RIGHT)
	level.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	level.offset_right = 1
	level.offset_bottom = 3
	level.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	level.grow_vertical = Control.GROW_DIRECTION_BEGIN
	slot.add_child(level)
	root.add_child(slot)
	return slot


func _fill_slot(slot: Control, icon: Texture2D, level: int) -> void:
	(slot.get_child(0) as TextureRect).texture = icon
	(slot.get_child(1) as Label).text = str(level) if level > 0 else ""
	slot.modulate = Color.WHITE if icon != null else Color(1, 1, 1, 0.55)


func _right_label(root: Control, size: int, top: float) -> Label:
	var label := UiKit.label("", size, HORIZONTAL_ALIGNMENT_RIGHT)
	label.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	label.offset_top = top
	label.offset_right = -6
	label.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	root.add_child(label)
	return label
