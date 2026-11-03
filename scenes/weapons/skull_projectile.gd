class_name SkullProjectile
extends Node2D
## Череп, который летит за целью и проклинает её при попадании.

const SPEED := 150.0
const TURN := 6.0
const LIFETIME := 4.0

var target: Enemy
var damage := 40.0
var curse := 0.15
var curse_time := 4.0
var blast := 0.0
var blast_radius := 0.0
var source: StringName

var _velocity := Vector2.ZERO
var _time := 0.0
var _sprite: AnimatedSprite2D


func _ready() -> void:
	z_index = 1
	_sprite = SpriteLib.pack_sprite("projectiles/skull_cursed_flaming", 10.0)
	add_child(_sprite)
	if is_instance_valid(target):
		_velocity = global_position.direction_to(target.center()) * SPEED


func _physics_process(delta: float) -> void:
	_time += delta
	if _time >= LIFETIME or not is_instance_valid(target) or target.dead:
		queue_free()
		return
	var wanted := global_position.direction_to(target.center()) * SPEED
	_velocity = _velocity.lerp(wanted, minf(TURN * delta, 1.0))
	global_position += _velocity * delta
	# Спрайт нарисован летящим вправо: поворачиваем по скорости, не переворачивая череп вверх ногами.
	rotation = _velocity.angle()
	_sprite.flip_v = absf(wrapf(rotation, -PI, PI)) > PI / 2.0
	if global_position.distance_to(target.center()) < 6.0 + target.data.radius:
		target.curse(curse, curse_time, blast, blast_radius)
		target.take_damage(damage, _velocity.normalized(), source)
		queue_free()
