class_name Hud
extends CanvasLayer
## HUD по раскладке HoloCure: слева сверху портрет героя, ОЗ и щит, под ними
## ряд из 6 слотов оружия, ряд из 6 слотов предметов и 3 слота навыков (рамки из пака); таймер по центру;
## уровень, убийства и «Поток» справа; полоса опыта во всю ширину сверху.

const SLOT := 20
const SLOT_GAP := 1
const SLOTS_X := 40.0
const HP_WIDTH := 125.0

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
var _skill_slots: Array[Control] = []
var _boss_arrow: TextureRect
## Состояние слотов в прошлый раз: перестраиваем иконки, только когда оно меняется.
var _slots_signature := ""
var _boss: Enemy
var _boss_box: Control
var _boss_name: Label
var _boss_bar: ProgressBar
var _banner: Label


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
		var frame := "ui/slot_weapon_class" if i < UpgradeSystem.CLASS_SLOTS else "ui/slot_weapon_common"
		_weapon_slots.append(_make_slot(root, Vector2(SLOTS_X + i * (SLOT + SLOT_GAP), 24), frame))
	for i in UpgradeSystem.ITEM_SLOTS:
		_item_slots.append(_make_slot(root, Vector2(SLOTS_X + i * (SLOT + SLOT_GAP), 45), "ui/slot_item"))
	for i in player.character.skills.size():
		_skill_slots.append(_make_slot(root, Vector2(SLOTS_X + i * (SLOT + SLOT_GAP), 66), "ui/slot_skill"))

	_boss_arrow = TextureRect.new()
	_boss_arrow.texture = SpriteLib.pack("ui/edge_arrow")
	_boss_arrow.size = Vector2(16, 16)
	_boss_arrow.pivot_offset = Vector2(8, 8)
	_boss_arrow.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_boss_arrow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(_boss_arrow)
	_boss_arrow.hide()

	_time_label = UiKit.label("", 14, HORIZONTAL_ALIGNMENT_CENTER)
	_time_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_time_label.offset_top = 8
	_time_label.grow_horizontal = Control.GROW_DIRECTION_BOTH
	root.add_child(_time_label)

	_boss_box = VBoxContainer.new()
	_boss_box.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_boss_box.offset_top = 28
	_boss_box.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_boss_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_boss_box.add_theme_constant_override(&"separation", 1)
	_boss_name = UiKit.label("", 9, HORIZONTAL_ALIGNMENT_CENTER)
	_boss_name.add_theme_color_override(&"font_color", Color(1, 0.55, 0.45))
	_boss_box.add_child(_boss_name)
	_boss_bar = UiKit.bar(Color(0.75, 0.15, 0.2))
	_boss_bar.custom_minimum_size = Vector2(260, 6)
	_boss_box.add_child(_boss_bar)
	root.add_child(_boss_box)
	_boss_box.hide()

	_banner = UiKit.label("", 16, HORIZONTAL_ALIGNMENT_CENTER)
	_banner.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_banner.offset_top = 70
	_banner.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_banner.add_theme_color_override(&"font_color", Color(1, 0.4, 0.35))
	_banner.add_theme_constant_override(&"outline_size", 6)
	root.add_child(_banner)
	_banner.hide()
	EventBus.boss_incoming.connect(_on_boss_incoming)
	EventBus.arena_event.connect(func(title: String) -> void: _show_banner(title, Color(1, 0.8, 0.35)))
	EventBus.boss_spawned.connect(func(boss: Node2D) -> void: _boss = boss as Enemy)

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
	_update_boss()


func _update_boss() -> void:
	var alive := is_instance_valid(_boss) and not _boss.dead
	_boss_box.visible = alive
	_update_boss_arrow(alive)
	if alive:
		_boss_name.text = _boss.data.display_name
		_boss_bar.max_value = _boss.full_hp
		_boss_bar.value = _boss.hp


## Стрелка у края экрана, если босс за его пределами.
func _update_boss_arrow(alive: bool) -> void:
	var view := get_viewport().get_visible_rect().size
	var at := _boss.get_global_transform_with_canvas().origin if alive else Vector2.ZERO
	var inside := Rect2(Vector2.ZERO, view).grow(-8.0).has_point(at)
	_boss_arrow.visible = alive and not inside
	if not _boss_arrow.visible:
		return
	var center := view / 2.0
	var direction := center.direction_to(at)
	var edge := Rect2(Vector2.ZERO, view).grow(-14.0)
	# Луч из центра до рамки: где он пересекает край экрана.
	var t := INF
	if direction.x != 0.0:
		t = minf(t, ((edge.end.x if direction.x > 0.0 else edge.position.x) - center.x) / direction.x)
	if direction.y != 0.0:
		t = minf(t, ((edge.end.y if direction.y > 0.0 else edge.position.y) - center.y) / direction.y)
	_boss_arrow.position = center + direction * t - Vector2(8, 8)
	_boss_arrow.rotation = direction.angle()
	_boss_arrow.modulate.a = 0.6 + 0.4 * sin(GameState.elapsed * 8.0)


func _on_boss_incoming(title: String) -> void:
	_show_banner("Босс приближается: %s" % title, Color(1, 0.4, 0.35))


func _show_banner(text: String, color: Color) -> void:
	_banner.text = text
	_banner.add_theme_color_override(&"font_color", color)
	_banner.modulate.a = 1.0
	_banner.show()
	var fade := create_tween()
	fade.tween_interval(2.5)
	fade.tween_property(_banner, "modulate:a", 0.0, 0.5)
	fade.tween_callback(_banner.hide)


func _update_slots() -> void:
	var class_weapons: Array[Weapon] = []
	var general_weapons: Array[Weapon] = []
	for weapon: Weapon in player.weapons.values():
		(class_weapons if weapon.data.pool == WeaponData.Pool.CLASS else general_weapons).append(weapon)
	var signature := ""
	for weapon in class_weapons + general_weapons:
		signature += "%s%d," % [weapon.data.id, weapon.level]
	signature += "|%s|%s|%s" % [player.items, player.spent_items, player.healing_blocked()]
	for skill in player.character.skills:
		signature += ",%d" % player.skill_level(skill)
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
	var skills := player.character.skills.filter(func(s: SkillData) -> bool: return player.skill_level(s) > 0)
	for i in _skill_slots.size():
		var skill: SkillData = skills[i] if i < skills.size() else null
		_fill_slot(_skill_slots[i], skill.icon if skill != null else null, player.skill_level(skill) if skill != null else 0)


func _make_slot(root: Control, at: Vector2, frame: String) -> Control:
	var slot := TextureRect.new()
	slot.texture = SpriteLib.pack(frame)
	slot.position = at
	slot.size = Vector2(SLOT, SLOT)
	slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
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
