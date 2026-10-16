class_name MeteorWeapon
extends Weapon
## «Огненный дождь»: раз в interval секунд на случайного врага рядом падает огненный шар.

const CAST_RANGE := 200.0

var damage := 35.0
var blast_radius := 30.0
var interval := 2.0

var _cooldown := 0.6


func _physics_process(delta: float) -> void:
	if player.dead:
		return
	_cooldown -= delta
	if _cooldown > 0.0:
		return
	_cooldown = interval / player.attack_speed()
	var meteor := Meteor.new()
	meteor.damage = damage * player.might
	meteor.radius = blast_radius
	meteor.position = _pick_target()
	player.projectile_root.add_child(meteor)


func _pick_target() -> Vector2:
	var near := Enemy.in_radius(get_tree(), player.global_position, CAST_RANGE)
	if near.is_empty():
		return player.global_position + Vector2.from_angle(randf() * TAU) * randf_range(40.0, 120.0)
	return near.pick_random().center()
