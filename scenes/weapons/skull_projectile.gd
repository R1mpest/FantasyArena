class_name SkullProjectile
extends Node2D
## Череп, который летит за целью и проклинает её при попадании.

const SPEED := 150.0
const TURN := 6.0
const LIFETIME := 4.0
const TEXTURE := preload("res://assets/sprites/0x72/frames/skull.png")

var target: Enemy
var damage := 40.0
var curse := 0.15
var curse_time := 4.0
var blast := 0.0
var blast_radius := 0.0
var source: StringName

var _velocity := Vector2.ZERO
var _time := 0.0


func _ready() -> void:
	z_index = 1
	var sprite := Sprite2D.new()
	sprite.texture = TEXTURE
	sprite.modulate = Color(0.85, 0.6, 1.0)
	add_child(sprite)
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
	rotation = sin(_time * 10.0) * 0.2
	if global_position.distance_to(target.center()) < 6.0 + target.data.radius:
		target.curse(curse, curse_time, blast, blast_radius)
		target.take_damage(damage, _velocity.normalized(), source)
		queue_free()
