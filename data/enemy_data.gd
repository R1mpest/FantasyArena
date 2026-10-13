class_name EnemyData
extends Resource
## Параметры типа врага. Значения — базовые, на k(t) умножаются здоровье и урон.

@export var id: StringName
@export var display_name: String
## Имя анимации бега в паке 0x72 без суффикса _fN.
@export var anim_run: String
@export var max_hp: float = 10.0
@export var speed: float = 40.0
## Урон в секунду, пока враг касается игрока.
@export var contact_dps: float = 10.0
@export var xp: int = 1
@export var radius: float = 5.0
## С какой минуты забега тип начинает появляться.
@export var from_minute: float = 0.0
## Вес при случайном выборе типа.
@export var weight: float = 1.0
