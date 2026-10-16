class_name AutoWeapon
extends Node2D
## Стартовое оружие «Магический снаряд»: само стреляет в ближайшего врага.

## Угол между снарядами одного залпа, радианы (~12°).
const SPREAD := 0.21

var player: Player

var _cooldown := 0.5
## Сколько снарядов выпущено за забег (для «Резонанса»).
var _shots := 0


func _physics_process(delta: float) -> void:
	if player.dead:
		return
	_cooldown -= delta
	if _cooldown > 0.0:
		return
	var target := _nearest_enemy()
	if target == null:
		return
	_cooldown = player.fire_interval / player.attack_speed()
	_fire(target)


func _nearest_enemy() -> Enemy:
	var best: Enemy = null
	var best_distance := player.attack_range * player.attack_range
	for node in get_tree().get_nodes_in_group(&"enemies"):
		var enemy := node as Enemy
		if enemy.dead:
			continue
		var distance := global_position.distance_squared_to(enemy.global_position)
		if distance < best_distance:
			best = enemy
			best_distance = distance
	return best


func _fire(target: Enemy) -> void:
	var aim := global_position.direction_to(target.global_position + Vector2(0, -6))
	var count := int(player.projectile_count)
	for i in count:
		var projectile := Projectile.new()
		projectile.position = global_position
		projectile.velocity = aim.rotated((i - (count - 1) / 2.0) * SPREAD) * player.projectile_speed
		projectile.damage = player.damage * player.might
		projectile.pierce = int(player.pierce)
		projectile.lifetime = player.attack_range / player.projectile_speed * 1.3
		_shots += 1
		if player.resonance_every > 0 and _shots % player.resonance_every == 0:
			projectile.blast_radius = player.resonance_radius
		player.projectile_root.add_child(projectile)
