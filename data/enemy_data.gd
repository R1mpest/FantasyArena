class_name EnemyData
extends Resource
## Параметры типа врага. На k(t) умножается только здоровье; когда и как часто тип
## появляется, задаёт таблица волн (data/waves/wave_table.tres).

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
## Ступень: 1 — мелочь, 2 — средние, 3 — огры и элита. Проклятый идол заменяет ступень 1 на более высокую.
@export var tier: int = 1
## Босс: не замерзает (только замедляется), Проклятый череп целится в него первым.
@export var is_boss := false
## Рой: столько врагов появляется вместе в одной точке.
@export var group_size: int = 1
## Взрывной враг: подбегает к герою, через короткую задержку взрывается (урон герою) и исчезает.
@export var explode_damage: float = 0.0
@export var explode_radius: float = 0.0
## Своё поведение (скрипт-наследник Enemy) — для боссов.
@export var behaviour: Script
## Во сколько раз спрайт и тело крупнее обычного (боссы).
@export var size_scale: float = 1.0
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
