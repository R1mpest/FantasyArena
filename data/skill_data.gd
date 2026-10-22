class_name SkillData
extends Resource
## Личный навык персонажа (3 уровня). Логику навыка реализует узел Perk.

@export var id: StringName
@export var title: String
@export_multiline var description: String
@export var icon: Texture2D
## id навыка для Player.set_perk (mana_shield, flow, arcane_mark).
@export var perk: StringName
@export var max_level: int = 3
@export var weight: float = 1.0
## Параметры по уровням: [{ур. 1}, {ур. 2}, {ур. 3}]; ключ "text" — описание уровня на карте.
@export var level_params: Array[Dictionary] = []


func params_for(level: int) -> Dictionary:
	if level_params.is_empty():
		return {}
	return level_params[clampi(level - 1, 0, level_params.size() - 1)]


func text_for(level: int) -> String:
	return params_for(level).get("text", description)
