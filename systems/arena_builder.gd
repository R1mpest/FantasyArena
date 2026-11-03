class_name ArenaBuilder
extends Node2D
## Колизей: прямоугольник со срезанными углами, собранный из плиток 16x16 прямо в коде.
##
## Кольца от поля наружу: 0 — песок, 1 — бортик стены, 2 — стена, 3..7 — трибуны
## (публика / ступень / публика / ступень / публика), 8 — внешний бортик, дальше пусто.
## Центр поля — в точке (0, 0), герой стартует там.
##
## Для игры:
##   contains(p), clamp_inside(p, margin) — границы поля для героя и врагов;
##   gates — ворота (ArenaGate) с spawn_point и direction для спавнера;
##   camera_limits() — пределы для Camera2D;
##   set_cheering(true/false) — публика ликует или сидит спокойно;
##   emperor_gesture(&"idle" | &"up" | &"down") — жест императора в ложе;
##   herald_salute(helmet) — легат на балконе у ложи отдаёт честь (сам появляется
##   раз в HERALD_MIN..HERALD_MAX секунд, без шлема — с шансом HERALD_NO_HELMET).

const TILE := 16
## Поле в плитках: 88x56 = 1408x896 px.
const COLS := 88
const ROWS := 56
## Срез углов в плитках.
const CHAMFER := 8
## Сколько верхних рядов поля занимает лицевая сторона северной стены (по ней не ходят).
const FACE_ROWS := 2
const RINGS := 9

## Вариант графики песка: "day" — светлый дневной, "warm" — тёплый вечерний.
const VARIANT := "day"
const DIR := "res://assets/sprites/arena/" + VARIANT + "/"
## Легат и его балкон общие для всех вариантов песка.
const HERALD_DIR := "res://assets/sprites/arena/"
## Как часто легат сам выходит на балкон (сек) и шанс выйти без шлема.
const HERALD_MIN := 25.0
const HERALD_MAX := 50.0
const HERALD_NO_HELMET := 0.25
const BANNERS := ["red", "blue", "yellow", "green"]
const BANNER_PATH := "res://assets/sprites/0x72/frames/wall_banner_%s.png"

## Сдвиг сетки: поле центрировано в (0, 0).
const ORIGIN := Vector2(-COLS * TILE / 2.0, -ROWS * TILE / 2.0)

var gates: Array[ArenaGate] = []

var _base: TileMapLayer
var _crowd_calm: TileMapLayer
var _crowd_cheer: TileMapLayer
var _emperor: Sprite2D
var _rng := RandomNumberGenerator.new()
## Границы поля по отступу: clamp_inside зовут для сотен врагов каждый кадр.
var _planes_cache: Dictionary = {}
var _herald: Sprite2D
var _herald_rng := RandomNumberGenerator.new()
var _herald_wait := 0.0
var _herald_tween: Tween


func _ready() -> void:
	_rng.seed = 2026
	var tile_set := _make_tile_set(load(DIR + "arena_tiles.png"))
	_base = _make_layer(tile_set, -10)
	_crowd_calm = _make_layer(tile_set, -10)
	_crowd_cheer = _make_layer(tile_set, -10)
	_crowd_cheer.visible = false
	_fill_tiles()
	_add_decals()
	_add_gates()
	_add_braziers()
	_add_banners()
	_add_emperor()
	_add_herald()


func _process(delta: float) -> void:
	if _herald_tween and _herald_tween.is_running():
		return
	_herald_wait -= delta
	if _herald_wait <= 0.0:
		herald_salute(_herald_rng.randf() >= HERALD_NO_HELMET)


# ---------------------------------------------------------------- границы поля

## Полуплоскости поля: [нормаль внутрь (единичная), смещение]. Точка внутри, если n·p >= c.
func _planes(margin: float) -> Array:
	if _planes_cache.has(margin):
		return _planes_cache[margin]
	var w := COLS * TILE
	var h := ROWS * TILE
	var diag := TILE * (CHAMFER + 1) / sqrt(2.0) + margin
	var s := 1.0 / sqrt(2.0)
	var planes := [
		[Vector2(1, 0), margin],
		[Vector2(-1, 0), margin - w],
		[Vector2(0, 1), FACE_ROWS * TILE + margin],
		[Vector2(0, -1), margin - h],
		[Vector2(s, s), diag],
		[Vector2(-s, s), diag - w * s],
		[Vector2(s, -s), diag - h * s],
		[Vector2(-s, -s), diag - (w + h) * s],
	]
	_planes_cache[margin] = planes
	return planes


