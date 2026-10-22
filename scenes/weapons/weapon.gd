class_name Weapon
extends Node2D
## Оружие героя. Уровни 1–5 и их значения лежат в WeaponData; модификаторы
## предметов (урон, перезарядка, размер, Колчан) берутся у героя в момент атаки.

var player: Player
var data: WeaponData
var level := 0


func set_level(new_level: int) -> void:
	# Уровни применяются по порядку: в каждом указано только то, что меняется.
	for current in range(level + 1, new_level + 1):
		var params: Dictionary = data.levels[current - 1]
		for key: String in params:
			if key != "text" and key in self:
				set(key, params[key])
	level = new_level
	_on_level_changed()


func _on_level_changed() -> void:
	pass


func damage_of(base: float) -> float:
	return base * player.damage_mult()


func cooldown_of(base: float) -> float:
	return base * player.cooldown_factor()


func area() -> float:
	return player.area()


## Дополнительные снаряды от Колчана, если оружие их принимает.
func extra_projectiles() -> int:
	return player.extra_projectiles() if data != null and data.uses_quiver else 0
