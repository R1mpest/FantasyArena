class_name ArenaEvents
extends Node
## События арены по расписанию из таблицы волн. За WARNING секунд — надпись и открытые
## ворота, потом выход строя. Во время боя с боссом события пропускаются.
## line «Шеренга»: строй через всю арену от стены до стены, в нём дыра шириной в gap врагов
## недалеко от героя.
## pack «Стая»: плотная толпа из одних ворот летит по прямой через точку, где был герой.
## ring «Окружение»: вокруг героя разом встаёт кольцо, сжимается к месту, где он стоял,
## и у центра растворяется — герою надо прорваться или петлять внутри.

const WARNING := 1.5
const LINE_STEP := 18.0
const PACK_RADIUS := 30.0
## Враги из событий дают опыт с шансом 50% — иначе строй под аурой ломает темп уровней.
const XP_CHANCE := 0.5
## Враги из событий вчетверо крепче обычных того же времени: строй не должен таять под аурой.
const HP_MULT := 4.0
## Самое дальнее место дыры от линии героя, в шагах строя.
const GAP_SPREAD := 6
## Полуширина поиска краёв арены вдоль строя, в шагах (с запасом на любую арену).
const LINE_HALF_MAX := 120
const TITLES := {"line": "Шеренга!", "pack": "Выпустить стаю!", "ring": "Окружение!"}
## Кольцо: начальный и конечный радиус (у конечного враги исчезают), время сжатия по умолчанию.
const RING_RADIUS := 170.0
const RING_END := 18.0
const RING_TIME := 8.0

var spawner: EnemySpawner
var arena: ArenaBuilder
var player: Player

var _next := 0
var _warned := -1
## Подготовленные данные события между предупреждением и выходом: сторона, ворота.
var _prepared: Dictionary = {}


func _process(_delta: float) -> void:
	if not GameState.running or _next >= spawner.table.events.size():
		return
	var event: Dictionary = spawner.table.events[_next]
	var time := float(event["time"])
	if _warned < _next and GameState.elapsed >= time - WARNING:
		_warned = _next
		if get_tree().get_node_count_in_group(&"bosses") == 0:
			_prepare(event)
	if GameState.elapsed >= time:
		_next += 1
		if not _prepared.is_empty():
			_release(event)
		_prepared = {}


func _prepare(event: Dictionary) -> void:
	match String(event["type"]):
		"line":
			var side: Vector2 = [Vector2.RIGHT, Vector2.LEFT, Vector2.DOWN, Vector2.UP].pick_random()
			_prepared = {"direction": side, "gates": arena.gates.filter(func(g: ArenaGate) -> bool: return g.direction.dot(side) > 0.9)}
		"pack":
			# Ворота подальше от героя, чтобы стаю было видно на подлёте.
			var far := arena.gates.filter(func(g: ArenaGate) -> bool: return g.spawn_point.distance_to(player.global_position) > 220.0)
			_prepared = {"gates": [far.pick_random() if not far.is_empty() else arena.gates.pick_random()]}
		"ring":
			# Кольцо появляется из ниоткуда — ворота не открываются.
			_prepared = {"gates": []}
	for gate: ArenaGate in _prepared["gates"]:
		gate.open()
	EventBus.arena_event.emit(TITLES.get(String(event["type"]), "Событие!"))


func _release(event: Dictionary) -> void:
	var type := spawner.type_of(StringName(event["enemy"]))
	if type == null:
		return
	match String(event["type"]):
		"line":
			_release_line(event, type)
		"pack":
			_release_pack(event, type)
		"ring":
			_release_ring(event, type)
	for gate: ArenaGate in _prepared["gates"]:
		spawner._close_at[gate] = GameState.elapsed + EnemySpawner.GATE_HOLD * 2.0


## Строй вдоль стены, с которой идёт шеренга, от одного края арены до другого; в строю
## одна дыра в пределах GAP_SPREAD шагов от линии героя, чтобы до неё можно было добежать.
func _release_line(event: Dictionary, type: EnemyData) -> void:
	var direction: Vector2 = _prepared["direction"]
	var across := direction.orthogonal()
	var gap := int(event.get("gap", 3))
	# Точка старта — у стены напротив направления марша, на одной линии с героем.
	var start := arena.clamp_inside(player.global_position - direction * 2000.0, 16.0)
	var gap_start := randi_range(-GAP_SPREAD, GAP_SPREAD - gap)
	for i in range(-LINE_HALF_MAX, LINE_HALF_MAX + 1):
		if i >= gap_start and i < gap_start + gap:
			continue
		var at := start + across * i * LINE_STEP
		if not arena.contains(at, 8.0):
			continue
		if _spawn_marching(type, at, direction, float(event.get("speed", 70.0))) == null:
			return


func _release_pack(event: Dictionary, type: EnemyData) -> void:
	var gate: ArenaGate = _prepared["gates"][0]
	var aim := gate.spawn_point.direction_to(player.global_position)
	var speed := type.speed * float(event.get("speed_mult", 1.8))
	for i in int(event["count"]):
		var at := gate.spawn_point + Vector2.from_angle(randf() * TAU) * sqrt(randf()) * PACK_RADIUS
		if _spawn_marching(type, arena.clamp_inside(at, 8.0), aim, speed) == null:
			return


## Кольцо вокруг героя с шагом строя; точки за стенами пропускаются. Каждый враг идёт
## к центру так, чтобы к концу сжатия оказаться на RING_END, и там растворяется.
func _release_ring(event: Dictionary, type: EnemyData) -> void:
	var center := player.global_position
	var radius := float(event.get("radius", RING_RADIUS))
	var duration := float(event.get("duration", RING_TIME))
	var count := int(TAU * radius / LINE_STEP)
	for i in count:
		var direction := Vector2.from_angle(TAU * i / count)
		var at := center + direction * radius
		if not arena.contains(at, 8.0):
			continue
		var enemy := _spawn_marching(type, at, -direction, (radius - RING_END) / duration)
		if enemy == null:
			return
		enemy.vanish_at = GameState.elapsed + duration


## null — упёрлись в общий потолок врагов, дальше не выпускаем.
func _spawn_marching(type: EnemyData, at: Vector2, direction: Vector2, speed: float) -> Enemy:
	if get_tree().get_node_count_in_group(&"enemies") >= EnemySpawner.MAX_ENEMIES:
		return null
	var enemy := spawner._make(type, GameState.minutes(), false, at)
	enemy.k *= HP_MULT
	enemy.march_direction = direction
	enemy.march_speed = speed
	enemy.xp_chance = XP_CHANCE
	spawner.enemies_root.add_child(enemy)
	return enemy
