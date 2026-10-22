class_name WeaponData
extends Resource
## Оружие: 5 заранее заданных уровней. Классовое оружие у каждого персонажа своё,
## общее лежит в data/weapons/ и доступно всем.

enum Pool { CLASS, GENERAL }

@export var id: StringName
@export var title: String
@export_multiline var description: String
@export var icon: Texture2D
@export var pool: Pool = Pool.GENERAL
## Скрипт-наследник Weapon, который реализует поведение.
@export var weapon_script: Script
## Получает ли +снаряды от Колчана (только оружие с явными снарядами).
@export var uses_quiver := false
@export var weight := 1.0
## Уровни 1–5: на каждом уровне — новые значения свойств оружия и "text" для карты.
## Уровни применяются по порядку, поэтому в каждом указано только то, что меняется.
@export var levels: Array[Dictionary] = []


func max_level() -> int:
	return levels.size()


func text_for(level: int) -> String:
	return levels[clampi(level - 1, 0, levels.size() - 1)].get("text", description)
