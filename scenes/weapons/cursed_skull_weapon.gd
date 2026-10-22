class_name CursedSkullWeapon
extends Weapon
## «Проклятый череп»: раз в interval секунд череп летит в самого живучего врага
## (босс, затем элита и огры по ступени, затем по здоровью) и проклинает его.
## На 5-м уровне проклятый враг при смерти взрывается. Колчан — ещё черепа в следующие цели.

const CAST_RANGE := 220.0
const BLAST_RADIUS := 40.0

var damage := 40.0
var interval := 3.0
var curse := 0.15
var curse_time := 4.0
var explode := false

var _cooldown := 1.2


func _physics_process(delta: float) -> void:
	if player.dead:
		return
	_cooldown -= delta
	if _cooldown > 0.0:
		return
	var targets := Enemy.in_radius(get_tree(), global_position, CAST_RANGE * area())
	if targets.is_empty():
		return
	_cooldown = cooldown_of(interval)
	targets.sort_custom(_tougher)
	for i in mini(1 + extra_projectiles(), targets.size()):
		var skull := SkullProjectile.new()
		skull.target = targets[i]
		skull.damage = damage_of(damage)
		skull.curse = curse
		skull.curse_time = curse_time
		if explode:
			skull.blast = damage_of(damage) * 0.5
			skull.blast_radius = BLAST_RADIUS * area()
		skull.source = data.id
		skull.position = global_position
		player.projectile_root.add_child(skull)


static func _tougher(a: Enemy, b: Enemy) -> bool:
	if a.data.is_boss != b.data.is_boss:
		return a.data.is_boss
	if a.data.tier != b.data.tier:
		return a.data.tier > b.data.tier
	return a.hp > b.hp
