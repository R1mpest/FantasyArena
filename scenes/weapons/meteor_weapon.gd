class_name MeteorWeapon
extends Weapon
## «Огненный дождь»: раз в interval секунд на врагов рядом падают огненные шары.
## На 5-м уровне место падения горит.

const CAST_RANGE := 200.0

var damage := 35.0
var blast_radius := 30.0
var interval := 2.0
var count := 1.0
var burn := false
var burn_dps := 12.0
var burn_time := 3.0

var _cooldown := 0.6


func _physics_process(delta: float) -> void:
	if player.dead:
		return
	_cooldown -= delta
	if _cooldown > 0.0:
		return
	_cooldown = cooldown_of(interval)
	var near := Enemy.in_radius(get_tree(), player.global_position, CAST_RANGE * area())
	near.shuffle()
	for i in int(count) + extra_projectiles():
		var meteor := Meteor.new()
		meteor.damage = damage_of(damage)
		meteor.radius = blast_radius * area()
		meteor.source = data.id
		if burn:
			meteor.burn_dps = damage_of(burn_dps)
			meteor.burn_time = burn_time
		meteor.position = _target(near, i)
		player.projectile_root.add_child(meteor)


func _target(near: Array[Enemy], index: int) -> Vector2:
	if index < near.size():
		return near[index].center()
	return player.global_position + Vector2.from_angle(randf() * TAU) * randf_range(40.0, 120.0)
