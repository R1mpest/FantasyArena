class_name ChainLightningWeapon
extends Weapon
## «Цепная молния»: бьёт ближайшего врага и перескакивает на соседних, каждый
## перескок слабее на falloff. Колчан даёт дополнительные разряды от других целей.

const CAST_RANGE := 180.0
const JUMP_RANGE := 70.0

var damage := 20.0
var jumps := 3.0
var interval := 1.8
var falloff := 0.1

var _cooldown := 0.8


func _physics_process(delta: float) -> void:
	if player.dead:
		return
	_cooldown -= delta
	if _cooldown > 0.0:
		return
	var origin := global_position
	var near := Enemy.in_radius(get_tree(), origin, CAST_RANGE * area())
	if near.is_empty():
		return
	_cooldown = cooldown_of(interval)
	near.sort_custom(func(a: Enemy, b: Enemy) -> bool:
		return origin.distance_squared_to(a.center()) < origin.distance_squared_to(b.center()))
	var hit := {}
	for chain in 1 + extra_projectiles():
		var first: Enemy = null
		for enemy in near:
			if not hit.has(enemy) and not enemy.dead:
				first = enemy
				break
		if first == null:
			break
		_chain_from(origin, first, hit)


func _chain_from(origin: Vector2, first: Enemy, hit: Dictionary) -> void:
	var from := origin
	var current := first
	var strike := damage_of(damage)
	for i in int(jumps) + 1:
		hit[current] = true
		_bolt(from, current.center())
		from = current.center()
		current.take_damage(strike, Vector2.ZERO, data.id)
		strike *= 1.0 - falloff
		current = _next_target(from, hit)
		if current == null:
			break


func _next_target(from: Vector2, hit: Dictionary) -> Enemy:
	var best: Enemy = null
	var best_distance := INF
	for enemy in Enemy.in_radius(get_tree(), from, JUMP_RANGE * area()):
		var distance := from.distance_squared_to(enemy.center())
		if not hit.has(enemy) and distance < best_distance:
			best = enemy
			best_distance = distance
	return best


func _bolt(from: Vector2, to: Vector2) -> void:
	var bolt := LightningFx.new()
	bolt.from = from
	bolt.to = to
	player.projectile_root.add_child(bolt)
