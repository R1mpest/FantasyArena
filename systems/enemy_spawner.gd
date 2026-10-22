class_name EnemySpawner
extends Node
## Спавн волн по таблице (data/waves/wave_table.tres): на каждой минуте свой пул
## врагов с весами, пауза между волнами, размер волны, лимит на арене и шанс элиты.
## Точка появления — случайная на кольце за краем экрана.

const ENEMIES_DIR := "res://data/enemies/"
const WAVE_TABLE := "res://data/waves/wave_table.tres"
const MAX_ENEMIES := 300

var player: Player
## Куда добавлять врагов (слой с y-сортировкой).
var enemies_root: Node2D
var table: WaveTable

## id врага -> EnemyData.
var _types: Dictionary = {}
var _grid := EnemyGrid.new()
var _timer := 1.0


func _ready() -> void:
	add_child(_grid)
	table = load(WAVE_TABLE)
	for file in ResourceLoader.list_directory(ENEMIES_DIR):
		if file.ends_with(".tres"):
			var type: EnemyData = load(ENEMIES_DIR + file)
			_types[type.id] = type


func type_of(id: StringName) -> EnemyData:
	return _types.get(id)


func _process(delta: float) -> void:
	if not GameState.running:
		return
	_timer -= delta
	if _timer > 0.0:
		return
	var minutes := GameState.minutes()
	var segment := table.segment_at(minutes)
	_timer = float(segment["interval"])
	var limit := mini(int(segment["limit"]), MAX_ENEMIES)
	var in_wave: Dictionary = {}
	for i in int(segment["batch"]):
		if get_tree().get_node_count_in_group(&"enemies") >= limit:
			break
		var type := _pick_type(minutes, in_wave)
		if type == null:
			break
		type = _upgrade_tier(type, minutes, in_wave)
		in_wave[type.id] = in_wave.get(type.id, 0) + 1
		_spawn_group(type, minutes, randf() < float(segment["elite"]), limit)


## Рой появляется пачкой в одной точке, остальные — по одному.
func _spawn_group(type: EnemyData, minutes: float, elite: bool, limit: int) -> void:
	var at := player.global_position + Vector2.from_angle(randf() * TAU) * _ring_radius()
	for i in type.group_size:
		if i > 0 and get_tree().get_node_count_in_group(&"enemies") >= limit:
			return
		var offset := Vector2.ZERO if i == 0 else Vector2.from_angle(randf() * TAU) * randf_range(6.0, 16.0)
		_spawn(type, minutes, elite and i == 0, at + offset)


func _spawn(type: EnemyData, minutes: float, elite: bool = false, at: Vector2 = Vector2.INF) -> Enemy:
	var enemy: Enemy = type.behaviour.new() if type.behaviour != null else Enemy.new()
	enemy.data = type
	enemy.k = Formulas.difficulty(minutes)
	enemy.elite = elite
	enemy.target = player
	enemy.grid = _grid
	enemy.respawn_radius = _ring_radius()
	enemy.position = at if at != Vector2.INF else player.global_position + Vector2.from_angle(randf() * TAU) * enemy.respawn_radius
	enemies_root.add_child(enemy)
	return enemy


## Половина диагонали экрана плюс отступ: враг появляется сразу за краем.
func _ring_radius() -> float:
	return player.get_viewport_rect().size.length() / 2.0 + 24.0


## Проклятый идол: с его шансом враг ступени 1 заменяется врагом ступени выше из текущего пула.
func _upgrade_tier(type: EnemyData, minutes: float, in_wave: Dictionary) -> EnemyData:
	var chance: float = player.mods.get(&"tier_upgrade_chance", 0.0)
	if type.tier != 1 or chance <= 0.0 or randf() >= chance:
		return type
	var stronger := _pool(minutes, in_wave).filter(func(t: EnemyData) -> bool: return t.tier > 1)
	return type if stronger.is_empty() else stronger.pick_random()


func _at_cap(type: EnemyData, in_wave: Dictionary) -> bool:
	if type.max_per_wave > 0 and in_wave.get(type.id, 0) >= type.max_per_wave:
		return true
	return type.max_alive > 0 and get_tree().get_node_count_in_group(StringName("enemy_" + type.id)) >= type.max_alive


## Враги текущей минуты, которые ещё не упёрлись в свои лимиты.
func _pool(minutes: float, in_wave: Dictionary) -> Array:
	var weights: Dictionary = table.segment_at(minutes)["enemies"]
	var pool := []
	for id in weights:
		var type: EnemyData = _types.get(StringName(id))
		if type != null and not _at_cap(type, in_wave):
			pool.append(type)
	return pool


## Взвешенный случайный выбор по весам текущей минуты.
func _pick_type(minutes: float, in_wave: Dictionary = {}) -> EnemyData:
	var weights: Dictionary = table.segment_at(minutes)["enemies"]
	var pool := _pool(minutes, in_wave)
	if pool.is_empty():
		return null
	var total := 0.0
	for type: EnemyData in pool:
		total += float(weights[String(type.id)])
	var roll := randf() * total
	for type: EnemyData in pool:
		roll -= float(weights[String(type.id)])
		if roll <= 0.0:
			return type
	return pool.back()
