class_name UpgradeSystem
extends Node
## Выбор улучшений: 3 разных варианта взвешенной выборкой без возвращения.

const UPGRADES_DIR := "res://data/upgrades/"
## Бонус к весу уже взятых веток, чтобы билд складывался.
const OWNED_WEIGHT_BONUS := 1.3

var player: Player
var upgrades: Array[UpgradeData] = []
## id улучшения -> взятый уровень.
var levels: Dictionary = {}

var _heal := UpgradeData.new()


func _ready() -> void:
	for file in ResourceLoader.list_directory(UPGRADES_DIR):
		if file.ends_with(".tres"):
			upgrades.append(load(UPGRADES_DIR + file))
	_heal.id = &"heal"
	_heal.title = "Лечение"
	_heal.description = "Восстановить 30% здоровья"
	_heal.stat = &"heal"
	_heal.max_level = 0


func level_of(upgrade: UpgradeData) -> int:
	return levels.get(upgrade.id, 0)


func roll(count: int = 3) -> Array[UpgradeData]:
	var pool := upgrades.filter(func(u: UpgradeData) -> bool: return level_of(u) < u.max_level)
	var result: Array[UpgradeData] = []
	while result.size() < count and not pool.is_empty():
		var total := 0.0
		for upgrade: UpgradeData in pool:
			total += _weight(upgrade)
		var roll_value := randf() * total
		var picked: int = pool.size() - 1
		for i in pool.size():
			roll_value -= _weight(pool[i])
			if roll_value <= 0.0:
				picked = i
				break
		result.append(pool[picked])
		pool.remove_at(picked)
	if result.is_empty():
		result.append(_heal)
	return result


func apply(upgrade: UpgradeData) -> void:
	if upgrade == _heal:
		player.heal(player.max_hp * 0.3)
		return
	levels[upgrade.id] = level_of(upgrade) + 1
	player.apply_upgrade(upgrade)


func _weight(upgrade: UpgradeData) -> float:
	return upgrade.weight * (OWNED_WEIGHT_BONUS if level_of(upgrade) > 0 else 1.0)
