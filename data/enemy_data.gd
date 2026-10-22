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
## Ступень: 1 — мелочь, 2 — средние, 3 — огры и элита. Проклятый идол заменяет ступень 1 на более высокую.
@export var tier: int = 1
## Сколько врагов этого типа может быть на арене одновременно (0 — без ограничения).
@export var max_alive: int = 0
## Сколько врагов этого типа может появиться за одну волну (0 — без ограничения).
@export var max_per_wave: int = 0

@export_group("Дальний бой")
## Дистанция стрельбы; 0 — враг ближнего боя.
@export var attack_range: float = 0.0
@export var shot_damage: float = 0.0
@export var shot_interval: float = 2.5
@export var shot_speed: float = 100.0
