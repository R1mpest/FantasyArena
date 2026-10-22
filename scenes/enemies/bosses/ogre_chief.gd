class_name OgreChief
extends Boss
## «Огр-вожак» (5:00): идёт на героя и чередует две атаки —
## рывок по прямой (сначала полоса-предупреждение) и удар о землю (кольцо вокруг себя).

enum State { WALK, CHARGE_WINDUP, CHARGE, SLAM_WINDUP }

const WALK_TIME := 2.5
const CHARGE_WINDUP := 0.8
const CHARGE_LENGTH := 180.0
const CHARGE_SPEED := 320.0
const CHARGE_DAMAGE := 20.0
const SLAM_WINDUP := 0.9
const SLAM_RADIUS := 70.0
const SLAM_DAMAGE := 25.0
const DANGER := Color(1.0, 0.3, 0.2)

var _state := State.WALK
var _timer := WALK_TIME
var _charge_next := true
var _charge_direction := Vector2.RIGHT
var _charge_hit := false


func _boss_process(delta: float) -> void:
	_timer -= delta
	match _state:
		State.WALK:
			walk_toward(target.global_position, delta)
			if _timer <= 0.0:
				_start_attack()
		State.CHARGE_WINDUP:
			if _timer <= 0.0:
				_state = State.CHARGE
				_timer = CHARGE_LENGTH / CHARGE_SPEED
				_charge_hit = false
		State.CHARGE:
			global_position += _charge_direction * CHARGE_SPEED * delta
			if not _charge_hit and hits_hero(center(), data.radius * scale.x + 6.0):
				_charge_hit = true
				hero().take_damage(CHARGE_DAMAGE)
			if _timer <= 0.0:
				_walk()
		State.SLAM_WINDUP:
			if _timer <= 0.0:
				_walk()


func _start_attack() -> void:
	if _charge_next:
		_charge_direction = center().direction_to(hero_center())
		telegraph_line(center(), _charge_direction, CHARGE_LENGTH, 22.0, CHARGE_WINDUP, DANGER)
		_state = State.CHARGE_WINDUP
		_timer = CHARGE_WINDUP
	else:
		telegraph_circle(center(), SLAM_RADIUS, SLAM_WINDUP, DANGER, _slam)
		_state = State.SLAM_WINDUP
		_timer = SLAM_WINDUP
	_charge_next = not _charge_next


func _slam() -> void:
	if dead:
		return
	flash_blast(center(), SLAM_RADIUS, Color(1.0, 0.55, 0.2))
	if hits_hero(center(), SLAM_RADIUS):
		hero().take_damage(SLAM_DAMAGE)


func _walk() -> void:
	_state = State.WALK
	_timer = WALK_TIME
