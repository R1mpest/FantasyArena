class_name ItemEffect
extends Node2D
## Механика предмета, меняющего стиль игры. Статичную часть (урон, скорость...)
## дают модификаторы из ItemData, а здесь — то, что зависит от происходящего в бою.

var player: Player
var data: ItemData
var level := 0
var params: Dictionary = {}


func set_level(new_level: int) -> void:
	level = new_level
	params = data.params_for(level)
	_on_level_changed()


func _on_level_changed() -> void:
	pass
