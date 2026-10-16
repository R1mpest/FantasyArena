class_name UpgradeData
extends Resource
## Карта прокачки: стат игрока, стат оружия, новое оружие или личный навык персонажа.

enum Mode { ADD, MULTIPLY }
enum Kind { PLAYER_STAT, WEAPON_STAT, NEW_WEAPON, PERSONAL }

@export var id: StringName
@export var title: String
@export_multiline var description: String
@export var icon: Texture2D
@export var kind: Kind = Kind.PLAYER_STAT
## id оружия для WEAPON_STAT и NEW_WEAPON (orbs, meteor, aura).
@export var weapon: StringName
## id личного навыка для PERSONAL (resonance, mana_shield, flow).
@export var perk: StringName
## Параметры навыка по уровням для PERSONAL: [{ур. 1}, {ур. 2}, ...].
## Ключ "text" — описание этого уровня на карте.
@export var level_params: Array[Dictionary] = []
## Имя свойства Player или оружия, которое меняется.
@export var stat: StringName
@export var amount: float = 1.0
@export var mode: Mode = Mode.ADD
@export var max_level: int = 5
@export var weight: float = 1.0


func params_for(level: int) -> Dictionary:
	if level_params.is_empty():
		return {}
	return level_params[clampi(level - 1, 0, level_params.size() - 1)]


## Описание карты для уровня, который она даст.
func description_for(level: int) -> String:
	return params_for(level).get("text", description)


func apply_to(target: Object) -> void:
	var current: float = target.get(stat)
	target.set(stat, current * amount if mode == Mode.MULTIPLY else current + amount)
