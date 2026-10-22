class_name CardOffer
extends RefCounted
## Одна карта на повышении уровня: что она даёт и как её показать.

enum Kind { SKILL, WEAPON, ITEM, HEAL, XP }

var kind: Kind
## SkillData, WeaponData или ItemData; для лечения и опыта — null.
var data: Resource
## Уровень, который даст карта (1 — новое оружие, предмет или навык).
var level := 1
var max_level := 0
var title := ""
var description := ""
var icon: Texture2D
## Красная строка на карте (например, о конфликте предметов).
var warning := ""
## Для HEAL — доля макс. здоровья, для XP — количество опыта.
var amount := 0.0


func is_new() -> bool:
	return level == 1 and kind in [Kind.SKILL, Kind.WEAPON, Kind.ITEM]


func is_style_item() -> bool:
	return kind == Kind.ITEM and (data as ItemData).kind == ItemData.Kind.STYLE