func contains(world: Vector2, margin: float = 0.0) -> bool:
	var p := world - ORIGIN
	for plane in _planes(margin):
		if (plane[0] as Vector2).dot(p) < plane[1]:
			return false
	return true


## Вернуть точку на поле: если она за стеной, выталкивается к ближайшей границе.
func clamp_inside(world: Vector2, margin: float = 6.0) -> Vector2:
	var p := world - ORIGIN
	for _pass in 2:
		for plane in _planes(margin):
			var n: Vector2 = plane[0]
			var d := n.dot(p) - float(plane[1])
			if d < 0.0:
				p -= n * d
	return p + ORIGIN


## Пределы камеры: вся арена с трибунами, дальше камера не уезжает.
func camera_limits() -> Rect2i:
	var pad := RINGS * TILE
	return Rect2i(
		Vector2i(ORIGIN) - Vector2i(pad, pad),
		Vector2i(COLS * TILE + 2 * pad, ROWS * TILE + 2 * pad))


func set_cheering(on: bool) -> void:
	_crowd_calm.visible = not on
	_crowd_cheer.visible = on


func emperor_gesture(gesture: StringName) -> void:
	_emperor.frame = {&"idle": 0, &"up": 1, &"down": 2}.get(gesture, 0)


## Легат выходит на балкон, отдаёт честь и уходит. Можно звать на события:
## победа над боссом, указ императора, начало раунда.
func herald_salute(helmet: bool = true) -> void:
	if _herald_tween:
		_herald_tween.kill()
	var first := 0 if helmet else 2
	_herald.frame = first
	_herald.visible = true
	_herald.modulate.a = 0.0
	_herald_tween = create_tween()
	_herald_tween.tween_property(_herald, "modulate:a", 1.0, 0.35)
	_herald_tween.tween_interval(0.6)
	_herald_tween.tween_callback(func() -> void: _herald.frame = first + 1)
	_herald_tween.tween_interval(2.2)
	_herald_tween.tween_callback(func() -> void: _herald.frame = first)
	_herald_tween.tween_interval(0.6)
	_herald_tween.tween_property(_herald, "modulate:a", 0.0, 0.35)
	_herald_tween.tween_callback(func() -> void: _herald.visible = false)
	_herald_wait = _herald_rng.randf_range(HERALD_MIN, HERALD_MAX)


## Для мокапов: сразу показать нужный кадр (0..3).
func herald_show(frame: int) -> void:
	if _herald_tween:
		_herald_tween.kill()
	_herald.frame = frame
	_herald.visible = true
	_herald.modulate.a = 1.0
	_herald_wait = INF


func cell_to_world(cell: Vector2) -> Vector2:
	return ORIGIN + cell * TILE


# ---------------------------------------------------------------- плитки

func _make_tile_set(texture: Texture2D) -> TileSet:
	var tile_set := TileSet.new()
	tile_set.tile_size = Vector2i(TILE, TILE)
	var source := TileSetAtlasSource.new()
	source.texture = texture
	source.texture_region_size = Vector2i(TILE, TILE)
	var static_tiles: Array = []
	static_tiles.append_array(ArenaTiles.SAND)
	static_tiles.append_array(ArenaTiles.WALL)
	static_tiles.append_array(ArenaTiles.EDGE.values())
	static_tiles.append_array(ArenaTiles.FACE_TOP)
	static_tiles.append_array(ArenaTiles.FACE_BOTTOM)
	static_tiles.append_array([ArenaTiles.STEP, ArenaTiles.RIM])
	for corner: String in ArenaTiles.DIAG:
		static_tiles.append_array(ArenaTiles.DIAG[corner])
	for coords: Vector2i in static_tiles:
		source.create_tile(coords)
	# Публика: анимированные плитки, кадры идут вправо от первого.
	for coords: Vector2i in ArenaTiles.CROWD_CALM + ArenaTiles.CROWD_CHEER:
		source.create_tile(coords)
		source.set_tile_animation_frames_count(coords, ArenaTiles.CROWD_FRAMES)
		var cheer := ArenaTiles.CROWD_CHEER.has(coords)
		for i in ArenaTiles.CROWD_FRAMES:
			source.set_tile_animation_frame_duration(coords, i, 0.22 if cheer else 0.6)
		source.set_tile_animation_mode(coords, TileSetAtlasSource.TILE_ANIMATION_MODE_RANDOM_START_TIMES)
	tile_set.add_source(source, 0)
	return tile_set


