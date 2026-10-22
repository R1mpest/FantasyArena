class_name ItemData
extends Resource
## Предмет для слота предметов. Базовые дают модификаторы героя,
## меняющие стиль игры добавляют свою механику (у них отдельный узел-эффект).

enum Kind { BASIC, STYLE }

@export var id: StringName
@export var title: String
@export var icon: Texture2D
@export var kind: Kind = Kind.BASIC
@export var weight := 1.0
## Взяв этот предмет, игрок больше не увидит в выдаче эти (например, Стеклянная пушка → Латная пластина).
@export var excludes: Array[StringName] = []
## Уровни: модификаторы героя на этом уровне (итоговые, не прибавка) и "text" для карты.
## Модификаторы: might, cooldown_mult, area_mult, move_speed_mult, pickup_mult,
## damage_taken_mult (перемножаются), max_hp_bonus, regen, extra_projectiles (складываются).
@export var levels: Array[Dictionary] = []


func max_level() -> int:
	return levels.size()


func params_for(level: int) -> Dictionary:
	if levels.is_empty() or level <= 0:
		return {}
	return levels[mini(level, levels.size()) - 1]


func text_for(level: int) -> String:
	return params_for(level).get("text", "")
