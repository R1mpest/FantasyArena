class_name DemonBoss
extends Boss
## «Большой демон» (15:00, финальный). Фаза 1: кольца огненных снарядов с «окном»
## для прохода и метеоры по меткам. Фаза 2 (меньше 50% здоровья): быстрее,
## атаки чаще, призывает бесят.

const RING_INTERVAL := 3.0
const RING_COUNT := 16
const RING_GAP := 3
const RING_SPEED := 90.0
const RING_DAMAGE := 12.0
const METEOR_INTERVAL := 5.0
const METEOR_DELAY := 1.0
const METEOR_RADIUS := 30.0
const METEOR_DAMAGE := 20.0
const IMP_INTERVAL := 6.0
const IMP_COUNT := 4
const ENRAGE_AT := 0.5
const ENRAGED_SPEED := 1.4
const ENRAGED_RATE := 1.0 / 0.7
const FIRE := Color(1.0, 0.45, 0.15)

var enraged := false

var _ring := 2.0
var _meteors := 4.0
var _imps := 2.0


func _boss_process(delta: float) -> void:
	if not enraged and hp < full_hp * ENRAGE_AT:
		enraged = true
		flash_blast(center(), 60.0, FIRE)
	var rate := ENRAGED_RATE if enraged else 1.0
	walk_toward(target.global_position, delta, ENRAGED_SPEED if enraged else 1.0)

	_ring -= delta * rate
	if _ring <= 0.0:
		_ring = RING_INTERVAL
		_fire_ring()

	_meteors -= delta * rate
	if _meteors <= 0.0:
		_meteors = METEOR_INTERVAL
		var points := [hero_center()]
		for i in 2:
			points.append(hero_center() + Vector2.from_angle(randf() * TAU) * randf_range(30.0, 90.0))
		for point: Vector2 in points:
			telegraph_circle(point, METEOR_RADIUS, METEOR_DELAY, FIRE, _meteor_hit.bind(point))

	if enraged:
		_imps -= delta
		if _imps <= 0.0:
			_imps = IMP_INTERVAL
			summon(&"imp", IMP_COUNT, 30.0)


## Кольцо снарядов, в котором пропущено RING_GAP подряд — проход для героя.
func _fire_ring() -> void:
	var gap_start := randi() % RING_COUNT
	var offset := randf() * TAU
	for i in RING_COUNT:
		if (i - gap_start + RING_COUNT) % RING_COUNT < RING_GAP:
			continue
		shoot(Vector2.from_angle(offset + TAU * i / RING_COUNT), RING_SPEED, RING_DAMAGE, FIRE)


func _meteor_hit(point: Vector2) -> void:
	if dead:
		return
	flash_blast(point, METEOR_RADIUS, FIRE)
	if hits_hero(point, METEOR_RADIUS):
		hero().take_damage(METEOR_DAMAGE)
