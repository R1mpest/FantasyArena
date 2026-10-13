class_name EnemyGrid
extends Node
## Сетка врагов для расталкивания. Заменяет физические столкновения враг–враг:
## они занимали больше половины времени кадра при 300 врагах.

## Размер клетки не меньше суммы двух самых больших радиусов (огр 11 + огр 11).
const CELL := 24.0

## Сетка пересобирается раз в столько физических кадров: враги за это время смещаются
## меньше чем на пару пикселей, а сборка стоит столько же, сколько само расталкивание.
const REBUILD_EVERY := 2

## Vector2i клетки -> Array врагов в ней.
var _cells: Dictionary = {}
var _frame := 0


func _ready() -> void:
	# Сетка строится раньше, чем враги в этом кадре её читают.
	process_physics_priority = -10


func _physics_process(_delta: float) -> void:
	_frame += 1
	if _frame % REBUILD_EVERY != 0:
		return
	_cells.clear()
	for node in get_tree().get_nodes_in_group(&"enemies"):
		var enemy := node as Enemy
		var cell := _cell_of(enemy.global_position)
		var list: Array = _cells.get(cell, [])
		if list.is_empty():
			_cells[cell] = list
		list.append(enemy)


## Вектор, которым соседи выталкивают врага: тем сильнее, чем глубже перекрытие.
func separation(enemy: Enemy) -> Vector2:
	var push := Vector2.ZERO
	var center := _cell_of(enemy.global_position)
	for dy in range(-1, 2):
		for dx in range(-1, 2):
			var list: Array = _cells.get(center + Vector2i(dx, dy), [])
			for item in list:
				# Между пересборками часть врагов уже убита и освобождена.
				if item == enemy or not is_instance_valid(item):
					continue
				var other: Enemy = item
				var offset := enemy.global_position - other.global_position
				var reach := enemy.data.radius + other.data.radius
				var distance_sq := offset.length_squared()
				if distance_sq >= reach * reach:
					continue
				if distance_sq < 0.0001:
					offset = Vector2.from_angle(randf() * TAU)
					distance_sq = 1.0
				var distance := sqrt(distance_sq)
				push += offset / distance * (reach - distance) / reach
	return push


static func _cell_of(at: Vector2) -> Vector2i:
	return Vector2i(floori(at.x / CELL), floori(at.y / CELL))
