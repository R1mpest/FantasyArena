class_name UpgradeData
extends Resource
## Карта прокачки: стат игрока, стат оружия или новое оружие.

enum Mode { ADD, MULTIPLY }
enum Kind { PLAYER_STAT, WEAPON_STAT, NEW_WEAPON }

@export var id: StringName
@export var title: String
@export_multiline var description: String
@export var icon: Texture2D
@export var kind: Kind = Kind.PLAYER_STAT
## id оружия для WEAPON_STAT и NEW_WEAPON (orbs, meteor, aura).
@export var weapon: StringName
## Имя свойства Player или оружия, которое меняется.
@export var stat: StringName
@export var amount: float = 1.0
@export var mode: Mode = Mode.ADD
@export var max_level: int = 5
@export var weight: float = 1.0


func apply_to(target: Object) -> void:
	var current: float = target.get(stat)
	target.set(stat, current * amount if mode == Mode.MULTIPLY else current + amount)
