class_name EnemySpawner
extends Node
## Спавн волн по таблице (data/waves/wave_table.tres): на каждой минуте свой пул
## врагов с весами, пауза между волнами, размер волны, лимит на арене и шанс элиты.
## Точка появления — случайная на кольце за краем экрана.
## На арене враги выходят из ворот: решётка поднимается за GATE_LEAD до выхода,
## ворота выбираются среди ближайших к герою. Без арены — кольцо за краем экрана.
## Боссы — по времени из таблицы, из главных ворот: за 3 с предупреждение, пока босс жив, волны вдвое реже.

const ENEMIES_DIR := "res://data/enemies/"
const WAVE_TABLE := "res://data/waves/wave_table.tres"
const MAX_ENEMIES := 300
const BOSS_WARNING := 3.0
const BOSS_SPAWN_SLOWDOWN := 2.0
## За сколько секунд до выхода монстров поднимается решётка и сколько ворота стоят открытыми после.
const GATE_LEAD := 1.0
const GATE_HOLD := 1.5
## Из скольких ближайших к герою ворот выбираются ворота для волны.
const NEAREST_GATES := 3

var player: Player
## Куда добавлять врагов (слой с y-сортировкой).
var enemies_root: Node2D
## Арена с воротами (null — бесконечное поле, спавн на кольце за краем экрана).
var arena: ArenaBuilder
var table: WaveTable

## id врага -> EnemyData.
var _types: Dictionary = {}
var _grid := EnemyGrid.new()
var _timer := 1.0
## Индекс следующего босса в таблице и последнего, о котором уже предупредили.
var _next_boss := 0
var _warned := -1
## Волны, которые выйдут из ворот, когда поднимется решётка: {time, gate, type, elite, minutes, limit}.
var _pending: Array[Dictionary] = []
## Ворота -> время забега, когда их закрыть.
var _close_at: Dictionary = {}


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
	check_bosses()
	_release_pending()
	_close_gates()
	_timer -= delta
	if _timer > 0.0:
		return
	var minutes := GameState.minutes()
	var segment := table.segment_at(minutes)
	_timer = float(segment["interval"])
	if get_tree().get_node_count_in_group(&"bosses") > 0:
		_timer *= BOSS_SPAWN_SLOWDOWN
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
## На арене волна ставится в очередь к воротам и выходит, когда поднимется решётка.
func _spawn_group(type: EnemyData, minutes: float, elite: bool, limit: int) -> void:
	if arena != null:
		var gate := _pick_gate()
		gate.open()
		var time := GameState.elapsed + GATE_LEAD
		_pending.append({"time": time, "gate": gate, "type": type, "elite": elite, "minutes": minutes, "limit": limit})
		_close_at[gate] = maxf(_close_at.get(gate, 0.0), time + GATE_HOLD)
		return
	var at := player.global_position + Vector2.from_angle(randf() * TAU) * _ring_radius()
	for i in type.group_size:
		if i > 0 and get_tree().get_node_count_in_group(&"enemies") >= limit:
			return
		var offset := Vector2.ZERO if i == 0 else Vector2.from_angle(randf() * TAU) * randf_range(6.0, 16.0)
		_spawn(type, minutes, elite and i == 0, at + offset)


## Предупреждает о боссе за BOSS_WARNING секунд и выпускает его в срок.
func check_bosses() -> void:
	if _next_boss >= table.bosses.size():
		return
	var entry: Dictionary = table.bosses[_next_boss]
	var time := float(entry["time"])
	if _warned < _next_boss and GameState.elapsed >= time - BOSS_WARNING:
		_warned = _next_boss
		EventBus.boss_incoming.emit(type_of(StringName(entry["enemy"])).display_name)
	if GameState.elapsed >= time:
		_next_boss += 1
		spawn_boss(StringName(entry["enemy"]), entry.get("final", false))


## Случайные из ближайших к герою ворот (главные — тоже, кроме выхода босса).
func _pick_gate() -> ArenaGate:
	var gates := arena.gates.duplicate()
	var hero := player.global_position
	gates.sort_custom(func(a: ArenaGate, b: ArenaGate) -> bool:
		return a.spawn_point.distance_squared_to(hero) < b.spawn_point.distance_squared_to(hero))
	return gates[randi() % mini(NEAREST_GATES, gates.size())]


func _release_pending() -> void:
	var now := GameState.elapsed
	for wave in _pending.duplicate():
		if wave["time"] > now:
			continue
		_pending.erase(wave)
		var gate: ArenaGate = wave["gate"]
		var type: EnemyData = wave["type"]
		for i in type.group_size:
			# Лимиты проверяем и здесь: пока поднималась решётка, такие же враги
			# могли выйти из других ворот (без этого шаманов набиралось 11 при лимите 8).
			if get_tree().get_node_count_in_group(&"enemies") >= int(wave["limit"]) or _at_cap(type, {}):
				break
			# Чуть разбросать вдоль стены и вглубь, чтобы стая не стояла в одной точке.
			var spread := gate.direction.orthogonal() * randf_range(-14.0, 14.0) + gate.direction * randf_range(0.0, 10.0)
			_spawn(type, float(wave["minutes"]), bool(wave["elite"]) and i == 0, gate.spawn_point + spread)


func _close_gates() -> void:
	for gate: ArenaGate in _close_at.keys():
		if GameState.elapsed >= _close_at[gate]:
			_close_at.erase(gate)
			gate.close()


func spawn_boss(id: StringName, final: bool) -> Boss:
	var at := player.global_position + Vector2.from_angle(randf() * TAU) * _ring_radius() * 0.6
	if arena != null:
		at = arena.gates[0].spawn_point
		_close_at[arena.gates[0]] = GameState.elapsed + GATE_HOLD * 2.0
	var boss: Boss = _make(type_of(id), GameState.minutes(), false, at)
	boss.spawner = self
	boss.final = final
	enemies_root.add_child(boss)
	return boss


func _spawn(type: EnemyData, minutes: float, elite: bool = false, at: Vector2 = Vector2.INF) -> Enemy:
	var enemy := _make(type, minutes, elite, at)
	enemies_root.add_child(enemy)
	return enemy


func _make(type: EnemyData, minutes: float, elite: bool, at: Vector2) -> Enemy:
	var enemy: Enemy = type.behaviour.new() if type.behaviour != null else Enemy.new()
	enemy.data = type
	enemy.k = Formulas.difficulty(minutes)
	enemy.damage_k = Formulas.enemy_damage(minutes)
	enemy.elite = elite
	enemy.target = player
	enemy.grid = _grid
	enemy.arena = arena
	enemy.respawn_radius = _ring_radius()
	if at == Vector2.INF:
		at = arena.gates.pick_random().spawn_point if arena != null else player.global_position + Vector2.from_angle(randf() * TAU) * enemy.respawn_radius
	enemy.position = at
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
