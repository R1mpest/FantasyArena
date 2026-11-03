class_name FrostBellWeapon
extends Weapon
## «Морозный колокол»: раз в interval секунд волна холода вокруг героя ранит и замедляет
## врагов, на 5-м уровне — замораживает (боссов только замедляет).
##
## Кольцо волны рисуется кодом попиксельно (алгоритм средней точки), а не растянутым
## спрайтом: при любом радиусе линия остаётся толщиной в 1 игровой пиксель и совпадает
## по стилю с ассет-паком.

const WAVE_TIME := 0.35

## Цвета из палитры пака.
const COLOR_RING := Color("4fc3e0")
const COLOR_GLINT := Color("9ff3ff")
const COLOR_FLAKE := Color("f4f4f4")
const COLOR_FILL := Color(0.62, 0.95, 1.0, 0.10)
## Внутренний блик рисуется пунктиром: столько отрезков на круг (чётные видимы).
const GLINT_SEGMENTS := 16
const FLAKES := 6

var damage := 6.0
var radius := 70.0
var interval := 4.0
var slow := 0.3
var slow_time := 2.0
var freeze := 0.0

var _cooldown := 1.0
## Время с последнего удара колокола (для расходящегося кольца).
var _wave := WAVE_TIME
## Кэш точек окружности: радиус в пикселях -> PackedVector2Array.
var _circle_cache: Dictionary = {}


func _ready() -> void:
	z_index = -1


func _physics_process(delta: float) -> void:
	if _wave < WAVE_TIME:
		_wave += delta
		queue_redraw()
	if player.dead:
		return
	_cooldown -= delta
	if _cooldown > 0.0:
		return
	_cooldown = cooldown_of(interval)
	_wave = 0.0
	Sfx.play(&"bell")
	queue_redraw()
	for enemy in Enemy.in_radius(get_tree(), global_position, _radius()):
		enemy.take_damage(damage_of(damage), Vector2.ZERO, data.id)
		enemy.apply_slow(slow, slow_time)
		if freeze > 0.0:
			enemy.freeze(freeze)


func _radius() -> float:
	return radius * area()


func _draw() -> void:
	if _wave >= WAVE_TIME:
		return
	var progress := _wave / WAVE_TIME
	# Быстрый выброс в начале и плавное замедление к краю.
	var eased := 1.0 - (1.0 - progress) * (1.0 - progress)
	var r := maxi(2, roundi(_radius() * eased))
	# Кольцо держится ярким и гаснет в последней трети.
	var alpha := clampf((1.0 - progress) * 1.6, 0.0, 1.0)
	# Привязка к целым пикселям мира: иначе при движении героя кольцо «дрожит».
	var origin := global_position.round() - global_position

	draw_circle(origin, r, Color(COLOR_FILL, COLOR_FILL.a * alpha))
	_draw_pixel_ring(origin, r, Color(COLOR_RING, alpha))
	_draw_pixel_ring(origin, r - 1, Color(COLOR_GLINT, alpha), true)
	_draw_flakes(origin, r + 2, progress, Color(COLOR_FLAKE, alpha))


## Окружность толщиной в 1 пиксель. dashed — рисовать только чётные отрезки по углу.
func _draw_pixel_ring(origin: Vector2, r: int, color: Color, dashed: bool = false) -> void:
	if r < 1:
		return
	for point: Vector2 in _circle_points(r):
		if dashed:
			var segment := int((point.angle() + PI) / (TAU / GLINT_SEGMENTS))
			if segment % 2 != 0:
				continue
		draw_rect(Rect2(origin + point, Vector2.ONE), color)


## Снежинки снаружи кольца, медленно поворачиваются вместе с волной.
func _draw_flakes(origin: Vector2, r: int, progress: float, color: Color) -> void:
	for k in FLAKES:
		var angle := k * TAU / FLAKES + progress * 0.6
		var at := (Vector2.from_angle(angle) * r).round()
		draw_rect(Rect2(origin + at, Vector2.ONE), color)


## Точки окружности радиуса r по алгоритму средней точки (Брезенхэм).
func _circle_points(r: int) -> PackedVector2Array:
	if _circle_cache.has(r):
		return _circle_cache[r]
	var points := PackedVector2Array()
	var x := r
	var y := 0
	var err := 1 - r
	while x >= y:
		points.append_array([
			Vector2(x, y), Vector2(y, x), Vector2(-y, x), Vector2(-x, y),
			Vector2(-x, -y), Vector2(-y, -x), Vector2(y, -x), Vector2(x, -y),
		])
		y += 1
		if err < 0:
			err += 2 * y + 1
		else:
			x -= 1
			err += 2 * (y - x) + 1
	# На стыках октантов (y = 0 и x = y) одни и те же пиксели попадают дважды —
	# при полупрозрачном кольце они стали бы ярче соседних. Оставляем по одному.
	var unique := {}
	for point in points:
		unique[point] = true
	points = PackedVector2Array(unique.keys())
	_circle_cache[r] = points
	return points