func _make_layer(tile_set: TileSet, z: int) -> TileMapLayer:
	var layer := TileMapLayer.new()
	layer.tile_set = tile_set
	layer.position = ORIGIN
	layer.z_index = z
	add_child(layer)
	return layer


## [кольцо, угол]: угол "" — прямой участок, иначе "TL"/"TR"/"BL"/"BR" — срез.
func _ring_of(x: int, y: int) -> Array:
	var axis := maxi(0, maxi(maxi(-x, x - (COLS - 1)), maxi(-y, y - (ROWS - 1))))
	var corners := {
		"TL": CHAMFER - (x + y),
		"TR": CHAMFER - ((COLS - 1 - x) + y),
		"BL": CHAMFER - (x + (ROWS - 1 - y)),
		"BR": CHAMFER - ((COLS - 1 - x) + (ROWS - 1 - y)),
	}
	var best_corner := ""
	var best := -1
	for corner: String in corners:
		if corners[corner] > best:
			best = corners[corner]
			best_corner = corner
	if best >= 0 and best >= axis:
		return [best, best_corner]
	return [axis, ""]


func _fill_tiles() -> void:
	for y in range(-RINGS, ROWS + RINGS):
		for x in range(-RINGS, COLS + RINGS):
			var info := _ring_of(x, y)
			var ring: int = info[0]
			var corner: String = info[1]
			var cell := Vector2i(x, y)
			if ring >= RINGS:
				continue
			if corner != "":
				_base.set_cell(cell, 0, ArenaTiles.DIAG[corner][ring])
				continue
			match ring:
				0:
					if y < FACE_ROWS:
						var face: Array = ArenaTiles.FACE_TOP if y == 0 else ArenaTiles.FACE_BOTTOM
						_base.set_cell(cell, 0, face[_rng.randi() % face.size()])
					else:
						_base.set_cell(cell, 0, _weighted(ArenaTiles.SAND, ArenaTiles.SAND_WEIGHTS))
				1:
					_base.set_cell(cell, 0, ArenaTiles.EDGE[_side_of(x, y)])
				2:
					_base.set_cell(cell, 0, _weighted(ArenaTiles.WALL, ArenaTiles.WALL_WEIGHTS))
				3, 5, 7:
					var v := _rng.randi() % ArenaTiles.CROWD_CALM.size()
					_crowd_calm.set_cell(cell, 0, ArenaTiles.CROWD_CALM[v])
					_crowd_cheer.set_cell(cell, 0, ArenaTiles.CROWD_CHEER[v])
				4, 6:
					_base.set_cell(cell, 0, ArenaTiles.STEP)
				8:
					_base.set_cell(cell, 0, ArenaTiles.RIM)


## Случайная плитка из списка с весами.
func _weighted(tiles: Array, weights: Array) -> Vector2i:
	var total := 0
	for w: int in weights:
		total += w
	var roll := _rng.randi() % total
	for i in weights.size():
		roll -= weights[i]
		if roll < 0:
			return tiles[i]
	return tiles[0]


func _side_of(x: int, y: int) -> String:
	if y < 0:
		return "N"
	if y >= ROWS:
		return "S"
	if x < 0:
		return "W"
	return "E"


# ---------------------------------------------------------------- модули

func _sprite(texture: Texture2D, at: Vector2, z: int, centered: bool = false) -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.texture = texture
	sprite.centered = centered
	sprite.position = at
	sprite.z_index = z
	add_child(sprite)
	return sprite


func _add_decals() -> void:
	_sprite(load(DIR + "emblem.png"), Vector2.ZERO, -9, true)
	var stains := [load(DIR + "stain_0.png"), load(DIR + "stain_1.png")]
	var placed := 0
	while placed < 12:
		var p := Vector2(_rng.randf_range(-640, 640), _rng.randf_range(-400, 420))
		if contains(p, 40.0) and p.length() > 70.0:
			_sprite(stains[placed % 2], p, -9, true)
			placed += 1


