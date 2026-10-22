class_name NecromancerBoss
extends Boss
## «Некромант» (10:00): держит дистанцию, стреляет веером, поднимает скелетов
## (сначала метка призыва) и телепортируется, если герой подошёл вплотную.

const KEEP_DISTANCE := 150.0
const FAN_INTERVAL := 2.5
const FAN_COUNT := 5
const FAN_SPREAD := 0.22
const SHOT_SPEED := 110.0
const SHOT_DAMAGE := 10.0
const SUMMON_INTERVAL := 9.0
const SUMMON_WINDUP := 0.8
const SUMMON_COUNT := 6
const BLINK_RANGE := 70.0
const BLINK_COOLDOWN := 4.0
const MAGIC := Color(0.75, 0.45, 1.0)

var _fan := 1.5
var _summon := 5.0
var _blink := 0.0
var _strafe := 1.0


func _boss_process(delta: float) -> void:
	var to_hero := hero_center() - center()
	var distance := to_hero.length()
	var direction := to_hero.normalized()
	var move := direction.orthogonal() * _strafe * 0.6
	if distance > KEEP_DISTANCE + 20.0:
		move = direction
	elif distance < KEEP_DISTANCE - 30.0:
		move = -direction
	walk_toward(global_position + move * 10.0, delta)
	_sprite.flip_h = direction.x < 0.0

	_blink -= delta
	if distance < BLINK_RANGE and _blink <= 0.0:
		_blink = BLINK_COOLDOWN
		_strafe = -_strafe
		flash_blast(center(), 20.0, MAGIC)
		global_position = target.global_position + Vector2.from_angle(randf() * TAU) * 160.0
		flash_blast(center(), 20.0, MAGIC)

	_fan -= delta
	if _fan <= 0.0:
		_fan = FAN_INTERVAL
		for i in FAN_COUNT:
			shoot(direction.rotated((i - (FAN_COUNT - 1) / 2.0) * FAN_SPREAD), SHOT_SPEED, SHOT_DAMAGE, MAGIC)

	_summon -= delta
	if _summon <= 0.0:
		_summon = SUMMON_INTERVAL
		telegraph_circle(center(), 45.0, SUMMON_WINDUP, MAGIC, summon.bind(&"skelet", SUMMON_COUNT, 40.0))
