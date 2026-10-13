class_name Hud
extends CanvasLayer
## HUD: здоровье, полоса опыта, уровень, таймер, убийства.

var player: Player
var experience: Experience

var _hp_bar: ProgressBar
var _xp_bar: ProgressBar
var _level_label: Label
var _time_label: Label
var _kills_label: Label


func _ready() -> void:
	layer = 10
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	_xp_bar = UiKit.bar(Color(0.35, 0.6, 1.0))
	_xp_bar.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_xp_bar.offset_bottom = 6
	root.add_child(_xp_bar)

	_level_label = UiKit.label("", 10)
	_level_label.position = Vector2(6, 8)
	root.add_child(_level_label)

	_hp_bar = UiKit.bar(Color(0.85, 0.2, 0.25))
	_hp_bar.position = Vector2(6, 24)
	_hp_bar.size = Vector2(90, 7)
	root.add_child(_hp_bar)

	_time_label = UiKit.label("", 14, HORIZONTAL_ALIGNMENT_CENTER)
	_time_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_time_label.offset_top = 8
	_time_label.grow_horizontal = Control.GROW_DIRECTION_BOTH
	root.add_child(_time_label)

	_kills_label = UiKit.label("", 10, HORIZONTAL_ALIGNMENT_RIGHT)
	_kills_label.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_kills_label.offset_top = 8
	_kills_label.offset_right = -6
	_kills_label.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	root.add_child(_kills_label)



func _process(_delta: float) -> void:
	_hp_bar.max_value = player.max_hp
	_hp_bar.value = player.hp
	_xp_bar.max_value = experience.to_next
	_xp_bar.value = experience.xp
	_level_label.text = "Уровень %d" % experience.level
	_time_label.text = GameState.format_time()
	_kills_label.text = "Убито: %d" % GameState.kills
