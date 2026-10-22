class_name FrostBellWeapon
extends Weapon
## «Морозный колокол»: раз в interval секунд волна холода вокруг героя ранит и замедляет
## врагов, на 5-м уровне — замораживает (боссов только замедляет).

const WAVE_TIME := 0.35

var damage := 6.0
var radius := 70.0
var interval := 4.0
var slow := 0.3
var slow_time := 2.0
var freeze := 0.0

var _cooldown := 1.0
## Время с последнего удара колокола (для расходящегося кольца).
var _wave := WAVE_TIME


func _ready() -> void:
	z_index = -1


func _physics_process(delta: float) -> void:
	_wave += delta
	queue_redraw()
	if player.dead:
		return
	_cooldown -= delta
	if _cooldown > 0.0:
		return
	_cooldown = cooldown_of(interval)
	_wave = 0.0
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
	var r := _radius() * progress
	draw_circle(Vector2.ZERO, r, Color(0.6, 0.85, 1.0, 0.18 * (1.0 - progress)))
	draw_arc(Vector2.ZERO, r, 0.0, TAU, 48, Color(0.85, 0.95, 1.0, 1.0 - progress), 2.0)
