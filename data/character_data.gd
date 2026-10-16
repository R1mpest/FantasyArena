class_name CharacterData
extends Resource
## Персонаж: внешний вид, стартовые характеристики и личные навыки (карты «Личный навык»).

@export var id: StringName
@export var display_name: String
## Анимации из пака 0x72 без суффикса _fN.
@export var anim_idle: String
@export var anim_run: String
@export var max_hp: float = 100.0
@export var move_speed: float = 85.0
## Карты, которые выпадают только этому персонажу.
@export var personal_upgrades: Array[UpgradeData] = []