func _add_gates() -> void:
	var glow: Texture2D = load(DIR + "glow.png")
	var north_large: Texture2D = load(DIR + "gate_north_large.png")
	var north_small: Texture2D = load(DIR + "gate_north_small.png")
	var south: Texture2D = load(DIR + "gate_south.png")
	var side: Texture2D = load(DIR + "gate_side.png")
	# [текстура, размер кадра, кадров, левая верхняя клетка, точка спавна (клетки), направление, отразить, главные]
	var specs := [
		[north_large, Vector2i(64, 64), 4, Vector2i(42, -2), Vector2(44, 2.5), Vector2.DOWN, false, true],
		[north_small, Vector2i(48, 64), 4, Vector2i(21, -2), Vector2(22.5, 2.5), Vector2.DOWN, false, false],
		[north_small, Vector2i(48, 64), 4, Vector2i(64, -2), Vector2(65.5, 2.5), Vector2.DOWN, false, false],
		[south, Vector2i(48, 32), 3, Vector2i(43, ROWS), Vector2(44.5, ROWS - 0.5), Vector2.UP, false, false],
		[south, Vector2i(48, 32), 3, Vector2i(21, ROWS), Vector2(22.5, ROWS - 0.5), Vector2.UP, false, false],
		[south, Vector2i(48, 32), 3, Vector2i(64, ROWS), Vector2(65.5, ROWS - 0.5), Vector2.UP, false, false],
		[side, Vector2i(32, 48), 3, Vector2i(-2, 27), Vector2(0.5, 28.5), Vector2.RIGHT, true, false],
		[side, Vector2i(32, 48), 3, Vector2i(COLS, 27), Vector2(COLS - 0.5, 28.5), Vector2.LEFT, false, false],
	]
	for spec in specs:
		var gate := ArenaGate.new()
		gate.position = cell_to_world(Vector2(spec[3]))
		gate.z_index = -8
		add_child(gate)
		gate.setup(spec[0], spec[1], spec[2], glow, spec[6])
		gate.spawn_point = cell_to_world(spec[4])
		gate.direction = spec[5]
		gate.is_main = spec[7]
		gate.place_glow()
		gates.append(gate)


func _add_braziers() -> void:
	var strip: Texture2D = load(DIR + "brazier.png")
	var glow: Texture2D = load(DIR + "glow.png")
	var frames := SpriteFrames.new()
	frames.set_animation_speed(&"default", 8.0)
	for i in 4:
		var frame := AtlasTexture.new()
		frame.atlas = strip
		frame.region = Rect2(i * 16, 0, 16, 24)
		frames.add_frame(&"default", frame)
	var cells := [
		Vector2(14, 2.4), Vector2(32, 2.4), Vector2(56, 2.4), Vector2(74, 2.4),
		Vector2(14, ROWS - 0.6), Vector2(32, ROWS - 0.6), Vector2(56, ROWS - 0.6), Vector2(74, ROWS - 0.6),
		Vector2(0.8, 14), Vector2(0.8, 42), Vector2(COLS - 0.8, 14), Vector2(COLS - 0.8, 42),
	]
	for cell: Vector2 in cells:
		var at := cell_to_world(cell)
		_sprite(glow, at + Vector2(0, -4), -9, true)
		var brazier := AnimatedSprite2D.new()
		brazier.sprite_frames = frames
		brazier.position = at + Vector2(0, -12)
		brazier.z_index = -5
		brazier.frame = _rng.randi() % 4
		brazier.play()
		add_child(brazier)


func _add_banners() -> void:
	var xs := [10, 16, 29, 35, 52, 58, 71, 77]
	for i in xs.size():
		var texture: Texture2D = load(BANNER_PATH % BANNERS[i % BANNERS.size()])
		_sprite(texture, cell_to_world(Vector2(xs[i], 0)) + Vector2(0, 4), -8)


func _add_emperor() -> void:
	_emperor = _sprite(load(DIR + "emperor_box.png"), cell_to_world(Vector2(40, -7)), -8)
	_emperor.hframes = 3


func _add_herald() -> void:
	# Балкон справа от ложи, перила на уровне перил ложи.
	var top := cell_to_world(Vector2(48, -7)) + Vector2(-2, 52)
	_sprite(load(HERALD_DIR + "herald_balcony.png"), top, -7)
	_herald = _sprite(load(HERALD_DIR + "herald.png"), top + Vector2(4, 10 - 48), -8)
	_herald.hframes = 4
	_herald.visible = false
	_herald_rng.randomize()
	_herald_wait = _herald_rng.randf_range(HERALD_MIN * 0.4, HERALD_MAX * 0.6)
