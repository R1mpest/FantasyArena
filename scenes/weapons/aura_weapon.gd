class_name AuraWeapon
extends Weapon
## «Священная аура»: раз в tick секунд бьёт всех врагов внутри круга вокруг героя.
## На 5-м уровне ещё и замедляет их.

var damage := 8.0
var radius := 42.0
var tick := 0.5
var slow := 0.0

var _timer := 0.0
var _pulse := 0.0


func _ready() -> void:
	z_index = -1


func _physics_process(delta: float) -> void:
	_pulse = maxf(0.0, _pulse - delta * 3.0)
	queue_redraw()
	if player.dead:
		return
	_timer -= delta
	if _timer > 0.0:
		return
	_timer = cooldown_of(tick)
	for enemy in Enemy.in_radius(get_tree(), global_position, _radius()):
		enemy.take_damage(damage_of(damage), Vector2.ZERO, data.id)
		if slow > 0.0:
			enemy.apply_slow(slow, _timer * 1.5)
	_pulse = 1.0


func _radius() -> float:
	return radius * area()


func _draw() -> void:
	var r := _radius()
	# Святой свет: золотые цвета из иконки ауры.
	draw_circle(Vector2.ZERO, r, Color(1.0, 0.85, 0.3, 0.12 + 0.12 * _pulse))
	draw_arc(Vector2.ZERO, r, 0.0, TAU, 56, Color(1.0, 0.9, 0.43, 0.55 + 0.4 * _pulse), 1.0)
