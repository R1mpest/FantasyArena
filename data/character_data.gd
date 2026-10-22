class_name CharacterData
extends Resource
## Персонаж: внешний вид, стартовые характеристики, классовое оружие и личные навыки.

@export var id: StringName
@export var display_name: String
## Анимации из пака 0x72 без суффикса _fN.
@export var anim_idle: String
@export var anim_run: String
@export var max_hp: float = 100.0
@export var move_speed: float = 85.0
## Оружие, с которым начинается забег (оно же входит в class_weapons).
@export var starting_weapon: WeaponData
## Классовое оружие: занимает классовые слоты и выпадает только этому персонажу.
@export var class_weapons: Array[WeaponData] = []
## Личные навыки: свои у каждого персонажа.
@export var skills: Array[SkillData] = []
