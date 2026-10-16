class_name Perk
extends Node2D
## Личный навык персонажа. Уровни и их параметры задаются в UpgradeData.level_params.

var player: Player
var level := 0
var params: Dictionary = {}


func set_level(new_level: int, new_params: Dictionary) -> void:
	level = new_level
	params = new_params
	_on_level_changed()


func _on_level_changed() -> void:
	pass
