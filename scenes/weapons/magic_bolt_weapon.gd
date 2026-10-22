class_name MagicBoltWeapon
extends Weapon
## «Магический снаряд» — стартовое оружие мага. В режиме «Автоматически» стреляет
## в ближайшего врага, в режиме «По мыши» — к курсору (или по правому стику геймпада).
## На 5-м уровне каждый N-й снаряд взрывается при попадании.

## Угол между снарядами одного залпа, радианы (~12°).
const SPREAD := 0.21
const PROJECTILE_SPEED := 260.0
const BASE_RANGE := 200.0

var damage := 14.0
var fire_interval := 0.7
var projectile_count := 1.0
var pierce := 0.0
var resonance_every := 0.0
var resonance_radius := 0.0

var _cooldown := 0.5
## Сколько снарядов выпущено за забег (для взрыва каждого N-го).
var _shots := 0


func attack_range() -> float:
	return BASE_RANGE * area()


func _physics_process(delta: float) -> void:
	if player.dead:
		return
	_cooldown -= delta
	if _cooldown > 0.0:
		return
	var aim := _aim_direction()
	if aim == Vector2.ZERO:
		return
	_cooldown = cooldown_of(fire_interval)
	_fire(aim)


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	if SaveManager.aim_mode != SaveManager.AimMode.MOUSE or player.dead:
		return
	# Стрелка направления стрельбы вокруг героя.
	var aim := _manual_aim()
	var tip := aim * 18.0
	var side := aim.orthogonal() * 3.0
	draw_colored_polygon(PackedVector2Array([tip, aim * 12.0 + side, aim * 12.0 - side]), Color(0.85, 0.95, 1.0, 0.8))


## Направление выстрела; ZERO — стрелять некуда (в авторежиме нет врага в радиусе).
func _aim_direction() -> Vector2:
	if SaveManager.aim_mode == SaveManager.AimMode.MOUSE:
		return _manual_aim()
	var target := _nearest_enemy()
	if target == null:
		return Vector2.ZERO
	return global_position.direction_to(target.global_position + Vector2(0, -6))


func _manual_aim() -> Vector2:
	var stick := Vector2(Input.get_joy_axis(0, JOY_AXIS_RIGHT_X), Input.get_joy_axis(0, JOY_AXIS_RIGHT_Y))
	if stick.length() > 0.35:
		return stick.normalized()
	var to_mouse := get_global_mouse_position() - global_position
	return to_mouse.normalized() if to_mouse.length() > 1.0 else Vector2.RIGHT


func _nearest_enemy() -> Enemy:
	var best: Enemy = null
	var best_distance := attack_range() * attack_range()
	for node in get_tree().get_nodes_in_group(&"enemies"):
		var enemy := node as Enemy
		if enemy.dead:
			continue
		var distance := global_position.distance_squared_to(enemy.global_position)
		if distance < best_distance:
			best = enemy
			best_distance = distance
	return best


func _fire(aim: Vector2) -> void:
	var count := int(projectile_count)
	for i in count:
		var projectile := Projectile.new()
		projectile.position = global_position
		projectile.velocity = aim.rotated((i - (count - 1) / 2.0) * SPREAD) * PROJECTILE_SPEED
		projectile.damage = damage_of(damage)
		projectile.pierce = int(pierce)
		projectile.lifetime = attack_range() / PROJECTILE_SPEED * 1.3
		projectile.source = data.id
		_shots += 1
		if resonance_every > 0.0 and _shots % int(resonance_every) == 0:
			projectile.blast_radius = resonance_radius * area()
		player.projectile_root.add_child(projectile)
