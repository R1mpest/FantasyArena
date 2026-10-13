class_name EnemySpawner
extends Node
## Спавн волн: тип врага по весам, точка на кольце за краем экрана.

const ENEMIES_DIR := "res://data/enemies/"
const MAX_ENEMIES := 300

var player: Player
## Куда добавлять врагов (слой с y-сортировкой).
var enemies_root: Node2D

var _types: Array[EnemyData] = []
var _timer := 1.0


func _ready() -> void:
	for file in ResourceLoader.list_directory(ENEMIES_DIR):
		if file.ends_with(".tres"):
			_types.append(load(ENEMIES_DIR + file))


func _process(delta: float) -> void:
	if not GameState.running:
		return
	_timer -= delta
	if _timer > 0.0:
		return
	var minutes := GameState.minutes()
	_timer = Formulas.spawn_interval(minutes)
	for i in Formulas.spawn_batch(minutes):
		if get_tree().get_node_count_in_group(&"enemies") >= MAX_ENEMIES:
			break
		_spawn(_pick_type(minutes), minutes)


func _spawn(type: EnemyData, minutes: float) -> void:
	var enemy := Enemy.new()
	enemy.data = type
	enemy.k = Formulas.difficulty(minutes)
	enemy.target = player
	enemy.respawn_radius = _ring_radius()
	enemy.position = player.global_position + Vector2.from_angle(randf() * TAU) * enemy.respawn_radius
	enemies_root.add_child(enemy)


## Половина диагонали экрана плюс отступ: враг появляется сразу за краем.
func _ring_radius() -> float:
	return player.get_viewport_rect().size.length() / 2.0 + 24.0


## Взвешенный случайный выбор среди типов, доступных к этой минуте.
func _pick_type(minutes: float) -> EnemyData:
	var available := _types.filter(func(t: EnemyData) -> bool: return t.from_minute <= minutes)
	var total := 0.0
	for type: EnemyData in available:
		total += type.weight
	var roll := randf() * total
	for type: EnemyData in available:
		roll -= type.weight
		if roll <= 0.0:
			return type
	return available.back()
